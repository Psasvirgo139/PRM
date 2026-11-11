import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../repositories/notification_repository.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();

  List<Product> _products = [];
  List<Product> _allProductsCache = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId; // null = Tất cả danh mục
  String? _errorMessage;

  // ── Thuộc tính phân trang (Pagination) ──
  int _currentPage = 1;
  int _pageSize = 8; // Mặc định 8 sản phẩm / trang
  int _totalProductCount = 0;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  // Getters phân trang
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalProductCount => _totalProductCount;
  int get totalPages => (_totalProductCount == 0) ? 1 : (_totalProductCount / _pageSize).ceil();
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < totalPages;
  int get startIndex => _totalProductCount == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
  int get endIndex {
    final end = _currentPage * _pageSize;
    return end > _totalProductCount ? _totalProductCount : end;
  }

  // Tìm sản phẩm trong danh sách theo ID (tra cứu trang hiện tại, sau đó tra cứu toàn bộ cache)
  Product? findById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _allProductsCache.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
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

  Future<void> loadCategories() => fetchCategories();

  // Tải danh sách sản phẩm theo bộ lọc hiện tại có phân trang
  Future<void> loadProducts({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Đếm tổng số sản phẩm thỏa mãn điều kiện
      _totalProductCount = await _productRepository.getProductCount(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
      );

      // Nếu trang hiện tại vượt quá số trang thực tế thì quay về trang 1
      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = 1;
      }

      // 2. Lấy dữ liệu sản phẩm của trang hiện tại
      _products = await _productRepository.getPaginatedProducts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // 3. Cập nhật cache toàn bộ sản phẩm để phục vụ chi tiết và so sánh
      _allProductsCache = await _productRepository.getAllProducts();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách sản phẩm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chuyển đến trang chỉ định
  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages || page == _currentPage) return;
    _currentPage = page;
    await loadProducts();
  }

  // Trang kế tiếp
  Future<void> nextPage() async {
    if (hasNextPage) {
      await goToPage(_currentPage + 1);
    }
  }

  // Trang trước
  Future<void> previousPage() async {
    if (hasPreviousPage) {
      await goToPage(_currentPage - 1);
    }
  }

  // Thay đổi số lượng sản phẩm mỗi trang (8, 12, 16...)
  Future<void> setPageSize(int size) async {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 1;
    await loadProducts();
  }

  // Cập nhật từ khóa tìm kiếm (tự động reset về trang 1)
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;
    loadProducts();
  }

  // Lọc theo danh mục (tự động reset về trang 1)
  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _currentPage = 1;
    loadProducts();
  }

  // Xóa toàn bộ bộ lọc
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _currentPage = 1;
    loadProducts();
  }

  // Thêm sản phẩm mới (Admin / Staff)
  Future<bool> addProduct(Product product, {String actorName = 'nhân viên'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newId = await _productRepository.addProduct(product);
      await loadProducts();
      try {
        await NotificationRepository().notifyAdminsProductChange(
          productName: product.name,
          action: 'ADD',
          actorName: actorName,
          productId: newId,
        );
      } catch (_) {}
      return true;
    } catch (e) {
      _errorMessage = 'Thêm sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cập nhật sản phẩm (Admin / Staff)
  Future<bool> updateProduct(Product product, {String actorName = 'nhân viên'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.updateProduct(product);
      await loadProducts();
      try {
        await NotificationRepository().notifyAdminsProductChange(
          productName: product.name,
          action: 'UPDATE',
          actorName: actorName,
          productId: product.id,
        );
      } catch (_) {}
      return true;
    } catch (e) {
      _errorMessage = 'Cập nhật sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Xóa sản phẩm (Admin / Staff)
  Future<bool> deleteProduct(int productId, {String actorName = 'nhân viên'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final productToDelete = _products.where((p) => p.id == productId).firstOrNull;
      final productName = productToDelete?.name ?? 'ID #$productId';

      await _productRepository.deleteProduct(productId);
      await loadProducts();
      try {
        await NotificationRepository().notifyAdminsProductChange(
          productName: productName,
          action: 'DELETE',
          actorName: actorName,
          productId: productId,
        );
      } catch (_) {}
      return true;
    } catch (e) {
      _errorMessage = 'Xóa sản phẩm thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
