import 'ambulance.dart';

class AmbulanceRequest {
  final String id;
  final String userId;
  final String? ambulanceId;
  final String status;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? hospitalName;
  final String patientStatus;
  final int? etaMinutes;
  final DateTime createdAt;
  final Ambulance? ambulance;

  const AmbulanceRequest({
    required this.id,
    required this.userId,
    this.ambulanceId,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.hospitalName,
    required this.patientStatus,
    this.etaMinutes,
    required this.createdAt,
    this.ambulance,
  });

  AmbulanceRequest copyWith({
    String? id,
    String? userId,
    String? ambulanceId,
    String? status,
    double? pickupLatitude,
    double? pickupLongitude,
    String? hospitalName,
    String? patientStatus,
    int? etaMinutes,
    DateTime? createdAt,
    Ambulance? ambulance,
  }) {
    return AmbulanceRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ambulanceId: ambulanceId ?? this.ambulanceId,
      status: status ?? this.status,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      hospitalName: hospitalName ?? this.hospitalName,
      patientStatus: patientStatus ?? this.patientStatus,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      createdAt: createdAt ?? this.createdAt,
      ambulance: ambulance ?? this.ambulance,
    );
  }
}
