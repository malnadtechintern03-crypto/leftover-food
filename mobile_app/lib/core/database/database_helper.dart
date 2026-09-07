import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import '../constants/app_constants.dart';

/// Database helper managing SQLite connection, schema lifecycle, migrations, and cross-platform safety
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _ffiInitialized = false;

  DatabaseHelper._init();

  /// Ensures FFI is initialized on desktop platforms (Windows, Linux, macOS)
  static void ensureFfiInitialized() {
    if (_ffiInitialized || kIsWeb) return;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        ffi.sqfliteFfiInit();
        databaseFactory = ffi.databaseFactoryFfi;
        _ffiInitialized = true;
      }
    } catch (e) {
      debugPrint('DatabaseHelper FFI init note: $e');
    }
  }

  static Future<Database?>? _openDbFuture;

  Future<Database?> get database async {
    if (_database != null) return _database;
    if (_openDbFuture != null) return _openDbFuture!;
    _openDbFuture = _initDB(AppConstants.databaseName);
    _database = await _openDbFuture;
    _openDbFuture = null;
    return _database;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) {
      return null;
    }

    try {
      ensureFfiInitialized();
      String dbPath;
      try {
        final dbFolder = await getDatabasesPath();
        dbPath = join(dbFolder, filePath);
      } catch (_) {
        dbPath = filePath;
      }

      return await openDatabase(
        dbPath,
        version: AppConstants.databaseVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: _onOpenDB,
      );
    } catch (e) {
      debugPrint('DatabaseHelper note: SQLite init returned fallback ($e)');
      return null;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Food & Universal Products Items table
    await db.execute('''
      CREATE TABLE ${AppConstants.foodTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        barcode TEXT,
        image_path TEXT,
        category TEXT NOT NULL,
        subcategory TEXT,
        remaining_quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        manufacturing_date TEXT,
        expiry_date TEXT,
        reminder_date TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_days_before TEXT DEFAULT '7',
        notification_id INTEGER,
        expiry_status TEXT DEFAULT 'Safe',
        last_notification_sent TEXT,
        notes TEXT,
        is_consumed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        minimum_stock REAL,
        price REAL,
        storage_location TEXT NOT NULL DEFAULT 'pantry',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_interval INTEGER,
        next_reminder_date TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_food_expiry ON ${AppConstants.foodTable} (expiry_date);',
    );
    await db.execute(
      'CREATE INDEX idx_food_consumed ON ${AppConstants.foodTable} (is_consumed);',
    );
    await db.execute(
      'CREATE INDEX idx_food_category ON ${AppConstants.foodTable} (category);',
    );
    await db.execute(
      'CREATE INDEX idx_food_favorite ON ${AppConstants.foodTable} (is_favorite);',
    );
    await db.execute(
      'CREATE INDEX idx_food_location ON ${AppConstants.foodTable} (storage_location);',
    );
    await db.execute(
      'CREATE INDEX idx_food_barcode ON ${AppConstants.foodTable} (barcode);',
    );

    // 2. Shopping Items table
    await db.execute('''
      CREATE TABLE ${AppConstants.shoppingTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Waste Records table
    await db.execute('''
      CREATE TABLE ${AppConstants.wasteTable} (
        id TEXT PRIMARY KEY,
        food_id TEXT,
        food_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        waste_reason TEXT NOT NULL,
        estimated_cost REAL,
        wasted_at TEXT NOT NULL
      )
    ''');

    // 4. Budget Settings table
    await db.execute('''
      CREATE TABLE ${AppConstants.budgetTable} (
        id TEXT PRIMARY KEY,
        monthly_budget REAL NOT NULL DEFAULT 5000.0,
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        updated_at TEXT NOT NULL
      )
    ''');

    // 5. Recipe Favorites table
    await db.execute('''
      CREATE TABLE ${AppConstants.recipeFavoritesTable} (
        recipe_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');

    // 6. Product Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.remindersTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'default_user',
        product_id TEXT NOT NULL,
        reminder_date TEXT NOT NULL,
        days_before_expiry INTEGER NOT NULL,
        notification_id INTEGER NOT NULL,
        is_sent INTEGER NOT NULL DEFAULT 0,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reminders_product ON ${AppConstants.remindersTable} (product_id);',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_user ON ${AppConstants.remindersTable} (user_id);',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_date ON ${AppConstants.remindersTable} (reminder_date);',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_sent ON ${AppConstants.remindersTable} (is_sent);',
    );

    // 7. Sync Queue table for offline/online synchronization
    await db.execute('''
      CREATE TABLE ${AppConstants.syncQueueTable} (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Safe non-destructive column additions
      await _safelyAddColumn(db, AppConstants.foodTable, 'minimum_stock', 'REAL');
      await _safelyAddColumn(db, AppConstants.foodTable, 'price', 'REAL');
      await _safelyAddColumn(
          db, AppConstants.foodTable, 'storage_location', "TEXT NOT NULL DEFAULT 'pantry'");
      await _safelyAddColumn(
          db, AppConstants.foodTable, 'is_favorite', 'INTEGER NOT NULL DEFAULT 0');
      await _safelyAddColumn(
          db, AppConstants.foodTable, 'is_recurring', 'INTEGER NOT NULL DEFAULT 0');
      await _safelyAddColumn(db, AppConstants.foodTable, 'recurring_interval', 'INTEGER');
      await _safelyAddColumn(db, AppConstants.foodTable, 'next_reminder_date', 'TEXT');
      await _safelyAddColumn(db, AppConstants.foodTable, 'barcode', 'TEXT');

      // Create new tables if not already created
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.shoppingTable} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          category TEXT NOT NULL,
          is_purchased INTEGER NOT NULL DEFAULT 0,
          priority TEXT NOT NULL DEFAULT 'medium',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.wasteTable} (
          id TEXT PRIMARY KEY,
          food_id TEXT,
          food_name TEXT NOT NULL,
          category TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          waste_reason TEXT NOT NULL,
          estimated_cost REAL,
          wasted_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.budgetTable} (
          id TEXT PRIMARY KEY,
          monthly_budget REAL NOT NULL DEFAULT 5000.0,
          currency_symbol TEXT NOT NULL DEFAULT '₹',
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.recipeFavoritesTable} (
          recipe_id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Safe v4 column additions for Universal Products & Expiration Reminders
      await _safelyAddColumn(db, AppConstants.foodTable, 'brand', 'TEXT');
      await _safelyAddColumn(db, AppConstants.foodTable, 'subcategory', 'TEXT');
      await _safelyAddColumn(db, AppConstants.foodTable, 'manufacturing_date', 'TEXT');
      await _safelyAddColumn(db, AppConstants.foodTable, 'reminder_date', 'TEXT');
      await _safelyAddColumn(db, AppConstants.foodTable, 'reminder_enabled', 'INTEGER NOT NULL DEFAULT 1');
      await _safelyAddColumn(db, AppConstants.foodTable, 'reminder_days_before', "TEXT DEFAULT '7'");
      await _safelyAddColumn(db, AppConstants.foodTable, 'notification_id', 'INTEGER');
      await _safelyAddColumn(db, AppConstants.foodTable, 'expiry_status', "TEXT DEFAULT 'Safe'");
      await _safelyAddColumn(db, AppConstants.foodTable, 'last_notification_sent', 'TEXT');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.remindersTable} (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL DEFAULT 'default_user',
          product_id TEXT NOT NULL,
          reminder_date TEXT NOT NULL,
          days_before_expiry INTEGER NOT NULL,
          notification_id INTEGER NOT NULL,
          is_sent INTEGER NOT NULL DEFAULT 0,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_product ON ${AppConstants.remindersTable} (product_id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_user ON ${AppConstants.remindersTable} (user_id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_date ON ${AppConstants.remindersTable} (reminder_date);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_sent ON ${AppConstants.remindersTable} (is_sent);');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.syncQueueTable} (
          id TEXT PRIMARY KEY,
          action TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _safelyAddColumn(
    Database db,
    String table,
    String column,
    String columnDef,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $columnDef;');
    } catch (_) {
      // Column might already exist
    }
  }

  Future<void> _onOpenDB(Database db) async {
    try {
      await db.execute('PRAGMA journal_mode = WAL;');
      await db.execute('PRAGMA synchronous = NORMAL;');
    } catch (_) {}
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
