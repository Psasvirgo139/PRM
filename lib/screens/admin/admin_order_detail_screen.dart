import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/admin_provider.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final order = adminProvider.selectedOrder;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order != null ? order.orderCode : 'Chi tiết đơn hàng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: adminProvider.isLoadingDetail || order == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Current Status ──
                  _buildStatusSection(order.status, colorScheme),
                  const SizedBox(height: 20),

                  // ── Customer Info ──
                  _buildSectionCard(
                    title: 'Thông tin khách hàng',
                    icon: Icons.person_rounded,
                    children: [
                      _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Họ tên',
                          value: order.customerName),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Điện thoại',
                          value: order.phone,
                          isCopyable: true),
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Địa chỉ',
                          value: order.address,
                          isCopyable: true),
                      if (order.note.isNotEmpty)
                        _InfoRow(
                            icon: Icons.note_outlined,
                            label: 'Ghi chú',
                            value: order.note),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Order Items ──
                  _buildSectionCard(
                    title: 'Sản phẩm (${order.items.length})',
                    icon: Icons.shopping_bag_rounded,
                    children: [
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name & price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${CurrencyFormatter.format(item.productPrice)} × ${item.quantity}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Subtotal
                              Text(
                                CurrencyFormatter.format(item.subtotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Payment Summary ──
                  _buildSectionCard(
                    title: 'Thanh toán',
                    icon: Icons.receipt_rounded,
                    children: [
                      _PaymentRow(
                          label: 'Tạm tính',
                          amount: order.subtotal),
                      if (order.discount > 0)
                        _PaymentRow(
                            label: 'Giảm giá',
                            amount: -order.discount,
                            isDiscount: true),
                      if (order.shippingFee > 0)
                        _PaymentRow(
                            label: 'Phí vận chuyển',
                            amount: order.shippingFee),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG CỘNG',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(order.finalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.payment_rounded,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _getPaymentLabel(order.paymentMethod),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Order Info ──
                  _buildSectionCard(
                    title: 'Thông tin đơn hàng',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _InfoRow(
                          icon: Icons.tag_rounded,
                          label: 'Mã đơn',
                          value: order.orderCode,
                          isCopyable: true),
                      _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Ngày tạo',
                          value: _formatDateTime(order.createdAt)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ──
                  if (_canUpdateStatus(order.status))
                    _buildActionButtons(adminProvider, order.status, colorScheme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STATUS SECTION
  // ══════════════════════════════════════════════════════════════

  Widget _buildStatusSection(String status, ColorScheme colorScheme) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo.color.withValues(alpha: 0.15),
            statusInfo.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusInfo.icon, color: statusInfo.color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái đơn hàng',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusInfo.label,
                    style: TextStyle(
                      color: statusInfo.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildStatusTracker(status),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(String status) {
    if (status == 'CANCELLED') {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade800),
            const SizedBox(width: 8),
            Text(
              'Đơn hàng này đã bị hủy bỏ',
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final steps = ['Chờ xử lý', 'Đang xử lý', 'Hoàn thành'];
    int currentStep = 0;
    if (status == 'PROCESSING') currentStep = 1;
    if (status == 'COMPLETED') currentStep = 2;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isDone = stepIndex <= currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDone ? Colors.green : Colors.grey.shade300,
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SECTION CARD (Reusable container)
  // ══════════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ══════════════════════════════════════════════════════════════

  Widget _buildActionButtons(
      AdminProvider provider, String currentStatus, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action
        if (currentStatus == 'PENDING')
          FilledButton.icon(
            onPressed: provider.isUpdatingStatus
                ? null
                : () => _confirmStatusUpdate('PROCESSING'),
            icon: provider.isUpdatingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Xác nhận xử lý'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        if (currentStatus == 'PROCESSING')
          FilledButton.icon(
            onPressed: provider.isUpdatingStatus
                ? null
                : () => _confirmStatusUpdate('COMPLETED'),
            icon: provider.isUpdatingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: const Text('Hoàn thành đơn hàng'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),

        // Cancel button (for PENDING and PROCESSING)
        if (currentStatus == 'PENDING' || currentStatus == 'PROCESSING') ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: provider.isUpdatingStatus
                ? null
                : () => _confirmStatusUpdate('CANCELLED'),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy đơn hàng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  CONFIRM DIALOG
  // ══════════════════════════════════════════════════════════════

  Future<void> _confirmStatusUpdate(String newStatus) async {
    final statusInfo = _getStatusInfo(newStatus);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(statusInfo.icon, color: statusInfo.color),
            const SizedBox(width: 10),
            const Expanded(child: Text('Xác nhận')),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn chuyển trạng thái đơn hàng sang "${statusInfo.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: statusInfo.color),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<AdminProvider>()
          .updateOrderStatus(widget.orderId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Cập nhật trạng thái thành công!'
                  : 'Lỗi khi cập nhật trạng thái',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════

  bool _canUpdateStatus(String status) {
    return status == 'PENDING' || status == 'PROCESSING';
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING':
        return _StatusInfo(
          label: 'Chờ xử lý',
          color: Colors.amber.shade700,
          icon: Icons.hourglass_top_rounded,
        );
      case 'PROCESSING':
        return _StatusInfo(
          label: 'Đang xử lý',
          color: Colors.blue.shade700,
          icon: Icons.autorenew_rounded,
        );
      case 'COMPLETED':
        return _StatusInfo(
          label: 'Hoàn thành',
          color: Colors.green.shade700,
          icon: Icons.check_circle_rounded,
        );
      case 'CANCELLED':
        return _StatusInfo(
          label: 'Đã hủy',
          color: Colors.red.shade700,
          icon: Icons.cancel_rounded,
        );
      default:
        return _StatusInfo(
          label: status,
          color: Colors.grey.shade700,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _getPaymentLabel(String method) {
    switch (method) {
      case 'COD':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      default:
        return method;
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ══════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCopyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (isCopyable)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép "$value"'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;

  const _PaymentRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${CurrencyFormatter.format(amount.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
