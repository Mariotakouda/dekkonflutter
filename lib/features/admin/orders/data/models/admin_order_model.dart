class AdminOrderItemModel {
  final String id;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalAmount;

  AdminOrderItemModel({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderItemModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
    );
  }
}

class AdminOrderCustomerModel {
  final String id;
  final String name;
  final String? phone;

  AdminOrderCustomerModel({required this.id, required this.name, this.phone});

  factory AdminOrderCustomerModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderCustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class AdminOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final AdminOrderCustomerModel? customer;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double totalAmount;
  final String? notes;
  final DateTime placedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final List<AdminOrderItemModel> items;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>>? payments;
  final Map<String, dynamic>? delivery;
  final List<Map<String, dynamic>>? statusHistory;

  AdminOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customer,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.totalAmount,
    this.notes,
    required this.placedAt,
    this.confirmedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.items = const [],
    this.address,
    this.payments,
    this.delivery,
    this.statusHistory,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      customer: json['customer'] != null
          ? AdminOrderCustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      deliveryFee: double.parse(json['delivery_fee'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      notes: json['notes'] as String?,
      placedAt: DateTime.parse(json['placed_at'] as String),
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => AdminOrderItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      address: json['address'] as Map<String, dynamic>?,
      payments: json['payments'] != null ? List<Map<String, dynamic>>.from(json['payments'] as List) : null,
      delivery: json['delivery'] as Map<String, dynamic>?,
      statusHistory: json['status_history'] != null
          ? List<Map<String, dynamic>>.from(json['status_history'] as List)
          : null,
    );
  }
}

class AdminPaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}