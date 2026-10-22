import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _userId = 2; // Mặc định là ID 2 (tài khoản customer mẫu) khi chưa login

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get userId => _userId;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get distinctCount => _items.length;
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  CartProvider({int? initialUserId}) {
    if (initialUserId != null) {
      _userId = initialUserId;
    }
    loadCart();
  }

  /// Cập nhật user ID khi đăng nhập / đăng xuất và tự động tải lại giỏ hàng tương ứng
  void setUserId(int newUserId) {
    if (_userId != newUserId) {
      _userId = newUserId;
      loadCart();
    }
  }

  /// Tải danh sách sản phẩm trong giỏ hàng từ SQLite
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _cartRepository.getCartItems(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải giỏ hàng: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<bool> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartRepository.addToCart(
        userId: _userId,
        productId: productId,
        quantity: quantity,
      );
      _items = await _cartRepository.getCartItems(_userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Tăng số lượng sản phẩm trong giỏ (có kiểm tra tồn kho)
  Future<bool> increaseQuantity(CartItem item) async {
    if (item.id == null) return false;

    if (item.quantity >= item.availableStock) {
      _errorMessage = 'Đã đạt số lượng tồn kho tối đa (${item.availableStock})!';
      notifyListeners();
      return false;
    }

    try {
      final newQuantity = item.quantity + 1;
      await _cartRepository.updateQuantity(
        cartItemId: item.id!,
        newQuantity: newQuantity,
      );
      item.quantity = newQuantity;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Giảm số lượng sản phẩm trong giỏ (nếu về 0 thì tự động xóa)
  Future<void> decreaseQuantity(CartItem item) async {
    if (item.id == null) return;

    try {
      final newQuantity = item.quantity - 1;
      if (newQuantity <= 0) {
        await removeItem(item.id!);
      } else {
        await _cartRepository.updateQuantity(
          cartItemId: item.id!,
          newQuantity: newQuantity,
        );
        item.quantity = newQuantity;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Xóa hẳn 1 sản phẩm khỏi giỏ hàng
  Future<void> removeItem(int cartItemId) async {
    try {
      await _cartRepository.removeFromCart(cartItemId);
      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Xóa sạch tất cả sản phẩm trong giỏ của user
  Future<void> clearCart() async {
    try {
      await _cartRepository.clearCart(_userId);
      _items.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
