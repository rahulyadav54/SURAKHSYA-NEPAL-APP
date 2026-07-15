class PoliceReport {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? evidencePath;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  const PoliceReport({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.evidencePath,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  PoliceReport copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? evidencePath,
    String? category,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return PoliceReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      evidencePath: evidencePath ?? this.evidencePath,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
