class Hospital {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String phone;
  final String address;
  final int emergencyBedsAvailable;
  final int emergencyBedsTotal;
  final String specialists;
  final Map<String, dynamic> bloodStock;

  const Hospital({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.address,
    required this.emergencyBedsAvailable,
    required this.emergencyBedsTotal,
    required this.specialists,
    required this.bloodStock,
  });

  Hospital copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? phone,
    String? address,
    int? emergencyBedsAvailable,
    int? emergencyBedsTotal,
    String? specialists,
    Map<String, dynamic>? bloodStock,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyBedsAvailable: emergencyBedsAvailable ?? this.emergencyBedsAvailable,
      emergencyBedsTotal: emergencyBedsTotal ?? this.emergencyBedsTotal,
      specialists: specialists ?? this.specialists,
      bloodStock: bloodStock ?? this.bloodStock,
    );
  }
}
