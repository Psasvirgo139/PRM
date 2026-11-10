import 'package:flutter/material.dart';

class WheelPointer extends StatelessWidget {
  const WheelPointer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 46),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    // Tam giác hướng xuống
    path.moveTo(size.width / 2, size.height); // Đỉnh nhọn chúc xuống
    path.lineTo(size.width, size.height * 0.25);
    path.arcToPoint(
      Offset(0, size.height * 0.25),
      radius: Radius.circular(size.width / 2),
      clockwise: false,
    );
    path.close();

    // Bóng đổ của kim
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    // Thân kim màu vàng kim loại / đỏ nổi bật
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF1744), Color(0xFFD50000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Viền kim màu vàng bóng
    final strokePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // Chốt tròn ở đỉnh kim
    final circlePaint = Paint()..color = const Color(0xFFFFE082);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 5, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

