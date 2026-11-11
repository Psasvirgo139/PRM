class OrderItem {
  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double subtotal;

  OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      productPrice: (map['product_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

class Order {
  final int? id;
  final int? userId; // ID của khách hàng đặt đơn
  final String orderCode;
  final String customerName;
  final String phone;
  final String address;
  final String note;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double finalAmount;
  final String paymentMethod;
  final String status; // PENDING, PROCESSING, COMPLETED, CANCELLED
  final String createdAt;
  final List<OrderItem> items;

  Order({
    this.id,
    this.userId,
    required this.orderCode,
    required this.customerName,
    required this.phone,
    required this.address,
    this.note = '',
    required this.subtotal,
    this.discount = 0.0,
    this.shippingFee = 0.0,
    required this.finalAmount,
    this.paymentMethod = 'COD',
    this.status = 'PENDING',
    String? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'order_code': orderCode,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'note': note,
      'subtotal': subtotal,
      'discount': discount,
      'shipping_fee': shippingFee,
      'final_amount': finalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) {
    return Order(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      orderCode: map['order_code'] as String,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      note: (map['note'] as String?) ?? '',
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['final_amount'] as num).toDouble(),
      paymentMethod: (map['payment_method'] as String?) ?? 'COD',
      status: (map['status'] as String?) ?? 'PENDING',
      createdAt: (map['created_at'] as String?) ?? '',
      items: items,
    );
  }
}
