import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/compare_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/add_review_dialog.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/review_item_card.dart';
import '../../widgets/review_summary_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _localProduct;
  bool _isLoading = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _localProduct = widget.initialProduct;
    if (_localProduct == null) {
      _loadProduct();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  void _loadReviews() {
    final auth = context.read<AuthProvider>();
    context.read<ReviewProvider>().loadReviews(
      widget.productId,
      currentUserId: auth.currentUser?.id,
    );
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    final product = await context
        .read<ProductProvider>()
        .fetchProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _localProduct = product;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 26),
            SizedBox(width: 8),
            Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" khỏi hệ thống?\nHành động này không thể hoàn tác.',
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
              final success = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      success ? 'Đã xóa sản phẩm thành công' : 'Xóa sản phẩm thất bại',
                    ),
                    backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                  ),
                );
                if (success) {
                  context.pop();
                }
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
    final productProvider = context.watch<ProductProvider>();

    final product = productProvider.findById(widget.productId) ?? _localProduct;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Sản phẩm không tồn tại hoặc đã bị xóa',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại cửa hàng'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categoryName = productProvider.getCategoryName(product.categoryId);
    final isOutOfStock = product.isOutOfStock;
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Chia sẻ',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Đã sao chép liên kết ${product.name}'),
                ),
              );
            },
          ),
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
            ),
          ),
          IconButton(
            icon: Badge.count(
              count: cart.totalCount,
              isLabelVisible: cart.totalCount > 0,
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push('/cart'),
          ),
          if (auth.isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  ProductFormDialog.show(context, product: product);
                } else if (value == 'delete') {
                  _confirmDelete(context, product);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppColors.secondaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text('Sửa sản phẩm'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa sản phẩm', style: TextStyle(color: AppColors.errorRed)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 1100,
        child: isWide
            ? _buildWideLayout(context, product, categoryName, isOutOfStock, auth, cart)
            : _buildMobileLayout(context, product, categoryName, isOutOfStock, auth, cart),
      ),
      bottomNavigationBar: isWide ? null : _buildBottomBar(context, product, isOutOfStock, cart),
    );
  }

  // Bố cục thích ứng trên Desktop / Chrome Web (2 Cột rộng rãi)
  Widget _buildWideLayout(
    BuildContext context,
    Product product,
    String categoryName,
    bool isOutOfStock,
    AuthProvider auth,
    CartProvider cart,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột trái: Ảnh sản phẩm lớn
              Expanded(
                flex: 5,
                child: _buildProductImageSection(product, categoryName, isOutOfStock, height: 460),
              ),
              const SizedBox(width: 32),

              // Cột phải: Thông tin, Quản trị, Nút mua hàng & Chi tiết
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(product, categoryName, isOutOfStock),
                    const SizedBox(height: 16),

                    // Quản trị viên
                    if (auth.isAdmin) ...[
                      _buildAdminCard(context, product),
                      const SizedBox(height: 16),
                    ],

                    // Khung hành động Mua hàng trên Desktop
                    _buildDesktopActionCard(context, product, isOutOfStock, cart),
                    const SizedBox(height: 20),

                    // Cam kết
                    _buildHighlightsSection(),
                    const SizedBox(height: 20),

                    // Mô tả sản phẩm
                    _buildDescriptionSection(product),
                    const SizedBox(height: 20),

                    // Thông số
                    _buildSpecificationsCard(product, categoryName),
                    const SizedBox(height: 20),

                    // So sánh đối đầu
                    _buildComparisonActionSection(context, product, categoryName),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Phân hệ Đánh giá & Chấm điểm sản phẩm (Full width)
          _buildReviewsSection(context, product, auth),
        ],
      ),
    );
  }

  // Bố cục trên Mobile (Cuộn 1 Cột)
  Widget _buildMobileLayout(
    BuildContext context,
    Product product,
    String categoryName,
    bool isOutOfStock,
    AuthProvider auth,
    CartProvider cart,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImageSection(product, categoryName, isOutOfStock, height: 320),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(product, categoryName, isOutOfStock),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 14),
                  _buildAdminCard(context, product),
                ],
                const SizedBox(height: 20),
                _buildHighlightsSection(),
                const SizedBox(height: 20),
                _buildDescriptionSection(product),
                const SizedBox(height: 20),
                _buildSpecificationsCard(product, categoryName),
                const SizedBox(height: 24),

                // Phân hệ Đánh giá & Chấm điểm sản phẩm trên Mobile
                _buildReviewsSection(context, product, auth),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ảnh sản phẩm lớn với Hero Animation
  Widget _buildProductImageSection(
    Product product,
    String categoryName,
    bool isOutOfStock, {
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'product-img-${product.id}',
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image_not_supported_rounded, size: 64, color: AppColors.textMuted),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.devices_rounded, size: 72, color: AppColors.textMuted),
                  ),
          ),

          // Nhãn danh mục (Xanh biển nhạt)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondaryBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_rounded, size: 14, color: AppColors.secondaryBlue),
                  const SizedBox(width: 5),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: AppColors.secondaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nhãn tồn kho
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? AppColors.errorRed.withValues(alpha: 0.95)
                    : AppColors.successGreen.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOutOfStock ? 'Hết hàng' : 'Còn ${product.stockQuantity} sản phẩm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tiêu đề, giá bán & đánh giá sao
  Widget _buildProductHeader(Product product, String categoryName, bool isOutOfStock) {
    final reviewProvider = context.watch<ReviewProvider>();
    final avg = reviewProvider.averageRating;
    final total = reviewProvider.totalReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text(
                    total > 0 ? avg.toStringAsFixed(1) : '5.0',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($total đánh giá)',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            Text(
              'Danh mục: $categoryName',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatter.format(product.price),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Chính hãng 100%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentMint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Khung thao tác cho Admin
  Widget _buildAdminCard(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Quản trị viên: Quản lý sản phẩm này',
                style: TextStyle(
                  color: AppColors.secondaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    ProductFormDialog.show(context, product: product);
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Chỉnh sửa thông tin'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  side: const BorderSide(color: AppColors.errorRed),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _confirmDelete(context, product),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Thao tác mua hàng trên giao diện Web rộng
  Widget _buildDesktopActionCard(
    BuildContext context,
    Product product,
    bool isOutOfStock,
    CartProvider cart,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.backgroundLight,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: _quantity < product.stockQuantity
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Kho: ${product.stockQuantity}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange, width: 1.4),
                  ),
                  onPressed: isOutOfStock
                      ? null
                      : () => _handleAddToCart(context, product, cart),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Thêm vào giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isOutOfStock
                      ? null
                      : () async {
                          final success = await _handleAddToCart(context, product, cart);
                          if (success && context.mounted) context.push('/cart');
                        },
                  child: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Cam kết & quyền lợi khách hàng
  Widget _buildHighlightsSection() {
    return Row(
      children: [
        _buildHighlightItem(
          icon: Icons.verified_user_outlined,
          label: '100% Chính hãng',
          color: AppColors.accentMint,
        ),
        _buildHighlightItem(
          icon: Icons.local_shipping_outlined,
          label: 'Giao nhanh toàn quốc',
          color: AppColors.secondaryBlue,
        ),
        _buildHighlightItem(
          icon: Icons.replay_rounded,
          label: 'Đổi trả 7 ngày',
          color: AppColors.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mô tả sản phẩm
  Widget _buildDescriptionSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description_outlined, size: 20, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text(
              'Mô tả sản phẩm',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            product.description.isNotEmpty
                ? product.description
                : 'Sản phẩm này hiện chưa có mô tả chi tiết từ quản trị viên.',
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Bảng thông số phụ
  Widget _buildSpecificationsCard(Product product, String categoryName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSpecRow('Mã sản phẩm', '#${product.id}'),
          const Divider(height: 18),
          _buildSpecRow('Danh mục', categoryName),
          const Divider(height: 18),
          _buildSpecRow('Số lượng tồn kho', '${product.stockQuantity} sản phẩm'),
          const Divider(height: 18),
          _buildSpecRow('Ngày cập nhật', product.createdAt.split('T').first),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
      ],
    );
  }

  // Khung hành động So sánh thông số kỹ thuật đối đầu
  Widget _buildComparisonActionSection(BuildContext context, Product product, String categoryName) {
    final compare = context.watch<CompareProvider>();
    final isInCompare = compare.isInCompare(product.id ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppColors.primaryOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'So Sánh Thông Số Đối Đầu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Đặt lên bàn cân Chip, RAM, Pin, Màn hình song song',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nút bấm thêm vào so sánh
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isInCompare ? Colors.green : AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (!isInCompare) {
                  await compare.addProduct(product);
                }
                if (context.mounted) {
                  context.push('/compare');
                }
              },
              icon: Icon(
                isInCompare ? Icons.check_circle_rounded : Icons.add_chart_rounded,
                size: 18,
              ),
              label: Text(
                isInCompare
                    ? 'Đang so sánh (${compare.count}/3) — Mở xem ngay'
                    : 'Thêm vào bảng so sánh đối đầu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thanh công cụ mua hàng ở đáy (Mobile)
  Widget _buildBottomBar(BuildContext context, Product product, bool isOutOfStock, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: isOutOfStock
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.borderLight,
                  foregroundColor: AppColors.textMuted,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: null,
                child: const Text('Sản phẩm tạm thời hết hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: _quantity < product.stockQuantity
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                      ),
                      onPressed: () => _handleAddToCart(context, product, cart),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Thêm giỏ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final success = await _handleAddToCart(context, product, cart);
                        if (success && context.mounted) context.push('/cart');
                      },
                      child: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<bool> _handleAddToCart(BuildContext context, Product product, CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/login');
      return false;
    }

    final success = await cart.addToCart(
      productId: product.id!,
      quantity: _quantity,
    );
    if (!context.mounted) return false;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          content: Text('Đã thêm $_quantity x "${product.name}" vào giỏ hàng!'),
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: AppColors.primaryOrange,
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
      return true;
    } else if (cart.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(cart.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return false;
    }
    return false;
  }

  // Phân hệ hiển thị Đánh giá & Nhận xét của khách hàng
  Widget _buildReviewsSection(BuildContext context, Product product, AuthProvider auth) {
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.filteredReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewSummaryWidget(product: product),
        const SizedBox(height: 16),
        if (reviewProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          )
        else if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có đánh giá nào phù hợp bộ lọc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hãy là người đầu tiên chia sẻ cảm nhận thực tế về sản phẩm này!',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Viết đánh giá ngay'),
                  onPressed: () {
                    if (!auth.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để viết đánh giá'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    AddReviewDialog.show(context, product: product);
                  },
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ReviewItemCard(
                review: review,
                currentUser: auth.currentUser,
                onDelete: () => _confirmDeleteReview(context, review, product.id!),
              );
            },
          ),
      ],
    );
  }

  void _confirmDeleteReview(BuildContext context, Review review, int productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa nhận xét đánh giá này không?'),
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
              final auth = context.read<AuthProvider>();
              final success = await context.read<ReviewProvider>().deleteReview(
                    review.id!,
                    productId,
                    currentUserId: auth.currentUser?.id,
                  );
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa đánh giá thành công'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
