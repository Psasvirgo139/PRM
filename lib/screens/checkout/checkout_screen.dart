import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

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

  String _selectedPaymentMethod = 'COD'; // 'COD', 'BANKING', 'MOMO'
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
    } else {
      final userId = currentUser?.id ?? 2; // ID 2 là tài khoản customer mặc định trong seed
      orderProvider.loadCheckoutItems(userId);
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

    final userId = auth.currentUser?.id ?? 2;
    final subtotal = orderProvider.subtotal;
    final shippingFee = _calculateShippingFee(subtotal);

    // Xác nhận đặt hàng
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Xác nhận đặt hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hệ thống sẽ kiểm tra tồn kho và tạo đơn hàng cho ${orderProvider.checkoutItems.length} sản phẩm.'),
            const SizedBox(height: 10),
            Text(
              'Tổng tiền: ${CurrencyFormatter.format(subtotal + shippingFee)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Xem lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý đặt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // THỰC THI TRANSACTION ĐẶT HÀNG
    final createdOrder = await orderProvider.placeOrder(
      userId: userId,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      note: _noteController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      shippingFee: shippingFee,
      discount: 0.0,
    );

    if (!mounted) return;

    if (createdOrder != null) {
      // Đặt hàng thành công -> Chuyển sang Màn hình thành công
      context.go('/order-success', extra: createdOrder);
    } else {
      // Báo lỗi (ví dụ: Không đủ tồn kho hoặc lỗi transaction)
      final errorMsg = orderProvider.errorMessage ?? 'Không thể hoàn tất đơn hàng!';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Đặt hàng thất bại', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final items = orderProvider.checkoutItems;
    final subtotal = orderProvider.subtotal;
    final shippingFee = _calculateShippingFee(subtotal);
    final finalAmount = subtotal + shippingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Thanh Toán Đơn Hàng'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: orderProvider.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text('Đang kiểm tra tồn kho & thực hiện thanh toán...'),
                ],
              ),
            )
          : items.isEmpty
              ? _buildEmptyCheckout(context, auth.currentUser?.id ?? 2)
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

                        // Chi tiết bảng tính tiền
                        _buildPriceSummary(subtotal, shippingFee, finalAmount),
                        const SizedBox(height: 90), // chừa khoảng trống cho bottom bar
                      ],
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem(icon: Icons.shopping_cart, title: '1. Giỏ hàng', isDone: true),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
          _buildStepItem(icon: Icons.payment, title: '2. Thanh toán', isActive: true),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
          _buildStepItem(icon: Icons.check_circle_outline, title: '3. Hoàn tất', isPending: true),
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
    if (isActive) color = Colors.deepPurple;

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
            color: Colors.black.withOpacity(0.04),
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
              const Icon(Icons.location_on_outlined, color: Colors.deepPurple, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Đã tự động điền',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),

          // Họ tên
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên người nhận *',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 12),

          // Số điện thoại
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại liên hệ *',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
              if (val.trim().length < 9) return 'Số điện thoại không hợp lệ';
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập địa chỉ nhận hàng' : null,
          ),
          const SizedBox(height: 12),

          // Ghi chú đơn hàng
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Ghi chú cho shipper (tuỳ chọn)',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            color: Colors.black.withOpacity(0.04),
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
              Icon(Icons.payment, color: Colors.deepPurple, size: 22),
              SizedBox(width: 8),
              Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildPaymentOption(
            value: 'COD',
            title: 'Thanh toán tiền mặt khi nhận hàng (COD)',
            subtitle: 'Thanh toán cho nhân viên giao hàng khi nhận sản phẩm',
            icon: Icons.money,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'BANKING',
            title: 'Chuyển khoản ngân hàng (QR Pay)',
            subtitle: 'Quét mã VietQR chuyển khoản nhanh 24/7',
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
          color: isSelected ? Colors.deepPurple.shade50.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: Colors.deepPurple,
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
            color: Colors.black.withOpacity(0.04),
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
                  Icon(Icons.inventory_2_outlined, color: Colors.deepPurple, size: 22),
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
            separatorBuilder: (_, __) => const Divider(height: 16),
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
                    child: const Icon(Icons.devices, color: Colors.deepPurple, size: 28),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(item.productPrice),
                              style: const TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '  ×  ${item.quantity}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildPriceSummary(double subtotal, double shippingFee, double finalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              const Text('Tạm tính tiền hàng', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(CurrencyFormatter.format(subtotal), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phí vận chuyển', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                shippingFee == 0 ? 'Miễn phí' : CurrencyFormatter.format(shippingFee),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: shippingFee == 0 ? Colors.green : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giảm giá', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('0 ₫', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                  color: Colors.deepPurple,
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
            const Icon(Icons.remove_shopping_cart_outlined, size: 70, color: Colors.grey),
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
                      content: Text('Đã nạp 2 sản phẩm mẫu vào giỏ hàng để test!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Nạp giỏ hàng mẫu để test'),
              style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
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
            color: Colors.black.withOpacity(0.08),
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
                      color: Colors.deepPurple,
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
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
