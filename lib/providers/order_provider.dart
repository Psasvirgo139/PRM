import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  List<CartItem> _checkoutItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  Order? _lastCreatedOrder;
  List<Order> _userOrders = [];

  List<CartItem> get checkoutItems => _checkoutItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Order? get lastCreatedOrder => _lastCreatedOrder;
  List<Order> get userOrders => _userOrders;

  double get subtotal => _checkoutItems.fold(0.0, (sum, item) => sum + item.subtotal);
  int get totalItemsCount => _checkoutItems.fold(0, (sum, item) => sum + item.quantity);

  /// Nạp các sản phẩm trong giỏ hàng của người dùng để chuẩn bị checkout
  Future<void> loadCheckoutItems(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _checkoutItems = await _orderRepository.getCartItems(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải giỏ hàng: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gán danh sách sản phẩm cần thanh toán trực tiếp (ví dụ: mua ngay hoặc chọn từ giỏ hàng)
  void setCheckoutItems(List<CartItem> items) {
    _checkoutItems = List.from(items);
    _errorMessage = null;
    notifyListeners();
  }

  /// Nạp dữ liệu giỏ hàng mẫu để test nhanh
  Future<void> seedSampleCart(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _orderRepository.seedCartItemsForTest(userId);
      _checkoutItems = await _orderRepository.getCartItems(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kiểm tra tồn kho trước khi thanh toán
  Future<bool> checkStockBeforeCheckout() async {
    try {
      await _orderRepository.validateStock(_checkoutItems);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Thực hiện thanh toán và chạy SQLite Transaction
  Future<Order?> placeOrder({
    required int userId,
    required String customerName,
    required String phone,
    required String address,
    String note = '',
    required String paymentMethod,
    double discount = 0.0,
    double shippingFee = 0.0,
  }) async {
    if (_checkoutItems.isEmpty) {
      _errorMessage = 'Giỏ hàng của bạn đang trống!';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderRepository.createOrderWithTransaction(
        userId: userId,
        customerName: customerName,
        phone: phone,
        address: address,
        note: note,
        paymentMethod: paymentMethod,
        items: _checkoutItems,
        discount: discount,
        shippingFee: shippingFee,
      );

      _lastCreatedOrder = order;
      _checkoutItems.clear(); // Xóa giỏ hàng trên giao diện sau khi thanh toán thành công
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Tải lịch sử đơn hàng của người dùng
  Future<void> loadUserOrders(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userOrders = await _orderRepository.getOrdersByUserId(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
