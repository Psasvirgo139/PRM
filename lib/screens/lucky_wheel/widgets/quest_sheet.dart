import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/lucky_wheel_provider.dart';
import '../../../providers/quest_provider.dart';

class QuestSheet extends StatelessWidget {
  const QuestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final wheelProvider = context.read<LuckyWheelProvider>();
    final quest = questProvider.todayQuest;

    final isLoginClaimed = quest?.loginClaimed ?? false;
    final orderEarned = quest?.orderSpinsEarned ?? 0;
    const maxOrderEarned = 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh kéo trên đỉnh
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhiệm Vụ Nhận Lượt Quay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hoàn thành để nhận thêm vé quay may mắn mỗi ngày',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nhiệm vụ 1: Điểm danh mỗi ngày
          _buildQuestItem(
            context: context,
            icon: Icons.calendar_today_rounded,
            iconColor: Colors.deepPurple,
            title: 'Điểm danh hàng ngày',
            subtitle: 'Đăng nhập mở ứng dụng mỗi ngày',
            rewardText: '+1 Lượt quay',
            isCompleted: isLoginClaimed,
            progressText: isLoginClaimed ? '1/1' : '0/1',
            buttonLabel: isLoginClaimed ? 'Đã nhận' : 'Nhận ngay',
            buttonAction: isLoginClaimed
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await questProvider.claimDailyLogin();
                    if (success) {
                      await wheelProvider.loadSpins();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Chúc mừng bạn nhận được +1 lượt quay điểm danh!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 12),

          // Nhiệm vụ 2: Mua hàng tích lượt
          _buildQuestItem(
            context: context,
            icon: Icons.shopping_bag_rounded,
            iconColor: Colors.blue,
            title: 'Mua sắm đơn hàng',
            subtitle: 'Hoàn tất đơn hàng bất kỳ (+1 lượt/đơn)',
            rewardText: '+1 Lượt / đơn (Tối đa 2)',
            isCompleted: orderEarned >= maxOrderEarned,
            progressText: '$orderEarned/$maxOrderEarned',
            buttonLabel: orderEarned >= maxOrderEarned ? 'Đã đủ' : 'Mua ngay',
            buttonAction: orderEarned >= maxOrderEarned
                ? null
                : () {
                    Navigator.of(context).pop();
                    context.go('/');
                  },
          ),
          const SizedBox(height: 16),

          // Ghi chú
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nhiệm vụ được làm mới vào 00:00 mỗi ngày. Các lượt quay tích lũy không bị hết hạn.',
                    style: TextStyle(fontSize: 11.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String rewardText,
    required bool isCompleted,
    required String progressText,
    required String buttonLabel,
    VoidCallback? buttonAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade300 : iconColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rewardText,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($progressText)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: buttonAction,
            style: FilledButton.styleFrom(
              backgroundColor: isCompleted ? Colors.grey.shade400 : const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

