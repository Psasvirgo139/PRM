class Voucher {
  final int? id;
  final String code;
  final String title;
  final String description;
  final String discountType; // 'FIXED', 'PERCENT', 'FREE_SHIP'
  final double discountValue; // Ví dụ: 20000 hoặc 10 (10%)
  final double minOrderValue; // Đơn tối thiểu
  final double maxDiscount; // Tối đa giảm (cho loại PERCENT)
  final String colorHex;
  final String createdAt;

  Voucher({
    this.id,
    required this.code,
    required this.title,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0.0,
    this.maxDiscount = 0.0,
    this.colorHex = '#FF9800',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isFixed => discountType == 'FIXED';
  bool get isPercent => discountType == 'PERCENT';
  bool get isFreeShip => discountType == 'FREE_SHIP';

  /// Tính số tiền thực tế được giảm dựa trên giá trị đơn hàng
  double calculateDiscount(double subtotal, {double shippingFee = 30000.0}) {
    if (subtotal < minOrderValue) return 0.0;

    if (isFreeShip) {
      return shippingFee;
    }

    if (isFixed) {
      return discountValue > subtotal ? subtotal : discountValue;
    }

    if (isPercent) {
      final calculated = subtotal * (discountValue / 100.0);
      if (maxDiscount > 0 && calculated > maxDiscount) {
        return maxDiscount;
      }
      return calculated;
    }

    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_value': minOrderValue,
      'max_discount': maxDiscount,
      'color_hex': colorHex,
      'created_at': createdAt,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] as int?,
      code: map['code'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      discountType: (map['discount_type'] as String?) ?? 'FIXED',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map['min_order_value'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble() ?? 0.0,
      colorHex: (map['color_hex'] as String?) ?? '#FF9800',
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }
}

class UserVoucher {
  final int? id;
  final int userId;
  final int voucherId;
  final bool isUsed;
  final String? usedAt;
  final String acquiredAt;
  final Voucher? voucher;

  UserVoucher({
    this.id,
    required this.userId,
    required this.voucherId,
    this.isUsed = false,
    this.usedAt,
    String? acquiredAt,
    this.voucher,
  }) : acquiredAt = acquiredAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'voucher_id': voucherId,
      'is_used': isUsed ? 1 : 0,
      'used_at': usedAt,
      'acquired_at': acquiredAt,
    };
  }

  factory UserVoucher.fromMap(Map<String, dynamic> map, {Voucher? voucher}) {
    return UserVoucher(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      voucherId: map['voucher_id'] as int,
      isUsed: (map['is_used'] as int?) == 1,
      usedAt: map['used_at'] as String?,
      acquiredAt: (map['acquired_at'] as String?) ?? '',
      voucher: voucher,
    );
  }
}

