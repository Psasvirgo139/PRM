import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: const Center(
        child: Text('Màn hình Đăng Nhập (Tài khoản: admin / customer)'),
      ),
    );
  }
}
