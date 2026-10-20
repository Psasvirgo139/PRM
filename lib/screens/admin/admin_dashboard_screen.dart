import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Text('Màn hình Quản trị: Thống kê, Quản lý kho hàng, Duyệt tất cả đơn hàng'),
      ),
    );
  }
}
