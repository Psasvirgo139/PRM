import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán & Chốt đơn')),
      body: const Center(
        child: Text('Màn hình Đặt hàng & Transaction trừ kho (Phụ trách: Member 4)'),
      ),
    );
  }
}
