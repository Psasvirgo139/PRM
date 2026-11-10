import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/voucher_provider.dart';
import '../../widgets/lucky_wheel_logo.dart';
import 'widgets/voucher_card.dart';

class VoucherWalletScreen extends StatefulWidget {
  const VoucherWalletScreen({super.key});

  @override
  State<VoucherWalletScreen> createState() => _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends State<VoucherWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voucherProvider = context.watch<VoucherProvider>();
    final available = voucherProvider.availableVouchers;
    final used = voucherProvider.usedVouchers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Kho Voucher Của Tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút đi tới Vòng quay may mắn
          TextButton.icon(
            onPressed: () => context.push('/lucky-wheel'),
            icon: const LuckyWheelLogo(size: 18, strokeColor: Color(0xFFFF7A30), fillColor: Colors.white),
            label: const Text('Quay thêm', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF7A30))),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF7A30),
          indicatorColor: const Color(0xFFFF7A30),
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Khả dụng (${available.length})'),
            Tab(text: 'Đã sử dụng (${used.length})'),
          ],
        ),
      ),
      body: voucherProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Voucher khả dụng
                RefreshIndicator(
                  onRefresh: () => voucherProvider.loadUserVouchers(),
                  child: available.isEmpty
                      ? _buildEmptyState(
                          title: 'Chưa có voucher khả dụng',
                          subtitle:
                              'Tham gia Vòng Quay May Mắn ngay để rinh các mã giảm giá siêu hấp dẫn!',
                          buttonText: 'Quay Thưởng Ngay',
                          onAction: () => context.push('/lucky-wheel'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: available.length,
                          itemBuilder: (ctx, index) {
                            return VoucherCard(userVoucher: available[index]);
                          },
                        ),
                ),

                // Tab 2: Voucher đã dùng
                RefreshIndicator(
                  onRefresh: () => voucherProvider.loadUserVouchers(),
                  child: used.isEmpty
                      ? _buildEmptyState(
                          title: 'Chưa có lịch sử voucher',
                          subtitle: 'Các voucher bạn đã sử dụng khi thanh toán sẽ hiển thị tại đây.',
                          buttonText: 'Khám phá sản phẩm',
                          onAction: () => context.go('/'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: used.length,
                          itemBuilder: (ctx, index) {
                            return VoucherCard(userVoucher: used[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    size: 64,
                    color: Colors.deepPurple.shade300,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const LuckyWheelLogo(size: 18, strokeColor: Colors.white, fillColor: Colors.transparent),
                  label: Text(buttonText),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A30),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

