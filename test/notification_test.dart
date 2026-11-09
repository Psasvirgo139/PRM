import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prm/core/database/database_helper.dart';
import 'package:prm/models/cart_item.dart';
import 'package:prm/models/notification_item.dart';
import 'package:prm/repositories/admin_repository.dart';
import 'package:prm/repositories/notification_repository.dart';
import 'package:prm/repositories/order_repository.dart';
import 'package:prm/providers/auth_provider.dart';
import 'package:prm/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate('UPDATE products SET stock_quantity = 50');
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('Notification System Tests', () {
    test('Admin seed notification exists for 2026-11-01 monthly report', () async {
      final notifRepo = NotificationRepository();
      final adminNotifs = await notifRepo.getNotifications(1); // Admin id=1
      
      final nov1Notif = adminNotifs.firstWhere(
        (n) => n.createdAt.startsWith('2026-11-01') && n.message.contains('tháng 10'),
        orElse: () => adminNotifs.firstWhere(
          (n) => n.message.toLowerCase().contains('tháng 10'),
        ),
      );

      expect(nov1Notif, isNotNull);
      expect(nov1Notif.type, 'REPORT');
      expect(nov1Notif.message, 'Báo cáo doanh thu tháng 10 của bạn đã có, hãy xem ngay.');
    });

    test('Customer and Employee seed notifications exist', () async {
      final notifRepo = NotificationRepository();
      
      final empNotifs = await notifRepo.getNotifications(2); // Employee id=2
      expect(empNotifs.isNotEmpty, true);

      final custNotifs = await notifRepo.getNotifications(3); // Customer id=3
      expect(custNotifs.isNotEmpty, true);
    });

    test('Notification CRUD and read status toggling', () async {
      final notifRepo = NotificationRepository();
      const testUserId = 3;

      final initialUnread = await notifRepo.getUnreadCount(testUserId);

      // Create a new notification
      final newNotif = NotificationItem(
        userId: testUserId,
        title: 'Khuyến mãi đặc biệt',
        message: 'Giảm 20% phụ kiện hôm nay!',
        type: 'SYSTEM',
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      final createdId = await notifRepo.createNotification(newNotif);
      expect(createdId, isPositive);

      final unreadAfterAdd = await notifRepo.getUnreadCount(testUserId);
      expect(unreadAfterAdd, initialUnread + 1);

      // Mark as read
      await notifRepo.markAsRead(createdId);
      final notifs = await notifRepo.getNotifications(testUserId);
      final readItem = notifs.firstWhere((n) => n.id == createdId);
      expect(readItem.isRead, true);

      // Delete notification
      await notifRepo.deleteNotification(createdId);
      final notifsAfterDelete = await notifRepo.getNotifications(testUserId);
      expect(notifsAfterDelete.any((n) => n.id == createdId), false);
    });

    test('Order placement automatically creates notifications for Customer and Employees', () async {
      final orderRepo = OrderRepository();
      final notifRepo = NotificationRepository();

      const customerId = 4; // Use customer 4 to avoid interference with other test files
      const employeeId = 2;

      final cartItem = CartItem(
        id: 998,
        userId: customerId,
        productId: 2,
        productName: 'Samsung Galaxy S24 Ultra',
        productPrice: 26990000,
        productImageUrl: '',
        availableStock: 10,
        quantity: 1,
      );

      final createdOrder = await orderRepo.createOrderWithTransaction(
        userId: customerId,
        customerName: 'Trần Thị B',
        phone: '0987654322',
        address: 'Đà Nẵng',
        paymentMethod: 'COD',
        items: [cartItem],
      );

      // Customer receives notification: dự kiến giao trong 3 ngày
      final custNotifs = await notifRepo.getNotifications(customerId);
      final orderPlacedNotif = custNotifs.firstWhere(
        (n) => n.message.contains(createdOrder.orderCode) && n.message.contains('dự kiến giao trong 3 ngày'),
      );
      expect(orderPlacedNotif, isNotNull);
      expect(orderPlacedNotif.type, 'ORDER');

      // Employee receives notification: có đơn hàng mới cần xử lý
      final empNotifs = await notifRepo.getNotifications(employeeId);
      final empOrderNotif = empNotifs.firstWhere(
        (n) => n.message.contains(createdOrder.orderCode) && n.title.contains('Đơn hàng mới'),
      );
      expect(empOrderNotif, isNotNull);
      expect(empOrderNotif.message, contains('Trần Thị B'));
    });

    test('Order status updates notify the Customer appropriately', () async {
      final orderRepo = OrderRepository();
      final adminRepo = AdminRepository();
      final notifRepo = NotificationRepository();

      const customerId = 4;

      final cartItem = CartItem(
        id: 997,
        userId: customerId,
        productId: 4,
        productName: 'AirPods Pro 2 USB-C',
        productPrice: 5490000,
        productImageUrl: '',
        availableStock: 25,
        quantity: 1,
      );

      final createdOrder = await orderRepo.createOrderWithTransaction(
        userId: customerId,
        customerName: 'Trần Thị B',
        phone: '0987654322',
        address: 'Đà Nẵng',
        paymentMethod: 'COD',
        items: [cartItem],
      );

      // 1. Employee duyệt đơn -> PROCESSING
      await adminRepo.updateOrderStatus(createdOrder.id!, 'PROCESSING');
      var custNotifs = await notifRepo.getNotifications(customerId);
      var processingNotif = custNotifs.firstWhere(
        (n) => n.message.contains(createdOrder.orderCode) && n.message.contains('đã được duyệt, đang được xử lý'),
      );
      expect(processingNotif, isNotNull);

      // 2. Giao thành công -> COMPLETED
      await adminRepo.updateOrderStatus(createdOrder.id!, 'COMPLETED');
      custNotifs = await notifRepo.getNotifications(customerId);
      var completedNotif = custNotifs.firstWhere(
        (n) => n.message.contains(createdOrder.orderCode) && n.message.contains('đã được giao thành công, vui lòng đánh giá sản phẩm'),
      );
      expect(completedNotif, isNotNull);
    });

    test('Admin can trigger monthly report notification', () async {
      final notifRepo = NotificationRepository();
      const adminId = 1;

      await notifRepo.notifyAdminMonthlyReport(
        adminId: adminId,
        monthName: 'tháng 11',
      );

      final adminNotifs = await notifRepo.getNotifications(adminId);
      final reportNotif = adminNotifs.firstWhere(
        (n) => n.message.contains('Báo cáo doanh thu tháng 11 của bạn đã có, hãy xem ngay.'),
      );
      expect(reportNotif, isNotNull);
      expect(reportNotif.type, 'REPORT');
    });

    test('All 3 roles (Admin, Employee, Customer) can login quickly and access notifications', () async {
      final authProv = AuthProvider();
      final notifProv = NotificationProvider();

      // 1. Quick Login as Admin
      final adminSuccess = await authProv.login('admin', 'admin123');
      expect(adminSuccess, true);
      expect(authProv.isAdmin, true);
      expect(authProv.currentUser?.role, 'ADMIN');

      notifProv.setUserId(authProv.currentUser?.id);
      await notifProv.loadNotifications();
      expect(notifProv.notifications.isNotEmpty, true);
      expect(notifProv.notifications.any((n) => n.type == 'REPORT'), true);

      // 2. Quick Login as Employee
      final empSuccess = await authProv.login('employee', 'emp123');
      expect(empSuccess, true);
      expect(authProv.isEmployee, true);
      expect(authProv.canManageOrders, true);

      notifProv.setUserId(authProv.currentUser?.id);
      await notifProv.loadNotifications();
      expect(notifProv.notifications.isNotEmpty, true);

      // 3. Quick Login as Customer
      final custSuccess = await authProv.login('customer', 'cust123');
      expect(custSuccess, true);
      expect(authProv.isCustomer, true);
      expect(authProv.canManageOrders, false);

      notifProv.setUserId(authProv.currentUser?.id);
      await notifProv.loadNotifications();
      expect(notifProv.notifications.isNotEmpty, true);

      // 4. Logout clears notifications
      await authProv.logout();
      notifProv.setUserId(null);
      expect(notifProv.notifications.isEmpty, true);
      expect(notifProv.unreadCount, 0);
    });
  });
}
