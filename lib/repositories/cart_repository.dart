import '../core/database/database_helper.dart';
import '../models/cart_item.dart';

class CartRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Lấy danh sách sản phẩm trong giỏ hàng kèm theo thông tin chi tiết của sản phẩm
  Future<List<CartItem>> getCartItems(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        c.id,
        c.user_id,
        c.product_id,
        c.quantity,
        p.name,
        p.price,
        p.image_url,
        p.stock_quantity
      FROM cart_items c
      INNER JOIN products p ON c.product_id = p.id
      WHERE c.user_id = ?
      ORDER BY c.id DESC
    ''', [userId]);

    return results.map((map) => CartItem.fromDbJoin(map)).toList();
  }

  /// Thêm sản phẩm vào giỏ hàng với kiểm tra tồn kho
  Future<void> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final db = await _dbHelper.database;

    // 1. Kiểm tra tồn kho của sản phẩm
    final productQuery = await db.query(
      'products',
      columns: ['id', 'name', 'stock_quantity'],
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productQuery.isEmpty) {
      throw Exception('Sản phẩm không tồn tại!');
    }

    final product = productQuery.first;
    final stockQuantity = (product['stock_quantity'] as int?) ?? 0;
    final productName = product['name'] as String;

    if (stockQuantity <= 0) {
      throw Exception('Sản phẩm "$productName" hiện đã hết hàng!');
    }

    // 2. Kiểm tra xem sản phẩm đã có trong giỏ của user chưa
    final existingCartQuery = await db.query(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );

    if (existingCartQuery.isNotEmpty) {
      final existingItem = existingCartQuery.first;
      final currentQuantity = existingItem['quantity'] as int;
      final newQuantity = currentQuantity + quantity;

      if (newQuantity > stockQuantity) {
        throw Exception(
          'Không thể thêm! Giỏ đã có $currentQuantity sản phẩm, tổng yêu cầu $newQuantity vượt quá tồn kho ($stockQuantity).',
        );
      }

      await db.update(
        'cart_items',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [existingItem['id']],
      );
    } else {
      if (quantity > stockQuantity) {
        throw Exception(
          'Số lượng yêu cầu ($quantity) vượt quá số lượng có sẵn trong kho ($stockQuantity).',
        );
      }

      await db.insert('cart_items', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  /// Cập nhật số lượng của một mục trong giỏ
  Future<void> updateQuantity({
    required int cartItemId,
    required int newQuantity,
  }) async {
    final db = await _dbHelper.database;

    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    await db.update(
      'cart_items',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  /// Xóa một sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(int cartItemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cart_items',
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  /// Xóa sạch giỏ hàng của user
  Future<void> clearCart(int userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
