import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/review.dart';
import '../models/user.dart';
import 'image_viewer_dialog.dart';

class ReviewItemCard extends StatelessWidget {
  final Review review;
  final User? currentUser;
  final VoidCallback? onDelete;

  const ReviewItemCard({
    super.key,
    required this.review,
    this.currentUser,
    this.onDelete,
  });

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildPhotoThumbnail(BuildContext context, String imgUrl) {
    Widget imageWidget;
    if (imgUrl.startsWith('data:image')) {
      final commaIndex = imgUrl.indexOf(',');
      final base64Data = commaIndex != -1 ? imgUrl.substring(commaIndex + 1) : imgUrl;
      imageWidget = Image.memory(
        base64Decode(base64Data),
        width: 84,
        height: 84,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.network(
        imgUrl,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 84,
          height: 84,
          color: AppColors.backgroundLight,
          child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
        ),
      );
    }

    return GestureDetector(
      onTap: () => ImageViewerDialog.show(context, imgUrl),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              imageWidget,
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = currentUser != null &&
        (currentUser!.isAdmin || currentUser!.id == review.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Tên, Ngày, Nút xóa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                backgroundImage: (review.userAvatar != null && review.userAvatar!.isNotEmpty)
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: (review.userAvatar == null || review.userAvatar!.isEmpty)
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
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
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.isVerifiedBuyer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mintLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppColors.accentMint),
                                SizedBox(width: 3),
                                Text(
                                  'Đã mua hàng',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Stars
                        Row(
                          children: List.generate(5, (index) {
                            final filled = index < review.rating.round();
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 15,
                              color: filled ? const Color(0xFFF59E0B) : AppColors.textMuted,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canDelete && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                  tooltip: 'Xóa đánh giá',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Nội dung đánh giá
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),

          // Hình ảnh đính kèm (nếu có)
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) =>
                    _buildPhotoThumbnail(context, review.images[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

