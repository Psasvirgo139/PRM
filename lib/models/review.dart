import 'dart:convert';

class Review {
  final int? id;
  final int productId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final List<String> images;
  final bool isVerifiedBuyer;
  final String createdAt;

  Review({
    this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    List<String>? images,
    this.isVerifiedBuyer = false,
    String? createdAt,
  })  : images = images ?? const [],
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'images': jsonEncode(images),
      'is_verified_buyer': isVerifiedBuyer ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];
    if (map['images'] != null) {
      try {
        final decoded = jsonDecode(map['images'] as String);
        if (decoded is List) {
          parsedImages = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedImages = [];
      }
    }

    return Review(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      userId: map['user_id'] as int,
      userName: (map['user_name'] as String?) ?? 'Khách hàng',
      userAvatar: map['user_avatar'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: (map['comment'] as String?) ?? '',
      images: parsedImages,
      isVerifiedBuyer: (map['is_verified_buyer'] as int? ?? 0) == 1,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  Review copyWith({
    int? id,
    int? productId,
    int? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    List<String>? images,
    bool? isVerifiedBuyer,
    String? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerifiedBuyer: isVerifiedBuyer ?? this.isVerifiedBuyer,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

