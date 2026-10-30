import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: const Center(
        child: Text('Màn hình Profile: Xem/Sửa họ tên, SĐT, Địa chỉ, Đổi mật khẩu, Đăng xuất'),
      ),
    );
  }
}
