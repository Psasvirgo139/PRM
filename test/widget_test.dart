import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/category.dart';
import 'package:prm/models/order.dart';
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

  group('Order Model Tests', () {
    test('Order serialization and items test', () {
      final item = OrderItem(
        id: 1,
        orderId: 10,
        productId: 1,
        productName: 'iPhone 15',
        productPrice: 20000000,
        quantity: 2,
        subtotal: 40000000,
      );

      final order = Order(
        id: 10,
        userId: 2,
        orderCode: 'ORD-20261104-001',
        customerName: 'Nguyễn Văn A',
        phone: '0987654321',
        address: 'Hà Nội',
        subtotal: 40000000,
        finalAmount: 40000000,
        paymentMethod: 'COD',
        status: 'PENDING',
        items: [item],
      );

      expect(order.orderCode, 'ORD-20261104-001');
      expect(order.items.length, 1);
      expect(order.items.first.subtotal, 40000000);
      expect(order.status, 'PENDING');

      final map = order.toMap();
      expect(map['order_code'], 'ORD-20261104-001');
      expect(map['customer_name'], 'Nguyễn Văn A');
      expect(map['final_amount'], 40000000);
    });

    test('Customer isolation and role permission logic', () {
      final customer = User(
        id: 3,
        username: 'customer',
        password: 'cust123',
        fullName: 'Khách Hàng',
        role: 'CUSTOMER',
      );
      final employee = User(
        id: 2,
        username: 'employee',
        password: 'emp123',
        fullName: 'Nhân Viên',
        role: 'EMPLOYEE',
      );
      final admin = User(
        id: 1,
        username: 'admin',
        password: 'admin123',
        fullName: 'Quản Trị Viên',
        role: 'ADMIN',
      );

      // Chỉ Customer mới xem lịch sử mua hàng cá nhân
      expect(customer.isCustomer, true);
      expect(customer.canManageOrders, false);

      // Admin & Employee quản lý đơn hàng hệ thống
      expect(employee.isCustomer, false);
      expect(employee.canManageOrders, true);
      expect(admin.isCustomer, false);
      expect(admin.canManageOrders, true);

      // Phân tách đơn hàng theo userId
      final orderList = [
        Order(id: 1, userId: 3, orderCode: 'ORD-1', customerName: 'Cust A', phone: '', address: '', subtotal: 100, finalAmount: 100, paymentMethod: 'COD', status: 'COMPLETED', items: []),
        Order(id: 2, userId: 3, orderCode: 'ORD-2', customerName: 'Cust A', phone: '', address: '', subtotal: 200, finalAmount: 200, paymentMethod: 'COD', status: 'PENDING', items: []),
        Order(id: 3, userId: 4, orderCode: 'ORD-3', customerName: 'Cust B', phone: '', address: '', subtotal: 300, finalAmount: 300, paymentMethod: 'COD', status: 'PROCESSING', items: []),
      ];

      final custOrders = orderList.where((o) => o.userId == customer.id).toList();
      expect(custOrders.length, 2);
      expect(custOrders.every((o) => o.userId == 3), true);
    });
  });
}
