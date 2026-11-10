import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';

class AddReviewDialog extends StatefulWidget {
  final Product product;

  const AddReviewDialog({
    super.key,
    required this.product,
  });

  static Future<bool?> show(BuildContext context, {required Product product}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddReviewDialog(product: product),
    );
  }

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  double _selectedRating = 5.0;
  final List<String> _uploadedImages = [];
  bool _isSubmitting = false;

  // Ảnh mẫu gợi ý mở hộp đẹp giúp kiểm thử nhanh tức thì
  static const List<Map<String, String>> _sampleTechPhotos = [
    {
      'label': 'Ảnh mở hộp',
      'url': 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600',
    },
    {
      'label': 'Ảnh cận cảnh',
      'url': 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600',
    },
    {
      'label': 'Ảnh trên bàn làm việc',
      'url': 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=600',
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingLabel(double rating) {
    switch (rating.round()) {
      case 1:
        return 'Rất tệ 😞';
      case 2:
        return 'Chưa hài lòng 🙁';
      case 3:
        return 'Bình thường 😐';
      case 4:
        return 'Hài lòng 😊';
      case 5:
      default:
        return 'Cực kỳ hài lòng! 🌟';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return const Color(0xFFF59E0B);
    if (rating >= 3) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_uploadedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa đính kèm 3 hình ảnh cho mỗi đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';

        setState(() {
          _uploadedImages.add(dataUri);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addSamplePhoto(String url) {
    if (_uploadedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa đính kèm 3 hình ảnh'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_uploadedImages.contains(url)) {
      setState(() {
        _uploadedImages.add(url);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để gửi đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/login');
      return;
    }

    setState(() => _isSubmitting = true);

    final reviewProvider = context.read<ReviewProvider>();
    final success = await reviewProvider.submitReview(
      productId: widget.product.id!,
      user: auth.currentUser!,
      rating: _selectedRating,
      comment: _commentController.text,
      images: _uploadedImages,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.successGreen,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Cảm ơn bạn! Đánh giá đã được đăng thành công.'),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorRed,
            content: Text(reviewProvider.errorMessage ?? 'Gửi đánh giá thất bại'),
          ),
        );
      }
    }
  }

  Widget _buildImageThumbnail(String imgUrl, int index) {
    Widget imageWidget;
    if (imgUrl.startsWith('data:image')) {
      final commaIndex = imgUrl.indexOf(',');
      final base64Data = commaIndex != -1 ? imgUrl.substring(commaIndex + 1) : imgUrl;
      imageWidget = Image.memory(
        base64Decode(base64Data),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.network(
        imgUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 72,
          height: 72,
          color: AppColors.backgroundLight,
          child: const Icon(Icons.broken_image, size: 24, color: AppColors.textMuted),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10, top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: imageWidget,
          ),
        ),
        Positioned(
          top: 0,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _uploadedImages.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final isVerified = reviewProvider.isVerifiedBuyer;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đánh giá sản phẩm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),

                // Huy hiệu khách hàng đã mua sản phẩm
                if (isVerified)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentMint.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.accentMint, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Xác thực: Bạn đã mua sản phẩm này! Đánh giá sẽ được gắn huy hiệu Đã Mua Hàng.',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Phần chọn số sao
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          final isSelected = star <= _selectedRating;
                          return IconButton(
                            iconSize: 36,
                            splashRadius: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            icon: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isSelected ? _getRatingColor(_selectedRating) : Colors.black26,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedRating = star.toDouble();
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingLabel(_selectedRating),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(_selectedRating),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ô nhập bình luận
                const Text(
                  'Nhận xét của bạn *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Chất lượng hoàn thiện, thời lượng pin, hiệu năng thực tế, thái độ đóng gói và giao hàng...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
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
                      borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập nhận xét của bạn';
                    }
                    if (value.trim().length < 5) {
                      return 'Nội dung nhận xét tối thiểu 5 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Thêm hình ảnh thực tế
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hình ảnh thực tế (Tối đa 3 ảnh)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_uploadedImages.length}/3',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Danh sách ảnh đã chọn
                if (_uploadedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _uploadedImages.length,
                      itemBuilder: (context, index) =>
                          _buildImageThumbnail(_uploadedImages[index], index),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Nút chụp / chọn ảnh
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryBlue,
                        side: const BorderSide(color: AppColors.secondaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 12.5)),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12.5)),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),

                // Gợi ý ảnh mẫu (tiện dụng khi chạy web không có webcam)
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    const Text('Gợi ý ảnh mẫu: ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _sampleTechPhotos.map((sample) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                label: Text(sample['label']!, style: const TextStyle(fontSize: 11)),
                                onPressed: () => _addSamplePhoto(sample['url']!),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Gửi đánh giá',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

