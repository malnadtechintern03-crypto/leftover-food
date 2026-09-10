import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

/// Auth Local Data Source Provider
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSource(prefs ?? _FallbackEmptySharedPreferences());
});

/// Auth Remote Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) {
    // If prefs isn't ready yet (e.g. before AppInitializer finishes), create temporary fallback
    return AuthRepositoryImpl(
      remoteDataSource: ref.watch(authRemoteDataSourceProvider),
      localDataSource: AuthLocalDataSource(
        // Use an in-memory or empty SharedPreferences for initial safety
        _FallbackEmptySharedPreferences(),
      ),
    );
  }
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: AuthLocalDataSource(prefs),
  );
});

/// Fallback SharedPreferences for synchronous safety before AppInitializer initializes
class _FallbackEmptySharedPreferences implements SharedPreferences {
  final Map<String, Object> _map = {};

  @override
  Object? get(String key) => _map[key];

  @override
  bool? getBool(String key) => _map[key] as bool?;

  @override
  double? getDouble(String key) => _map[key] as double?;

  @override
  int? getInt(String key) => _map[key] as int?;

  @override
  Set<String> getKeys() => _map.keys.toSet();

  @override
  String? getString(String key) => _map[key] as String?;

  @override
  List<String>? getStringList(String key) => _map[key] as List<String>?;

  @override
  bool containsKey(String key) => _map.containsKey(key);

  @override
  Future<bool> setBool(String key, bool value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _map.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _map.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> commit() async => true;
}

/// StateNotifier controlling reactive authentication status
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  /// Checks if an active session is already persisted
  Future<void> checkAuthStatus() async {
    try {
      final user = await _repository.getCurrentUser();
      if (mounted) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Logs in a user with email and password
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      if (mounted) {
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return false;
    }
  }

  /// Registers a new user account
  Future<bool> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      if (mounted) {
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return false;
    }
  }

  /// Logs in as a guest user for offline evaluation
  Future<void> loginAsGuest() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.loginAsGuest();
      if (mounted) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Updates current user profile details (name, email)
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final current = state.valueOrNull ?? User.guest();
      final updated = current.copyWith(
        name: name.trim(),
        email: email.trim(),
      );
      await _repository.updateUser(updated);
      if (mounted) {
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return false;
    }
  }

  /// Logs out current user and clears session
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      if (mounted) {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

/// Global Auth Controller Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

/// Current User Shortcut Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull;
});

/// Is Authenticated Shortcut Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Is Guest Shortcut Provider
final isGuestUserProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isGuest ?? false;
});
