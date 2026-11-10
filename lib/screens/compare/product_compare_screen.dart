import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../models/product_spec.dart';
import '../../providers/cart_provider.dart';
import '../../providers/compare_provider.dart';
import '../../repositories/compare_repository.dart';

class ProductCompareScreen extends StatefulWidget {
  const ProductCompareScreen({super.key});

  @override
  State<ProductCompareScreen> createState() => _ProductCompareScreenState();
}

class _ProductCompareScreenState extends State<ProductCompareScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final CompareRepository _compareRepository = CompareRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final compare = context.read<CompareProvider>();
      // Nếu chưa có sản phẩm nào, tự động nạp mẫu 2 điện thoại để demo đối đầu ngay
      if (compare.count == 0) {
        compare.loadDefaultDemoComparison();
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Mở BottomSheet chọn sản phẩm để thêm vào bảng so sánh hoặc thay thế
  void _openProductSelector(BuildContext context, {int? replaceIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductSelectorSheet(
        replaceIndex: replaceIndex,
        repository: _compareRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compare = context.watch<CompareProvider>();
    final cart = context.watch<CartProvider>();
    final products = compare.selectedProducts;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'So Sánh Thông Số Đối Đầu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa tất cả',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa bảng so sánh?'),
                    content: const Text('Toàn bộ sản phẩm sẽ được gỡ khỏi danh sách so sánh đối đầu.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          compare.clear();
                        },
                        child: const Text('Xóa hết'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: compare.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryOrange),
                  SizedBox(height: 16),
                  Text('Đang nạp bảng thông số kỹ thuật đối đầu...'),
                ],
              ),
            )
          : products.isEmpty
              ? _buildEmptyState(context, compare)
              : ResponsiveContainer(
                  maxWidth: 1200,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thanh điều khiển Differential Highlight
                        _buildControlFilterBar(compare),
                        const SizedBox(height: 16),

                        // Bảng so sánh đối đầu với Horizontal Sync Scrolling
                        _buildComparisonTable(context, compare, cart),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Thanh công cụ tùy chỉnh bộ lọc so sánh thông minh
  Widget _buildControlFilterBar(CompareProvider compare) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tùy chỉnh đối đầu thông minh (Smart Specs)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Làm nổi bật thông số khác biệt & tìm sản phẩm vượt trội',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Switch: Chỉ xem điểm khác biệt
              FilterChip(
                selected: compare.showOnlyDifferences,
                avatar: Icon(
                  compare.showOnlyDifferences ? Icons.visibility_rounded : Icons.visibility_outlined,
                  size: 16,
                  color: compare.showOnlyDifferences ? Colors.white : AppColors.primaryOrange,
                ),
                label: const Text('Chỉ xem điểm khác biệt'),
                selectedColor: AppColors.primaryOrange,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: compare.showOnlyDifferences ? Colors.white : Colors.black87,
                ),
                onSelected: (_) => compare.toggleShowOnlyDifferences(),
              ),

              // Switch: Đánh dấu thông số khác biệt
              FilterChip(
                selected: compare.highlightDifferences,
                avatar: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: compare.highlightDifferences ? Colors.white : Colors.amber.shade800,
                ),
                label: const Text('Tô màu khác biệt'),
                selectedColor: Colors.amber.shade700,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: compare.highlightDifferences ? Colors.white : Colors.black87,
                ),
                onSelected: (_) => compare.toggleHighlightDifferences(),
              ),

              // Switch: Thông số vượt trội
              FilterChip(
                selected: compare.highlightBestSpecs,
                avatar: Icon(
                  Icons.military_tech_rounded,
                  size: 16,
                  color: compare.highlightBestSpecs ? Colors.white : Colors.green.shade800,
                ),
                label: const Text('Đánh dấu vượt trội ★'),
                selectedColor: Colors.green.shade700,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: compare.highlightBestSpecs ? Colors.white : Colors.black87,
                ),
                onSelected: (_) => compare.toggleHighlightBestSpecs(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Toàn bộ Bảng so sánh dạng Sync Scrolling
  Widget _buildComparisonTable(
    BuildContext context,
    CompareProvider compare,
    CartProvider cart,
  ) {
    final products = compare.selectedProducts;
    final mergedGroups = compare.getMergedGroups();

    // Độ rộng tiêu chuẩn cho mỗi cột sản phẩm
    const double specColWidth = 140.0;
    const double productColWidth = 200.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: specColWidth + (products.length < 3 ? products.length + 1 : 3) * productColWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER ROW: Cột nhãn + Danh sách sản phẩm song song
                _buildProductHeadersRow(context, compare, cart, specColWidth, productColWidth),
                const Divider(height: 1, thickness: 1.5),

                // 2. CÁC NHÓM THÔNG SỐ (SPEC GROUPS)
                for (final group in mergedGroups) ...[
                  _buildSpecGroupHeader(group, specColWidth, productColWidth, products.length),
                  _buildSpecGroupItems(compare, group, specColWidth, productColWidth),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dòng Header sản phẩm cố định kích thước
  Widget _buildProductHeadersRow(
    BuildContext context,
    CompareProvider compare,
    CartProvider cart,
    double specColWidth,
    double productColWidth,
  ) {
    final products = compare.selectedProducts;
    final int slotsCount = products.length < 3 ? products.length + 1 : 3;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô góc trên cùng bên trái
          SizedBox(
            width: specColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐỐI ĐẦU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${products.length}/3 Thiết bị',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cuộn ngang để xem đủ sản phẩm',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // Các cột sản phẩm
          for (int i = 0; i < slotsCount; i++)
            SizedBox(
              width: productColWidth,
              child: i < products.length
                  ? _buildProductHeaderCard(context, compare, cart, products[i], i)
                  : _buildAddProductPlaceholder(context, compare),
            ),
        ],
      ),
    );
  }

  /// Thẻ sản phẩm ở Header
  Widget _buildProductHeaderCard(
    BuildContext context,
    CompareProvider compare,
    CartProvider cart,
    Product product,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nút xóa & Nút đổi máy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _openProductSelector(context, replaceIndex: index),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 2),
                      Text('Đổi', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => compare.removeProduct(product.id!),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Ảnh sản phẩm
          InkWell(
            onTap: () => context.push('/product/${product.id}', extra: product),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.devices, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tên sản phẩm
          InkWell(
            onTap: () => context.push('/product/${product.id}', extra: product),
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),

          // Giá bán
          Text(
            CurrencyFormatter.format(product.price),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),

          // Nút thêm vào giỏ hàng
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: product.isOutOfStock
                  ? null
                  : () async {
                      final ok = await cart.addToCart(productId: product.id!, quantity: 1);
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.shopping_cart_outlined, size: 14),
              label: Text(
                product.isOutOfStock ? 'Hết hàng' : 'Thêm giỏ',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ô trống "+" để thêm sản phẩm so sánh thứ 2 hoặc thứ 3
  Widget _buildAddProductPlaceholder(BuildContext context, CompareProvider compare) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => _openProductSelector(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primaryOrange, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              'Thêm sản phẩm ${compare.count + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Tối đa 3 máy đối đầu',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh tiêu đề Nhóm thông số (Spec Group Header)
  Widget _buildSpecGroupHeader(
    SpecGroup group,
    double specColWidth,
    double productColWidth,
    int productCount,
  ) {
    final int slotsCount = productCount < 3 ? productCount + 1 : 3;
    final totalWidth = specColWidth + slotsCount * productColWidth;

    return Container(
      width: totalWidth,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(group.icon, size: 18, color: AppColors.primaryOrange),
          const SizedBox(width: 8),
          Text(
            group.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Các dòng thông số con bên trong nhóm với Differential Highlight
  Widget _buildSpecGroupItems(
    CompareProvider compare,
    SpecGroup group,
    double specColWidth,
    double productColWidth,
  ) {
    final comparisonResults = compare.getGroupComparisonResults(group);
    final products = compare.selectedProducts;
    final int slotsCount = products.length < 3 ? products.length + 1 : 3;

    return Column(
      children: [
        for (final res in comparisonResults) ...[
          Container(
            decoration: BoxDecoration(
              // Tô màu nền nổi bật khi thông số giữa các sản phẩm có sự khác biệt
              color: (compare.highlightDifferences && res.isDifferent)
                  ? Colors.amber.withValues(alpha: 0.08)
                  : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cột nhãn thông số bên trái
                Container(
                  width: specColWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          res.referenceItem.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (compare.highlightDifferences && res.isDifferent)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),

                // Các cột giá trị tương ứng từng sản phẩm
                for (int i = 0; i < slotsCount; i++)
                  SizedBox(
                    width: productColWidth,
                    child: i < products.length
                        ? _buildSpecValueCell(res, i)
                        : const SizedBox(),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Ô giá trị thông số với nhãn "Vượt trội ★" khi sản phẩm dẫn đầu
  Widget _buildSpecValueCell(SpecComparisonResult res, int productIndex) {
    final item = productIndex < res.productItems.length ? res.productItems[productIndex] : null;
    final isWinner = res.bestProductIndex == productIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.withValues(alpha: 0.06) : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item?.value ?? '—',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner ? Colors.green.shade900 : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade300, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10, color: Colors.green.shade800),
                      const SizedBox(width: 2),
                      Text(
                        'Vượt trội',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Trạng thái trống khi chưa có thiết bị nào trong bảng
  Widget _buildEmptyState(BuildContext context, CompareProvider compare) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 64,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có thiết bị nào để so sánh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn từ 2 đến 3 điện thoại hoặc laptop để so sánh chi tiết đối đầu thông số kỹ thuật.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => _openProductSelector(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Chọn sản phẩm'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => compare.loadDefaultDemoComparison(),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Xem mẫu demo Flagship'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet tìm kiếm và chọn sản phẩm để so sánh
class _ProductSelectorSheet extends StatefulWidget {
  final int? replaceIndex;
  final CompareRepository repository;

  const _ProductSelectorSheet({
    this.replaceIndex,
    required this.repository,
  });

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final list = await widget.repository.getComparableProducts(
      categoryId: _selectedCategory,
      searchQuery: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _products = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compare = context.watch<CompareProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle kéo
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Tiêu đề
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.replaceIndex != null ? 'Thay thế cột ${widget.replaceIndex! + 1}' : 'Chọn sản phẩm so sánh',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Đã chọn ${compare.count}/3',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sản phẩm (iPhone, Galaxy, MacBook...)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (_) => _loadProducts(),
            ),
          ),
          const SizedBox(height: 8),

          // Lọc theo danh mục
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip(null, 'Tất cả'),
                const SizedBox(width: 8),
                _buildCategoryChip(1, 'Điện thoại'),
                const SizedBox(width: 8),
                _buildCategoryChip(2, 'Laptop'),
                const SizedBox(width: 8),
                _buildCategoryChip(3, 'Phụ kiện'),
              ],
            ),
          ),
          const Divider(height: 16),

          // Danh sách sản phẩm
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : _products.isEmpty
                    ? const Center(child: Text('Không tìm thấy sản phẩm phù hợp'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _products.length,
                        separatorBuilder: (_, _) => const Divider(height: 12),
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          final isAlreadySelected = compare.isInCompare(p.id ?? 0);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.devices, size: 20),
                                ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              CurrencyFormatter.format(p.price),
                              style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            trailing: isAlreadySelected
                                ? Chip(
                                    label: const Text('Đang so sánh', style: TextStyle(fontSize: 11, color: Colors.green)),
                                    backgroundColor: Colors.green.shade50,
                                  )
                                : FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryOrange,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onPressed: () async {
                                      if (widget.replaceIndex != null) {
                                        await compare.replaceProduct(widget.replaceIndex!, p);
                                      } else {
                                        await compare.addProduct(p);
                                      }
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: Text(widget.replaceIndex != null ? 'Chọn thay thế' : 'Chọn so sánh'),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int? catId, String label) {
    final isSelected = _selectedCategory == catId;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primaryOrange,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      onSelected: (_) {
        setState(() => _selectedCategory = catId);
        _loadProducts();
      },
    );
  }
}
