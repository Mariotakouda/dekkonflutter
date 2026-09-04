class OrderItemModel {
  final String id;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalAmount;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double totalAmount;
  final String? notes;
  final DateTime placedAt;
  final List<OrderItemModel> items;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? payment;
  final List<Map<String, dynamic>>? statusHistory;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.totalAmount,
    this.notes,
    required this.placedAt,
    this.items = const [],
    this.address,
    this.payment,
    this.statusHistory,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      deliveryFee: double.parse(json['delivery_fee'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      notes: json['notes'] as String?,
      placedAt: DateTime.parse(json['placed_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      address: json['address'] as Map<String, dynamic>?,
      payment: json['payment'] as Map<String, dynamic>?,
      statusHistory: json['status_history'] != null
          ? List<Map<String, dynamic>>.from(json['status_history'] as List)
          : null,
    );
  }
}