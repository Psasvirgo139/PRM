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

  /// Thông báo cho Quản trị viên (Admin) về mốc doanh thu đạt được (ví dụ: đạt mốc 5.000.000 VND)
  Future<void> notifyAdminRevenueMilestone({
    int? adminId,
    required double milestoneAmount,
    String periodName = 'hôm nay',
  }) async {
    final db = await _dbHelper.database;
    final formattedAmount = CurrencyFormatter.format(milestoneAmount);

    List<int> targetAdminIds = [];
    if (adminId != null) {
      targetAdminIds.add(adminId);
    } else {
      final admins = await db.query(
        'users',
        columns: ['id'],
        where: "role = 'ADMIN'",
      );
      targetAdminIds = admins.map((a) => a['id'] as int).toList();
    }

    final now = DateTime.now().toIso8601String();
    for (final aId in targetAdminIds) {
      await db.insert('notifications', {
        'user_id': aId,
        'title': 'Mốc doanh thu mới',
        'message': 'Doanh thu $periodName đã đạt mốc $formattedAmount!',
        'type': 'REPORT',
        'related_id': null,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Thông báo cho toàn bộ Nhân viên (Employee) khi đơn hàng bị hủy
  Future<void> notifyEmployeesOrderCancelled({
    required String orderCode,
    required String customerName,
    int? orderId,
  }) async {
    final db = await _dbHelper.database;
    final employees = await db.query(
      'users',
      columns: ['id'],
      where: "role = 'EMPLOYEE'",
    );

    final now = DateTime.now().toIso8601String();
    for (final emp in employees) {
      final empId = emp['id'] as int;
      await db.insert('notifications', {
        'user_id': empId,
        'title': 'Đơn hàng bị hủy',
        'message': 'Đơn hàng $orderCode từ khách hàng $customerName đã bị hủy. Vui lòng kiểm tra và xử lý hoàn hàng.',
        'type': 'ORDER',
        'related_id': orderId,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Thông báo cảnh báo tồn kho (gửi tới cả Admin và Employee)
  Future<void> notifyStockAlert({
    required String productName,
    required int stockQuantity,
    int? productId,
  }) async {
    final db = await _dbHelper.database;
    final staff = await db.query(
      'users',
      columns: ['id'],
      where: "role IN ('ADMIN', 'EMPLOYEE')",
    );

    final isOutOfStock = stockQuantity <= 0;
    final title = isOutOfStock ? 'Cảnh báo hết hàng' : 'Cảnh báo sắp hết hàng';
    final message = isOutOfStock
        ? '$productName đã hết hàng trong kho. Vui lòng kiểm tra và nhập thêm hàng.'
        : '$productName chỉ còn $stockQuantity sản phẩm trong kho.';

    final now = DateTime.now().toIso8601String();
    for (final person in staff) {
      final staffId = person['id'] as int;
      await db.insert('notifications', {
        'user_id': staffId,
        'title': title,
        'message': message,
        'type': 'STOCK',
        'related_id': productId,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Thông báo cho Quản trị viên (Admin) khi có thay đổi dữ liệu sản phẩm
  Future<void> notifyAdminsProductChange({
    required String productName,
    required String action, // 'ADD', 'UPDATE', 'DELETE'
    String actorName = 'nhân viên',
    int? productId,
  }) async {
    final db = await _dbHelper.database;
    final admins = await db.query(
      'users',
      columns: ['id'],
      where: "role = 'ADMIN'",
    );

    String title;
    String message;

    switch (action.toUpperCase()) {
      case 'ADD':
        title = 'Thêm sản phẩm mới';
        message = 'Sản phẩm $productName vừa được thêm bởi $actorName.';
        break;
      case 'DELETE':
        title = 'Xóa sản phẩm';
        message = 'Sản phẩm $productName vừa được xóa bởi $actorName.';
        break;
      case 'UPDATE':
      default:
        title = 'Cập nhật sản phẩm';
        message = 'Sản phẩm $productName vừa được thay đổi dữ liệu bởi $actorName.';
        break;
    }

    final now = DateTime.now().toIso8601String();
    for (final admin in admins) {
      final adminId = admin['id'] as int;
      await db.insert('notifications', {
        'user_id': adminId,
        'title': title,
        'message': message,
        'type': 'PRODUCT',
        'related_id': productId,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Gửi thông báo chương trình khuyến mãi cho Khách hàng
  Future<void> notifyCustomersPromotion({
    required String title,
    required String message,
    int? customerId,
  }) async {
    final db = await _dbHelper.database;
    List<int> targetCustomerIds = [];

    if (customerId != null) {
      targetCustomerIds.add(customerId);
    } else {
      final customers = await db.query(
        'users',
        columns: ['id'],
        where: "role = 'CUSTOMER'",
      );
      targetCustomerIds = customers.map((c) => c['id'] as int).toList();
    }

    final now = DateTime.now().toIso8601String();
    for (final cId in targetCustomerIds) {
      await db.insert('notifications', {
        'user_id': cId,
        'title': title,
        'message': message,
        'type': 'PROMOTION',
        'related_id': null,
        'is_read': 0,
        'created_at': now,
      });
    }
  }

  /// Thông báo cho khách hàng khi nhận/trúng voucher (từ Vòng quay may mắn hoặc sự kiện)
  Future<void> notifyCustomerWonVoucher({
    required int userId,
    required String voucherTitle,
    required String voucherCode,
    int? voucherId,
  }) async {
    await createNotification(
      NotificationItem(
        userId: userId,
        title: 'Trúng Voucher May Mắn!',
        message: 'Chúc mừng bạn đã quay trúng voucher $voucherTitle ($voucherCode). Hãy vào Kho Voucher để sử dụng ngay!',
        type: 'VOUCHER',
        relatedId: voucherId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Thông báo khi khách hàng gửi đánh giá sản phẩm (gửi cảm ơn cho Khách và thông báo cho Quản trị viên)
  Future<void> notifyReviewSubmitted({
    required int customerId,
    required String customerName,
    required int productId,
    required double rating,
    required String comment,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final starText = rating.toInt();

    // 1. Lấy tên sản phẩm để thông báo rõ ràng
    String prodName = 'Sản phẩm';
    final prodRows = await db.query(
      'products',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (prodRows.isNotEmpty) {
      prodName = prodRows.first['name'] as String;
    }

    // 2. Gửi thông báo cảm ơn cho khách hàng
    await createNotification(
      NotificationItem(
        userId: customerId,
        title: 'Đánh giá sản phẩm thành công',
        message: 'Cảm ơn bạn đã đánh giá $starText sao cho "$prodName"! Đóng góp của bạn giúp cộng đồng mua sắm tốt hơn.',
        type: 'REVIEW',
        relatedId: productId,
        createdAt: now,
      ),
    );

    // 3. Gửi thông báo cho Admin
    final admins = await db.query(
      'users',
      columns: ['id'],
      where: "role = 'ADMIN'",
    );

    final snippet = comment.length > 50 ? '${comment.substring(0, 50)}...' : comment;
    for (final admin in admins) {
      final adminId = admin['id'] as int;
      await db.insert('notifications', {
        'user_id': adminId,
        'title': 'Đánh giá sản phẩm mới',
        'message': 'Khách hàng $customerName vừa đánh giá $starText sao cho "$prodName": "$snippet"',
        'type': 'REVIEW',
        'related_id': productId,
        'is_read': 0,
        'created_at': now,
      });
    }
  }
}
