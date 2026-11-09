import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../providers/product_provider.dart';

class BannerItem {
  final String title;
  final String subtitle;
  final String tag;
  final String imageUrl;
  final List<Color> gradientColors;
  final int? targetCategoryId;
  final String? targetSearch;

  const BannerItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.imageUrl,
    required this.gradientColors,
    this.targetCategoryId,
    this.targetSearch,
  });
}

class HomeCarouselBanner extends StatefulWidget {
  const HomeCarouselBanner({super.key});

  @override
  State<HomeCarouselBanner> createState() => _HomeCarouselBannerState();
}

class _HomeCarouselBannerState extends State<HomeCarouselBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static const List<BannerItem> _banners = [
    BannerItem(
      title: 'Galaxy S24 Ultra & iPhone 15 Pro',
      subtitle: 'Siêu phẩm công nghệ AI đỉnh cao - Trợ giá đến 5.000.000đ',
      tag: 'HOT DEAL ĐIỆN THOẠI',
      imageUrl: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600',
      gradientColors: [Color(0xFFFF7A30), Color(0xFFFF9E63)],
      targetCategoryId: 1, // Điện thoại
    ),
    BannerItem(
      title: 'MacBook Air M3 Siêu Mỏng Nhẹ',
      subtitle: 'Chip M3 thế hệ mới - Giảm ngay 10% cho Học sinh & Sinh viên',
      tag: 'LAPTOP CHÍNH HÃNG',
      imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600',
      gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      targetCategoryId: 2, // Laptop
    ),
    BannerItem(
      title: 'Siêu Hội Phụ Kiện Âm Thanh',
      subtitle: 'AirPods Pro, Keychron K2, Chuột MX Master 3S giá sốc',
      tag: 'GIẢM ĐẾN 40%',
      imageUrl: 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=600',
      gradientColors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
      targetCategoryId: 3, // Phụ kiện
    ),
    BannerItem(
      title: 'Thu Cũ Đổi Mới - Trợ Giá Khủng',
      subtitle: 'Lên đời thiết bị chỉ từ 0đ - Thẩm định máy chuyên sâu tại chỗ',
      tag: 'TRADE-IN TIẾT KIỆM',
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600',
      gradientColors: [Color(0xFFEA580C), Color(0xFFFB923C)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.94);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerTap(BannerItem banner) {
    final productProvider = context.read<ProductProvider>();
    if (banner.targetCategoryId != null) {
      productProvider.selectCategory(banner.targetCategoryId);
    } else if (banner.targetSearch != null) {
      productProvider.setSearchQuery(banner.targetSearch!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final double bannerHeight = isDesktop ? 220 : (isTablet ? 190 : 165);

    return Column(
      children: [
        // ── 1. PageView Carousel Banner ──
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildBannerCard(context, banner),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── 2. Chỉ báo trang (Indicator Dots / Bars) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isSelected = _currentPage == index;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isSelected ? 24 : 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // ── 3. Quick Action Services (Theo phong cách CellphoneS như ảnh mẫu) ──
        _buildQuickServicesRow(context),
      ],
    );
  }

  Widget _buildBannerCard(BuildContext context, BannerItem banner) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleBannerTap(banner),
          child: Stack(
            children: [
              // Ảnh minh họa ở góc phải
              Positioned(
                right: -10,
                bottom: -15,
                top: -15,
                width: 170,
                child: Opacity(
                  opacity: 0.88,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(80)),
                    child: Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Dải bóng mờ che chữ bên trái để dễ đọc
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        banner.gradientColors.first.withValues(alpha: 0.95),
                        banner.gradientColors.first.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // Nội dung Text bên trái
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 110, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge nhãn
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Tiêu đề
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // Nút Xem ngay
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem ngay',
                            style: TextStyle(
                              color: banner.gradientColors.first,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: banner.gradientColors.first,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4 mục tiện ích nhanh (Deal sốc, Định giá thu cũ, Ưu đãi, Thu cũ đổi mới như ảnh)
  Widget _buildQuickServicesRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionItem(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            title: 'Deal sốc\nđến 50%',
            badgeText: 'HOT',
            onTap: () {
              context.read<ProductProvider>().setSearchQuery('');
              context.read<ProductProvider>().selectCategory(null);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.currency_exchange_rounded,
            color: AppColors.secondaryBlue,
            bgColor: AppColors.blueLight,
            title: 'Thu cũ\nđổi mới',
            badgeText: 'MỚI',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Chương trình Thu cũ đổi mới trợ giá đến 3 Triệu đồng!'),
                ),
              );
            },
          ),
          _buildQuickActionItem(
            icon: Icons.school_rounded,
            color: AppColors.accentMint,
            bgColor: AppColors.mintLight,
            title: 'Ưu đãi\ngiáo dục',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Ưu đãi giảm thêm 500.000đ cho Học sinh & Sinh viên!'),
                ),
              );
            },
          ),
          _buildQuickActionItem(
            icon: Icons.verified_rounded,
            color: AppColors.primaryOrange,
            bgColor: AppColors.orangeLight,
            title: 'Chính hãng\n100%',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Tất cả sản phẩm đều cam kết chính hãng & bảo hành 12 tháng.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badgeText != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
