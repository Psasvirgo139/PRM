import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/wheel_slice.dart';

class WheelPainter extends CustomPainter {
  final List<WheelSlice> slices;

  WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final sliceAngle = (2 * pi) / slices.length;

    // 1. Vẽ bóng đổ phía sau và vành khung đỏ san hô (Coral-Red) theo phong cách ảnh mẫu
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center + const Offset(0, 8), radius, shadowPaint);

    // Vành khung đỏ cam rực rỡ
    final outerRimPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFF5722), Color(0xFFE53935), Color(0xFFB71C1C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outerRimPaint);

    // Đường viền vàng bóng kim loại ở mép ngoài
    final outerGoldBorder = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1.5, outerGoldBorder);

    // 2. Viền bóng đèn LED màu trắng sáng xung quanh
    final rimRadius = radius - 10;
    final innerWheelRadius = rimRadius - 8;

    // Vẽ các chấm đèn LED viền ngoài (màu trắng sáng xen kẽ ánh vàng kim)
    final dotCount = 16;
    final dotRadius = 4.2;
    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * pi / dotCount) * i;
      final dotCenter = Offset(
        center.dx + (rimRadius - 2) * cos(angle),
        center.dy + (rimRadius - 2) * sin(angle),
      );
      final isBulbOn = i % 2 == 0;
      final bulbPaint = Paint()
        ..color = isBulbOn ? Colors.white : const Color(0xFFFFF9C4);
      canvas.drawCircle(dotCenter, dotRadius, bulbPaint);
    }

    // Vòng chỉ vàng ngăn cách vành đỏ với các nan quạt
    final innerGoldBorder = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerWheelRadius, innerGoldBorder);

    // 3. Vẽ từng nan quạt xen kẽ Đỏ San Hô và Kem Vàng
    for (int i = 0; i < slices.length; i++) {
      final startAngle = i * sliceAngle;
      final slice = slices[i];

      final arcRect = Rect.fromCircle(center: center, radius: innerWheelRadius);
      final slicePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [slice.secondaryColor, slice.primaryColor],
        ).createShader(arcRect);

      canvas.drawArc(arcRect, startAngle, sliceAngle, true, slicePaint);

      // Đường viền ngăn cách màu vàng kim tinh tế giữa các nan
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawArc(arcRect, startAngle, sliceAngle, true, borderPaint);

      // 4. Vẽ Text và Icon xoay theo hướng nan quạt
      _drawSliceContent(
        canvas: canvas,
        center: center,
        radius: innerWheelRadius,
        sliceAngle: sliceAngle,
        currentSliceAngle: startAngle + sliceAngle / 2,
        slice: slice,
      );
    }

    // 5. Viền vòng tròn trung tâm (Center Hub vàng kim phối đỏ)
    final centerHubRadius = radius * 0.23;
    final hubOuterPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFECB3), Color(0xFFFFD54F), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: center, radius: centerHubRadius));
    canvas.drawCircle(center, centerHubRadius, hubOuterPaint);

    final hubInnerPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerHubRadius - 4, hubInnerPaint);
  }

  void _drawSliceContent({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double sliceAngle,
    required double currentSliceAngle,
    required WheelSlice slice,
  }) {
    canvas.save();

    // Di chuyển gốc tọa độ về tâm và xoay theo góc giữa nan
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentSliceAngle);

    // Xác định màu sắc nội dung nan: Nan kem chữ đỏ, Nan đỏ chữ vàng/trắng
    final isCreamSlice = slice.index % 2 == 1;
    final contentColor = isCreamSlice ? const Color(0xFFC62828) : const Color(0xFFFFFDE7);
    final shadowColor = isCreamSlice ? Colors.black12 : Colors.black45;

    // Vẽ Icon phía gần viền ngoài
    final iconSpan = TextSpan(
      text: String.fromCharCode(slice.icon.codePoint),
      style: TextStyle(
        fontFamily: slice.icon.fontFamily,
        package: slice.icon.fontPackage,
        fontSize: 22,
        color: contentColor,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: shadowColor, blurRadius: 3, offset: const Offset(1, 1)),
        ],
      ),
    );

    final iconPainter = TextPainter(
      text: iconSpan,
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(radius * 0.72 - iconPainter.width / 2, -iconPainter.height / 2),
    );

    // Vẽ Nhãn chính (ví dụ: '20.000₫', 'GIẢM 10%', '+1 LƯỢT')
    final labelSpan = TextSpan(
      text: slice.label,
      style: TextStyle(
        color: contentColor,
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
        shadows: [
          Shadow(color: shadowColor, blurRadius: 2, offset: const Offset(1, 1)),
        ],
      ),
    );

    final labelPainter = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(radius * 0.46 - labelPainter.width / 2, -labelPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

