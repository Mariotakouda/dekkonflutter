class CategoryAttributeModel {
  final String id;
  final String categoryId;
  final String key;
  final String label;
  final String type; // text | number | boolean | select | multiselect
  final List<String> options;
  final bool isRequired;
  final bool isVariantAttribute;
  final int sortOrder;

  CategoryAttributeModel({
    required this.id,
    required this.categoryId,
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    required this.isRequired,
    required this.isVariantAttribute,
    required this.sortOrder,
  });

  factory CategoryAttributeModel.fromJson(Map<String, dynamic> json) {
    return CategoryAttributeModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : [],
      isRequired: json['is_required'] as bool? ?? false,
      isVariantAttribute: json['is_variant_attribute'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class AdminProductVariantModel {
  final String id;
  final String sku;
  final String name;
  final double? price;
  final double effectivePrice;
  final Map<String, dynamic> attributes;
  final bool isActive;
  final bool isDefault;
  final Map<String, dynamic>? inventory;

  AdminProductVariantModel({
    required this.id,
    required this.sku,
    required this.name,
    this.price,
    required this.effectivePrice,
    required this.attributes,
    required this.isActive,
    required this.isDefault,
    this.inventory,
  });

  factory AdminProductVariantModel.fromJson(Map<String, dynamic> json) {
    return AdminProductVariantModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : null,
      effectivePrice: double.parse(
        (json['effective_price'] ?? json['price'] ?? 0).toString(),
      ),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      inventory: json['inventory'] as Map<String, dynamic>?,
    );
  }
}

class AdminProductImageModel {
  final String id;
  final String url;
  final String? altText;
  final int sortOrder;
  final bool isPrimary;

  AdminProductImageModel({
    required this.id,
    required this.url,
    this.altText,
    required this.sortOrder,
    required this.isPrimary,
  });

  factory AdminProductImageModel.fromJson(Map<String, dynamic> json) {
    return AdminProductImageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class AdminProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final double? costPrice;
  final String? brand;
  final double? weight;
  final String status;
  final bool isFeatured;
  final Map<String, dynamic>? category;
  final Map<String, dynamic> attributes;
  final List<AdminProductImageModel> images;
  final List<AdminProductVariantModel> variants;

  AdminProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    this.costPrice,
    this.brand,
    this.weight,
    required this.status,
    required this.isFeatured,
    this.category,
    this.attributes = const {},
    this.images = const [],
    this.variants = const [],
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    return AdminProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      price: double.parse(json['price'].toString()),
      compareAtPrice: json['compare_at_price'] != null ? double.parse(json['compare_at_price'].toString()) : null,
      costPrice: json['cost_price'] != null ? double.parse(json['cost_price'].toString()) : null,
      brand: json['brand'] as String?,
      weight: json['weight'] != null ? double.parse(json['weight'].toString()) : null,
      status: (json['status'] ?? 'DRAFT').toString(),
      isFeatured: json['is_featured'] as bool? ?? false,
      category: json['category'] as Map<String, dynamic>?,
      // Le backend peut renvoyer [] (tableau PHP vide) au lieu de {} quand il
      // n'y a pas d'attributs — on l'accepte sans planter.
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : <String, dynamic>{},
      images: json['images'] != null
          ? (json['images'] as List)
              .map((image) => AdminProductImageModel.fromJson(image as Map<String, dynamic>))
              .toList()
          : const [],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((variant) => AdminProductVariantModel.fromJson(variant as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).firstOrNull;
    return (primary ?? images.first).url;
  }
}

class AdminCategoryModel {
  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final int? productsCount;
  final List<AdminCategoryModel> children;
  final List<CategoryAttributeModel> attributes;


  AdminCategoryModel({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    this.productsCount,
    this.children = const [],
    this.attributes = const [],

  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      productsCount: json['products_count'] as int?,
      children: json['children'] != null
          ? (json['children'] as List).map((c) => AdminCategoryModel.fromJson(c as Map<String, dynamic>)).toList()
          : [],
      attributes: json['attributes'] != null
          ? (json['attributes'] as List).map((a) => CategoryAttributeModel.fromJson(a as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class AdminPaginatedProducts<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedProducts({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}