import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Logo Vòng Quay May Mắn vẽ vector chuẩn theo mẫu thiết kế
/// Gồm: Chân đế hình thang, 2 vòng tròn đồng tâm, 12 nan hoa, trục giữa và kim chỉ giọt nước
class LuckyWheelLogo extends StatelessWidget {
  final double size;
  final Color strokeColor;
  final Color fillColor;

  const LuckyWheelLogo({
    super.key,
    this.size = 28,
    this.strokeColor = const Color(0xFF1E1E1E),
    this.fillColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LuckyWheelLogoPainter(
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _LuckyWheelLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;

  _LuckyWheelLogoPainter({
    required this.strokeColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Tỉ lệ scale dựa trên canvas 100x100
    final double s = math.min(w, h) / 100.0;
    final double strokeWidth = math.max(1.2, 4.4 * s);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Tọa độ tâm bánh xe (hơi dịch lên trên để chừa chỗ cho chân đế)
    final double cx = w / 2.0;
    final double cy = 48.0 * s;

    // Bán kính các vòng tròn
    final double rOuter = 36.5 * s;
    final double rInner = 29.5 * s;
    final double rHub = 6.2 * s;

    // ── 1. Vẽ Chân đế hình thang (Stand/Base) ──
    final double baseY = 91.0 * s;
    final double baseHalfW = 16.5 * s;
    final double baseLeftX = cx - baseHalfW;
    final double baseRightX = cx + baseHalfW;

    // Điểm tiếp xúc của 2 chân lên vòng ngoài (khoảng góc 65° và 115°)
    final double attachAngle = 65.0 * math.pi / 180.0;
    final double attachDx = rOuter * math.cos(attachAngle);
    final double attachDy = rOuter * math.sin(attachAngle);
    final double legLeftX = cx - attachDx;
    final double legRightX = cx + attachDx;
    final double legTopY = cy + attachDy;

    final basePath = Path()
      ..moveTo(baseLeftX, baseY)
      ..lineTo(baseRightX, baseY)
      ..lineTo(legRightX, legTopY)
      ..lineTo(legLeftX, legTopY)
      ..close();

    // Fill nền trắng cho chân đế để không bị lọt nền sau, sau đó vẽ viền
    canvas.drawPath(basePath, fillPaint);
    canvas.drawPath(basePath, strokePaint);

    // ── 2. Vẽ Vòng tròn ngoài & Vòng tròn trong (Double Rim) ──
    // Fill nền trắng cho lòng bánh xe
    canvas.drawCircle(Offset(cx, cy), rOuter, fillPaint);

    // Vẽ 12 nan hoa (Spokes) tỏa ra từ tâm
    for (int i = 0; i < 12; i++) {
      final double angle = (i * 30.0) * math.pi / 180.0;
      final double startX = cx + rHub * math.cos(angle);
      final double startY = cy + rHub * math.sin(angle);
      final double endX = cx + rOuter * math.cos(angle);
      final double endY = cy + rOuter * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), strokePaint);
    }

    // Vẽ vòng tròn trong (Inner Circle)
    canvas.drawCircle(Offset(cx, cy), rInner, strokePaint);

    // Vẽ vòng tròn ngoài (Outer Circle)
    canvas.drawCircle(Offset(cx, cy), rOuter, strokePaint);

    // ── 3. Vẽ Trục giữa (Center Hub) ──
    // Đè nền trắng để che các đầu nan hoa, sau đó vẽ viền tròn
    canvas.drawCircle(Offset(cx, cy), rHub, fillPaint);
    canvas.drawCircle(Offset(cx, cy), rHub, strokePaint);

    // ── 4. Vẽ Kim chỉ giọt nước (Top Pointer) ở vị trí 12 giờ ──
    // Đỉnh trên dạng vòm tròn nhô ra khỏi vòng ngoài, mũi nhọn chúc xuống
    final double pointerTipY = cy - rInner + (4.0 * s); // Chúc xuống qua vành ngoài
    final double pointerHalfW = 4.8 * s;
    final double arcCenterY = cy - rOuter - (3.5 * s);

    final pointerPath = Path()
      ..moveTo(cx, pointerTipY)
      ..lineTo(cx + pointerHalfW, arcCenterY)
      ..arcToPoint(
        Offset(cx - pointerHalfW, arcCenterY),
        radius: Radius.circular(pointerHalfW),
        clockwise: false,
      )
      ..close();

    // Fill nền trắng để che đè lên đường viền bánh xe bên dưới, rồi vẽ viền đen
    canvas.drawPath(pointerPath, fillPaint);
    canvas.drawPath(pointerPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _LuckyWheelLogoPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor || oldDelegate.fillColor != fillColor;
  }
}
