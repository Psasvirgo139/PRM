import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilterIndex = 0; // 0: Tất cả, 1: Chưa đọc

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && auth.currentUser?.id != null) {
        context.read<NotificationProvider>().loadNotifications(auth.currentUser!.id!);
      }
    });
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  void _handleNotificationTap(NotificationItem item, AuthProvider auth) {
    // 1. Đánh dấu đã đọc
    if (!item.isRead && item.id != null && auth.currentUser?.id != null) {
      context.read<NotificationProvider>().markAsRead(item.id!, auth.currentUser!.id!);
    }

    // 2. Điều hướng tương ứng với loại thông báo & vai trò
    if (item.type == 'REPORT' || item.type == 'STOCK' || item.type == 'PRODUCT') {
      if (auth.isAdmin) {
        context.push('/admin');
      } else if (auth.isEmployee) {
        context.push('/admin/orders');
      }
    } else if (item.type == 'PROMOTION') {
      context.go('/');
    } else if (item.type == 'ORDER') {
      if (auth.canManageOrders) {
        if (item.relatedId != null) {
          context.push('/admin/orders/${item.relatedId}');
        } else {
          context.push('/admin/orders');
        }
      } else {
        context.push('/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notifProvider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifProvider.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (auth.isLoggedIn && notifProvider.notifications.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Tùy chọn',
              onSelected: (value) async {
                if (value == 'mark_all_read' && user?.id != null) {
                  await notifProvider.markAllAsRead(user!.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả là đã đọc'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else if (value == 'clear_all' && user?.id != null) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc muốn xóa tất cả thông báo không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa tất cả'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await notifProvider.clearAll(user!.id!);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Đọc tất cả'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 800,
        child: !auth.isLoggedIn || user == null
            ? _buildNotLoggedIn(context)
            : Column(
                children: [
                  // Filter bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả (${notifProvider.notifications.length})',
                          isSelected: _selectedFilterIndex == 0,
                          onTap: () => setState(() => _selectedFilterIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Chưa đọc (${notifProvider.unreadCount})',
                          isSelected: _selectedFilterIndex == 1,
                          onTap: () => setState(() => _selectedFilterIndex = 1),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Notifications list
                  Expanded(
                    child: notifProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildNotificationsList(notifProvider, auth, user.id!),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.orangeLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryOrange : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    NotificationProvider notifProvider,
    AuthProvider auth,
    int userId,
  ) {
    final list = _selectedFilterIndex == 1
        ? notifProvider.notifications.where((n) => !n.isRead).toList()
        : notifProvider.notifications;

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifProvider.loadNotifications(userId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilterIndex == 1
                        ? 'Bạn không có thông báo chưa đọc nào!'
                        : 'Bạn chưa có thông báo nào!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các cập nhật đơn hàng và hệ thống sẽ hiển thị tại đây.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifProvider.loadNotifications(userId),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final item = list[index];
          return _buildNotificationCard(item, notifProvider, auth, userId);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationItem item,
    NotificationProvider notifProvider,
    AuthProvider auth,
    int userId,
  ) {
    final isUnread = !item.isRead;
    final iconData = _getIconData(item);
    final iconBgColor = _getIconBgColor(item);
    final iconColor = _getIconColor(item);

    return Dismissible(
      key: Key('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        if (item.id != null) {
          notifProvider.deleteNotification(item.id!, userId);
        }
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(item, auth),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primaryOrange.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppColors.primaryOrange.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: isUnread ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnread ? Colors.black87 : Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(NotificationItem item) {
    if (item.type == 'REPORT') {
      return Icons.assessment_rounded;
    }
    if (item.type == 'STOCK') {
      return Icons.inventory_2_rounded;
    }
    if (item.type == 'PRODUCT') {
      return Icons.edit_note_rounded;
    }
    if (item.type == 'PROMOTION') {
      return Icons.local_offer_rounded;
    }
    final msg = item.message.toLowerCase();
    final title = item.title.toLowerCase();
    if (title.contains('thành công') || msg.contains('thành công') || msg.contains('đánh giá')) {
      return Icons.check_circle_rounded;
    }
    if (msg.contains('đang được xử lý') || msg.contains('đang xử lý') || msg.contains('đã được duyệt')) {
      return Icons.autorenew_rounded;
    }
    if (title.contains('hủy') || msg.contains('hủy')) {
      return Icons.cancel_rounded;
    }
    if (title.contains('mới') || msg.contains('mới') || title.contains('đặt hàng')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconBgColor(NotificationItem item) {
    if (item.type == 'REPORT') {
      return Colors.purple.shade50;
    }
    if (item.type == 'STOCK') {
      return Colors.amber.shade50;
    }
    if (item.type == 'PRODUCT') {
      return Colors.teal.shade50;
    }
    if (item.type == 'PROMOTION') {
      return Colors.pink.shade50;
    }
    final msg = item.message.toLowerCase();
    final title = item.title.toLowerCase();
    if (title.contains('thành công') || msg.contains('thành công')) {
      return Colors.green.shade50;
    }
    if (msg.contains('đang được xử lý') || msg.contains('đang xử lý') || msg.contains('đã được duyệt')) {
      return Colors.blue.shade50;
    }
    if (title.contains('hủy') || msg.contains('hủy')) {
      return Colors.red.shade50;
    }
    return AppColors.orangeLight;
  }

  Color _getIconColor(NotificationItem item) {
    if (item.type == 'REPORT') {
      return Colors.purple.shade700;
    }
    if (item.type == 'STOCK') {
      return Colors.amber.shade800;
    }
    if (item.type == 'PRODUCT') {
      return Colors.teal.shade700;
    }
    if (item.type == 'PROMOTION') {
      return Colors.pink.shade700;
    }
    final msg = item.message.toLowerCase();
    final title = item.title.toLowerCase();
    if (title.contains('thành công') || msg.contains('thành công')) {
      return Colors.green.shade700;
    }
    if (msg.contains('đang được xử lý') || msg.contains('đang xử lý') || msg.contains('đã được duyệt')) {
      return Colors.blue.shade700;
    }
    if (title.contains('hủy') || msg.contains('hủy')) {
      return Colors.red.shade700;
    }
    return AppColors.primaryOrange;
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 72,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập để xem thông báo cập nhật đơn hàng và hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

