import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: AppColors.surfaceWhite,
      child: Column(
        children: [
          // Header hiển thị thông tin User / Quyền hạn với màu sắc tươi sáng
          Container(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 20, 18, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A30), Color(0xFFFF9E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                      ? NetworkImage(user!.avatarUrl)
                      : null,
                  child: (user?.avatarUrl.isEmpty ?? true)
                      ? const Icon(
                          Icons.person_rounded,
                          size: 34,
                          color: AppColors.primaryOrange,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'Khách ghé thăm',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user != null
                            ? (user.email.isNotEmpty ? user.email : '@${user.username}')
                            : 'Đăng nhập để xem giỏ & đơn hàng',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (auth.isLoggedIn) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            auth.isAdmin
                                ? '👑 QUẢN TRỊ VIÊN'
                                : auth.isEmployee
                                    ? '💼 NHÂN VIÊN'
                                    : '👤 KHÁCH HÀNG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Danh sách các Menu mục
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.primaryOrange,
                  title: 'Trang chủ / Sản phẩm',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: AppColors.primaryOrange,
                  title: 'Giỏ hàng',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/cart');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.compare_arrows_rounded,
                  iconColor: AppColors.primaryOrange,
                  title: 'So sánh sản phẩm',
                  subtitle: 'Đối đầu thông số kỹ thuật (Smart Specs)',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/compare');
                  },
                ),
                if (!auth.canManageOrders)
                  _buildDrawerItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.secondaryBlue,
                    title: 'Đơn hàng của tôi',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/orders');
                    },
                  ),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.secondaryBlue,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),

                // Phân quyền Quản trị (Admin & Employee)
                if (auth.canManageOrders) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Divider(color: AppColors.borderSoft),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      auth.isAdmin ? 'QUẢN TRỊ HỆ THỐNG' : 'PHÂN HỆ NHÂN VIÊN',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (auth.isAdmin)
                    _buildDrawerItem(
                      icon: Icons.dashboard_outlined,
                      iconColor: AppColors.secondaryBlue,
                      title: 'Bảng điều khiển Admin',
                      subtitle: 'Thống kê doanh thu & tồn kho',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin');
                      },
                    ),
                  _buildDrawerItem(
                    icon: Icons.list_alt_rounded,
                    iconColor: AppColors.secondaryBlue,
                    title: 'Quản lý Đơn hàng',
                    subtitle: 'Cập nhật trạng thái xử lý',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/orders');
                    },
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSoft),

          // Footer: Nút Đăng nhập / Đăng xuất
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: auth.isLoggedIn
                ? ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.errorLight.withValues(alpha: 0.5),
                    leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                    title: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã đăng xuất tài khoản thành công'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
      onTap: onTap,
    );
  }
}
