import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';

/// Local data source persisting authentication sessions using SharedPreferences.
class AuthLocalDataSource {
  final SharedPreferences _prefs;

  const AuthLocalDataSource(this._prefs);

  /// Saves active user profile and token to local preferences
  Future<void> saveUser(User user) async {
    await _prefs.setString(AppConstants.keyAuthUserId, user.id);
    await _prefs.setString(AppConstants.keyAuthUserName, user.name);
    await _prefs.setString(AppConstants.keyAuthUserEmail, user.email);
    await _prefs.setString(AppConstants.keyAuthRole, user.role);
    await _prefs.setBool(AppConstants.keyAuthIsGuest, user.isGuest);
    if (user.token != null) {
      await _prefs.setString(AppConstants.keyAuthToken, user.token!);
    }
    if (user.createdAt != null) {
      await _prefs.setString(AppConstants.keyAuthCreatedAt, user.createdAt!);
    }
  }

  /// Retrieves the currently persisted user, or null if unauthenticated
  Future<User?> getUser() async {
    final id = _prefs.getString(AppConstants.keyAuthUserId);
    if (id == null || id.isEmpty) {
      return null;
    }

    final name = _prefs.getString(AppConstants.keyAuthUserName) ?? 'Home Chef';
    final email = _prefs.getString(AppConstants.keyAuthUserEmail) ?? '';
    final role = _prefs.getString(AppConstants.keyAuthRole) ?? 'user';
    final token = _prefs.getString(AppConstants.keyAuthToken);
    final createdAt = _prefs.getString(AppConstants.keyAuthCreatedAt);
    final isGuest = _prefs.getBool(AppConstants.keyAuthIsGuest) ?? false;

    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      token: token,
      createdAt: createdAt,
      isGuest: isGuest,
    );
  }

  /// Clears all authentication session keys
  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.keyAuthUserId);
    await _prefs.remove(AppConstants.keyAuthUserName);
    await _prefs.remove(AppConstants.keyAuthUserEmail);
    await _prefs.remove(AppConstants.keyAuthToken);
    await _prefs.remove(AppConstants.keyAuthIsGuest);
    await _prefs.remove(AppConstants.keyAuthRole);
    await _prefs.remove(AppConstants.keyAuthCreatedAt);
  }

  /// Checks if an active session exists
  bool isLoggedIn() {
    final id = _prefs.getString(AppConstants.keyAuthUserId);
    return id != null && id.isNotEmpty;
  }
}
