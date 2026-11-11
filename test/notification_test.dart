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

    test('Admin seed notifications cover monthly report, revenue milestone, stock alerts, and product changes', () async {
      final notifRepo = NotificationRepository();
      final adminNotifs = await notifRepo.getNotifications(1); // Admin id=1

      // 1. Báo cáo doanh thu tháng 10
      expect(
        adminNotifs.any((n) => n.type == 'REPORT' && n.message.toLowerCase().contains('tháng 10')),
        true,
      );

      // 2. Báo cáo doanh thu theo mốc
      expect(
        adminNotifs.any((n) => n.type == 'REPORT' && n.message.contains('5.000.000 VND')),
        true,
      );

      // 3. Cảnh báo hết hàng
      expect(
        adminNotifs.any((n) => n.type == 'STOCK' && n.message.contains('đã hết hàng')),
        true,
      );

      // 4. Cảnh báo tồn kho thấp (Keychron K2 chỉ còn 3 sản phẩm)
      expect(
        adminNotifs.any((n) => n.type == 'STOCK' && n.message.contains('chỉ còn 3 sản phẩm')),
        true,
      );

      // 5. Thay đổi dữ liệu sản phẩm
      expect(
        adminNotifs.any((n) => n.type == 'PRODUCT' && n.message.contains('thay đổi dữ liệu bởi nhân viên')),
        true,
      );
    });

    test('Employee seed notifications cover orders to process, cancelled orders, and stock alerts', () async {
      final notifRepo = NotificationRepository();
      final empNotifs = await notifRepo.getNotifications(2); // Employee id=2

      // 1. Đơn hàng mới cần xử lý
      expect(
        empNotifs.any((n) => n.type == 'ORDER' && n.title.contains('cần xử lý')),
        true,
      );

      // 2. Đơn hàng bị hủy
      expect(
        empNotifs.any((n) => n.type == 'ORDER' && n.title.contains('bị hủy')),
        true,
      );

      // 3. Cảnh báo hàng tồn kho
      expect(
        empNotifs.any((n) => n.type == 'STOCK' && n.message.contains('đã hết hàng')),
        true,
      );
    });

    test('Customer seed notifications cover placed orders, status changes, cancelled orders, and promotions', () async {
      final notifRepo = NotificationRepository();

      // Customer 1 (id=3)
      final cust1Notifs = await notifRepo.getNotifications(3);
      expect(cust1Notifs.any((n) => n.title.contains('Đặt hàng thành công')), true);
      expect(cust1Notifs.any((n) => n.title.contains('giao thành công')), true);
      expect(cust1Notifs.any((n) => n.title.contains('đã hủy')), true);
      expect(cust1Notifs.any((n) => n.type == 'PROMOTION'), true);

      // Customer 2 (id=4)
      final cust2Notifs = await notifRepo.getNotifications(4);
      expect(cust2Notifs.any((n) => n.title.contains('đang xử lý')), true);
      expect(cust2Notifs.any((n) => n.type == 'PROMOTION'), true);
    });

    test('Cancelling an order notifies both Customer and Employees', () async {
      final orderRepo = OrderRepository();
      final notifRepo = NotificationRepository();

      const customerId = 4;
      const employeeId = 2;

      final cartItem = CartItem(
        id: 996,
        userId: customerId,
        productId: 1,
        productName: 'iPhone 15 Pro Max 256GB',
        productPrice: 29990000,
        productImageUrl: '',
        availableStock: 50,
        quantity: 1,
      );

      final order = await orderRepo.createOrderWithTransaction(
        userId: customerId,
        customerName: 'Trần Thị B',
        phone: '0912345678',
        address: 'Đà Nẵng',
        paymentMethod: 'COD',
        items: [cartItem],
      );

      // Customer hủy đơn
      final cancelResult = await orderRepo.cancelOrder(order.id!, customerId);
      expect(cancelResult, true);

      // Customer nhận thông báo hủy
      final custNotifs = await notifRepo.getNotifications(customerId);
      expect(
        custNotifs.any((n) => n.message.contains(order.orderCode) && n.message.contains('đã bị hủy')),
        true,
      );

      // Employee nhận thông báo đơn hàng bị hủy
      final empNotifs = await notifRepo.getNotifications(employeeId);
      expect(
        empNotifs.any((n) => n.message.contains(order.orderCode) && n.title.contains('bị hủy')),
        true,
      );
    });

    test('Customer and Admin seed notifications include Voucher and Review types', () async {
      final notifRepo = NotificationRepository();

      // Customer 1 (id=3) có thông báo voucher may mắn và đánh giá
      final cust1Notifs = await notifRepo.getNotifications(3);
      expect(cust1Notifs.any((n) => n.type == 'VOUCHER'), true);
      expect(cust1Notifs.any((n) => n.type == 'REVIEW'), true);

      // Customer 2 (id=4) có thông báo đánh giá
      final cust2Notifs = await notifRepo.getNotifications(4);
      expect(cust2Notifs.any((n) => n.type == 'REVIEW'), true);

      // Admin (id=1) có thông báo đánh giá sản phẩm mới từ khách
      final adminNotifs = await notifRepo.getNotifications(1);
      expect(adminNotifs.any((n) => n.type == 'REVIEW'), true);
    });
  });
}
