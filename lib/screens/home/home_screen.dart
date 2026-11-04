import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_form_dialog.dart';

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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" khỏi hệ thống?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<ProductProvider>().deleteProduct(product.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã xóa sản phẩm thành công'
                          : 'Xóa sản phẩm thất bại',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();

    final categories = productProvider.categories;
    final products = productProvider.products;
    final isLoading = productProvider.isLoading;
    final selectedCatId = productProvider.selectedCategoryId;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'PRM393 E-Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Lối tắt trang Quản trị (Admin / Employee)
          if (auth.canManageOrders)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: auth.isAdmin ? 'Admin Dashboard' : 'Quản lý đơn hàng',
              onPressed: () => context.push(auth.isAdmin ? '/admin' : '/admin/orders'),
            ),

          // Lịch sử đơn hàng
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Đơn hàng của tôi',
            onPressed: () => context.push('/orders'),
          ),

          // Giỏ hàng kèm Badge số lượng
          IconButton(
            icon: Badge.count(
              count: cart.totalCount,
              isLabelVisible: cart.totalCount > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push('/cart'),
          ),

          // Hồ sơ người dùng
          IconButton(
            icon: Icon(auth.isLoggedIn ? Icons.account_circle : Icons.login),
            tooltip: auth.isLoggedIn ? 'Tài khoản' : 'Đăng nhập',
            onPressed: () => context.push(auth.isLoggedIn ? '/profile' : '/login'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.loadCategories();
          await productProvider.loadProducts();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Banner chào mừng / Phân hệ Quản trị Admin
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: auth.canManageOrders
                    ? _buildAdminBanner(context, auth)
                    : _buildCustomerBanner(auth),
              ),
            ),

            // 2. Thanh tìm kiếm (Search Bar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm điện thoại, laptop, phụ kiện...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    productProvider.setSearchQuery(val);
                  },
                ),
              ),
            ),

            // 3. Thanh lọc Danh mục sản phẩm (Categories Horizontal List)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // Chip "Tất cả"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: selectedCatId == null,
                        label: const Text('Tất cả'),
                        avatar: const Icon(Icons.apps_rounded, size: 18),
                        onSelected: (_) {
                          productProvider.selectCategory(null);
                        },
                      ),
                    ),
                    // Các danh mục từ SQLite Database
                    ...categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: selectedCatId == cat.id,
                          label: Text(cat.name),
                          avatar: Icon(
                            cat.icon == 'phone_android'
                                ? Icons.phone_android
                                : cat.icon == 'laptop'
                                    ? Icons.laptop
                                    : Icons.headphones,
                            size: 18,
                          ),
                          onSelected: (_) {
                            productProvider.selectCategory(cat.id);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Tiêu đề danh sách sản phẩm
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sản phẩm (${products.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (auth.isAdmin)
                      TextButton.icon(
                        onPressed: () => ProductFormDialog.show(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm mới'),
                      ),
                  ],
                ),
              ),
            ),

            // 5. Grid hiển thị sản phẩm
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Không tìm thấy sản phẩm nào!',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          productProvider.setSearchQuery('');
                          productProvider.selectCategory(null);
                        },
                        child: const Text('Đặt lại bộ lọc'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
      // Floating Action Button cho Admin thêm nhanh sản phẩm
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => ProductFormDialog.show(context),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Thêm SP'),
            )
          : null,
    );
  }

  // Banner hiển thị cho Admin / Employee
  Widget _buildAdminBanner(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: auth.isAdmin
              ? [Colors.deepPurple.shade700, Colors.deepPurple.shade500]
              : [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (auth.isAdmin ? Colors.deepPurple : Colors.teal).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                auth.isAdmin ? Icons.admin_panel_settings : Icons.badge,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auth.isAdmin
                      ? 'Phân Hệ Quản Trị (Admin)'
                      : 'Phân Hệ Nhân Viên (Employee)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            auth.isAdmin
                ? 'Thống kê doanh thu, cảnh báo hết hàng, quản lý đơn hàng & sản phẩm.'
                : 'Tiếp nhận, xử lý và cập nhật trạng thái đơn hàng của khách hàng.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                    foregroundColor: Colors.deepPurple,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Admin Dashboard'),
                ),
              FilledButton.tonal(
                onPressed: () => context.push('/admin/orders'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: auth.isAdmin ? Colors.deepPurple : Colors.teal,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Quản lý Đơn hàng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Banner chào mừng cho khách hàng
  Widget _buildCustomerBanner(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isLoggedIn
                      ? 'Xin chào, ${auth.currentUser?.fullName}!'
                      : 'Chào mừng bạn đến với PRM393 E-Shop!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thiết bị công nghệ chính hãng - Bảo hành toàn diện.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white70,
            size: 36,
          ),
        ],
      ),
    );
  }

  // Thẻ hiển thị sản phẩm trong Grid
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    bool isAdmin,
    CartProvider cart,
  ) {
    final theme = Theme.of(context);
    final isOut = product.isOutOfStock;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.devices, size: 40, color: Colors.grey),
                        ),

                  // Badge trạng thái tồn kho
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOut
                            ? Colors.red.withValues(alpha: 0.9)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOut ? 'Hết hàng' : 'Kho: ${product.stockQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thông tin chi tiết sản phẩm
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Thao tác phân quyền:
                    // 1. ADMIN: Cho phép Sửa và Xóa sản phẩm
                    // 2. KHÁCH HÀNG: Cho phép Thêm vào giỏ hàng
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  foregroundColor: Colors.deepPurple,
                                  side: BorderSide(color: Colors.deepPurple.shade300),
                                ),
                                onPressed: () {
                                  ProductFormDialog.show(context, product: product);
                                },
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Sửa', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'Xóa sản phẩm',
                              onPressed: () => _confirmDelete(context, product),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: isOut ? Colors.grey.shade300 : Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isOut || product.id == null
                              ? null
                              : () async {
                                  final success = await cart.addToCart(productId: product.id!);
                                  if (!context.mounted) return;

                                  if (success) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã thêm "${product.name}" vào giỏ!'),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'Xem giỏ',
                                          textColor: Colors.amberAccent,
                                          onPressed: () => context.push('/cart'),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else if (cart.errorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(cart.errorMessage!),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                          label: Text(
                            isOut ? 'Hết hàng' : 'Thêm giỏ',
                            style: const TextStyle(fontSize: 11),
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
