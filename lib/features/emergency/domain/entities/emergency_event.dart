class EmergencyEvent {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;

  const EmergencyEvent({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  EmergencyEvent copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
  }) {
    return EmergencyEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
