// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Hybrid online-sync + offline-resilient implementation of AuthRepository.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final user = await _remoteDataSource.login(
        email: cleanEmail,
        password: password,
      );
      await _localDataSource.saveUser(user);
      return user;
    } catch (e) {
      debugPrint('AuthRepository: Remote login note: $e');

      // Offline-First Resilience Fallback:
      // If remote backend is unreachable, check demo credentials or local cached session
      final isNetworkIssue = e is SocketException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException');

      if (isNetworkIssue) {
        // 1. Check Demo User credentials
        if (cleanEmail == 'user@homepantry.com' && password == 'user123') {
          const demoUser = User(
            id: 'user_demo_chef',
            name: 'Demo Chef',
            email: 'user@homepantry.com',
            role: 'user',
            status: 'active',
          );
          await _localDataSource.saveUser(demoUser);
          return demoUser;
        }

        // 2. Check if a local cached user matches this email
        final cached = await _localDataSource.getUser();
        if (cached != null && cached.email.toLowerCase() == cleanEmail) {
          return cached;
        }

        throw Exception(
          'Unable to reach pantry server. You can tap "Quick Demo Login" or "Continue as Guest" while offline.',
        );
      }

      // Re-throw server-provided error message (e.g. 'Invalid email address or password.')
      rethrow;
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final user = await _remoteDataSource.register(
        name: name,
        email: cleanEmail,
        password: password,
      );
      await _localDataSource.saveUser(user);
      return user;
    } catch (e) {
      debugPrint('AuthRepository: Remote register note: $e');

      final isNetworkIssue = e is SocketException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException');

      if (isNetworkIssue) {
        // Offline registration fallback
        final offlineUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          email: cleanEmail,
          role: 'user',
          status: 'active',
          createdAt: DateTime.now().toIso8601String(),
        );
        await _localDataSource.saveUser(offlineUser);
        return offlineUser;
      }

      rethrow;
    }
  }

  @override
  Future<User> loginAsGuest() async {
    final guestUser = User.guest();
    await _localDataSource.saveUser(guestUser);
    return guestUser;
  }

  @override
  Future<void> logout() async {
    final current = await _localDataSource.getUser();
    if (current != null && !current.isGuest) {
      // Notify backend if online
      _remoteDataSource.logout(current.id);
    }
    await _localDataSource.clearUser();
  }

  @override
  Future<User?> getCurrentUser() async {
    return await _localDataSource.getUser();
  }

  @override
  Future<User> updateUser(User user) async {
    await _localDataSource.saveUser(user);
    if (!user.isGuest && user.id.isNotEmpty) {
      try {
        await _remoteDataSource.updateProfile(
          userId: user.id,
          name: user.name,
          email: user.email,
        );
      } catch (e) {
        debugPrint('AuthRepository: Remote update profile note (non-fatal): $e');
      }
    }
    return user;
  }

  @override
  Future<bool> isLoggedIn() async {
    return _localDataSource.isLoggedIn();
  }
}
