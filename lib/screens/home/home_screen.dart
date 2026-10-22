import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
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
    final productProvider = context.watch<ProductProvider>();

    final categories = productProvider.categories;
    final products = productProvider.products;
    final isLoading = productProvider.isLoading;
    final selectedCatId = productProvider.selectedCategoryId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PRM393 E-Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Đơn hàng',
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.loadProducts();
        },
        child: CustomScrollView(
          slivers: [
            // 1. Banner chào mừng / Phân quyền Admin
            if (auth.isAdmin)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Chế độ Quản trị viên: Bạn có quyền Thêm, Sửa, Xóa sản phẩm.',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => ProductFormDialog.show(context),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Thêm mới'),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Thanh tìm kiếm (Search Bar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  onChanged: (value) {
                    productProvider.setSearchQuery(value);
                  },
                ),
              ),
            ),

            // 3. Bộ lọc danh mục nằm ngang (Category Filter Chips)
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
                    // Danh sách category từ SQLite
                    ...categories.map((cat) {
                      final isSelected = selectedCatId == cat.id;
                      IconData iconData = Icons.label_outline;
                      if (cat.name.contains('Điện thoại')) {
                        iconData = Icons.phone_android;
                      } else if (cat.name.contains('Laptop')) {
                        iconData = Icons.laptop_mac;
                      } else if (cat.name.contains('Phụ kiện')) {
                        iconData = Icons.headphones;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat.name),
                          avatar: Icon(iconData, size: 18),
                          onSelected: (_) {
                            productProvider.selectCategory(cat.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Tiêu đề số lượng sản phẩm tìm thấy
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
                    if (selectedCatId != null || _searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          productProvider.clearFilters();
                        },
                        child: const Text(
                          'Xóa bộ lọc',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. Danh sách sản phẩm (Product Grid)
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tìm thấy sản phẩm nào phù hợp',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Thử đổi từ khóa hoặc chọn danh mục khác',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          productProvider.clearFilters();
                        },
                        child: const Text('Xem tất cả sản phẩm'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product, auth.isAdmin);
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

  // Thẻ hiển thị thông tin sản phẩm
  Widget _buildProductCard(BuildContext context, Product product, bool isAdmin) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
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
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.devices, size: 40, color: Colors.grey),
                      ),
                // Badge tồn kho
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? Colors.red.withValues(alpha: 0.9)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.isOutOfStock ? 'Hết hàng' : 'Kho: ${product.stockQuantity}',
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

                  // Nút thao tác phân quyền:
                  // Nếu là ADMIN -> Hiện nút Sửa và Xóa
                  // Nếu không phải ADMIN -> Hiện nút Chi tiết / Giỏ hàng
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: product.isOutOfStock
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã chọn: ${product.name}'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add_shopping_cart, size: 14),
                        label: Text(
                          product.isOutOfStock ? 'Hết hàng' : 'Mua ngay',
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
    );
  }
}
