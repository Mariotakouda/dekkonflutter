class ProductVariantModel {
  final String id;
  final String sku;
  final String name;
  final double price;
  final Map<String, dynamic> attributes;
  final bool isDefault;
  final int availableQuantity;
  final bool inStock;

  ProductVariantModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.attributes,
    required this.isDefault,
    required this.availableQuantity,
    required this.inStock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      isDefault: json['is_default'] as bool? ?? false,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? false,
    );
  }
}

class ProductImageModel {
  final String url;
  final String? altText;
  final bool isPrimary;

  ProductImageModel({required this.url, this.altText, required this.isPrimary});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final String? brand;
  final bool isFeatured;
  final List<ProductImageModel> images;
  final List<ProductVariantModel> variants;
  final double? averageRating;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    this.brand,
    required this.isFeatured,
    this.images = const [],
    this.variants = const [],
    this.averageRating,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      price: double.parse(json['price'].toString()),
      compareAtPrice: json['compare_at_price'] != null
          ? double.parse(json['compare_at_price'].toString())
          : null,
      brand: json['brand'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((i) => ProductImageModel.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
              .toList()
          : [],
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : null,
    );
  }

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).firstOrNull;
    return (primary ?? images.first).url;
  }

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((compareAtPrice! - price) / compareAtPrice! * 100).roundToDouble();
  }
}

/// Résultat paginé générique, réutilisable pour toute liste (produits, commandes, avis...).
class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}