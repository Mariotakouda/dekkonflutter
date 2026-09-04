/// Wrapper générique correspondant au format JSON uniforme du backend
/// ({success, message, data, meta}) — voir ApiResponse.php côté Laravel.
class ApiResponseWrapper<T> {
  final bool success;
  final String? message;
  final T? data;
  final PaginationMeta? meta;

  ApiResponseWrapper({
    required this.success,
    this.message,
    this.data,
    this.meta,
  });

  factory ApiResponseWrapper.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponseWrapper<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      meta: json['meta'] != null ? PaginationMeta.fromJson(json['meta']) : null,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}