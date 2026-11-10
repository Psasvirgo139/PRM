import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../models/payos_payment_data.dart';
import '../../providers/order_provider.dart';
import '../../services/payos_service.dart';

class PayOSPaymentScreen extends StatefulWidget {
  final Order order;
  final PayOSPaymentData payosData;

  const PayOSPaymentScreen({
    super.key,
    required this.order,
    required this.payosData,
  });

  @override
  State<PayOSPaymentScreen> createState() => _PayOSPaymentScreenState();
}

class _PayOSPaymentScreenState extends State<PayOSPaymentScreen> {
  final PayOSService _payosService = PayOSService();

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 900; // 15 phút đếm ngược
  bool _isChecking = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startPolling() {
    // Tự động kiểm tra trạng thái thanh toán mỗi 4 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!_isChecking && !_isSuccess) {
        await _checkPaymentStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isSuccess) return;

    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final status = await _payosService.getPaymentInformation(widget.payosData.orderCode);

      if (!mounted) return;

      if (status.isPaid) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() {
          _isSuccess = true;
          _isChecking = false;
        });

        // Cập nhật trạng thái đơn hàng trong DB thành PROCESSING
        if (widget.order.id != null) {
          await Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(
            widget.order.id!,
            'PROCESSING',
            userId: widget.order.userId,
          );
        }

        if (!mounted) return;

        // Hiển thị thông báo thành công và chuyển trang
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thanh Toán Thành Công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'payOS đã xác nhận giao dịch thành công cho đơn hàng #${widget.order.orderCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/order-success', extra: widget.order);
                  },
                  child: const Text('Xem đơn hàng'),
                ),
              ],
            ),
          ),
        );
      } else {
        if (!silent) {
          setState(() => _isChecking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hệ thống chưa nhận được thanh toán. Vui lòng thử lại sau giây lát!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kiểm tra thất bại: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPayOSCheckoutUrl() async {
    final uri = Uri.parse(widget.payosData.checkoutUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở trình duyệt';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở liên kết: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời trang thanh toán?'),
        content: const Text(
          'Đơn hàng của bạn đã được ghi nhận ở trạng thái Chờ thanh toán. Bạn có thể thanh toán sau trong mục Đơn hàng của tôi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại thanh toán'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/orders');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.primaryOrange),
              SizedBox(width: 8),
              Text('Cổng Thanh Toán payOS'),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Kiểm tra trạng thái',
              onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
            ),
          ],
        ),
        body: ResponsiveContainer(
          maxWidth: 650,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Header Đếm ngược thời gian thanh toán
                _buildCountdownBanner(),
                const SizedBox(height: 16),

                // Thẻ mã QR VietQR
                _buildQrCard(),
                const SizedBox(height: 16),

                // Nút hành động nhanh: Mở trang web payOS & Kiểm tra
                _buildActionButtons(),
                const SizedBox(height: 16),

                // Bảng thông tin chuyển khoản chi tiết
                _buildBankTransferDetailsCard(),
                const SizedBox(height: 20),

                // Nút hoàn tất / để sau
                _buildFooterButtons(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBanner() {
    final isLowTime = _remainingSeconds < 180;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowTime ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: isLowTime ? Colors.red : Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thời gian thanh toán còn lại:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLowTime ? Colors.red.shade900 : Colors.blue.shade900,
                ),
              ),
            ],
          ),
          Text(
            _formatCountdown(_remainingSeconds),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isLowTime ? Colors.red.shade900 : Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & Tiêu đề QR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'payOS VietQR',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tự động duyệt 24/7',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Khung hiển thị QR code bằng qr_flutter
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.payosData.qrCode.isNotEmpty
                ? QrImageView(
                    data: widget.payosData.qrCode,
                    version: QrVersions.auto,
                    size: 230.0,
                    gapless: false,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  )
                : const SizedBox(
                    width: 230,
                    height: 230,
                    child: Center(
                      child: Text('Không có dữ liệu VietQR'),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          Text(
            'Quét mã qua bất kỳ App Ngân hàng hoặc Ví điện tử',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),

          // Tổng tiền nổi bật
          Text(
            CurrencyFormatter.format(widget.payosData.amount.toDouble()),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Nút mở trang web PayOS
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primaryOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.open_in_browser, color: AppColors.primaryOrange, size: 20),
            label: const Text(
              'Mở cổng payOS',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
            ),
            onPressed: _openPayOSCheckoutUrl,
          ),
        ),
        const SizedBox(width: 12),

        // Nút kiểm tra thanh toán ngay
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              _isChecking ? 'Đang kiểm tra...' : 'Kiểm tra ngay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(Icons.account_balance, color: AppColors.primaryOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Thông tin chuyển khoản',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),

          // Ngân hàng
          _buildInfoRow(
            label: 'Ngân hàng',
            value: widget.payosData.bankName,
            isHighlight: false,
          ),
          const Divider(height: 16),

          // Chủ tài khoản
          _buildInfoRow(
            label: 'Chủ tài khoản',
            value: widget.payosData.accountName,
            isHighlight: false,
          ),
          const Divider(height: 16),

          // Số tài khoản
          _buildInfoRow(
            label: 'Số tài khoản',
            value: widget.payosData.accountNumber,
            isHighlight: true,
            onCopy: () => _copyToClipboard(widget.payosData.accountNumber, 'Số tài khoản'),
          ),
          const Divider(height: 16),

          // Số tiền
          _buildInfoRow(
            label: 'Số tiền',
            value: CurrencyFormatter.format(widget.payosData.amount.toDouble()),
            isHighlight: true,
            onCopy: () => _copyToClipboard(widget.payosData.amount.toString(), 'Số tiền'),
          ),
          const Divider(height: 16),

          // Nội dung chuyển khoản
          _buildInfoRow(
            label: 'Nội dung chuyển khoản',
            value: widget.payosData.description,
            isHighlight: true,
            onCopy: () => _copyToClipboard(widget.payosData.description, 'Nội dung'),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu ý: Vui lòng nhập chính xác Nội dung chuyển khoản để hệ thống tự động xác nhận đơn hàng của bạn.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isHighlight = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? AppColors.primaryOrange : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.copy, size: 14, color: AppColors.primaryOrange),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              context.go('/orders');
            }
          },
          child: Text(
            'Thanh toán sau (Lưu đơn vào lịch sử)',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

