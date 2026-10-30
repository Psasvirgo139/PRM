class Product {
  final int? id;
  final int? categoryId;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final String createdAt;

  Product({
    this.id,
    this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    required this.stockQuantity,
    this.imageUrl = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isOutOfStock => stockQuantity <= 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as int?) ?? 0,
      imageUrl: (map['image_url'] as String?) ?? '',
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? imageUrl,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
