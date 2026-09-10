import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/admin_sync_service.dart';
import '../../domain/entities/user.dart';

/// Remote data source communicating with PHP/MySQL Admin REST API (`/api/user-auth.php`).
class AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Resolves the active REST API endpoint
  Future<String> _resolveApiBaseUrl() async {
    final discovered = await AdminSyncService.getWorkingBaseUrl();
    if (discovered != null && discovered.isNotEmpty) {
      return '$discovered/api';
    }
    // If no server is reachable on this network, throw SocketException to immediately engage offline fallback
    throw const SocketException('No local authentication server reachable on network');
  }

  /// Sends login request to `/api/user-auth.php`
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = await _resolveApiBaseUrl();
    final uri = Uri.parse('$baseUrl/user-auth.php');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'action': 'login',
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 8));

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['status'] == 'success') {
      final userMap = data['user'] as Map<String, dynamic>;
      final token = data['token']?.toString();
      return User.fromMap({
        ...userMap,
        'token': ?token,
      });
    } else {
      final message = data['message']?.toString() ?? 'Failed to authenticate.';
      throw Exception(message);
    }
  }

  /// Sends registration request to `/api/user-auth.php`
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final baseUrl = await _resolveApiBaseUrl();
    final uri = Uri.parse('$baseUrl/user-auth.php');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'action': 'register',
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 8));

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == 'success') {
      final userMap = data['user'] as Map<String, dynamic>;
      final token = data['token']?.toString();
      return User.fromMap({
        ...userMap,
        'token': ?token,
      });
    } else {
      final message = data['message']?.toString() ?? 'Failed to create account.';
      throw Exception(message);
    }
  }

  /// Sends logout notice to `/api/user-auth.php`
  Future<void> logout(String? userId) async {
    try {
      final baseUrl = await _resolveApiBaseUrl();
      final uri = Uri.parse('$baseUrl/user-auth.php');

      await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'action': 'logout',
          'user_id': userId ?? '',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Remote logout notice note (non-fatal): $e');
    }
  }

  /// Sends profile update request to `/api/user-auth.php` (if remote API is reachable)
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      final baseUrl = await _resolveApiBaseUrl();
      final uri = Uri.parse('$baseUrl/user-auth.php');

      await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'action': 'update_profile',
          'user_id': userId,
          'name': name.trim(),
          'email': email.trim(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Remote update profile note (offline/non-fatal): $e');
    }
  }
}
