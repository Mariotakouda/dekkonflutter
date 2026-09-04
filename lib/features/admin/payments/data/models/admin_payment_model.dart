class AdminPaymentModel {
  final String id;
  final Map<String, dynamic>? order;
  final String method;
  final String status;
  final double amount;
  final String? provider;
  final String? transactionReference;
  final DateTime? paidAt;
  final DateTime createdAt;

  AdminPaymentModel({
    required this.id,
    this.order,
    required this.method,
    required this.status,
    required this.amount,
    this.provider,
    this.transactionReference,
    this.paidAt,
    required this.createdAt,
  });

  factory AdminPaymentModel.fromJson(Map<String, dynamic> json) {
    return AdminPaymentModel(
      id: json['id'] as String,
      order: json['order'] as Map<String, dynamic>?,
      method: json['method'] as String,
      status: json['status'] as String,
      amount: double.parse(json['amount'].toString()),
      provider: json['provider'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminPaginatedPayments<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedPayments({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}