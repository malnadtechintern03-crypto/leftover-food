import 'package:flutter/foundation.dart';

/// Represents an authenticated mobile user or guest session in FoodSave / Home Pantry.
@immutable
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? token;
  final String? createdAt;
  final bool isGuest;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.status = 'active',
    this.token,
    this.createdAt,
    this.isGuest = false,
  });

  /// Factory for guest / offline mode session
  factory User.guest() {
    return const User(
      id: 'guest_user',
      name: 'Guest Chef',
      email: 'guest@homepantry.local',
      role: 'guest',
      status: 'active',
      isGuest: true,
    );
  }

  /// Calculates clean uppercase initials for avatar badges (e.g. 'Demo Chef' -> 'DC')
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0][0];
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  /// Display name fallback
  String get displayName => name.isNotEmpty ? name : 'Home Chef';

  bool get isActive => status == 'active';

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? token,
    String? createdAt,
    bool? isGuest,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'token': token,
      'created_at': createdAt,
      'is_guest': isGuest ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Home Chef',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      status: map['status']?.toString() ?? 'active',
      token: map['token']?.toString(),
      createdAt: map['created_at']?.toString(),
      isGuest: map['is_guest'] == 1 || map['is_guest'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          isGuest == other.isGuest;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ isGuest.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, isGuest: $isGuest)';
}
