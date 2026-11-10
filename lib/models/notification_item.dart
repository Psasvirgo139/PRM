class NotificationItem {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final String type; // 'ORDER', 'REPORT', 'SYSTEM'
  final int? relatedId; // e.g. orderId
  final bool isRead;
  final String createdAt;

  NotificationItem({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'ORDER',
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      type: (map['type'] as String?) ?? 'ORDER',
      relatedId: map['related_id'] as int?,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  NotificationItem copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    int? relatedId,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

