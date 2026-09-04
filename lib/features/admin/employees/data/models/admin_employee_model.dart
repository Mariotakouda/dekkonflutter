class AdminRoleModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isSystem;
  final int? usersCount;
  final List<AdminPermissionModel> permissions;

  AdminRoleModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isSystem,
    this.usersCount,
    this.permissions = const [],
  });

  factory AdminRoleModel.fromJson(Map<String, dynamic> json) {
    return AdminRoleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      usersCount: json['users_count'] as int?,
      permissions: json['permissions'] != null
          ? (json['permissions'] as List).map((p) => AdminPermissionModel.fromJson(p as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class AdminPermissionModel {
  final String id;
  final String name;
  final String code;
  final String? description;

  AdminPermissionModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory AdminPermissionModel.fromJson(Map<String, dynamic> json) {
    return AdminPermissionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
    );
  }
}

class AdminEmployeeModel {
  final String id;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String? position;
  final String? dateHiredAt;
  final String? gender;
  final String status;
  final Map<String, dynamic>? user;
  final bool isDriver;

  AdminEmployeeModel({
    required this.id,
    required this.employeeNumber,
    required this.firstName,
    required this.lastName,
    this.position,
    this.dateHiredAt,
    this.gender,
    required this.status,
    this.user,
    required this.isDriver,
  });

  factory AdminEmployeeModel.fromJson(Map<String, dynamic> json) {
    return AdminEmployeeModel(
      id: json['id'] as String,
      employeeNumber: json['employee_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      position: json['position'] as String?,
      dateHiredAt: json['date_hired_at'] as String?,
      gender: json['gender'] as String?,
      status: json['status'] as String,
      user: json['user'] as Map<String, dynamic>?,
      isDriver: json['is_driver'] as bool? ?? false,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String? get roleName => (user?['role'] as Map<String, dynamic>?)?['name'] as String?;
}

class AdminPaginatedEmployees<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  AdminPaginatedEmployees({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}