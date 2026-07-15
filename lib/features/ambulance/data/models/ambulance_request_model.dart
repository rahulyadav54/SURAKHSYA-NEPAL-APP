import '../../domain/entities/ambulance_request.dart';
import 'ambulance_model.dart';

class AmbulanceRequestModel extends AmbulanceRequest {
  const AmbulanceRequestModel({
    required super.id,
    required super.userId,
    super.ambulanceId,
    required super.status,
    required super.pickupLatitude,
    required super.pickupLongitude,
    super.hospitalName,
    required super.patientStatus,
    super.etaMinutes,
    required super.createdAt,
    super.ambulance,
  });

  factory AmbulanceRequestModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceRequestModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      ambulanceId: json['ambulance_id'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      hospitalName: json['hospital_name'] as String?,
      patientStatus: json['patient_status'] as String? ?? 'STABLE',
      etaMinutes: json['eta_minutes'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      // Handle nested join response from Supabase (foreign key match on 'ambulances')
      ambulance: json['ambulances'] != null 
          ? AmbulanceModel.fromJson(json['ambulances'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'ambulance_id': ambulanceId,
      'status': status,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'hospital_name': hospitalName,
      'patient_status': patientStatus,
      'eta_minutes': etaMinutes,
    };
  }
}
