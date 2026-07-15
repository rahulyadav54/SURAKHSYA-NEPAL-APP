class FireReport {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? imagePath;
  final String? videoPath;
  final String description;
  final String aiPredictedSeverity;
  final String status;
  final DateTime createdAt;

  const FireReport({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.imagePath,
    this.videoPath,
    required this.description,
    required this.aiPredictedSeverity,
    required this.status,
    required this.createdAt,
  });

  FireReport copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? imagePath,
    String? videoPath,
    String? description,
    String? aiPredictedSeverity,
    String? status,
    DateTime? createdAt,
  }) {
    return FireReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      description: description ?? this.description,
      aiPredictedSeverity: aiPredictedSeverity ?? this.aiPredictedSeverity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
