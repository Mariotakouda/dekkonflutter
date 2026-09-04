class CartItemModel {
  final String id;
  final String productVariantId;
  final String productName;
  final String variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final int availableQuantity;
  final bool isAvailable;

  CartItemModel({
    required this.id,
    required this.productVariantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.availableQuantity,
    required this.isAvailable,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productVariantId: json['product_variant_id'] as String,
      productName: json['product_name'] as String,
      variantName: json['variant_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      lineTotal: double.parse(json['line_total'].toString()),
      availableQuantity: json['available_quantity'] as int,
      isAvailable: json['is_available'] as bool,
    );
  }
}

class CartModel {
  final String id;
  final String status;
  final List<CartItemModel> items;
  final double subtotal;
  final bool hasUnavailableItems;

  CartModel({
    required this.id,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.hasUnavailableItems,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as String,
      status: json['status'] as String,
      items: (json['items'] as List)
          .map((i) => CartItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: double.parse(json['subtotal'].toString()),
      hasUnavailableItems: json['has_unavailable_items'] as bool? ?? false,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
}