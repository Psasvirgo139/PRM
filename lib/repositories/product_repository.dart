import '../core/database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Lấy toàn bộ danh mục sản phẩm
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final res = await db.query('categories');
    return res.map((map) => Category.fromMap(map)).toList();
  }

  // Tìm kiếm và lọc sản phẩm theo từ khóa và danh mục
  Future<List<Product>> getProducts({
    String? search,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR description LIKE ?)');
      final keyword = '%${search.trim()}%';
      whereArgs.add(keyword);
      whereArgs.add(keyword);
    }

    if (categoryId != null && categoryId > 0) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    final res = await db.query(
      'products',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    return res.map((map) => Product.fromMap(map)).toList();
  }

  // Lấy chi tiết sản phẩm theo ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return Product.fromMap(res.first);
    }
    return null;
  }

  // Thêm sản phẩm mới (dành cho Admin)
  Future<int> addProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  // Cập nhật sản phẩm (dành cho Admin)
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Xóa sản phẩm (dành cho Admin)
  Future<int> deleteProduct(int productId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
