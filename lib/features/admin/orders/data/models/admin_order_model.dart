/// Petits helpers de parsing tolérants : une valeur manquante, nulle ou d'un
/// type légèrement différent (ex. int envoyé là où on attend un double) ne
/// doit jamais faire planter tout l'écran de détail — au pire on affiche un
/// champ vide/à 0, jamais une page d'erreur générique.
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

DateTime? _dateOrNull(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

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
      id: _str(json, 'id'),
      productName: _str(json, 'product_name', 'Article'),
      sku: _str(json, 'sku'),
      quantity: _int(json, 'quantity'),
      unitPrice: _num(json, 'unit_price'),
      totalAmount: _num(json, 'total_amount'),
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
      id: _str(json, 'id'),
      name: _str(json, 'name', 'Client'),
      phone: _strOrNull(json, 'phone'),
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
    // Certains items/entrées d'historique peuvent, selon la ressource
    // Laravel utilisée, arriver dans une forme inattendue (ex. un objet
    // au lieu d'une liste, ou un champ manquant sur une commande ancienne).
    // On les ignore individuellement plutôt que de faire planter tout
    // l'écran de détail — mieux vaut une commande incomplète qu'une page
    // d'erreur générique "impossible de charger cette commande".
    List<AdminOrderItemModel> parseItems(dynamic raw) {
      if (raw is! List) return [];
      final result = <AdminOrderItemModel>[];
      for (final i in raw) {
        if (i is Map<String, dynamic>) {
          try {
            result.add(AdminOrderItemModel.fromJson(i));
          } catch (_) {
            // item individuel malformé : on l'ignore plutôt que de tout casser
          }
        }
      }
      return result;
    }

    List<Map<String, dynamic>>? parseMapList(dynamic raw) {
      if (raw is! List) return null;
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    return AdminOrderModel(
      id: _str(json, 'id'),
      orderNumber: _str(json, 'order_number'),
      status: _str(json, 'status', 'PENDING'),
      customer: json['customer'] is Map<String, dynamic>
          ? AdminOrderCustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      subtotal: _num(json, 'subtotal'),
      discountAmount: _num(json, 'discount_amount'),
      deliveryFee: _num(json, 'delivery_fee'),
      totalAmount: _num(json, 'total_amount'),
      notes: _strOrNull(json, 'notes'),
      placedAt: _dateOrNull(json, 'placed_at') ?? DateTime.now(),
      confirmedAt: _dateOrNull(json, 'confirmed_at'),
      deliveredAt: _dateOrNull(json, 'delivered_at'),
      cancelledAt: _dateOrNull(json, 'cancelled_at'),
      items: parseItems(json['items']),
      address: json['address'] is Map<String, dynamic> ? json['address'] as Map<String, dynamic> : null,
      payments: parseMapList(json['payments']),
      delivery: json['delivery'] is Map<String, dynamic> ? json['delivery'] as Map<String, dynamic> : null,
      statusHistory: parseMapList(json['status_history']),
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