import '../core/database/database_helper.dart';
import '../models/review.dart';

class ReviewRepository {
  final DatabaseHelper _dbHelper;

  ReviewRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Lấy toàn bộ danh sách đánh giá của sản phẩm (sắp xếp mới nhất lên đầu)
  Future<List<Review>> getReviewsByProductId(int productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reviews',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC, id DESC',
    );
    return maps.map((m) => Review.fromMap(m)).toList();
  }

  // Thêm đánh giá mới
  Future<int> addReview(Review review) async {
    final db = await _dbHelper.database;
    return await db.insert('reviews', review.toMap());
  }

  // Xóa đánh giá
  Future<bool> deleteReview(int reviewId) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'reviews',
      where: 'id = ?',
      whereArgs: [reviewId],
    );
    return count > 0;
  }

  // Kiểm tra khách hàng đã từng mua sản phẩm này chưa (đơn hàng COMPLETED)
  Future<bool> hasUserPurchasedProduct(int userId, int productId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders o
      INNER JOIN order_items oi ON o.id = oi.order_id
      WHERE o.user_id = ? 
        AND oi.product_id = ? 
        AND o.status = 'COMPLETED'
    ''', [userId, productId]);

    if (results.isNotEmpty) {
      final count = (results.first['count'] as num?)?.toInt() ?? 0;
      return count > 0;
    }
    return false;
  }

  // Lấy đánh giá của một user cụ thể cho sản phẩm (nếu có)
  Future<Review?> getUserReviewForProduct(int userId, int productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reviews',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Review.fromMap(maps.first);
    }
    return null;
  }
}

