import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Trị',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (authProvider.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) context.go('/');
              },
            ),
        ],
      ),
      body: adminProvider.isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProvider.loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stat Cards Grid ──
                    _buildStatCardsGrid(adminProvider, colorScheme),
                    const SizedBox(height: 24),

                    // ── Order Status Summary ──
                    _buildOrderStatusSummary(adminProvider, colorScheme),
                    const SizedBox(height: 24),

                    // ── Pending Orders Preview ──
                    _buildPendingOrdersSection(adminProvider, colorScheme),
                    const SizedBox(height: 24),

                    // ── Low Stock Alerts ──
                    _buildLowStockSection(adminProvider, colorScheme),
                    const SizedBox(height: 24),

                    // ── Quick Actions ──
                    _buildQuickActions(colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STAT CARDS GRID (2x2)
  // ══════════════════════════════════════════════════════════════

  Widget _buildStatCardsGrid(AdminProvider provider, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.monetization_on_rounded,
          label: 'Tổng doanh thu',
          value: CurrencyFormatter.format(provider.totalRevenue),
          gradientColors: [Colors.green.shade400, Colors.green.shade700],
        ),
        _StatCard(
          icon: Icons.today_rounded,
          label: 'Hôm nay',
          value: CurrencyFormatter.format(provider.todayRevenue),
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Tổng đơn hàng',
          value: '${provider.totalOrders}',
          gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
        ),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Khách hàng',
          value: '${provider.totalCustomers}',
          gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ORDER STATUS SUMMARY (Horizontal chips)
  // ══════════════════════════════════════════════════════════════

  Widget _buildOrderStatusSummary(AdminProvider provider, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng quan đơn hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Nhấn để xem chi tiết',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusChip(
                label: 'Chờ xử lý',
                count: provider.pendingOrdersCount,
                color: Colors.amber,
                icon: Icons.hourglass_top_rounded,
                onTap: () => context.push('/admin/orders?status=PENDING'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusChip(
                label: 'Đang xử lý',
                count: provider.processingOrdersCount,
                color: Colors.blue,
                icon: Icons.autorenew_rounded,
                onTap: () => context.push('/admin/orders?status=PROCESSING'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatusChip(
                label: 'Hoàn thành',
                count: provider.completedOrdersCount,
                color: Colors.green,
                icon: Icons.check_circle_rounded,
                onTap: () => context.push('/admin/orders?status=COMPLETED'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusChip(
                label: 'Đã hủy',
                count: provider.cancelledOrdersCount,
                color: Colors.red,
                icon: Icons.cancel_rounded,
                onTap: () => context.push('/admin/orders?status=CANCELLED'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PENDING ORDERS PREVIEW
  // ══════════════════════════════════════════════════════════════

  Widget _buildPendingOrdersSection(AdminProvider provider, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đơn chờ xử lý',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (provider.pendingOrdersPreview.isNotEmpty)
              TextButton.icon(
                onPressed: () => context.push('/admin/orders'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Xem tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.pendingOrdersPreview.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Không có đơn nào chờ xử lý!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...provider.pendingOrdersPreview.map(
            (order) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.push('/admin/orders/${order.id}'),
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Icon(Icons.hourglass_top_rounded,
                      color: Colors.amber.shade800, size: 20),
                ),
                title: Text(
                  order.orderCode,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  order.customerName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                trailing: Text(
                  CurrencyFormatter.format(order.finalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  LOW STOCK ALERTS
  // ══════════════════════════════════════════════════════════════

  Widget _buildLowStockSection(AdminProvider provider, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            Text(
              'Cảnh báo tồn kho',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            if (provider.lowStockProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.lowStockProducts.length}',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.lowStockProducts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Tất cả sản phẩm đều đủ hàng!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...provider.lowStockProducts.map(
            (product) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: product.isOutOfStock
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.isOutOfStock
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    product.isOutOfStock
                        ? Icons.error_rounded
                        : Icons.warning_rounded,
                    color: product.isOutOfStock
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  product.isOutOfStock ? 'HẾT HÀNG' : 'Sắp hết hàng',
                  style: TextStyle(
                    color: product.isOutOfStock
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Kho: ${product.stockQuantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: product.isOutOfStock
                              ? Colors.red.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      tooltip: 'Nhập thêm hàng',
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 22,
                      onPressed: () => _showRestockDialog(product),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  RESTOCK DIALOG
  // ══════════════════════════════════════════════════════════════

  Future<void> _showRestockDialog(Product product) async {
    final controller = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Nhập hàng vào kho',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'Tồn kho hiện tại: ${product.stockQuantity}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Số lượng nhập thêm',
                  hintText: 'Nhập số lượng (vd: 10)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Số lượng phải lớn hơn 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final addQty = int.parse(controller.text.trim());
      final newTotal = product.stockQuantity + addQty;
      final success = await context
          .read<AdminProvider>()
          .restockProduct(product.id!, newTotal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã nhập thêm +$addQty sản phẩm cho "${product.name}"!'
                  : 'Lỗi khi cập nhật kho hàng',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  QUICK ACTIONS
  // ══════════════════════════════════════════════════════════════

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push('/admin/orders'),
        icon: const Icon(Icons.list_alt_rounded),
        label: const Text('Quản lý Đơn hàng'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradientColors;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: color.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: color.shade700),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension _ColorShade on Color {
  Color get shade700 {
    return Color.lerp(this, Colors.black, 0.3) ?? this;
  }

  Color get shade900 {
    return Color.lerp(this, Colors.black, 0.5) ?? this;
  }
}
