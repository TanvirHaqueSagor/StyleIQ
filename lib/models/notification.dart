import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Individual notification record sent to a user
class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? category;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    String? id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.category,
    this.isRead = false,
    this.data,
    DateTime? createdAt,
    this.readAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Check if notification is unread
  bool get isUnread => !isRead;

  /// Get formatted creation date
  String get formattedCreatedAt {
    final formatter = DateFormat('MMM d, yyyy \'at\' h:mm a');
    return formatter.format(createdAt);
  }

  /// Mark notification as read
  Notification markAsRead() {
    if (isRead) return this;
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'category': category,
      'is_read': isRead,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? category,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}