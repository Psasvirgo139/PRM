import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order? order;

  const OrderSuccessScreen({super.key, this.order});

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'BANKING':
        return 'Chuyển khoản ngân hàng (QR Pay)';
      case 'MOMO':
        return 'Ví điện tử MoMo';
      case 'COD':
      default:
        return 'Thanh toán tiền mặt khi nhận hàng (COD)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOrder = order;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Đặt Hàng Thành Công'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: effectiveOrder == null
            ? _buildNoOrderData(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Header Thành công
                    _buildSuccessHeader(effectiveOrder),
                    const SizedBox(height: 16),

                    // Thông tin mã đơn và tổng tiền
                    _buildOrderSummaryCard(context, effectiveOrder),
                    const SizedBox(height: 16),

                    // Thông tin người nhận
                    _buildDeliveryInfoCard(effectiveOrder),
                    const SizedBox(height: 16),

                    // Chi tiết các sản phẩm đã đặt
                    _buildOrderItemsCard(effectiveOrder),
                    const SizedBox(height: 24),

                    // Các nút điều hướng
                    _buildActionButtons(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNoOrderData(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Đơn hàng của bạn đã được ghi nhận!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Quay lại trang chủ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade600,
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cảm ơn bạn đã đặt hàng!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đơn hàng của bạn đã được tạo thành công và đang chờ xác nhận.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mã đơn hàng',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.orderCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép mã đơn hàng'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy, size: 14, color: Colors.deepPurple),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thời gian tạo', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                _formatDateTime(order.createdAt),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phương thức', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Flexible(
                child: Text(
                  _getPaymentMethodLabel(order.paymentMethod),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trạng thái', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400, width: 0.8),
                ),
                child: Text(
                  'Chờ xử lý (${order.status})',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                CurrencyFormatter.format(order.finalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Thông tin nhận hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.customerName} - ${order.phone}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.address,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                ),
              ),
            ],
          ),
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ghi chú: ${order.note}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: Colors.deepPurple, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sản phẩm đã mua',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Text(
                '${order.items.length} món',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.devices, color: Colors.deepPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(item.productPrice)}  ×  ${item.quantity}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => context.go('/'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.home_outlined),
            label: const Text(
              'Tiếp tục mua sắm',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/orders'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text(
              'Xem lịch sử đơn hàng',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
