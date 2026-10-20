import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đơn hàng')),
      body: const Center(
        child: Text('Màn hình Lịch sử & Chi tiết đơn hàng (Phụ trách: Member 5)'),
      ),
    );
  }
}
