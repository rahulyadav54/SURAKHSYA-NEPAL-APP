import '../entities/ambulance.dart';
import '../entities/ambulance_request.dart';

abstract class AmbulanceRepository {
  Future<List<Ambulance>> fetchNearbyAmbulances();
  Future<String> requestAmbulance({
    required double latitude,
    required double longitude,
    required String patientStatus,
  });
  Stream<AmbulanceRequest> subscribeToRequestUpdates(String requestId);
}
