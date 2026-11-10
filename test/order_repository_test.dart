import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prm/core/database/database_helper.dart';
import 'package:prm/models/cart_item.dart';
import 'package:prm/repositories/admin_repository.dart';
import 'package:prm/repositories/order_repository.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate('UPDATE products SET stock_quantity = 50');
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('Customer Order History & Processing Tests', () {
    test('Customer can fetch seed orders', () async {
      final repo = OrderRepository();
      final orders = await repo.getOrdersByUserId(3); // Customer id=3
      expect(orders.length, greaterThanOrEqualTo(3)); // Seed orders 1, 3, 5
      expect(orders.every((o) => o.userId == 3), true);
    });

    test('Customer places new order, sees it in history, and sees status updates', () async {
      final orderRepo = OrderRepository();
      final adminRepo = AdminRepository();

      const customerId = 3;
      final initialOrders = await orderRepo.getOrdersByUserId(customerId);
      final initialCount = initialOrders.length;

      // 1. Tạo đơn hàng mới cho customer (userId=3)
      final cartItem = CartItem(
        id: 999,
        userId: customerId,
        productId: 1,
        productName: 'iPhone 15 Pro Max 256GB',
        productPrice: 29990000,
        productImageUrl: '',
        availableStock: 10,
        quantity: 1,
      );

      final createdOrder = await orderRepo.createOrderWithTransaction(
        userId: customerId,
        customerName: 'Nguyễn Văn A',
        phone: '0987654321',
        address: 'Số 123 Cầu Giấy, Hà Nội',
        paymentMethod: 'COD',
        items: [cartItem],
      );

      expect(createdOrder.userId, customerId);
      expect(createdOrder.status, 'PENDING');

      // 2. Customer đọc lại history -> phải thấy đơn hàng mới này
      final updatedOrders = await orderRepo.getOrdersByUserId(customerId);
      expect(updatedOrders.length, initialCount + 1);
      final foundOrder = updatedOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(foundOrder.orderCode, createdOrder.orderCode);
      expect(foundOrder.status, 'PENDING');
      expect(foundOrder.items.length, 1);
      expect(foundOrder.items.first.productName, 'iPhone 15 Pro Max 256GB');

      // 3. Employee xử lý đơn hàng: PENDING -> PROCESSING
      await adminRepo.updateOrderStatus(createdOrder.id!, 'PROCESSING');

      // Customer đọc lại history -> trạng thái phải là PROCESSING
      final processingOrders = await orderRepo.getOrdersByUserId(customerId);
      final processingOrder = processingOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(processingOrder.status, 'PROCESSING');

      // 4. Employee hoàn thành đơn hàng: PROCESSING -> COMPLETED
      await adminRepo.updateOrderStatus(createdOrder.id!, 'COMPLETED');

      // Customer đọc lại history -> trạng thái phải là COMPLETED
      final completedOrders = await orderRepo.getOrdersByUserId(customerId);
      final completedOrder = completedOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(completedOrder.status, 'COMPLETED');

      // 5. Đảm bảo Customer 4 (khách khác) không thấy đơn hàng của Customer 3
      final customer4Orders = await orderRepo.getOrdersByUserId(4);
      expect(customer4Orders.any((o) => o.id == createdOrder.id), false);
    });
  });
}
