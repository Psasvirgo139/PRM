import 'package:flutter/material.dart';

enum WheelSliceType {
  voucher,
  extraSpin,
  noLuck,
}

class WheelSlice {
  final int index;
  final String label;
  final String subLabel;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final WheelSliceType type;
  final String? voucherCode; // Khớp với voucher.code nếu là loại voucher
  final int weight; // Trọng số xác suất trúng (càng lớn càng dễ trúng)

  const WheelSlice({
    required this.index,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.type,
    this.voucherCode,
    this.weight = 10,
  });

  bool get isVoucher => type == WheelSliceType.voucher;
  bool get isExtraSpin => type == WheelSliceType.extraSpin;
  bool get isNoLuck => type == WheelSliceType.noLuck;
}

/// Danh sách cấu hình 8 nan của Vòng quay may mắn
class DefaultWheelConfig {
  static const List<WheelSlice> slices = [
    // 1. Giảm 20.000₫ (Màu Đỏ Cam)
    WheelSlice(
      index: 0,
      label: '20.000₫',
      subLabel: 'Đơn từ 200k',
      icon: Icons.confirmation_number_rounded,
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFF5252),
      type: WheelSliceType.voucher,
      voucherCode: 'LUCKY20K',
      weight: 20,
    ),

    // 2. Thêm 1 lượt quay (Màu Kem Vàng)
    WheelSlice(
      index: 1,
      label: '+1 LƯỢT',
      subLabel: 'Quay tiếp',
      icon: Icons.replay_rounded,
      primaryColor: Color(0xFFFFF3D6),
      secondaryColor: Color(0xFFFFFBEB),
      type: WheelSliceType.extraSpin,
      weight: 15,
    ),

    // 3. Giảm 50.000₫ (Màu Đỏ Cam)
    WheelSlice(
      index: 2,
      label: '50.000₫',
      subLabel: 'Đơn từ 500k',
      icon: Icons.redeem_rounded,
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFF5252),
      type: WheelSliceType.voucher,
      voucherCode: 'SUPER50K',
      weight: 10,
    ),

    // 4. Chúc bạn may mắn lần sau (Màu Kem Vàng)
    WheelSlice(
      index: 3,
      label: 'MAY MẮN',
      subLabel: 'Lần sau nhé',
      icon: Icons.sentiment_satisfied_alt_rounded,
      primaryColor: Color(0xFFFFF3D6),
      secondaryColor: Color(0xFFFFFBEB),
      type: WheelSliceType.noLuck,
      weight: 25,
    ),

    // 5. Giảm 10% (Màu Đỏ Cam)
    WheelSlice(
      index: 4,
      label: 'GIẢM 10%',
      subLabel: 'Tối đa 100k',
      icon: Icons.percent_rounded,
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFF5252),
      type: WheelSliceType.voucher,
      voucherCode: 'SALE10',
      weight: 12,
    ),

    // 6. Miễn phí vận chuyển (Màu Kem Vàng)
    WheelSlice(
      index: 5,
      label: 'FREE SHIP',
      subLabel: 'Đơn từ 150k',
      icon: Icons.local_shipping_rounded,
      primaryColor: Color(0xFFFFF3D6),
      secondaryColor: Color(0xFFFFFBEB),
      type: WheelSliceType.voucher,
      voucherCode: 'FREESHIP',
      weight: 15,
    ),

    // 7. Giảm 100.000₫ (Màu Đỏ Cam VIP)
    WheelSlice(
      index: 6,
      label: '100.000₫',
      subLabel: 'Đơn từ 1tr',
      icon: Icons.workspace_premium_rounded,
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFF5252),
      type: WheelSliceType.voucher,
      voucherCode: 'VIP100K',
      weight: 5,
    ),

    // 8. Giảm 30.000₫ (Màu Kem Vàng)
    WheelSlice(
      index: 7,
      label: '30.000₫',
      subLabel: 'Đơn từ 250k',
      icon: Icons.bolt_rounded,
      primaryColor: Color(0xFFFFF3D6),
      secondaryColor: Color(0xFFFFFBEB),
      type: WheelSliceType.voucher,
      voucherCode: 'FLASH30K',
      weight: 15,
    ),
  ];
}

