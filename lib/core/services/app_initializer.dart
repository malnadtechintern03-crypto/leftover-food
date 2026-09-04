import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../../features/food_inventory/data/datasources/food_local_datasource.dart';

/// Centralized app startup service that parallelizes startup tasks
/// and guarantees fast, non-blocking startup.
class AppInitializer {
  static final AppInitializer instance = AppInitializer._init();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SharedPreferences? _sharedPreferences;
  SharedPreferences? get sharedPreferences => _sharedPreferences;

  AppInitializer._init();

  /// Prepares essential non-blocking bindings and platform FFI
  void ensureEarlyBindings() {
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          ffi.sqfliteFfiInit();
          databaseFactory = ffi.databaseFactoryFfi;
        }
      } catch (e) {
        debugPrint('Desktop SQLite FFI early init note: $e');
      }
    }
  }

  /// Sets preloaded SharedPreferences instance
  void setSharedPreferences(SharedPreferences prefs) {
    _sharedPreferences = prefs;
  }

  Future<void>? _initFuture;

  /// Initializes services concurrently in the background
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture!;
    _initFuture = _performInitialize();
    return _initFuture!;
  }

  Future<void> _performInitialize() async {
    ensureEarlyBindings();

    // Start local push notifications in background without holding up the startup pipeline
    unawaited(_initNotifications());

    // Run core startup operations concurrently
    await Future.wait([
      _initSharedPreferences(),
      _initDatabaseAndSeed(),
    ]);

    _isInitialized = true;
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification init non-fatal warning: $e');
    }
  }

  Future<void> _initSharedPreferences() async {
    if (_sharedPreferences != null) return;
    try {
      _sharedPreferences = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init non-fatal warning: $e');
    }
  }

  Future<void> _initDatabaseAndSeed() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final foodDataSource = FoodLocalDataSourceImpl(dbHelper);
      await foodDataSource.seedSampleData();
    } catch (e) {
      debugPrint('Database seed non-fatal warning: $e');
    }
  }
}
