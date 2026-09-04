class AdminDriverModel {
  final String id;
  final String name;
  final String? vehicleType;
  final String? vehicleNumber;
  final String status;
  final int? activeDeliveriesCount;

  AdminDriverModel({
    required this.id,
    required this.name,
    this.vehicleType,
    this.vehicleNumber,
    required this.status,
    this.activeDeliveriesCount,
  });

  factory AdminDriverModel.fromJson(Map<String, dynamic> json) {
    return AdminDriverModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      status: json['status'] as String,
      activeDeliveriesCount: json['active_deliveries_count'] as int?,
    );
  }
}

class AdminDeliveryModel {
  final String id;
  final Map<String, dynamic>? order;
  final AdminDriverModel? driver;
  final String status;
  final double deliveryFee;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final String? failureReason;

  AdminDeliveryModel({
    required this.id,
    this.order,
    this.driver,
    required this.status,
    required this.deliveryFee,
    this.assignedAt,
    this.pickedUpAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.failedAt,
    this.failureReason,
  });

  factory AdminDeliveryModel.fromJson(Map<String, dynamic> json) {
    return AdminDeliveryModel(
      id: json['id'] as String,
      order: json['order'] as Map<String, dynamic>?,
      driver: json['driver'] != null ? AdminDriverModel.fromJson(json['driver'] as Map<String, dynamic>) : null,
      status: json['status'] as String,
      deliveryFee: double.parse(json['delivery_fee'].toString()),
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at'] as String) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.parse(json['picked_up_at'] as String) : null,
      outForDeliveryAt: json['out_for_delivery_at'] != null ? DateTime.parse(json['out_for_delivery_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      failedAt: json['failed_at'] != null ? DateTime.parse(json['failed_at'] as String) : null,
      failureReason: json['failure_reason'] as String?,
    );
  }
}

class AdminPaginatedDeliveries<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedDeliveries({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}