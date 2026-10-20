import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa Hàng Công Nghệ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Đơn hàng',
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Giỏ hàng',
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Dự Án PRM393 - Base Skeleton',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Đã tích hợp: SQLite (sqflite), Provider, GoRouter, Intl.\nXem chi tiết phân chia task tại file TASK_ASSIGNMENT.md',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/cart'),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Giỏ hàng'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/orders'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Đơn hàng'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
