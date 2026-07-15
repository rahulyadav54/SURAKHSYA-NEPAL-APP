import '../../domain/entities/hospital.dart';

class HospitalModel extends Hospital {
  const HospitalModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.phone,
    required super.address,
    required super.emergencyBedsAvailable,
    required super.emergencyBedsTotal,
    required super.specialists,
    required super.bloodStock,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      emergencyBedsAvailable: json['emergency_beds_available'] as int? ?? 0,
      emergencyBedsTotal: json['emergency_beds_total'] as int? ?? 0,
      specialists: json['specialist_doctors'] as String? ?? '',
      bloodStock: json['blood_stock'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'address': address,
      'emergency_beds_available': emergencyBedsAvailable,
      'emergency_beds_total': emergencyBedsTotal,
      'specialist_doctors': specialists,
      'blood_stock': bloodStock,
    };
  }
}
