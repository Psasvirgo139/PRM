import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/wheel_slice.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lucky_wheel_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/voucher_provider.dart';
import 'widgets/quest_sheet.dart';
import 'widgets/wheel_painter.dart';
import 'widgets/wheel_pointer.dart';
import 'widgets/win_dialog.dart';

class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _wheelAnimation;

  double _currentRotation = 0.0;
  WheelSlice? _currentTargetSlice;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _animController.addListener(() {
      if (_wheelAnimation != null) {
        setState(() {
          _currentRotation = _wheelAnimation!.value;
        });
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinFinished();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để tham gia Vòng quay may mắn!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onSpinFinished() async {
    final wheelProvider = context.read<LuckyWheelProvider>();
    final voucherProvider = context.read<VoucherProvider>();

    if (_currentTargetSlice != null) {
      await wheelProvider.completeSpin(_currentTargetSlice!);
      await voucherProvider.loadUserVouchers();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => WinDialog(
            slice: _currentTargetSlice!,
            wonVoucher: wheelProvider.lastWonVoucher,
            onSpinAgain: () {},
          ),
        );
      }
    }
  }

  Future<void> _handleSpin() async {
    final wheelProvider = context.read<LuckyWheelProvider>();

    if (_animController.isAnimating || wheelProvider.isSpinning) return;

    if (wheelProvider.spinsLeft <= 0) {
      _showNoSpinsAlert();
      return;
    }

    final targetSlice = await wheelProvider.startSpin();
    if (targetSlice == null) {
      if (mounted && wheelProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wheelProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _currentTargetSlice = targetSlice;

    // Tính toán góc quay đích xác định bằng toán học
    final totalSlices = wheelProvider.slices.length;
    final sliceAngle = (2 * pi) / totalSlices;

    // Góc trung tâm của nan trúng thưởng
    final targetCenterAngle = targetSlice.index * sliceAngle + sliceAngle / 2;

    // Kim chỉ nằm ở góc -pi / 2 (đỉnh trên 12h)
    // Để nan trúng thưởng nằm tại đỉnh: (targetCenterAngle + R) = -pi / 2 (mod 2pi)
    // => R = -pi / 2 - targetCenterAngle
    final currentMod = _currentRotation % (2 * pi);
    double targetAngleMod = (-pi / 2 - targetCenterAngle) % (2 * pi);
    if (targetAngleMod < 0) {
      targetAngleMod += 2 * pi;
    }

    double delta = targetAngleMod - currentMod;
    if (delta < 0) {
      delta += 2 * pi;
    }

    // Quay thêm tối thiểu 6 vòng đầy để tạo cảm giác xoay vù vù
    const extraRounds = 6;
    final endAngle = _currentRotation + (extraRounds * 2 * pi) + delta;

    _wheelAnimation = Tween<double>(
      begin: _currentRotation,
      end: endAngle,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.reset();
    _animController.forward();
  }

  void _showNoSpinsAlert() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const QuestSheet(),
    );
  }

  void _openQuestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const QuestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wheelProvider = context.watch<LuckyWheelProvider>();
    final questProvider = context.watch<QuestProvider>();
    final isSpinning = _animController.isAnimating || wheelProvider.isSpinning;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Vòng Quay May Mắn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút mở Kho Voucher cá nhân
          IconButton(
            icon: const Icon(Icons.wallet_giftcard_rounded, color: Color(0xFFFFD54F)),
            tooltip: 'Kho Voucher của tôi',
            onPressed: () => context.push('/vouchers'),
          ),
          // Nút mở danh sách Nhiệm vụ
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFFD54F)),
            tooltip: 'Nhiệm vụ nhận lượt',
            onPressed: _openQuestSheet,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF3D00), // Đỏ cam hoàng hôn rực rỡ
              Color(0xFFFF5722), // Cam ấm áp
              Color(0xFFFF7043), // Cam san hô
              Color(0xFFE64A19), // Đỏ cam đầm ấm
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 4),

                // 1. Hero Header phong cách Lễ hội / Đại tiệc Hội viên như ảnh mẫu
                _buildFestiveHeader(),
                const SizedBox(height: 14),

                // 2. Thanh trạng thái lượt quay & nút nhận nhiệm vụ
                _buildStatusBar(wheelProvider, questProvider),
                const SizedBox(height: 20),

                // 3. Vòng Quay May Mắn & Kim Chỉ & Mây bồng bềnh
                _buildWheelContainer(wheelProvider, isSpinning),
                const SizedBox(height: 24),

                // 4. Ticker các phần quà hấp dẫn
                _buildRewardsTicker(),
                const SizedBox(height: 16),

                // 5. Bảng hướng dẫn & thể lệ
                _buildRulesCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header phong cách lễ hội (Đặc quyền thành viên - Vòng quay may mắn - 100% trúng thưởng)
  Widget _buildFestiveHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Tag vàng trên đỉnh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'ĐẶC QUYỀN THÀNH VIÊN',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Tiêu đề 3D chữ vàng viền đỏ nổi bật
          const Text(
            'VÒNG QUAY MAY MẮN',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: 1.2,
              shadows: [
                Shadow(color: Color(0xFFB71C1C), offset: Offset(0, 3), blurRadius: 4),
                Shadow(color: Colors.black38, offset: Offset(0, 6), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Dải ruy băng đỏ cam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFFF5252), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'MUA SẮM LIỀN TAY - 100% TRÚNG QUÀ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(LuckyWheelProvider wheel, QuestProvider quest) {
    final canClaimDaily = quest.todayQuest?.canClaimLogin ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon vé quay
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD54F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFFC62828), size: 22),
            ),
            const SizedBox(width: 12),

            // Số lượt còn lại
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số lượt quay khả dụng',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${wheel.spinsLeft} Lượt',
                    style: const TextStyle(
                      color: Color(0xFFFFF8E1),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nút nhận thêm lượt
            FilledButton.icon(
              onPressed: _openQuestSheet,
              icon: Icon(
                canClaimDaily ? Icons.card_giftcard_rounded : Icons.add_circle_outline,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                canClaimDaily ? 'Nhận +1 🎁' : 'Thêm lượt',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelContainer(LuckyWheelProvider wheel, bool isSpinning) {
    final wheelSize = MediaQuery.of(context).size.width * 0.88;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Đèn hào quang ánh dương tỏa sáng (Sunburst Glow)
          Container(
            width: wheelSize + 30,
            height: wheelSize + 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Bánh xe tự quay thông qua CustomPainter
          Transform.rotate(
            angle: _currentRotation,
            child: CustomPaint(
              size: Size(wheelSize, wheelSize),
              painter: WheelPainter(slices: wheel.slices),
            ),
          ),

          // Kim chỉ cố định ở đỉnh trên (12h)
          Positioned(
            top: -18,
            child: const WheelPointer(),
          ),

          // Nút QUAY ở giữa tâm bánh xe
          GestureDetector(
            onTap: isSpinning ? null : _handleSpin,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSpinning
                      ? [Colors.grey.shade600, Colors.grey.shade800]
                      : [const Color(0xFFFF5252), const Color(0xFFC62828)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFFFD54F), width: 4.0),
              ),
              child: Center(
                child: Text(
                  isSpinning ? '...' : 'QUAY',
                  style: const TextStyle(
                    color: Color(0xFFFFFDE7),
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_rounded, color: Color(0xFFE64A19), size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Quay trúng Voucher áp dụng ngay tại màn hình Giỏ hàng & Thanh toán!',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: Color(0xFFE64A19), size: 22),
              SizedBox(width: 8),
              Text(
                'Thể Lệ Vòng Quay',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '• Điểm danh mỗi ngày: Tặng ngay +1 lượt quay miễn phí.\n'
            '• Hoàn tất đơn hàng: Tặng +1 lượt quay/đơn (Tối đa 2 lượt/ngày).\n'
            '• Voucher trúng thưởng được tự động lưu vào Kho Voucher của bạn và không thể quy đổi thành tiền mặt.\n'
            '• Bạn có thể áp dụng Voucher trực tiếp khi thanh toán đơn hàng.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.55),
          ),
        ],
      ),
    );
  }
}

