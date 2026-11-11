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

  // Tìm kiếm và lọc sản phẩm có hỗ trợ phân trang (LIMIT & OFFSET)
  Future<List<Product>> getPaginatedProducts({
    String? search,
    int? categoryId,
    int page = 1,
    int pageSize = 8,
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

    final int offset = (page > 1) ? (page - 1) * pageSize : 0;

    final res = await db.query(
      'products',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
      limit: pageSize,
      offset: offset,
    );

    return res.map((map) => Product.fromMap(map)).toList();
  }

  // Đếm tổng số sản phẩm thỏa mãn điều kiện lọc
  Future<int> getProductCount({
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

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products $whereString',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    if (res.isNotEmpty) {
      return (res.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // Tìm kiếm và lọc sản phẩm theo từ khóa và danh mục (toàn bộ)
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

  // Lấy toàn bộ sản phẩm
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'products',
      orderBy: 'id ASC',
    );
    return results.map((e) => Product.fromMap(e)).toList();
  }
}
