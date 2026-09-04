import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../deliveries/data/models/admin_delivery_model.dart';
import '../../../employees/data/models/admin_employee_model.dart';
import '../../data/repositories/admin_drivers_repository.dart';

final adminDriversRepositoryProvider = Provider<AdminDriversRepository>((ref) {
  return AdminDriversRepository(ref.watch(dioProvider));
});

final adminEligibleEmployeesProvider = FutureProvider.autoDispose<List<AdminEmployeeModel>>((ref) async {
  final repository = ref.watch(adminDriversRepositoryProvider);
  final employees = await repository.getEligibleEmployees();
  return employees.where((e) => !e.isDriver).toList();
});

class AdminDriversListNotifier extends AsyncNotifier<List<AdminDriverModel>> {
  AdminDriversRepository get _repository => ref.read(adminDriversRepositoryProvider);

  @override
  Future<List<AdminDriverModel>> build() async {
    return _repository.getDrivers();
  }

  Future<String?> create({required String employeeId, String? vehicleType, String? vehicleNumber}) async {
    try {
      await _repository.createDriver(employeeId: employeeId, vehicleType: vehicleType, vehicleNumber: vehicleNumber);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateStatus(String id, String status) async {
    try {
      await _repository.updateDriver(id, {'status': status});
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateVehicle(String id, {String? vehicleType, String? vehicleNumber}) async {
    try {
      await _repository.updateDriver(id, {
        'vehicle_type': ?vehicleType,
        'vehicle_number': ?vehicleNumber,
      });
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminDriversListProvider = AsyncNotifierProvider<AdminDriversListNotifier, List<AdminDriverModel>>(
  AdminDriversListNotifier.new,
);