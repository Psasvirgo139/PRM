class CartItem {
  final int? id;
  final int? userId;
  final int productId;
  final String productName;
  final double productPrice;
  final String productImageUrl;
  final int availableStock;
  int quantity;

  CartItem({
    this.id,
    this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImageUrl = '',
    required this.availableStock,
    this.quantity = 1,
  });

  double get subtotal => productPrice * quantity;

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toOrderItemMap(int orderId) {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromDbJoin(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      productId: map['product_id'] as int,
      productName: (map['name'] as String?) ?? 'Sản phẩm',
      productPrice: (map['price'] as num?)?.toDouble() ?? 0.0,
      productImageUrl: (map['image_url'] as String?) ?? '',
      availableStock: (map['stock_quantity'] as int?) ?? 0,
      quantity: (map['quantity'] as int?) ?? 1,
    );
  }
}
