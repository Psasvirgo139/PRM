import '../core/database/database_helper.dart';
import '../models/order.dart';
import '../models/product.dart';

class AdminRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ══════════════════════════════════════════════════════════════
  //  DASHBOARD STATISTICS
  // ══════════════════════════════════════════════════════════════

  /// Lấy tổng doanh thu (chỉ tính đơn COMPLETED)
  Future<double> getTotalRevenue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(final_amount), 0) as total FROM orders WHERE status = 'COMPLETED'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Lấy doanh thu hôm nay (chỉ tính đơn COMPLETED)
  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(final_amount), 0) as total FROM orders WHERE status = 'COMPLETED' AND created_at LIKE ?",
      ['$today%'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Lấy tổng số đơn hàng
  Future<int> getTotalOrders() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM orders");
    return (result.first['count'] as int?) ?? 0;
  }

  /// Lấy số đơn theo từng trạng thái
  Future<Map<String, int>> getOrderCountByStatus() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT status, COUNT(*) as count FROM orders GROUP BY status",
    );
    final map = <String, int>{};
    for (var row in result) {
      map[row['status'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
  }

  /// Lấy tổng số sản phẩm
  Future<int> getTotalProducts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM products");
    return (result.first['count'] as int?) ?? 0;
  }

  /// Lấy tổng số khách hàng (role = CUSTOMER)
  Future<int> getTotalCustomers() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM users WHERE role = 'CUSTOMER'",
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ══════════════════════════════════════════════════════════════
  //  LOW STOCK ALERTS
  // ══════════════════════════════════════════════════════════════

  /// Lấy danh sách sản phẩm sắp hết hàng hoặc hết hàng
  Future<List<Product>> getLowStockProducts({int threshold = 3}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'stock_quantity <= ?',
      whereArgs: [threshold],
      orderBy: 'stock_quantity ASC',
    );
    return result.map((m) => Product.fromMap(m)).toList();
  }

  /// Cập nhật thêm số lượng tồn kho (nhập hàng)
  Future<void> updateProductStock(int productId, int newQuantity) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'stock_quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ORDER MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Lấy tất cả đơn hàng (có thể filter theo status)
  Future<List<Order>> getAllOrders({String? statusFilter}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT * FROM orders';
    List<dynamic> args = [];

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query += ' WHERE status = ?';
      args.add(statusFilter);
    }

    query += ' ORDER BY created_at DESC';

    final result = await db.rawQuery(query, args);

    // Lấy order_items cho từng order
    List<Order> orders = [];
    for (var orderMap in result) {
      final orderId = orderMap['id'] as int;
      final itemsResult = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemsResult.map((m) => OrderItem.fromMap(m)).toList();
      orders.add(Order.fromMap(orderMap, items: items));
    }

    return orders;
  }

  /// Lấy danh sách đơn hàng PENDING (cho preview trên dashboard)
  Future<List<Order>> getPendingOrders({int limit = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'orders',
      where: "status = 'PENDING'",
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((m) => Order.fromMap(m)).toList();
  }

  /// Lấy chi tiết 1 đơn hàng (kèm order_items)
  Future<Order?> getOrderDetail(int orderId) async {
    final db = await _dbHelper.database;
    final orderResult = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderResult.isEmpty) return null;

    final itemsResult = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    final items = itemsResult.map((m) => OrderItem.fromMap(m)).toList();

    return Order.fromMap(orderResult.first, items: items);
  }

  /// Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final db = await _dbHelper.database;
    await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
