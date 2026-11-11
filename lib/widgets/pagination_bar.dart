import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final VoidCallback? onScrollToTop;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.pageSize,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.onScrollToTop,
  });

  void _handlePageTap(int page) {
    if (page == currentPage || page < 1 || page > totalPages) return;
    onPageChanged(page);
    onScrollToTop?.call();
  }

  List<dynamic> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final List<dynamic> pages = [];
    if (currentPage <= 3) {
      pages.addAll([1, 2, 3, 4, '...', totalPages]);
    } else if (currentPage >= totalPages - 2) {
      pages.addAll([1, '...', totalPages - 3, totalPages - 2, totalPages - 1, totalPages]);
    } else {
      pages.addAll([1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages]);
    }
    return pages;
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isNext = false,
    bool isMobile = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surfaceWhite : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled ? AppColors.borderLight : AppColors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNext) Icon(icon, size: 16, color: isEnabled ? AppColors.textPrimary : AppColors.textMuted),
              if (!isMobile) ...[
                if (!isNext) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                if (isNext) const SizedBox(width: 4),
              ],
              if (isNext) Icon(icon, size: 16, color: isEnabled ? AppColors.textPrimary : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(dynamic item, bool isMobile) {
    if (item is String) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          item,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final int pageNum = item as int;
    final bool isSelected = pageNum == currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePageTap(pageNum),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isMobile ? 34 : 38,
            height: isMobile ? 34 : 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryOrange : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x33FF7A30),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$pageNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(context);
    final pageNumbers = _buildPageNumbers();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
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
        children: [
          // Dòng thông tin & Dropdown chọn số sản phẩm / trang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Thông tin hiển thị
              Expanded(
                child: Text(
                  'Hiển thị $startIndex - $endIndex trên tổng số $totalItems sản phẩm',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Bộ chọn số sản phẩm / trang (8, 12, 16)
              if (onPageSizeChanged != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mỗi trang: ',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: pageSize,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryOrange),
                          items: const [
                            DropdownMenuItem(value: 8, child: Text('8 SP')),
                            DropdownMenuItem(value: 12, child: Text('12 SP')),
                            DropdownMenuItem(value: 16, child: Text('16 SP')),
                            DropdownMenuItem(value: 24, child: Text('24 SP')),
                          ],
                          onChanged: (newSize) {
                            if (newSize != null) {
                              onPageSizeChanged!(newSize);
                              onScrollToTop?.call();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (totalPages > 1) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),

            // Dòng điều hướng số trang
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút Trang Trước
                _buildNavButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Trước',
                  isEnabled: currentPage > 1,
                  onTap: () => _handlePageTap(currentPage - 1),
                  isMobile: isMobile,
                ),
                const SizedBox(width: 4),

                // Danh sách số trang
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: pageNumbers.map((item) => _buildPageButton(item, isMobile)).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Nút Trang Sau
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Sau',
                  isEnabled: currentPage < totalPages,
                  onTap: () => _handlePageTap(currentPage + 1),
                  isNext: true,
                  isMobile: isMobile,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

