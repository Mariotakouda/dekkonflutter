import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_employee_model.dart';
import '../../data/repositories/admin_employees_repository.dart';

final adminEmployeesRepositoryProvider = Provider<AdminEmployeesRepository>((ref) {
  return AdminEmployeesRepository(ref.watch(dioProvider));
});

final adminRolesProvider = FutureProvider.autoDispose<List<AdminRoleModel>>((ref) async {
  final repository = ref.watch(adminEmployeesRepositoryProvider);
  return repository.getRoles();
});

final adminPermissionsProvider = FutureProvider.autoDispose<List<AdminPermissionModel>>((ref) async {
  final repository = ref.watch(adminEmployeesRepositoryProvider);
  return repository.getPermissions();
});

final adminEmployeeDetailProvider = FutureProvider.autoDispose.family<AdminEmployeeModel, String>((ref, id) async {
  final repository = ref.watch(adminEmployeesRepositoryProvider);
  return repository.getEmployee(id);
});

class AdminEmployeeListState {
  final List<AdminEmployeeModel> employees;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  AdminEmployeeListState({
    this.employees = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  AdminEmployeeListState copyWith({
    List<AdminEmployeeModel>? employees,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return AdminEmployeeListState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class AdminEmployeeListNotifier extends Notifier<AdminEmployeeListState> {
  @override
  AdminEmployeeListState build() {
    Future.microtask(loadFirstPage);
    return AdminEmployeeListState();
  }

  AdminEmployeesRepository get _repository => ref.read(adminEmployeesRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getEmployees(page: 1);
      state = state.copyWith(
        employees: result.items,
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getEmployees(page: nextPage);
      state = state.copyWith(
        employees: [...state.employees, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final adminEmployeeListProvider = NotifierProvider<AdminEmployeeListNotifier, AdminEmployeeListState>(
  AdminEmployeeListNotifier.new,
);

class AdminEmployeeFormNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminEmployeesRepository get _repository => ref.read(adminEmployeesRepositoryProvider);

  Future<String?> create(Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.createEmployee(data);
      ref.read(adminEmployeeListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> update(String id, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.updateEmployee(id, data);
      ref.invalidate(adminEmployeeDetailProvider(id));
      ref.read(adminEmployeeListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> deactivate(String id) async {
    state = true;
    try {
      await _repository.deactivateEmployee(id);
      ref.read(adminEmployeeListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminEmployeeFormProvider = NotifierProvider<AdminEmployeeFormNotifier, bool>(
  AdminEmployeeFormNotifier.new,
);

class AdminRoleFormNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminEmployeesRepository get _repository => ref.read(adminEmployeesRepositoryProvider);

  Future<String?> create({
    required String name,
    required String code,
    String? description,
    List<String> permissionIds = const [],
  }) async {
    state = true;
    try {
      await _repository.createRole(name: name, code: code, description: description, permissionIds: permissionIds);
      ref.invalidate(adminRolesProvider);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> update(String id, {String? name, String? description}) async {
    state = true;
    try {
      await _repository.updateRole(id, name: name, description: description);
      ref.invalidate(adminRolesProvider);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> delete(String id) async {
    state = true;
    try {
      await _repository.deleteRole(id);
      ref.invalidate(adminRolesProvider);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> syncPermissions(String roleId, List<String> permissionIds) async {
    state = true;
    try {
      await _repository.syncRolePermissions(roleId, permissionIds);
      ref.invalidate(adminRolesProvider);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminRoleFormProvider = NotifierProvider<AdminRoleFormNotifier, bool>(
  AdminRoleFormNotifier.new,
);