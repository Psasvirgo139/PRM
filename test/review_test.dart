import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/review.dart';

void main() {
  group('Review Model & Parsing Tests', () {
    test('Review serialization toMap and fromMap works correctly', () {
      final review = Review(
        id: 1,
        productId: 10,
        userId: 2,
        userName: 'Nguyễn Văn Test',
        userAvatar: 'https://example.com/avatar.jpg',
        rating: 4.5,
        comment: 'Sản phẩm dùng rất êm, đóng gói cẩn thận!',
        images: ['https://example.com/photo1.jpg', 'data:image/jpeg;base64,abc123'],
        isVerifiedBuyer: true,
        createdAt: '2026-11-09T10:00:00.000',
      );

      final map = review.toMap();
      expect(map['id'], 1);
      expect(map['product_id'], 10);
      expect(map['user_id'], 2);
      expect(map['user_name'], 'Nguyễn Văn Test');
      expect(map['rating'], 4.5);
      expect(map['comment'], 'Sản phẩm dùng rất êm, đóng gói cẩn thận!');
      expect(map['is_verified_buyer'], 1);
      expect(map['created_at'], '2026-11-09T10:00:00.000');

      final fromMapReview = Review.fromMap(map);
      expect(fromMapReview.id, 1);
      expect(fromMapReview.productId, 10);
      expect(fromMapReview.userName, 'Nguyễn Văn Test');
      expect(fromMapReview.rating, 4.5);
      expect(fromMapReview.isVerifiedBuyer, true);
      expect(fromMapReview.images.length, 2);
      expect(fromMapReview.images[0], 'https://example.com/photo1.jpg');
      expect(fromMapReview.images[1], 'data:image/jpeg;base64,abc123');
    });

    test('Review handles empty or invalid images gracefully', () {
      final mapWithNullImages = {
        'id': 2,
        'product_id': 10,
        'user_id': 3,
        'user_name': 'Khách hàng',
        'rating': 5.0,
        'comment': 'Tốt',
        'images': null,
        'is_verified_buyer': 0,
        'created_at': '2026-11-09T10:00:00.000',
      };

      final review = Review.fromMap(mapWithNullImages);
      expect(review.images, isEmpty);
      expect(review.isVerifiedBuyer, false);

      final mapWithMalformedImages = {
        'id': 3,
        'product_id': 10,
        'user_id': 3,
        'user_name': 'Khách hàng',
        'rating': 3.0,
        'comment': 'Bình thường',
        'images': 'not a json',
        'is_verified_buyer': 0,
        'created_at': '2026-11-09T10:00:00.000',
      };

      final reviewMalformed = Review.fromMap(mapWithMalformedImages);
      expect(reviewMalformed.images, isEmpty);
    });

    test('Review copyWith updates properties correctly', () {
      final original = Review(
        id: 1,
        productId: 5,
        userId: 2,
        userName: 'Gốc',
        rating: 3.0,
        comment: 'Cũ',
        isVerifiedBuyer: false,
      );

      final updated = original.copyWith(
        rating: 5.0,
        comment: 'Mới cập nhật',
        isVerifiedBuyer: true,
        images: ['https://example.com/new.jpg'],
      );

      expect(updated.id, original.id);
      expect(updated.productId, original.productId);
      expect(updated.userName, 'Gốc');
      expect(updated.rating, 5.0);
      expect(updated.comment, 'Mới cập nhật');
      expect(updated.isVerifiedBuyer, true);
      expect(updated.images.length, 1);
    });
  });
}

