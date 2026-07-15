import '../../domain/entities/police_report.dart';

class PoliceReportModel extends PoliceReport {
  const PoliceReportModel({
    required super.id,
    required super.userId,
    required super.latitude,
    required super.longitude,
    super.evidencePath,
    required super.category,
    required super.description,
    required super.status,
    required super.createdAt,
  });

  factory PoliceReportModel.fromJson(Map<String, dynamic> json) {
    return PoliceReportModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      evidencePath: json['evidence_path'] as String?,
      category: json['category'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
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
      'evidence_path': evidencePath,
      'category': category,
      'description': description,
      'status': status,
    };
  }
}
