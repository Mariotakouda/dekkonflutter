class AdminPromotionModel {
  final String id;
  final String name;
  final String code;
  final String type;
  final double value;
  final double? minimumAmount;
  final double? maximumDiscountAmount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final bool isValid;
  final int? productsCount;

  AdminPromotionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.value,
    this.minimumAmount,
    this.maximumDiscountAmount,
    this.startsAt,
    this.endsAt,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
    required this.isValid,
    this.productsCount,
  });

  factory AdminPromotionModel.fromJson(Map<String, dynamic> json) {
    return AdminPromotionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
      value: double.parse(json['value'].toString()),
      minimumAmount: json['minimum_amount'] != null ? double.parse(json['minimum_amount'].toString()) : null,
      maximumDiscountAmount:
          json['maximum_discount_amount'] != null ? double.parse(json['maximum_discount_amount'].toString()) : null,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at'] as String) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isValid: json['is_valid'] as bool? ?? false,
      productsCount: json['products_count'] as int?,
    );
  }

  String get valueLabel => type == 'PERCENTAGE' ? '${value.toInt()}%' : '${value.toInt()} FCFA';
}

class AdminPaginatedPromotions<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedPromotions({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}