import '../entities/user.dart';

/// Contract defining authentication operations across the application.
abstract class AuthRepository {
  /// Authenticates a user with email and password.
  Future<User> login({
    required String email,
    required String password,
  });

  /// Registers a new user account with name, email, and password.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  /// Starts or continues an offline-safe guest chef session.
  Future<User> loginAsGuest();

  /// Logs out the active user, clearing cached session credentials.
  Future<void> logout();

  /// Retrieves the currently cached active user, if any.
  Future<User?> getCurrentUser();

  /// Updates local and remote user profile details.
  Future<User> updateUser(User user);

  /// Returns true if a valid user or guest session is active.
  Future<bool> isLoggedIn();
}
