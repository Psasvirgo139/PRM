import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();

  // ── Dashboard state ──
  bool _isLoadingDashboard = false;
  double _totalRevenue = 0;
  double _todayRevenue = 0;
  int _totalOrders = 0;
  int _pendingOrdersCount = 0;
  int _processingOrdersCount = 0;
  int _completedOrdersCount = 0;
  int _cancelledOrdersCount = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  List<Product> _lowStockProducts = [];
  List<Order> _pendingOrdersPreview = [];

  // ── Order management state ──
  bool _isLoadingOrders = false;
  List<Order> _allOrders = [];
  String? _statusFilter;
  Order? _selectedOrder;
  bool _isLoadingDetail = false;
  bool _isUpdatingStatus = false;

  // ══════════════════════════════════════════════════════════════
  //  GETTERS
  // ══════════════════════════════════════════════════════════════

  bool get isLoadingDashboard => _isLoadingDashboard;
  double get totalRevenue => _totalRevenue;
  double get todayRevenue => _todayRevenue;
  int get totalOrders => _totalOrders;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get processingOrdersCount => _processingOrdersCount;
  int get completedOrdersCount => _completedOrdersCount;
  int get cancelledOrdersCount => _cancelledOrdersCount;
  int get totalProducts => _totalProducts;
  int get totalCustomers => _totalCustomers;
  List<Product> get lowStockProducts => _lowStockProducts;
  List<Order> get pendingOrdersPreview => _pendingOrdersPreview;

  bool get isLoadingOrders => _isLoadingOrders;
  List<Order> get allOrders => _allOrders;
  String? get statusFilter => _statusFilter;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isUpdatingStatus => _isUpdatingStatus;

  // ══════════════════════════════════════════════════════════════
  //  DASHBOARD ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      // Chạy song song tất cả queries để tăng tốc
      final results = await Future.wait([
        _repository.getTotalRevenue(),
        _repository.getTodayRevenue(),
        _repository.getTotalOrders(),
        _repository.getOrderCountByStatus(),
        _repository.getTotalProducts(),
        _repository.getTotalCustomers(),
        _repository.getLowStockProducts(),
        _repository.getPendingOrders(),
      ]);

      _totalRevenue = results[0] as double;
      _todayRevenue = results[1] as double;
      _totalOrders = results[2] as int;

      final statusMap = results[3] as Map<String, int>;
      _pendingOrdersCount = statusMap['PENDING'] ?? 0;
      _processingOrdersCount = statusMap['PROCESSING'] ?? 0;
      _completedOrdersCount = statusMap['COMPLETED'] ?? 0;
      _cancelledOrdersCount = statusMap['CANCELLED'] ?? 0;

      _totalProducts = results[4] as int;
      _totalCustomers = results[5] as int;
      _lowStockProducts = results[6] as List<Product>;
      _pendingOrdersPreview = results[7] as List<Order>;
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════
  //  ORDER MANAGEMENT ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> loadOrders({String? status}) async {
    _isLoadingOrders = true;
    _statusFilter = status;
    notifyListeners();

    try {
      _allOrders = await _repository.getAllOrders(statusFilter: status);
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    _isLoadingOrders = false;
    notifyListeners();
  }

  Future<void> loadOrderDetail(int orderId) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      _selectedOrder = await _repository.getOrderDetail(orderId);
    } catch (e) {
      debugPrint('Error loading order detail: $e');
    }

    _isLoadingDetail = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    _isUpdatingStatus = true;
    notifyListeners();

    try {
      await _repository.updateOrderStatus(orderId, newStatus);

      // Cập nhật local state ngay lập tức (không cần query lại)
      // Update trong danh sách orders
      final idx = _allOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final old = _allOrders[idx];
        _allOrders[idx] = Order(
          id: old.id,
          userId: old.userId,
          orderCode: old.orderCode,
          customerName: old.customerName,
          phone: old.phone,
          address: old.address,
          note: old.note,
          subtotal: old.subtotal,
          discount: old.discount,
          shippingFee: old.shippingFee,
          finalAmount: old.finalAmount,
          paymentMethod: old.paymentMethod,
          status: newStatus,
          createdAt: old.createdAt,
          items: old.items,
        );
      }

      // Update selected order nếu đang xem detail
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = Order(
          id: _selectedOrder!.id,
          userId: _selectedOrder!.userId,
          orderCode: _selectedOrder!.orderCode,
          customerName: _selectedOrder!.customerName,
          phone: _selectedOrder!.phone,
          address: _selectedOrder!.address,
          note: _selectedOrder!.note,
          subtotal: _selectedOrder!.subtotal,
          discount: _selectedOrder!.discount,
          shippingFee: _selectedOrder!.shippingFee,
          finalAmount: _selectedOrder!.finalAmount,
          paymentMethod: _selectedOrder!.paymentMethod,
          status: newStatus,
          createdAt: _selectedOrder!.createdAt,
          items: _selectedOrder!.items,
        );
      }

      _isUpdatingStatus = false;
      notifyListeners();

      // Cập nhật ngầm các số liệu thống kê Dashboard
      _refreshDashboardStats();

      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _isUpdatingStatus = false;
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật nhanh số lượng tồn kho của sản phẩm
  Future<bool> restockProduct(int productId, int newQuantity) async {
    try {
      await _repository.updateProductStock(productId, newQuantity);
      _lowStockProducts = await _repository.getLowStockProducts();
      _totalProducts = await _repository.getTotalProducts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restocking product: $e');
      return false;
    }
  }

  /// Cập nhật ngầm các số liệu dashboard khi đơn hàng thay đổi
  Future<void> _refreshDashboardStats() async {
    try {
      final results = await Future.wait([
        _repository.getTotalRevenue(),
        _repository.getTodayRevenue(),
        _repository.getTotalOrders(),
        _repository.getOrderCountByStatus(),
        _repository.getPendingOrders(),
      ]);
      _totalRevenue = results[0] as double;
      _todayRevenue = results[1] as double;
      _totalOrders = results[2] as int;
      final statusMap = results[3] as Map<String, int>;
      _pendingOrdersCount = statusMap['PENDING'] ?? 0;
      _processingOrdersCount = statusMap['PROCESSING'] ?? 0;
      _completedOrdersCount = statusMap['COMPLETED'] ?? 0;
      _cancelledOrdersCount = statusMap['CANCELLED'] ?? 0;
      _pendingOrdersPreview = results[4] as List<Order>;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing dashboard stats: $e');
    }
  }

  /// Đặt filter status và load lại danh sách
  void setStatusFilter(String? status) {
    loadOrders(status: status);
  }
}
