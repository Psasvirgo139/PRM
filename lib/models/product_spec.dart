import 'package:flutter/material.dart';

/// Đại diện cho một dòng thông số kỹ thuật chi tiết
class SpecItem {
  final String key;
  final String label;
  final String value;
  final double? numericValue; // Dùng để tính toán so sánh số liệu (RAM, Pin, MHz...)
  final String? unit; // Đơn vị: GB, mAh, W, inch, g, MP...
  final bool isHigherBetter; // True: số càng cao càng tốt; False: số càng thấp càng tốt (trọng lượng)
  final String? highlightBadge; // Ví dụ: "Vượt trội", "Mạnh nhất", "Pin trâu"

  const SpecItem({
    required this.key,
    required this.label,
    required this.value,
    this.numericValue,
    this.unit,
    this.isHigherBetter = true,
    this.highlightBadge,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        'label': label,
        'value': value,
        'numericValue': numericValue,
        'unit': unit,
        'isHigherBetter': isHigherBetter,
        'highlightBadge': highlightBadge,
      };

  factory SpecItem.fromMap(Map<String, dynamic> map) => SpecItem(
        key: map['key'] as String,
        label: map['label'] as String,
        value: map['value'] as String,
        numericValue: (map['numericValue'] as num?)?.toDouble(),
        unit: map['unit'] as String?,
        isHigherBetter: (map['isHigherBetter'] as bool?) ?? true,
        highlightBadge: map['highlightBadge'] as String?,
      );

  SpecItem copyWith({
    String? key,
    String? label,
    String? value,
    double? numericValue,
    String? unit,
    bool? isHigherBetter,
    String? highlightBadge,
  }) {
    return SpecItem(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      numericValue: numericValue ?? this.numericValue,
      unit: unit ?? this.unit,
      isHigherBetter: isHigherBetter ?? this.isHigherBetter,
      highlightBadge: highlightBadge ?? this.highlightBadge,
    );
  }
}

/// Nhóm thông số (ví dụ: Hiệu năng & Vi xử lý, Màn hình, Pin & Sạc...)
class SpecGroup {
  final String id;
  final String name;
  final IconData icon;
  final List<SpecItem> items;

  const SpecGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
  });
}

/// Toàn bộ bảng thông số của 1 sản phẩm
class ProductSpecs {
  final int productId;
  final String productName;
  final String categoryName;
  final List<SpecGroup> groups;

  const ProductSpecs({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.groups,
  });

  SpecItem? findSpec(String key) {
    for (final group in groups) {
      for (final item in group.items) {
        if (item.key == key) return item;
      }
    }
    return null;
  }
}

/// Kết quả so sánh giữa nhiều thông số của các sản phẩm
class SpecComparisonResult {
  final SpecItem referenceItem;
  final List<SpecItem?> productItems;
  final bool isDifferent;
  final int? bestProductIndex; // Index của sản phẩm có thông số tốt nhất trong hàng

  const SpecComparisonResult({
    required this.referenceItem,
    required this.productItems,
    required this.isDifferent,
    this.bestProductIndex,
  });
}

