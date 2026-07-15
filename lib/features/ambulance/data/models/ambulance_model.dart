import '../../domain/entities/ambulance.dart';

class AmbulanceModel extends Ambulance {
  const AmbulanceModel({
    required super.id,
    required super.driverName,
    required super.licensePlate,
    required super.phone,
    required super.latitude,
    required super.longitude,
    required super.status,
  });

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      id: json['id'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_name': driverName,
      'license_plate': licensePlate,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory AmbulanceModel.fromEntity(Ambulance entity) {
    return AmbulanceModel(
      id: entity.id,
      driverName: entity.driverName,
      licensePlate: entity.licensePlate,
      phone: entity.phone,
      latitude: entity.latitude,
      longitude: entity.longitude,
      status: entity.status,
    );
  }
}
