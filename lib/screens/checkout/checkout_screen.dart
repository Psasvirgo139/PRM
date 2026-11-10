import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/lucky_wheel_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payos_service.dart';
import '../../providers/quest_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../widgets/lucky_wheel_logo.dart';
import '../voucher/widgets/voucher_card.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? initialItems;

  const CheckoutScreen({super.key, this.initialItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedPaymentMethod = 'PAYOS'; // 'PAYOS', 'COD', 'BANKING', 'MOMO'
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      _initializeData();
    }
  }

  void _initializeData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // 1. Tự động điền (Auto-fill) thông tin người nhận từ tài khoản đăng nhập
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.fullName;
      _phoneController.text = currentUser.phone;
      _addressController.text = currentUser.address;
    } else {
      // Dữ liệu mặc định nếu chưa đăng nhập (để tiện test ngay)
      _nameController.text = 'Nguyễn Văn A (Khách hàng)';
      _phoneController.text = '0987654321';
      _addressController.text = 'Số 123 Cầu Giấy, Dịch Vọng Hậu, Hà Nội';
    }

    // 2. Nạp danh sách sản phẩm cần thanh toán
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      orderProvider.setCheckoutItems(widget.initialItems!);
    } else if (currentUser?.id != null) {
      orderProvider.loadCheckoutItems(currentUser!.id!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _calculateShippingFee(double subtotal) {
    if (subtotal == 0) return 0.0;
    // Miễn phí vận chuyển cho đơn hàng từ 5 triệu trở lên
    if (subtotal >= 5000000) return 0.0;
    return 30000.0;
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin nhận hàng!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final router = GoRouter.of(context);

    // Kiểm tra đăng nhập bắt buộc đối với Khách hàng
    if (!auth.isLoggedIn || auth.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập tài khoản Khách hàng để hoàn tất đặt hàng!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/login');
      return;
    }

    if (auth.canManageOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản Quản trị / Nhân viên không thể đặt hàng. Vui lòng đăng nhập tài khoản Khách hàng!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userId = auth.currentUser!.id!;
    final subtotal = orderProvider.subtotal;
    final shippingFee = _calculateShippingFee(subtotal);

    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final questProvider = Provider.of<QuestProvider>(context, listen: false);
    final luckyWheelProvider = Provider.of<LuckyWheelProvider>(context, listen: false);

    final discount = voucherProvider.calculateCurrentDiscount(subtotal, shippingFee: shippingFee);
    final finalAmount = (subtotal - discount + shippingFee).clamp(0.0, double.infinity);

    // Xác nhận đặt hàng
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text('Xác nhận đặt hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hệ thống sẽ kiểm tra tồn kho và tạo đơn hàng cho ${orderProvider.checkoutItems.length} sản phẩm.',
            ),
            const SizedBox(height: 10),
            if (discount > 0) ...[
              Text(
                'Giảm giá voucher: -${CurrencyFormatter.format(discount)}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Tổng thanh toán: ${CurrencyFormatter.format(finalAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Xem lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý đặt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // THỰC THI TRANSACTION ĐẶT HÀNG
    final createdOrder = await orderProvider.placeOrder(
      userId: userId,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      note: _noteController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      shippingFee: shippingFee,
      discount: discount,
    );

    if (!mounted) return;

    if (createdOrder != null) {
      // 1. Tiêu thụ Voucher đã dùng (nếu có)
      await voucherProvider.consumeSelectedVoucher();

      // 2. Tự động thưởng nhiệm vụ mua hàng (+1 lượt quay, tối đa 2 lượt/ngày)
      final rewardedSpin = await questProvider.rewardOrderCompleted();
      if (rewardedSpin) {
        await luckyWheelProvider.loadSpins();
      }

      // 3. Làm mới giỏ hàng trong CartProvider sau khi transaction thành công
      cart.loadCart();

      if (!mounted) return;

      if (_selectedPaymentMethod == 'PAYOS') {
        // Hiển thị dialog đang khởi tạo thanh toán payOS
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
            amount: createdOrder.finalAmount.round(),
            description: 'DH${createdOrder.id ?? payosOrderCode}',
            items: createdOrder.items.map((i) => {
              'name': i.productName,
              'quantity': i.quantity,
              'price': i.productPrice.round(),
            }).toList(),
          );

          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop(); // đóng loading dialog

          // Chuyển sang màn hình thanh toán PayOS
          router.push(
            '/payos-payment',
            extra: {
              'order': createdOrder,
              'payosData': payosData,
            },
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop(); // đóng loading dialog

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Thông báo thanh toán'),
                ],
              ),
              content: Text(
                'Đơn hàng "${createdOrder.orderCode}" đã được tạo thành công.\nTuy nhiên việc khởi tạo cổng payOS gặp sự cố: ${e.toString().replaceAll('Exception: ', '')}\n\nBạn có thể vào mục "Lịch sử đơn hàng" để tiếp tục thanh toán sau.',
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    router.go('/order-success', extra: createdOrder);
                  },
                  child: const Text('Xem đơn hàng'),
                ),
              ],
            ),
          );
        }
      } else {
        // Đặt hàng thành công -> Chuyển sang Màn hình thành công
        router.go('/order-success', extra: createdOrder);

        // Hiển thị thông báo thưởng lượt quay nếu đạt điều kiện
        if (rewardedSpin && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Chúc mừng bạn nhận được +1 Lượt Quay May Mắn từ đơn hàng này!'),
              backgroundColor: Colors.purple,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      // Báo lỗi (ví dụ: Không đủ tồn kho hoặc lỗi transaction)
      final errorMsg = orderProvider.errorMessage ?? 'Không thể hoàn tất đơn hàng!';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text(
            'Đặt hàng thất bại',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final voucherProvider = context.watch<VoucherProvider>();

    final items = orderProvider.checkoutItems;
    final subtotal = orderProvider.subtotal;
    final shippingFee = _calculateShippingFee(subtotal);
    final discount = voucherProvider.calculateCurrentDiscount(subtotal, shippingFee: shippingFee);
    final finalAmount = (subtotal - discount + shippingFee).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Thanh Toán Đơn Hàng'),
        centerTitle: true,
      ),
      body: orderProvider.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryOrange),
                  SizedBox(height: 16),
                  Text('Đang kiểm tra tồn kho & thực hiện thanh toán...'),
                ],
              ),
            )
          : items.isEmpty
              ? _buildEmptyCheckout(context, auth.currentUser?.id ?? 3)
              : ResponsiveContainer(
                  maxWidth: 800,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thanh trạng thái các bước
                          _buildStepProgress(),
                          const SizedBox(height: 16),

                        // Form Thông tin người nhận
                        _buildDeliveryAddressSection(auth.isLoggedIn),
                        const SizedBox(height: 16),

                        // Chọn phương thức thanh toán
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 16),

                        // Danh sách mặt hàng thanh toán
                        _buildCartItemsReview(items),
                        const SizedBox(height: 16),

                        // Chọn Voucher Giảm Giá (Vòng quay may mắn / Kho Voucher)
                        _buildVoucherSelectionSection(voucherProvider, subtotal, shippingFee),
                        const SizedBox(height: 16),

                        // Chi tiết bảng tính tiền
                        _buildPriceSummary(subtotal, shippingFee, discount, finalAmount),
                        const SizedBox(height: 90), // chừa khoảng trống cho bottom bar
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildBottomCheckoutBar(finalAmount, orderProvider.isLoading),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem(
            icon: Icons.shopping_cart,
            title: '1. Giỏ hàng',
            isDone: true,
          ),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
          _buildStepItem(
            icon: Icons.payment,
            title: '2. Thanh toán',
            isActive: true,
          ),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
          _buildStepItem(
            icon: Icons.check_circle_outline,
            title: '3. Hoàn tất',
            isPending: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    bool isDone = false,
    bool isActive = false,
    bool isPending = false,
  }) {
    Color color = Colors.grey;
    if (isDone) color = Colors.green;
    if (isActive) color = AppColors.primaryOrange;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryOrange,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Đã tự động điền',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn chưa đăng nhập. Vui lòng đăng nhập để đơn hàng được lưu vào lịch sử cá nhân của bạn.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 24),

          // Họ tên
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên người nhận *',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Vui lòng nhập họ tên'
                : null,
          ),
          const SizedBox(height: 12),

          // Số điện thoại
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại liên hệ *',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              if (val.trim().length < 9) {
                return 'Số điện thoại không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Địa chỉ chi tiết
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Địa chỉ giao hàng (Số nhà, đường, phường/xã...) *',
              prefixIcon: const Icon(Icons.home_outlined, size: 20),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Vui lòng nhập địa chỉ nhận hàng'
                : null,
          ),
          const SizedBox(height: 12),

          // Ghi chú đơn hàng
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Ghi chú cho shipper (tuỳ chọn)',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: AppColors.primaryOrange, size: 22),
              SizedBox(width: 8),
              Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildPaymentOption(
            value: 'PAYOS',
            title: 'Cổng thanh toán payOS (VietQR 24/7)',
            subtitle: 'Quét mã VietQR tự động xác nhận sau 3 giây (Khuyên dùng)',
            icon: Icons.qr_code_2_rounded,
            badge: 'Tự động duyệt',
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'COD',
            title: 'Thanh toán tiền mặt khi nhận hàng (COD)',
            subtitle: 'Thanh toán cho nhân viên giao hàng khi nhận sản phẩm',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'BANKING',
            title: 'Chuyển khoản ngân hàng thủ công',
            subtitle: 'Chuyển khoản qua số tài khoản cá nhân',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'MOMO',
            title: 'Ví điện tử MoMo',
            subtitle: 'Liên kết thanh toán một chạm nhanh chóng',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orangeLight.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryOrange : Colors.grey.shade700,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? AppColors.primaryOrange : Colors.black87,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300, width: 0.8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // ignore: deprecated_member_use
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedPaymentMethod,
              activeColor: AppColors.primaryOrange,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsReview(List<CartItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryOrange,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kiểm tra đơn hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${items.length} món',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              final isStockLow = item.availableStock < 5;
              final isOutOfStock = item.availableStock <= 0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.devices,
                      color: AppColors.primaryOrange,
                      size: 28,
                    ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(item.productPrice),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '  ×  ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? Colors.red.shade50
                                    : isStockLow
                                        ? Colors.orange.shade50
                                        : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOutOfStock
                                    ? 'Hết hàng'
                                    : 'Kho: ${item.availableStock}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock
                                      ? Colors.red
                                      : isStockLow
                                          ? Colors.orange.shade900
                                          : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
        ],
      ),
    );
  }

  Widget _buildVoucherSelectionSection(
    VoucherProvider voucherProvider,
    double subtotal,
    double shippingFee,
  ) {
    final selectedUserVoucher = voucherProvider.selectedVoucherForCheckout;
    final voucher = selectedUserVoucher?.voucher;
    final discount = voucherProvider.calculateCurrentDiscount(subtotal, shippingFee: shippingFee);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedUserVoucher != null ? Colors.deepPurple.shade300 : Colors.grey.shade200,
          width: selectedUserVoucher != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Voucher Giảm Giá',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openVoucherPickerBottomSheet(voucherProvider, subtotal),
                icon: const Icon(Icons.style_outlined, size: 16),
                label: Text(
                  selectedUserVoucher != null ? 'Đổi mã' : 'Chọn Voucher',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (selectedUserVoucher != null && voucher != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              voucher.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              voucher.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tiết kiệm: -${CurrencyFormatter.format(discount)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                  tooltip: 'Bỏ chọn mã này',
                  onPressed: () => voucherProvider.selectVoucherForCheckout(null),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Chọn voucher từ kho để được giảm giá hoặc miễn phí vận chuyển.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _openVoucherPickerBottomSheet(VoucherProvider voucherProvider, double subtotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final available = voucherProvider.availableVouchers;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kho Voucher Khả Dụng',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push('/lucky-wheel');
                        },
                        icon: const LuckyWheelLogo(size: 18, strokeColor: AppColors.primaryOrange, fillColor: Colors.white),
                        label: const Text('Quay thêm', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: available.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Bạn chưa có voucher nào trong kho!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Chơi Vòng Quay May Mắn để nhận ngay nhiều voucher giảm giá.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    context.push('/lucky-wheel');
                                  },
                                  child: const Text('Đi đến Vòng Quay'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: available.length,
                            itemBuilder: (context, index) {
                              final uv = available[index];
                              final v = uv.voucher;
                              final isSelected =
                                  voucherProvider.selectedVoucherForCheckout?.id == uv.id;
                              final isEligible = v == null || subtotal >= v.minOrderValue;

                              return Opacity(
                                opacity: isEligible ? 1.0 : 0.5,
                                child: Column(
                                  children: [
                                    VoucherCard(
                                      userVoucher: uv,
                                      isSelectable: isEligible,
                                      isSelected: isSelected,
                                      onSelect: () {
                                        voucherProvider.selectVoucherForCheckout(uv);
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                    if (!isEligible)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          'Chưa đủ điều kiện: Cần đơn hàng từ ${CurrencyFormatter.format(v.minOrderValue)}',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceSummary(
    double subtotal,
    double shippingFee,
    double discount,
    double finalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính tiền hàng',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                CurrencyFormatter.format(subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phí vận chuyển',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                shippingFee == 0
                    ? 'Miễn phí'
                    : CurrencyFormatter.format(shippingFee),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: shippingFee == 0 ? Colors.green : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giảm giá Voucher',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                discount > 0 ? '- ${CurrencyFormatter.format(discount)}' : '0 ₫',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: discount > 0 ? Colors.green : Colors.black87,
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.format(finalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCheckout(BuildContext context, int userId) {
    final orderProvider = context.read<OrderProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có sản phẩm nào trong giỏ hàng để thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn sản phẩm vào giỏ hàng hoặc nạp dữ liệu mẫu để test tính năng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await orderProvider.seedSampleCart(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã nạp 2 sản phẩm mẫu vào giỏ hàng để test!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Nạp giỏ hàng mẫu để test'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
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

  Widget _buildBottomCheckoutBar(double finalAmount, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng tiền thanh toán',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    CurrencyFormatter.format(finalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _handlePlaceOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Đặt hàng ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
