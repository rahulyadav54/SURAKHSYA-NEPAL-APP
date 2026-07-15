import '../entities/emergency_event.dart';

abstract class EmergencyRepository {
  Future<void> triggerSosAlert({required double latitude, required double longitude});
  Future<List<EmergencyEvent>> fetchEmergencyHistory();
}
