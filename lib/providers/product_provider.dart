import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId; // null = Tất cả danh mục
  String? _errorMessage;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  // Tìm sản phẩm trong danh sách theo ID
  Product? findById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Lấy tên danh mục theo ID
  String getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Chưa phân loại';
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return 'Chưa phân loại';
    }
  }

  // Lấy chi tiết sản phẩm từ SQLite (nếu chưa có trong bộ nhớ)
  Future<Product?> fetchProductDetail(int id) async {
    final existing = findById(id);
    if (existing != null) return existing;
    return await _productRepository.getProductById(id);
  }

  ProductProvider() {
    initData();
  }

  Future<void> initData() async {
    await fetchCategories();
    await loadProducts();
  }

  // Tải danh sách danh mục
  Future<void> fetchCategories() async {
    try {
      _categories = await _productRepository.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh mục: $e';
      notifyListeners();
    }
  }

  // Tải danh sách sản phẩm theo bộ lọc hiện tại
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productRepository.getProducts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
      );
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách sản phẩm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật từ khóa tìm kiếm
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadProducts();
  }

  // Lọc theo danh mục (null hoặc 0 là chọn tất cả)
  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  // Xóa toàn bộ bộ lọc
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    loadProducts();
  }

  // Thêm sản phẩm mới (Admin)
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.addProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Thêm sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cập nhật sản phẩm (Admin)
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Cập nhật sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Xóa sản phẩm (Admin)
  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.deleteProduct(productId);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Xóa sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
