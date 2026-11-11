import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product; // null nếu là tạo mới, khác null nếu là chỉnh sửa

  const ProductFormDialog({super.key, this.product});

  static Future<void> show(BuildContext context, {Product? product}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stockQuantity.toString() : '10',
    );
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _selectedCategoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final imageUrl = _imageUrlController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    if (isEditing) {
      final updatedProduct = widget.product!.copyWith(
        name: name,
        price: price,
        stockQuantity: stock,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
        description: description,
      );
      success = await provider.updateProduct(updatedProduct);
    } else {
      final newProduct = Product(
        name: name,
        price: price,
        stockQuantity: stock,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
        description: description,
      );
      success = await provider.addProduct(newProduct);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Đã cập nhật sản phẩm thành công'
                : 'Đã thêm sản phẩm mới thành công',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return Dialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Dialog ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Sửa thông tin sản phẩm' : 'Thêm sản phẩm mới',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Cập nhật giá, kho và chi tiết sản phẩm'
                              : 'Nhập thông tin sản phẩm công nghệ vào hệ thống',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    tooltip: 'Đóng',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSoft),
              const SizedBox(height: 14),

              // ── Form Nội dung cuộn ──
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Tên sản phẩm
                        _buildFieldLabel('Tên sản phẩm', isRequired: true),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: _buildInputDecoration(
                            hintText: 'VD: iPhone 15 Pro Max 256GB',
                            prefixIcon: Icons.devices_rounded,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
                        ),
                        const SizedBox(height: 14),

                        // 2. Danh mục sản phẩm
                        _buildFieldLabel('Danh mục sản phẩm'),
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedCategoryId,
                          dropdownColor: AppColors.surfaceWhite,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: _buildInputDecoration(
                            hintText: 'Chọn danh mục',
                            prefixIcon: Icons.category_rounded,
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Chưa phân loại'),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        const SizedBox(height: 14),

                        // 3. Giá bán và Tồn kho (Cùng hàng, chia tỷ lệ đều, nhãn rõ ràng)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Giá bán
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Giá bán (VNĐ)', isRequired: true),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryOrange,
                                    ),
                                    decoration: _buildInputDecoration(
                                      hintText: 'VD: 25000000',
                                      prefixIcon: Icons.monetization_on_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Nhập giá bán';
                                      }
                                      final num = double.tryParse(v.trim());
                                      if (num == null || num < 0) return 'Giá không hợp lệ';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Tồn kho
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Số lượng kho', isRequired: true),
                                  TextFormField(
                                    controller: _stockController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                    decoration: _buildInputDecoration(
                                      hintText: 'VD: 10',
                                      prefixIcon: Icons.inventory_2_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Nhập tồn kho';
                                      }
                                      final num = int.tryParse(v.trim());
                                      if (num == null || num < 0) return 'Không hợp lệ';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 4. Đường dẫn ảnh (URL)
                        _buildFieldLabel('Đường dẫn hình ảnh (URL)'),
                        TextFormField(
                          controller: _imageUrlController,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          decoration: _buildInputDecoration(
                            hintText: 'https://images.unsplash.com/...',
                            prefixIcon: Icons.image_outlined,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        // Xem trước ảnh nếu có link
                        if (_imageUrlController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.network(
                                    _imageUrlController.text.trim(),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
                                        SizedBox(width: 8),
                                        Text('Không thể tải ảnh từ link này', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Xem trước ảnh', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // 5. Mô tả sản phẩm
                        _buildFieldLabel('Mô tả chi tiết sản phẩm'),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                          decoration: InputDecoration(
                            hintText: 'Nhập đặc điểm nổi bật, thông số kỹ thuật, cấu hình chi tiết...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surfaceWhite,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.borderSoft),
              const SizedBox(height: 12),

              // ── Action Buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị đầu mục (Title/Label) rõ ràng, nằm ngay phía trên ô nhập
  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          children: [
            TextSpan(text: label),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  // Decoration chuẩn, không bị lệch chữ hay cấn viền
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryOrange, size: 20),
      filled: true,
      fillColor: AppColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.6),
      ),
    );
  }
}
