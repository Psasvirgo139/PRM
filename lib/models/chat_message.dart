import 'dart:convert';

class ChatMessage {
  final int? id;
  final int? userId;
  final String sender; // 'user' hoặc 'ai'
  final String content;
  final List<int> suggestedProductIds;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    this.userId,
    required this.sender,
    required this.content,
    List<int>? suggestedProductIds,
    DateTime? createdAt,
  })  : suggestedProductIds = suggestedProductIds ?? const [],
        createdAt = createdAt ?? DateTime.now();

  bool get isUser => sender == 'user';
  bool get isAi => sender == 'ai';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sender': sender,
      'content': content,
      'suggested_product_ids': jsonEncode(suggestedProductIds),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    List<int> productIds = [];
    if (map['suggested_product_ids'] != null) {
      try {
        final decoded = jsonDecode(map['suggested_product_ids'] as String);
        if (decoded is List) {
          productIds = decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0).toList();
        }
      } catch (_) {
        productIds = [];
      }
    }

    return ChatMessage(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      sender: (map['sender'] as String?) ?? 'ai',
      content: (map['content'] as String?) ?? '',
      suggestedProductIds: productIds,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ChatMessage copyWith({
    int? id,
    int? userId,
    String? sender,
    String? content,
    List<int>? suggestedProductIds,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      suggestedProductIds: suggestedProductIds ?? this.suggestedProductIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

