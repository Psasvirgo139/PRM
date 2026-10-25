import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          content: Text(
            isEditing
                ? 'Đã cập nhật sản phẩm thành công'
                : 'Đã thêm sản phẩm mới thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'Sửa thông tin sản phẩm' : 'Thêm sản phẩm mới'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên sản phẩm
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    hintText: 'VD: iPhone 15 Pro Max',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 12),

                // Danh mục
                DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
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
                const SizedBox(height: 12),

                // Giá và Số lượng tồn kho
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá bán (VNĐ) *',
                          hintText: 'VD: 25000000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tồn kho *',
                          hintText: 'VD: 10',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nhập tồn kho';
                          }
                          final num = int.tryParse(v.trim());
                          if (num == null || num < 0) return 'Số không hợp lệ';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Link ảnh
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Đường dẫn ảnh (URL)',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_imageUrlController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 60,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Text('Ảnh không tải được', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Mô tả sản phẩm
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả sản phẩm',
                    hintText: 'Mô tả cấu hình, đặc điểm nổi bật...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy bỏ'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm'),
        ),
      ],
    );
  }
}
