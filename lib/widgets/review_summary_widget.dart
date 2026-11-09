import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import 'add_review_dialog.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final Product product;

  const ReviewSummaryWidget({
    super.key,
    required this.product,
  });

  Widget _buildProgressBar(int star, int count, int total) {
    final double percent = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            '$star',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 7,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final total = reviewProvider.totalReviews;
    final avg = reviewProvider.averageRating;
    final starCounts = reviewProvider.starCounts;
    final withImagesCount = reviewProvider.withImagesCount;
    final currentStarFilter = reviewProvider.starFilter;
    final currentOnlyImages = reviewProvider.filterOnlyWithImages;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Nút "Viết đánh giá"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Đánh giá & Nhận xét',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: const Text(
                  'Viết đánh giá',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  if (!auth.isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng đăng nhập để viết đánh giá cho sản phẩm'),
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
          const SizedBox(height: 18),

          // Khối tóm tắt điểm và thanh phần trăm sao
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Cột điểm trung bình
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        total > 0 ? avg.toStringAsFixed(1) : '5.0',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final filled = index < (total > 0 ? avg.round() : 5);
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: filled ? const Color(0xFFF59E0B) : AppColors.textMuted,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total lượt đánh giá',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 90,
                  width: 1,
                  color: AppColors.borderLight,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                // Cột các thanh phần trăm
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildProgressBar(5, starCounts[5] ?? 0, total),
                      _buildProgressBar(4, starCounts[4] ?? 0, total),
                      _buildProgressBar(3, starCounts[3] ?? 0, total),
                      _buildProgressBar(2, starCounts[2] ?? 0, total),
                      _buildProgressBar(1, starCounts[1] ?? 0, total),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hàng chip lọc nhanh
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  label: 'Tất cả ($total)',
                  isSelected: currentStarFilter == null && !currentOnlyImages,
                  onTap: () => reviewProvider.resetFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Có hình ảnh ($withImagesCount)',
                  isSelected: currentOnlyImages,
                  onTap: () => reviewProvider.setFilter(onlyWithImages: !currentOnlyImages),
                ),
                const SizedBox(width: 8),
                ...[5, 4, 3, 2, 1].map((star) {
                  final count = starCounts[star] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      context: context,
                      label: '$star ★ ($count)',
                      isSelected: currentStarFilter == star,
                      onTap: () => reviewProvider.setFilter(star: star),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

