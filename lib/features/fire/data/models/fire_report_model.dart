import '../../domain/entities/fire_report.dart';

class FireReportModel extends FireReport {
  const FireReportModel({
    required super.id,
    required super.userId,
    required super.latitude,
    required super.longitude,
    super.imagePath,
    super.videoPath,
    required super.description,
    required super.aiPredictedSeverity,
    required super.status,
    required super.createdAt,
  });

  factory FireReportModel.fromJson(Map<String, dynamic> json) {
    return FireReportModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['image_path'] as String?,
      videoPath: json['video_path'] as String?,
      description: json['description'] as String? ?? '',
      aiPredictedSeverity: json['ai_predicted_severity'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'REPORTED',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'image_path': imagePath,
      'video_path': videoPath,
      'description': description,
      'ai_predicted_severity': aiPredictedSeverity,
      'status': status,
    };
  }
}
