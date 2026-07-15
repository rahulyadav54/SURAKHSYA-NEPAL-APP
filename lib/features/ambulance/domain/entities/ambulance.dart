class Ambulance {
  final String id;
  final String driverName;
  final String licensePlate;
  final String phone;
  final double latitude;
  final double longitude;
  final String status;

  const Ambulance({
    required this.id,
    required this.driverName,
    required this.licensePlate,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  Ambulance copyWith({
    String? id,
    String? driverName,
    String? licensePlate,
    String? phone,
    double? latitude,
    double? longitude,
    String? status,
  }) {
    return Ambulance(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      licensePlate: licensePlate ?? this.licensePlate,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }
}
