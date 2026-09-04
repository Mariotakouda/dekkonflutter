class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}