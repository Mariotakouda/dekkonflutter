class AdminInventoryVariantModel {
  final String id;
  final String sku;
  final String name;
  final String productName;

  AdminInventoryVariantModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.productName,
  });

  factory AdminInventoryVariantModel.fromJson(Map<String, dynamic> json) {
    return AdminInventoryVariantModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      productName: json['product_name'] as String,
    );
  }
}

class AdminInventoryModel {
  final String id;
  final AdminInventoryVariantModel? variant;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int lowStockThreshold;
  final bool isLowStock;

  AdminInventoryModel({
    required this.id,
    this.variant,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.lowStockThreshold,
    required this.isLowStock,
  });

  factory AdminInventoryModel.fromJson(Map<String, dynamic> json) {
    return AdminInventoryModel(
      id: json['id'] as String,
      variant: json['variant'] != null
          ? AdminInventoryVariantModel.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      reservedQuantity: json['reserved_quantity'] as int,
      availableQuantity: json['available_quantity'] as int,
      lowStockThreshold: json['low_stock_threshold'] as int,
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );
  }
}

class AdminStockMovementModel {
  final String id;
  final Map<String, dynamic>? variant;
  final String type;
  final int quantity;
  final String? reason;
  final Map<String, dynamic>? user;
  final DateTime createdAt;

  AdminStockMovementModel({
    required this.id,
    this.variant,
    required this.type,
    required this.quantity,
    this.reason,
    this.user,
    required this.createdAt,
  });

  factory AdminStockMovementModel.fromJson(Map<String, dynamic> json) {
    return AdminStockMovementModel(
      id: json['id'] as String,
      variant: json['variant'] as Map<String, dynamic>?,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      reason: json['reason'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminPaginatedInventory<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedInventory({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}