import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/addresses_model.dart';

class AddressesRepository {
  final Dio _dio;

  AddressesRepository(this._dio);

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dio.get(ApiConstants.addresses);
      final data = response.data['data'] as List;
      return data.map((a) => AddressModel.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AddressModel> createAddress({
    required String recipientName,
    required String phone,
    required String city,
    required String district,
    required String addressLine,
    String? landmarkNote,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'recipient_name': recipientName,
        'phone': phone,
        'city': city,
        'district': district,
        'address_line': addressLine,
        'is_default': isDefault,
      };

      if (landmarkNote case final value?) data['landmark_note'] = value;
      if (latitude case final value?) data['latitude'] = value;
      if (longitude case final value?) data['longitude'] = value;

      final response = await _dio.post(ApiConstants.addresses, data: data);
      return AddressModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete('${ApiConstants.addresses}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AddressModel> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.addresses}/$id', data: data);
      return AddressModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}