class AddressModel {
  final String id;
  final String recipientName;
  final String phone;
  final String city;
  final String district;
  final String addressLine;
  final String? landmarkNote;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.city,
    required this.district,
    required this.addressLine,
    this.landmarkNote,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      recipientName: json['recipient_name'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      addressLine: json['address_line'] as String,
      landmarkNote: json['landmark_note'] as String?,
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  String get shortLabel => '$district, $city';
  String get fullLabel => '$addressLine, $district, $city';
}