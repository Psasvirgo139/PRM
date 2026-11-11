import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String username, String password) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderProv = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await auth.login(username, password);

    if (!mounted) return;

    if (success) {
      final currentUser = auth.currentUser;
      if (currentUser?.id != null) {
        cart.setUserId(currentUser!.id!);
        await cart.loadCart();

        if (currentUser.isCustomer) {
          await orderProv.loadUserOrders(currentUser.id!);
        } else {
          orderProv.clearUserOrders();
        }
      }

      if (!mounted) return;

      String roleTitle = 'Khách hàng';
      if (auth.isAdmin) {
        roleTitle = 'Admin (Quản trị viên)';
      } else if (auth.isEmployee) {
        roleTitle = 'Nhân viên (Employee)';
      }

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Đăng nhập thành công với vai trò: $roleTitle'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(auth.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Đăng nhập tài khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.orangeLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 48,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng nhập để quản lý hoặc mua sắm công nghệ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    // Ô nhập Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryOrange),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên đăng nhập'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Ô nhập Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryOrange),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập mật khẩu'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Nút Đăng nhập
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handleLogin(
                                  _usernameController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Nút chuyển sang Đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.borderLight)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'HOẶC TEST NHANH VAI TRÒ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.borderLight)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nút test nhanh vai trò Admin
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.secondaryBlue,
                        side: const BorderSide(color: AppColors.secondaryBlue, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: auth.isLoading ? null : () => _handleLogin('admin', 'admin123'),
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('Đăng nhập Admin (admin / admin123)'),
                    ),
                    const SizedBox(height: 10),

                    // Nút test nhanh vai trò Nhân viên
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.accentMint,
                        side: const BorderSide(color: AppColors.accentMint, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: auth.isLoading ? null : () => _handleLogin('employee', 'emp123'),
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Đăng nhập Nhân viên (employee / emp123)'),
                    ),
                    const SizedBox(height: 10),

                    // Nút test nhanh vai trò Khách hàng
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: auth.isLoading ? null : () => _handleLogin('customer', 'cust123'),
                      icon: const Icon(Icons.person_rounded),
                      label: const Text('Đăng nhập Khách hàng (customer / cust123)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
