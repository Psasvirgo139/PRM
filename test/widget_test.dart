import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/cart_item.dart';

void main() {
  group('CartItem Model Tests', () {
    test('subtotal calculates correctly based on quantity and price', () {
      final item = CartItem(
        id: 1,
        userId: 2,
        productId: 10,
        productName: 'iPhone 15 Pro Max',
        productPrice: 29990000.0,
        availableStock: 5,
        quantity: 2,
      );

      expect(item.subtotal, 59980000.0);
    });

    test('toDbMap produces valid map for SQLite insertion', () {
      final item = CartItem(
        userId: 2,
        productId: 10,
        productName: 'iPhone 15 Pro Max',
        productPrice: 29990000.0,
        availableStock: 5,
        quantity: 3,
      );

      final map = item.toDbMap();
      expect(map['user_id'], 2);
      expect(map['product_id'], 10);
      expect(map['quantity'], 3);
    });
  });
}
