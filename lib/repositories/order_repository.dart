import 'dart:math';

import '../core/database/database_helper.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'notification_repository.dart';

class OutOfStockException implements Exception {
  final String productName;
  final int availableStock;
  final int requestedQuantity;

  OutOfStockException({
    required this.productName,
    required this.availableStock,
    required this.requestedQuantity,
  });

  @override
  String toString() {
    if (availableStock <= 0) {
      return 'Sản phẩm "$productName" hiện đã hết hàng trong kho!';
    }
    return 'Sản phẩm "$productName" chỉ còn $availableStock sản phẩm trong kho (bạn yêu cầu $requestedQuantity)!';
  }
}

class OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Lấy danh sách sản phẩm trong giỏ hàng của user kèm thông tin chi tiết từ bảng products
  Future<List<CartItem>> getCartItems(int userId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      '''
      SELECT 
        c.id as id,
        c.user_id as user_id,
        c.product_id as product_id,
        c.quantity as quantity,
        p.name as name,
        p.price as price,
        p.image_url as image_url,
        p.stock_quantity as stock_quantity
      FROM cart_items c
      INNER JOIN products p ON c.product_id = p.id
      WHERE c.user_id = ?
    ''',
      [userId],
    );

    return res.map((row) => CartItem.fromDbJoin(row)).toList();
  }

  /// Nạp các sản phẩm mẫu vào giỏ hàng phục vụ việc test nhanh checkout flow
  Future<void> seedCartItemsForTest(int userId) async {
    final db = await _dbHelper.database;
    // Lấy 2 sản phẩm đầu tiên có tồn kho > 0
    final products = await db.query(
      'products',
      where: 'stock_quantity > 0',
      limit: 2,
    );

    for (var p in products) {
      final productId = p['id'] as int;
      await db.rawInsert(
        '''
        INSERT OR REPLACE INTO cart_items (user_id, product_id, quantity)
        VALUES (?, ?, ?)
      ''',
        [userId, productId, 1],
      );
    }
  }

  /// Kiểm tra tồn kho của danh sách sản phẩm (Read-only check trước khi chạy transaction)
  Future<void> validateStock(List<CartItem> items) async {
    final db = await _dbHelper.database;

    for (final item in items) {
      final res = await db.query(
        'products',
        columns: ['id', 'name', 'stock_quantity'],
        where: 'id = ?',
        whereArgs: [item.productId],
      );

      if (res.isEmpty) {
        throw Exception(
          'Sản phẩm "${item.productName}" không tồn tại trong hệ thống.',
        );
      }

      final stock = res.first['stock_quantity'] as int;
      if (stock < item.quantity) {
        throw OutOfStockException(
          productName: item.productName,
          availableStock: stock,
          requestedQuantity: item.quantity,
        );
      }
    }
  }

  /// Tạo đơn hàng hoàn chỉnh sử dụng SQLite Transaction:
  /// 1. Kiểm tra tồn kho bên trong transaction
  /// 2. Trừ số lượng tồn kho của từng sản phẩm
  /// 3. Chèn bản ghi vào bảng orders
  /// 4. Chèn chi tiết các mặt hàng vào bảng order_items
  /// 5. Xóa các sản phẩm đã thanh toán khỏi cart_items
  Future<Order> createOrderWithTransaction({
    required int userId,
    required String customerName,
    required String phone,
    required String address,
    String note = '',
    required String paymentMethod,
    required List<CartItem> items,
    double discount = 0.0,
    double shippingFee = 0.0,
  }) async {
    if (items.isEmpty) {
      throw Exception('Không có sản phẩm nào để thanh toán!');
    }

    final db = await _dbHelper.database;

    // Tính tổng tiền
    final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final finalAmount = max(0.0, subtotal - discount + shippingFee);
    final now = DateTime.now();
    final orderCode =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.microsecondsSinceEpoch % 1000000}-${Random().nextInt(900) + 100}';

    Order? createdOrder;
    final lowStockList = <({String name, int remainingStock, int id})>[];

    // Bắt đầu thực thi SQLite Transaction
    await db.transaction((txn) async {
      // BƯỚC 1: Kiểm tra tồn kho bên trong Transaction để đảm bảo tính cô lập (ACID)
      for (final item in items) {
        final productRows = await txn.query(
          'products',
          columns: ['id', 'name', 'stock_quantity'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productRows.isEmpty) {
          throw Exception('Sản phẩm "${item.productName}" không còn tồn tại.');
        }

        final currentStock = productRows.first['stock_quantity'] as int;
        if (currentStock < item.quantity) {
          throw OutOfStockException(
            productName: item.productName,
            availableStock: currentStock,
            requestedQuantity: item.quantity,
          );
        }
      }

      // BƯỚC 2: Trừ tồn kho sản phẩm trong bảng products và theo dõi cảnh báo tồn kho
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );

        final pRows = await txn.rawQuery(
          'SELECT name, stock_quantity FROM products WHERE id = ?',
          [item.productId],
        );
        if (pRows.isNotEmpty) {
          final remStock = pRows.first['stock_quantity'] as int;
          final pName = pRows.first['name'] as String;
          if (remStock <= 5) {
            lowStockList.add((name: pName, remainingStock: remStock, id: item.productId));
          }
        }
      }

      // BƯỚC 3: Thêm đơn hàng vào bảng orders
      final orderMap = {
        'user_id': userId,
        'order_code': orderCode,
        'customer_name': customerName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'note': note.trim(),
        'subtotal': subtotal,
        'discount': discount,
        'shipping_fee': shippingFee,
        'final_amount': finalAmount,
        'payment_method': paymentMethod,
        'status': 'PENDING',
        'created_at': now.toIso8601String(),
      };

      final orderId = await txn.insert('orders', orderMap);

      // BƯỚC 4: Thêm từng sản phẩm vào bảng order_items
      final orderItemsList = <OrderItem>[];
      for (final item in items) {
        final orderItemId = await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'product_price': item.productPrice,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        });

        orderItemsList.add(
          OrderItem(
            id: orderItemId,
            orderId: orderId,
            productId: item.productId,
            productName: item.productName,
            productPrice: item.productPrice,
            quantity: item.quantity,
            subtotal: item.subtotal,
          ),
        );
      }

      // BƯỚC 5: Xóa các sản phẩm đã thanh toán khỏi cart_items của người dùng
      final productIds = items.map((i) => i.productId).toList();
      final placeholders = List.filled(productIds.length, '?').join(',');
      await txn.delete(
        'cart_items',
        where: 'user_id = ? AND product_id IN ($placeholders)',
        whereArgs: [userId, ...productIds],
      );

      createdOrder = Order(
        id: orderId,
        userId: userId,
        orderCode: orderCode,
        customerName: customerName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        note: note.trim(),
        subtotal: subtotal,
        discount: discount,
        shippingFee: shippingFee,
        finalAmount: finalAmount,
        paymentMethod: paymentMethod,
        status: 'PENDING',
        createdAt: now.toIso8601String(),
        items: orderItemsList,
      );
    });

    final confirmedOrder = createdOrder;
    if (confirmedOrder == null) {
      throw Exception('Không thể tạo đơn hàng do lỗi hệ thống.');
    }

    // Gửi thông báo tự động cho Customer, Employee và cảnh báo tồn kho cho Staff
    try {
      final notifRepo = NotificationRepository();
      await notifRepo.notifyCustomerOrderPlaced(
        userId: userId,
        orderCode: orderCode,
        orderId: confirmedOrder.id,
      );
      await notifRepo.notifyEmployeesNewOrder(
        orderCode: orderCode,
        customerName: customerName.trim(),
        finalAmount: finalAmount,
        orderId: confirmedOrder.id,
      );

      // Cảnh báo tồn kho khi sản phẩm còn ít (<= 5) hoặc hết hàng (0)
      for (final alert in lowStockList) {
        await notifRepo.notifyStockAlert(
          productName: alert.name,
          stockQuantity: alert.remainingStock,
          productId: alert.id,
        );
      }
    } catch (_) {}

    return confirmedOrder;
  }

  /// Lấy danh sách các đơn hàng của user
  Future<List<Order>> getOrdersByUserId(int userId) async {
    final db = await _dbHelper.database;
    final orderMaps = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    final List<Order> result = [];
    for (final map in orderMaps) {
      final orderId = map['id'] as int;
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemMaps.map((m) => OrderItem.fromMap(m)).toList();
      result.add(Order.fromMap(map, items: items));
    }
    return result;
  }

  /// Khách hàng hủy đơn hàng (chỉ áp dụng với đơn PENDING)
  /// Sử dụng Transaction để cập nhật status và hoàn trả tồn kho vào bảng products
  Future<bool> cancelOrder(int orderId, int userId) async {
    final db = await _dbHelper.database;

    final orderRows = await db.query(
      'orders',
      where: 'id = ? AND user_id = ?',
      whereArgs: [orderId, userId],
    );

    if (orderRows.isEmpty) {
      throw Exception('Không tìm thấy đơn hàng cần hủy!');
    }

    final currentStatus = orderRows.first['status'] as String;
    if (currentStatus != 'PENDING') {
      throw Exception('Chỉ có thể hủy đơn hàng đang ở trạng thái Chờ xác nhận (PENDING)!');
    }

    final itemRows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    await db.transaction((txn) async {
      // 1. Hoàn lại số lượng tồn kho cho các sản phẩm
      for (final item in itemRows) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as int;
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
          [quantity, productId],
        );
      }

      // 2. Chuyển trạng thái đơn sang CANCELLED
      await txn.update(
        'orders',
        {'status': 'CANCELLED'},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });

    // Gửi thông báo hủy đơn tới Customer và toàn bộ Nhân viên (Employee)
    try {
      final orderCode = orderRows.first['order_code'] as String;
      final customerName = (orderRows.first['customer_name'] as String?) ?? 'Khách hàng';
      final notifRepo = NotificationRepository();
      await notifRepo.notifyCustomerOrderStatusChange(
        userId: userId,
        orderCode: orderCode,
        status: 'CANCELLED',
        orderId: orderId,
      );
      await notifRepo.notifyEmployeesOrderCancelled(
        orderCode: orderCode,
        customerName: customerName,
        orderId: orderId,
      );
    } catch (_) {}

    return true;
  }

  /// Cập nhật trạng thái đơn hàng (ví dụ: chuyển sang PROCESSING sau khi PayOS thanh toán thành công)
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
