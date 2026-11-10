import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/compare_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/compare_bottom_bar.dart';
import '../../widgets/home_carousel_banner.dart';
import '../../widgets/lucky_wheel_logo.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      productProvider.loadCategories();
      productProvider.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dialog xác nhận xóa sản phẩm dành riêng cho Admin
  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 28),
            SizedBox(width: 10),
            Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn sản phẩm "${product.name}" khỏi hệ thống?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<ProductProvider>().deleteProduct(product.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          success ? 'Đã xóa sản phẩm thành công' : 'Xóa sản phẩm thất bại',
                        ),
                      ],
                    ),
                    backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final productProvider = context.watch<ProductProvider>();

    final categories = productProvider.categories;
    final products = productProvider.products;
    final isLoading = productProvider.isLoading;
    final selectedCatId = productProvider.selectedCategoryId;

    final crossAxisCount = Responsive.gridCrossAxisCount(context);
    final childAspectRatio = Responsive.gridChildAspectRatio(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryOrange, size: 22),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                children: [
                  TextSpan(text: 'PRM', style: TextStyle(color: AppColors.textPrimary)),
                  TextSpan(text: ' Shop', style: TextStyle(color: AppColors.primaryOrange)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Lối tắt trang Quản trị (Admin / Employee)
          if (auth.canManageOrders)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: auth.isAdmin ? 'Admin Dashboard' : 'Quản lý đơn hàng',
              onPressed: () => context.push(auth.isAdmin ? '/admin' : '/admin/orders'),
            ),

          // Lịch sử đơn hàng (Chỉ dành cho Khách hàng)
          if (!auth.canManageOrders)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Đơn hàng của tôi',
              onPressed: () => context.push('/orders'),
            ),

          // Thông báo kèm Badge số lượng chưa đọc
          IconButton(
            icon: Badge.count(
              count: notifProvider.unreadCount,
              isLabelVisible: notifProvider.unreadCount > 0,
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Thông báo',
            onPressed: () => context.push('/notifications'),
          // So sánh đối đầu thông số kỹ thuật (Smart Specs)
          Consumer<CompareProvider>(
            builder: (_, compare, _) => IconButton(
              icon: Badge.count(
                count: compare.count,
                isLabelVisible: compare.count > 0,
                backgroundColor: AppColors.primaryOrange,
                child: const Icon(Icons.compare_arrows_rounded),
              ),
              tooltip: 'So sánh đối đầu',
              onPressed: () => context.push('/compare'),
          // Vòng quay may mắn (Lucky Wheel) - Logo vòng quay chuẩn thiết kế theo hình mẫu
          IconButton(
            tooltip: 'Vòng quay may mắn',
            onPressed: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để tham gia Vòng quay may mắn!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.push('/login');
              } else {
                context.push('/lucky-wheel');
              }
            },
            icon: const LuckyWheelLogo(
              size: 26,
              strokeColor: AppColors.textPrimary,
              fillColor: Colors.white,
            ),
          ),

          // Giỏ hàng kèm Badge số lượng
          IconButton(
            icon: Badge.count(
              count: cart.totalCount,
              isLabelVisible: cart.totalCount > 0,
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            tooltip: 'Giỏ hàng',
            onPressed: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để xem giỏ hàng!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.push('/login');
              } else {
                context.push('/cart');
              }
            },
          ),

          // Hồ sơ người dùng
          IconButton(
            icon: Icon(auth.isLoggedIn ? Icons.account_circle_outlined : Icons.login_rounded),
            tooltip: auth.isLoggedIn ? 'Tài khoản' : 'Đăng nhập',
            onPressed: () => context.push(auth.isLoggedIn ? '/profile' : '/login'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const CompareBottomBar(),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async {
          await productProvider.loadCategories();
          await productProvider.loadProducts();
        },
        child: ResponsiveContainer(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Thanh tìm kiếm (Search Bar M3 Style ở trên cùng)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm điện thoại, laptop, phụ kiện chính hãng...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryOrange, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {});
                        productProvider.setSearchQuery(val);
                      },
                    ),
                  ),
                ),
              ),

              // 2. Banner quản trị (chỉ hiện khi user là Admin/Employee)
              if (auth.canManageOrders)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildAdminBanner(context, auth),
                  ),
                ),

              // 3. Carousel Slider Khuyến Mãi (Chuẩn CellphoneS như ảnh mẫu)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: HomeCarouselBanner(),
                ),
              ),

              // 3.1 Banner Vòng Quay May Mắn (Đồng bộ UI & Màu thương hiệu dự án)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: GestureDetector(
                    onTap: () {
                      if (!auth.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng đăng nhập để tham gia Vòng quay may mắn!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.push('/login');
                      } else {
                        context.push('/lucky-wheel');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryOrange, Color(0xFFFB923C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Logo vòng quay chuẩn thiết kế theo hình mẫu
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: LuckyWheelLogo(
                                size: 36,
                                strokeColor: Color(0xFF1E1E1E),
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'VÒNG QUAY MAY MẮN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Điểm danh & quay thưởng rinh voucher tới 100k!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Quay ngay',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: AppColors.primaryOrange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Thanh lọc Danh mục sản phẩm (Horizontal List)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      // Chip "Tất cả"
                      _buildCategoryChip(
                        label: 'Tất cả',
                        icon: Icons.apps_rounded,
                        isSelected: selectedCatId == null,
                        onTap: () => productProvider.selectCategory(null),
                      ),
                      // Các danh mục động từ Database
                      ...categories.map(
                        (cat) => _buildCategoryChip(
                          label: cat.name,
                          icon: cat.icon == 'phone_android'
                              ? Icons.phone_android_rounded
                              : cat.icon == 'laptop'
                                  ? Icons.laptop_mac_rounded
                                  : Icons.headphones_rounded,
                          isSelected: selectedCatId == cat.id,
                          onTap: () => productProvider.selectCategory(cat.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Tiêu đề danh sách sản phẩm
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sản phẩm (${products.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (auth.isAdmin)
                        FilledButton.tonalIcon(
                          onPressed: () => ProductFormDialog.show(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orangeLight,
                            foregroundColor: AppColors.primaryOrange,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm mới SP', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Grid sản phẩm hoặc Trạng thái rỗng / Loading
              if (isLoading)
                const SliverToBoxAdapter(
                  child: ProductSkeletonGrid(itemCount: 6),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.orangeLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Không tìm thấy sản phẩm nào!',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Vui lòng thử tìm từ khóa khác hoặc đặt lại bộ lọc',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setSearchQuery('');
                              productProvider.selectCategory(null);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Đặt lại bộ lọc'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildProductCard(context, product, auth.isAdmin, cart);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // FAB thêm nhanh sản phẩm cho Admin
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => ProductFormDialog.show(context),
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm SP', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // Chip danh mục thiết kế sáng và tươi mới
  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orangeLight : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryOrange : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Banner hiển thị cho Admin / Employee (Xanh biển nhạt & Trắng)
  Widget _buildAdminBanner(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280284C7),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  auth.isAdmin ? Icons.admin_panel_settings_rounded : Icons.badge_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  auth.isAdmin ? 'Phân Hệ Quản Trị Viên (Admin)' : 'Phân Hệ Nhân Viên',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý hệ thống sản phẩm, theo dõi đơn hàng và cập nhật trạng thái kho tức thì.',
            style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (auth.isAdmin)
                FilledButton.tonal(
                  onPressed: () => context.push('/admin'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.secondaryBlue,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Bảng Điều Khiển Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              FilledButton.tonal(
                onPressed: () => context.push('/admin/orders'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: AppColors.secondaryBlue,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Quản Lý Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Thẻ hiển thị sản phẩm tinh tế, sáng sủa
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    bool isAdmin,
    CartProvider cart,
  ) {
    final isOut = product.isOutOfStock;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hình ảnh sản phẩm kèm Hero Animation
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-img-${product.id}',
                    child: Container(
                      color: AppColors.borderSoft,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.borderSoft,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 36,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.devices_rounded, size: 40, color: AppColors.textMuted),
                            ),
                    ),
                  ),

                  // Nhãn trạng thái tồn kho ở góc trên bên trái
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isOut
                            ? AppColors.errorRed.withValues(alpha: 0.95)
                            : AppColors.successGreen.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOut ? 'Hết hàng' : 'Còn ${product.stockQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Nút So sánh nhanh ở góc trên bên phải
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<CompareProvider>(
                      builder: (_, compare, _) {
                        final isComparing = compare.isInCompare(product.id ?? 0);
                        return Tooltip(
                          message: isComparing ? 'Đã thêm so sánh (Bấm để gỡ)' : 'So sánh đối đầu sản phẩm',
                          child: InkWell(
                            onTap: () async {
                              if (isComparing) {
                                compare.removeProduct(product.id!);
                              } else {
                                final ok = await compare.addProduct(product);
                                if (!ok && compare.errorMessage != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(compare.errorMessage!),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isComparing
                                    ? AppColors.primaryOrange
                                    : Colors.white.withValues(alpha: 0.88),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.compare_arrows_rounded,
                                size: 16,
                                color: isComparing ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Chi tiết và Thao tác
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),

                    // Thao tác Admin (Sửa/Xóa) hoặc Khách hàng (Thêm giỏ)
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.borderSoft)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppColors.secondaryBlue,
                                  side: const BorderSide(color: AppColors.secondaryBlue, width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  ProductFormDialog.show(context, product: product);
                                },
                                icon: const Icon(Icons.edit_rounded, size: 14),
                                label: const Text('Sửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorRed),
                              tooltip: 'Xóa sản phẩm',
                              onPressed: () => _confirmDelete(context, product),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: isOut ? AppColors.borderLight : AppColors.primaryOrange,
                            foregroundColor: isOut ? AppColors.textMuted : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isOut || product.id == null
                              ? null
                              : () async {
                                  final auth = context.read<AuthProvider>();
                                  if (!auth.isLoggedIn) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    context.push('/login');
                                    return;
                                  }

                                  final success = await cart.addToCart(productId: product.id!);
                                  if (!context.mounted) return;

                                  if (success) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã thêm "${product.name}" vào giỏ!'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.textPrimary,
                                        action: SnackBarAction(
                                          label: 'Xem giỏ',
                                          textColor: AppColors.primaryOrange,
                                          onPressed: () => context.push('/cart'),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else if (cart.errorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(cart.errorMessage!),
                                        backgroundColor: AppColors.errorRed,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                          label: Text(
                            isOut ? 'Hết hàng' : 'Thêm giỏ',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
