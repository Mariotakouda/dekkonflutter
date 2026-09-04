class ReviewModel {
  final String id;
  final int rating;
  final String? comment;
  final String status;
  final Map<String, dynamic>? product;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.status,
    this.product,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      status: json['status'] as String,
      product: json['product'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}