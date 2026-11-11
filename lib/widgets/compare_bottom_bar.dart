import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/compare_provider.dart';

class CompareBottomBar extends StatelessWidget {
  const CompareBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final compare = context.watch<CompareProvider>();
    final products = compare.selectedProducts;

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Thumbnails các sản phẩm đang chọn
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: i < products.length
                            ? AppColors.primaryOrange
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: i < products.length
                        ? Image.network(
                            products[i].imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.devices,
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),

            // Thông tin số lượng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'So sánh đối đầu (${products.length}/3)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    products.length >= 2
                        ? 'Đã đủ máy để so sánh chi tiết'
                        : 'Chọn thêm 1 máy nữa',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            // Nút "So sánh ngay"
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                context.push('/compare');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'So sánh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Nút xóa tất cả
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              tooltip: 'Xóa bộ nhớ so sánh',
              visualDensity: VisualDensity.compact,
              onPressed: () => compare.clear(),
            ),
          ],
        ),
      ),
    );
  }
}
