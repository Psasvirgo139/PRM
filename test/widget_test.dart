import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('User copyWith updates fields correctly', () {
      final user = User(
        id: 1,
        username: 'testuser',
        password: 'password123',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '0987654321',
        address: 'Hà Nội',
        role: 'CUSTOMER',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final updated = user.copyWith(
        fullName: 'Updated Name',
        phone: '0912345678',
        address: 'Đà Nẵng',
      );

      expect(updated.fullName, 'Updated Name');
      expect(updated.phone, '0912345678');
      expect(updated.address, 'Đà Nẵng');
      expect(updated.email, 'test@example.com');
      expect(updated.username, 'testuser');
    });

    test('User toMap and fromMap serialization', () {
      final user = User(
        id: 2,
        username: 'cust',
        password: 'pass',
        fullName: 'Customer Name',
        role: 'CUSTOMER',
      );

      final map = user.toMap();
      expect(map['username'], 'cust');
      expect(map['role'], 'CUSTOMER');

      final fromMap = User.fromMap(map);
      expect(fromMap.username, user.username);
      expect(fromMap.fullName, user.fullName);
    });
  });
}
