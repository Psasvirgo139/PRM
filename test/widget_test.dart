import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/category.dart';
import 'package:prm/models/product.dart';
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
      expect(updated.isCustomer, true);
      expect(updated.isAdmin, false);
    });

    test('User role getters test', () {
      final admin = User(
        id: 1,
        username: 'admin',
        password: '123',
        fullName: 'Admin',
        role: 'ADMIN',
      );
      final employee = User(
        id: 2,
        username: 'emp',
        password: '123',
        fullName: 'Employee',
        role: 'EMPLOYEE',
      );

      expect(admin.isAdmin, true);
      expect(admin.canManageOrders, true);
      expect(employee.isEmployee, true);
      expect(employee.canManageOrders, true);
      expect(employee.isAdmin, false);
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

  group('Category and Product Model Tests', () {
    test('Category serialization test', () {
      final cat = Category(id: 1, name: 'Điện thoại', icon: 'phone_android');
      final map = cat.toMap();
      expect(map['name'], 'Điện thoại');
      expect(map['icon'], 'phone_android');

      final fromMap = Category.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.name, 'Điện thoại');
    });

    test('Product stock checks', () {
      final p1 = Product(
        id: 1,
        categoryId: 1,
        name: 'iPhone 15',
        description: 'Titanium',
        price: 29990000,
        stockQuantity: 10,
        imageUrl: '',
      );
      final p2 = Product(
        id: 2,
        categoryId: 1,
        name: 'Mouse',
        description: 'Wireless',
        price: 500000,
        stockQuantity: 0,
        imageUrl: '',
      );

      expect(p1.isOutOfStock, false);
      expect(p2.isOutOfStock, true);
    });
  });
}
