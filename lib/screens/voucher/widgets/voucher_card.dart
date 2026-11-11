import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/voucher.dart';

class VoucherCard extends StatelessWidget {
  final UserVoucher userVoucher;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onSelect;

  const VoucherCard({
    super.key,
    required this.userVoucher,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final voucher = userVoucher.voucher;
    if (voucher == null) return const SizedBox.shrink();

    final isUsed = userVoucher.isUsed;
    final primaryColor = isUsed
        ? Colors.grey.shade400
        : _parseColor(voucher.colorHex, defaultColor: Colors.deepPurple);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.deepPurple
              : (isUsed ? Colors.grey.shade300 : primaryColor.withValues(alpha: 0.3)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Cột bên trái: Badge giảm giá & icon
            Container(
              width: 95,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUsed ? Colors.grey.shade200 : primaryColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    voucher.isFreeShip
                        ? Icons.local_shipping_rounded
                        : (voucher.isPercent ? Icons.percent_rounded : Icons.confirmation_number_rounded),
                    color: primaryColor,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    voucher.isPercent
                        ? 'GIẢM ${voucher.discountValue.toInt()}%'
                        : (voucher.isFreeShip ? 'FREESHIP' : CurrencyFormatter.format(voucher.discountValue)),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Đường rãnh xé vé đứt đoạn
            CustomPaint(
              size: const Size(1, double.infinity),
              painter: _DashedLinePainter(color: Colors.grey.shade300),
            ),

            // Cột bên phải: Tiêu đề, Mã, Điều kiện & Nút dùng
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tiêu đề
                    Text(
                      voucher.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isUsed ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Mô tả / Điều kiện
                    Text(
                      voucher.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Mã code & Nút tương tác
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chip hiển thị mã
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: voucher.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã sao chép mã: ${voucher.code}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  voucher.code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        // Nút hành động
                        if (isSelectable)
                          FilledButton(
                            onPressed: isUsed ? null : onSelect,
                            style: FilledButton.styleFrom(
                              backgroundColor: isSelected ? Colors.green : Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              isSelected ? 'Đang chọn' : 'Áp dụng',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          )
                        else if (isUsed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Đã dùng',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              context.push('/cart');
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Dùng ngay ➔', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex, {Color defaultColor = Colors.deepPurple}) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 6.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    while (startY < size.height - 6.0) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

