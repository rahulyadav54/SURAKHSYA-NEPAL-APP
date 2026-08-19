import '../../../auth/domain/entities/user_role.dart';
import '../entities/emergency_event.dart';

abstract class EmergencyRepository {
  Future<void> triggerSosAlert({required double latitude, required double longitude});
  Future<List<EmergencyEvent>> fetchEmergencyHistory();
  
  Future<String> createEmergencyRequest({
    required ServiceType serviceType,
    required String emergencyType,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String photoUrl,
    String videoUrl,
    int peopleAffected,
    String fireType,
    String buildingType,
    bool explosionRisk,
    bool gasElectricalRisk,
  });

  Future<String?> uploadEmergencyMedia(String filePath, String fileName);

  Future<List<Map<String, dynamic>>> fetchNearbyResponders({
    required double latitude,
    required double longitude,
    required ServiceType serviceType,
    int limit,
  });
}


