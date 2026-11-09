import '../core/database/database_helper.dart';
import '../core/utils/currency_formatter.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Lấy danh sách thông báo của user (mới nhất lên đầu)
  Future<List<NotificationItem>> getNotifications(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return maps.map((m) => NotificationItem.fromMap(m)).toList();
  }

  /// Đếm số thông báo chưa đọc
  Future<int> getUnreadCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Tạo thông báo mới
  Future<int> createNotification(NotificationItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('notifications', item.toMap());
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(int notificationId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Đánh dấu tất cả thông báo của user là đã đọc
  Future<void> markAllAsRead(int userId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Xóa 1 thông báo
  Future<void> deleteNotification(int notificationId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Xóa toàn bộ thông báo của user
  Future<void> clearAllNotifications(int userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUSINESS LOGIC HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Thông báo cho khách hàng khi đặt đơn hàng mới
  Future<void> notifyCustomerOrderPlaced({
    required int userId,
    required String orderCode,
    int? orderId,
  }) async {
    await createNotification(
      NotificationItem(
        userId: userId,
        title: 'Đặt hàng thành công',
        message: 'Bạn đã đặt đơn hàng $orderCode, dự kiến giao trong 3 ngày.',
        type: 'ORDER',
        relatedId: orderId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Thông báo cho khách hàng khi trạng thái đơn hàng thay đổi
  Future<void> notifyCustomerOrderStatusChange({
    required int userId,
    required String orderCode,
    required String status,
    int? orderId,
  }) async {
    String title;
    String message;

    switch (status.toUpperCase()) {
      case 'PROCESSING':
        title = 'Đơn hàng đang xử lý';
        message = 'Đơn hàng $orderCode của bạn đã được duyệt, đang được xử lý.';
        break;
      case 'COMPLETED':
        title = 'Đơn hàng giao thành công';
        message = 'Đơn hàng $orderCode đã được giao thành công, vui lòng đánh giá sản phẩm.';
        break;
      case 'CANCELLED':
        title = 'Đơn hàng đã hủy';
        message = 'Đơn hàng $orderCode của bạn đã bị hủy.';
        break;
      default:
        title = 'Cập nhật đơn hàng';
        message = 'Đơn hàng $orderCode của bạn đã chuyển sang trạng thái $status.';
    }

    await createNotification(
      NotificationItem(
        userId: userId,
        title: title,
        message: message,
        type: 'ORDER',
        relatedId: orderId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Thông báo cho toàn bộ Nhân viên (Employee) khi có đơn hàng mới từ khách
  Future<void> notifyEmployeesNewOrder({
    required String orderCode,
    required String customerName,
    required double finalAmount,
    int? orderId,
  }) async {
    final db = await _dbHelper.database;
    final employees = await db.query(
      'users',
      columns: ['id'],
      where: "role = 'EMPLOYEE'",
    );

    final now = DateTime.now().toIso8601String();
    final formattedAmount = CurrencyFormatter.format(finalAmount);

    for (final emp in employees) {
      final empId = emp['id'] as int;
      await db.insert('notifications', {
        'user_id': empId,
        'title': 'Đơn hàng mới cần xử lý',
        'message': 'Có đơn hàng mới $orderCode từ khách hàng $customerName, giá trị $formattedAmount. Vui lòng kiểm tra và xử lý.',
        'type': 'ORDER',
        'related_id': orderId,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Thông báo cho Quản trị viên (Admin) về báo cáo doanh thu tháng mới
  Future<void> notifyAdminMonthlyReport({
    int adminId = 1,
    required String monthName,
  }) async {
    await createNotification(
      NotificationItem(
        userId: adminId,
        title: 'Báo cáo doanh thu $monthName',
        message: 'Báo cáo doanh thu $monthName của bạn đã có, hãy xem ngay.',
        type: 'REPORT',
        relatedId: null,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}
