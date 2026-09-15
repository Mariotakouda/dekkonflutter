/// Helpers de parsing tolérants : un champ manquant/null/d'un type
/// légèrement différent ne doit jamais faire planter tout l'écran de détail
/// de commande — voir AdminOrderModel pour le même traitement côté admin.
String _str(Map<String, dynamic> json, String key, [String fallback = '']) {
  final v = json[key];
  return v?.toString() ?? fallback;
}

String? _strOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v?.toString();
}

double _num(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return 0;
  return double.tryParse(v.toString()) ?? 0;
}

int _int(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return 0;
  return int.tryParse(v.toString()) ?? 0;
}

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
      id: _str(json, 'id'),
      productName: _str(json, 'product_name', 'Article'),
      sku: _str(json, 'sku'),
      quantity: _int(json, 'quantity'),
      unitPrice: _num(json, 'unit_price'),
      totalAmount: _num(json, 'total_amount'),
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
    List<OrderItemModel> parseItems(dynamic raw) {
      if (raw is! List) return [];
      final result = <OrderItemModel>[];
      for (final i in raw) {
        if (i is Map<String, dynamic>) {
          try {
            result.add(OrderItemModel.fromJson(i));
          } catch (_) {
            // article individuel malformé : on l'ignore plutôt que de
            // faire planter toute la commande (et donc toute la liste).
          }
        }
      }
      return result;
    }

    return OrderModel(
      id: _str(json, 'id'),
      orderNumber: _str(json, 'order_number'),
      status: _str(json, 'status', 'PENDING'),
      subtotal: _num(json, 'subtotal'),
      discountAmount: _num(json, 'discount_amount'),
      deliveryFee: _num(json, 'delivery_fee'),
      totalAmount: _num(json, 'total_amount'),
      notes: _strOrNull(json, 'notes'),
      placedAt: DateTime.tryParse(_str(json, 'placed_at')) ?? DateTime.now(),
      items: parseItems(json['items']),
      address: json['address'] is Map<String, dynamic> ? json['address'] as Map<String, dynamic> : null,
      payment: json['payment'] is Map<String, dynamic> ? json['payment'] as Map<String, dynamic> : null,
      statusHistory: json['status_history'] is List
          ? (json['status_history'] as List).whereType<Map<String, dynamic>>().toList()
          : null,
    );
  }
}