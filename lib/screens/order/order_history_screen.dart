import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payos_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int? _currentLoadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user != null && user.id != null && auth.isCustomer) {
      if (_currentLoadedUserId != user.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadOrders();
        });
      }
    } else {
      _currentLoadedUserId = null;
    }
  }

  void _loadOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user != null && user.id != null && auth.isCustomer) {
      _currentLoadedUserId = user.id;
      Provider.of<OrderProvider>(context, listen: false).loadUserOrders(user.id!);
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _getPaymentMethodTitle(String method) {
    switch (method.toUpperCase()) {
      case 'PAYOS':
        return 'Cổng payOS (VietQR 24/7)';
      case 'BANKING':
      case 'BANK_TRANSFER':
        return 'Chuyển khoản (VietQR)';
      case 'MOMO':
        return 'Ví MoMo';
      case 'COD':
      default:
        return 'Tiền mặt khi nhận hàng (COD)';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'PROCESSING':
        return Colors.blue.shade700;
      case 'SHIPPED':
        return Colors.purple.shade700;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade50;
      case 'PROCESSING':
        return Colors.blue.shade50;
      case 'SHIPPED':
        return Colors.purple.shade50;
      case 'COMPLETED':
        return Colors.green.shade50;
      case 'CANCELLED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PROCESSING':
        return 'Đang chuẩn bị';
      case 'SHIPPED':
        return 'Đang giao hàng';
      case 'COMPLETED':
        return 'Giao thành công';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Hộp thoại xác nhận hủy đơn hàng
  void _confirmCancelOrder(BuildContext context, Order order, int userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận hủy đơn hàng'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng "${order.orderCode}"?\nSố lượng tồn kho các sản phẩm sẽ được hoàn lại tự động.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final orderProvider = context.read<OrderProvider>();
              final success = await orderProvider.cancelOrder(order.id!, userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã hủy đơn hàng ${order.orderCode} thành công!'
                          : (orderProvider.errorMessage ?? 'Hủy đơn hàng thất bại!'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Hủy đơn hàng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Mua lại đơn hàng đã hoàn thành
  Future<void> _handleReorder(BuildContext context, Order order) async {
    final cart = context.read<CartProvider>();
    int addedCount = 0;

    for (final item in order.items) {
      final success = await cart.addToCart(
        productId: item.productId,
        quantity: item.quantity,
      );
      if (success) addedCount++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $addedCount sản phẩm vào giỏ hàng!'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Xem giỏ hàng',
            textColor: Colors.amberAccent,
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    }
  }

  // Khởi tạo và mở giao diện thanh toán payOS cho đơn hàng PENDING
  Future<void> _handlePayOSPayment(BuildContext context, Order order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryOrange),
                SizedBox(height: 16),
                Text(
                  'Đang khởi tạo cổng thanh toán payOS...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final payosService = PayOSService();
      final payosOrderCode = PayOSService.generateUniqueOrderCode();
      final payosData = await payosService.createPaymentLink(
        orderCode: payosOrderCode,
        amount: order.finalAmount.round(),
        description: 'DH${order.id ?? payosOrderCode}',
        items: order.items.map((i) => {
          'name': i.productName,
          'quantity': i.quantity,
          'price': i.productPrice.round(),
        }).toList(),
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // đóng loading

      context.push(
        '/payos-payment',
        extra: {
          'order': order,
          'payosData': payosData,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo mã payOS: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Modal BottomSheet hiển thị chi tiết đơn hàng đầy đủ
  void _showOrderDetailModal(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh kéo handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề & Trạng thái
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết đơn hàng',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.orderCode,
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(order.status),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(order.status).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Thời gian đặt
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian đặt: ${_formatDateTime(order.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Thông tin người nhận
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: Colors.deepPurple),
                            SizedBox(width: 6),
                            Text(
                              'Địa chỉ nhận hàng',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order.customerName} | ${order.phone}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.address,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        if (order.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Ghi chú: ${order.note}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phương thức thanh toán
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payment, size: 18, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phương thức thanh toán',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _getPaymentMethodTitle(order.paymentMethod),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách sản phẩm
                  const Text(
                    'Sản phẩm đã mua',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (ctx, index) {
                      final item = order.items[index];
                      return Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.devices, color: Colors.deepPurple, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.format(item.productPrice)} × ${item.quantity}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 24),

                  // Bảng tính tiền
                  _buildPriceDetailRow('Tạm tính tiền hàng', CurrencyFormatter.format(order.subtotal)),
                  const SizedBox(height: 6),
                  _buildPriceDetailRow('Phí vận chuyển', CurrencyFormatter.format(order.shippingFee)),
                  const SizedBox(height: 6),
                  _buildPriceDetailRow('Giảm giá', '-${CurrencyFormatter.format(order.discount)}'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormatter.format(order.finalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nút thanh toán payOS trực tiếp trong modal chi tiết
                  if (order.status.toUpperCase() == 'PENDING' && order.paymentMethod == 'PAYOS') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _handlePayOSPayment(context, order);
                        },
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text(
                          'Thanh toán ngay qua payOS',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (auth.isLoggedIn && auth.isCustomer && user?.id != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                orderProvider.loadUserOrders(user!.id!);
              },
            ),
        ],
      ),
      // Phân quyền: CHỈ KHÁCH HÀNG (CUSTOMER) mới được xem lịch sử đơn hàng cá nhân
      body: ResponsiveContainer(
        maxWidth: 900,
        child: !auth.isLoggedIn || user == null
            ? _buildNotLoggedIn(context)
            : auth.canManageOrders
                ? _buildAdminEmployeeRestricted(context, auth)
                : DefaultTabController(
                    length: 5,
                    child: Column(
                      children: [
                        // Thanh Tab lọc theo trạng thái
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelColor: AppColors.primaryOrange,
                            unselectedLabelColor: Colors.grey.shade600,
                            indicatorColor: AppColors.primaryOrange,
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: 'Tất cả'),
                              Tab(text: 'Chờ duyệt'),
                              Tab(text: 'Đang xử lý'),
                              Tab(text: 'Hoàn thành'),
                              Tab(text: 'Đã hủy'),
                            ],
                          ),
                        ),

                        // Nội dung các tab
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOrderList(context, orderProvider, user.id!, null),
                              _buildOrderList(context, orderProvider, user.id!, 'PENDING'),
                              _buildOrderList(context, orderProvider, user.id!, 'PROCESSING'),
                              _buildOrderList(context, orderProvider, user.id!, 'COMPLETED'),
                              _buildOrderList(context, orderProvider, user.id!, 'CANCELLED'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // Danh sách đơn hàng theo filter status
  Widget _buildOrderList(
    BuildContext context,
    OrderProvider provider,
    int userId,
    String? statusFilter,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.userOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi khi tải đơn hàng: ${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadUserOrders(userId),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = provider.userOrders.where((order) {
      if (statusFilter == null) return true;
      return order.status.toUpperCase() == statusFilter.toUpperCase();
    }).toList();

    if (filteredOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => provider.loadUserOrders(userId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      statusFilter == null
                          ? 'Bạn chưa có đơn hàng nào!'
                          : 'Chưa có đơn hàng nào ở mục "${_getStatusLabel(statusFilter)}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Khám phá các sản phẩm công nghệ và đặt mua ngay hôm nay!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Mua sắm ngay'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadUserOrders(userId),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredOrders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(context, order, userId);
        },
      ),
    );
  }

  // Thẻ đơn hàng
  Widget _buildOrderCard(BuildContext context, Order order, int userId) {
    final statusColor = _getStatusColor(order.status);
    final statusBgColor = _getStatusBackgroundColor(order.status);
    final isPending = order.status.toUpperCase() == 'PENDING';
    final isCompleted = order.status.toUpperCase() == 'COMPLETED';

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mã đơn & Badge trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_outlined, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getStatusLabel(order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Thời gian đặt hàng
            Text(
              'Đặt ngày: ${_formatDateTime(order.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 20),

            // Tóm tắt các mặt hàng
            ...order.items.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '× ${item.quantity}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '... và ${order.items.length - 3} sản phẩm khác',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),

            const Divider(height: 20),

            // Phương thức thanh toán & Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPaymentMethodTitle(order.paymentMethod),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          'Tổng tiền: ',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        Text(
                          CurrencyFormatter.format(order.finalAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Nút hành động
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút Thanh toán ngay cho đơn PayOS PENDING
                    if (isPending && order.paymentMethod == 'PAYOS') ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _handlePayOSPayment(context, order),
                        icon: const Icon(Icons.qr_code_2, size: 14),
                        label: const Text(
                          'Thanh toán',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Nút Hủy đơn nếu đang PENDING
                    if (isPending)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _confirmCancelOrder(context, order, userId),
                        child: const Text('Hủy đơn', style: TextStyle(fontSize: 12)),
                      ),

                    // Nút Mua lại nếu COMPLETED
                    if (isCompleted)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _handleReorder(context, order),
                        icon: const Icon(Icons.replay_rounded, size: 14),
                        label: const Text('Mua lại', style: TextStyle(fontSize: 12)),
                      ),

                    const SizedBox(width: 6),

                    // Nút Chi tiết
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => _showOrderDetailModal(context, order),
                      child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện khi truy cập bằng tài khoản Admin / Employee (Bị giới hạn)
  Widget _buildAdminEmployeeRestricted(BuildContext context, AuthProvider auth) {
    final roleName = auth.isAdmin ? 'Quản Trị Viên (Admin)' : 'Nhân Viên (Employee)';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (auth.isAdmin ? Colors.deepPurple : Colors.teal).shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                auth.isAdmin ? Icons.admin_panel_settings_rounded : Icons.badge_outlined,
                size: 72,
                color: auth.isAdmin ? Colors.deepPurple : Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chức năng dành cho Khách hàng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn đang đăng nhập với vai trò $roleName.\nTài khoản quản trị không có lịch sử mua hàng cá nhân. Vui lòng chuyển sang phân hệ Quản lý đơn hàng để xem và xử lý đơn hàng của toàn hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/admin/orders'),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Đi đến Quản lý Đơn hàng'),
              style: FilledButton.styleFrom(
                backgroundColor: auth.isAdmin ? Colors.deepPurple : Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Quay lại trang chủ'),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện khi chưa đăng nhập
  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 72,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập tài khoản Khách hàng để theo dõi và quản lý lịch sử đơn hàng của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
