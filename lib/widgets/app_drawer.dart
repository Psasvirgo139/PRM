import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header hiển thị thông tin User / Quyền hạn
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: auth.isAdmin
                    ? [Colors.deepPurple.shade700, Colors.deepPurple.shade900]
                    : [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                  ? NetworkImage(user!.avatarUrl)
                  : null,
              child: (user?.avatarUrl.isEmpty ?? true)
                  ? Icon(
                      auth.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      size: 40,
                      color: auth.isAdmin ? Colors.deepPurple : theme.colorScheme.primary,
                    )
                  : null,
            ),
            accountName: Text(
              user?.fullName ?? 'Khách ghé thăm',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user != null
                      ? (user.email.isNotEmpty ? user.email : '@${user.username}')
                      : 'Đăng nhập để trải nghiệm đầy đủ tính năng',
                  style: const TextStyle(fontSize: 12),
                ),
                if (auth.isLoggedIn) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: auth.isAdmin ? Colors.amber.shade700 : Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auth.isAdmin ? '👑 ADMIN (QUẢN TRỊ)' : '👤 KHÁCH HÀNG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Danh sách các Menu mục
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('Trang chủ / Sản phẩm'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_outlined),
                  title: const Text('Giỏ hàng'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/cart');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Đơn hàng của tôi'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/orders');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Thông tin cá nhân'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),

                // Phân quyền: Chỉ hiển thị mục Quản trị khi User là ADMIN
                if (auth.isAdmin) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'QUẢN TRỊ HỆ THỐNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined, color: Colors.deepPurple),
                    title: const Text(
                      'Bảng điều khiển Admin',
                      style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Thống kê, đơn hàng & tồn kho'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin');
                    },
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Footer: Nút Đăng nhập / Đăng xuất
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: auth.isLoggedIn
                ? ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: Colors.red.shade50,
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đăng xuất tài khoản')),
                        );
                      }
                    },
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập tài khoản'),
                  ),
          ),
        ],
      ),
    );
  }
}
