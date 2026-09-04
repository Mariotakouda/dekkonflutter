import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/addresses_model.dart';
import '../../data/repositories/addresses_repository.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(dioProvider));
});

class AddressesNotifier extends AsyncNotifier<List<AddressModel>> {
  AddressesRepository get _repository => ref.read(addressesRepositoryProvider);

  @override
  Future<List<AddressModel>> build() async {
    return _repository.getAddresses();
  }

  Future<void> add({
    required String recipientName,
    required String phone,
    required String city,
    required String district,
    required String addressLine,
    String? landmarkNote,
    bool isDefault = false,
  }) async {
    await _repository.createAddress(
      recipientName: recipientName,
      phone: phone,
      city: city,
      district: district,
      addressLine: addressLine,
      landmarkNote: landmarkNote,
      isDefault: isDefault,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await _repository.deleteAddress(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit(
    String id, {
    required String recipientName,
    required String phone,
    required String city,
    required String district,
    required String addressLine,
    String? landmarkNote,
    bool isDefault = false,
  }) async {
    await _repository.updateAddress(id, {
      'recipient_name': recipientName,
      'phone': phone,
      'city': city,
      'district': district,
      'address_line': addressLine,
      'landmark_note': landmarkNote,
      'is_default': isDefault,
    });
    ref.invalidateSelf();
    await future;
  }
}

final addressesNotifierProvider = AsyncNotifierProvider<AddressesNotifier, List<AddressModel>>(
  AddressesNotifier.new,
);