/// Represents an individual reminder trigger configured for a product
class ProductReminder {
  final String id;
  final String userId;
  final String productId;
  final DateTime reminderDate;
  final int daysBeforeExpiry;
  final int notificationId;
  final bool isSent;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductReminder({
    required this.id,
    this.userId = 'default_user',
    required this.productId,
    required this.reminderDate,
    required this.daysBeforeExpiry,
    required this.notificationId,
    this.isSent = false,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductReminder copyWith({
    String? id,
    String? userId,
    String? productId,
    DateTime? reminderDate,
    int? daysBeforeExpiry,
    int? notificationId,
    bool? isSent,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      reminderDate: reminderDate ?? this.reminderDate,
      daysBeforeExpiry: daysBeforeExpiry ?? this.daysBeforeExpiry,
      notificationId: notificationId ?? this.notificationId,
      isSent: isSent ?? this.isSent,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'reminder_date': reminderDate.toIso8601String(),
      'days_before_expiry': daysBeforeExpiry,
      'notification_id': notificationId,
      'is_sent': isSent ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductReminder.fromMap(Map<String, dynamic> map) {
    return ProductReminder(
      id: map['id'].toString(),
      userId: map['user_id']?.toString() ?? 'default_user',
      productId: map['product_id'].toString(),
      reminderDate: DateTime.parse(map['reminder_date'].toString()),
      daysBeforeExpiry: int.tryParse(map['days_before_expiry'].toString()) ?? 0,
      notificationId: int.tryParse(map['notification_id'].toString()) ?? 0,
      isSent: (int.tryParse(map['is_sent'].toString()) ?? 0) == 1,
      isEnabled: (int.tryParse(map['is_enabled'].toString()) ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ProductReminder.fromJson(Map<String, dynamic> json) => ProductReminder.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductReminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          reminderDate == other.reminderDate &&
          daysBeforeExpiry == other.daysBeforeExpiry &&
          notificationId == other.notificationId &&
          isSent == other.isSent &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      id.hashCode ^
      productId.hashCode ^
      reminderDate.hashCode ^
      daysBeforeExpiry.hashCode ^
      notificationId.hashCode ^
      isSent.hashCode ^
      isEnabled.hashCode;
}
