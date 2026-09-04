class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final CustomerModel? customer;
  final EmployeeModel? employee;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.customer,
    this.employee,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: json['status'] as String,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      employee: json['employee'] != null
          ? EmployeeModel.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isEmployee => employee != null;
}

class CustomerModel {
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;

  CustomerModel({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class EmployeeRoleModel {
  final String code;
  final String name;

  EmployeeRoleModel({required this.code, required this.name});

  factory EmployeeRoleModel.fromJson(Map<String, dynamic> json) {
    return EmployeeRoleModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

/// Regroupe les codes de permissions effectives d'un employé
/// (permissions de son rôle + permissions directes), telles que
/// renvoyées par `/auth/me` et `/auth/login` (champ `employee.permissions`).
class EmployeePermissions {
  final Set<String> codes;

  const EmployeePermissions(this.codes);

  factory EmployeePermissions.fromJson(List<dynamic>? json) {
    return EmployeePermissions((json ?? []).map((e) => e as String).toSet());
  }

  bool has(String code) => codes.contains(code);

  /// Vrai si l'employé possède AU MOINS une des permissions listées.
  /// Utile pour les routes backend gardées par `permission:a|b`.
  bool hasAny(List<String> codes) => codes.any(has);
}

class EmployeeModel {
  final String id;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String? position;
  final EmployeeRoleModel? role;
  final EmployeePermissions permissions;

  EmployeeModel({
    required this.id,
    required this.employeeNumber,
    required this.firstName,
    required this.lastName,
    this.position,
    this.role,
    this.permissions = const EmployeePermissions({}),
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      employeeNumber: json['employee_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      position: json['position'] as String?,
      role: json['role'] != null
          ? EmployeeRoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      permissions: EmployeePermissions.fromJson(json['permissions'] as List<dynamic>?),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  bool hasRole(String code) => role?.code == code;

  /// Vérifie si l'employé possède la permission donnée (via son rôle
  /// ou une permission directe). Renvoie toujours `true` pour un
  /// super-admin détecté via son rôle "admin"/"super_admin" si besoin
  /// d'un accès total — sinon se base uniquement sur `permissions`.
  bool hasPermission(String code) => permissions.has(code);

  /// Vrai si l'employé possède au moins une des permissions listées.
  bool hasAnyPermission(List<String> codes) => permissions.hasAny(codes);
}

class AuthResult {
  final UserModel user;
  final String token;

  AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}