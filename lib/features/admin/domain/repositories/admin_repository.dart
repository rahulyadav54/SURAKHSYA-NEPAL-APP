import '../../../auth/domain/entities/user_profile.dart';
import '../../../emergency/domain/entities/emergency_event.dart';
import '../../../ambulance/domain/entities/ambulance.dart';
import '../../../ambulance/domain/entities/ambulance_request.dart';
import '../../../fire/domain/entities/fire_report.dart';
import '../../../police/domain/entities/police_report.dart';
import '../../../hospital/domain/entities/hospital.dart';

abstract class AdminRepository {
  Future<List<UserProfile>> fetchProfiles();
  Future<List<EmergencyEvent>> fetchEmergencies();
  Future<List<AmbulanceRequest>> fetchAmbulanceRequests();
  Future<List<FireReport>> fetchFireReports();
  Future<List<PoliceReport>> fetchPoliceReports();
  Future<List<Hospital>> fetchHospitals();
  Future<List<Ambulance>> fetchAmbulances();

  Future<void> updateEmergencyStatus({required String id, required String status});
  Future<void> updateAmbulanceRequestStatus({required String id, required String status});
  Future<void> updateFireReportStatus({required String id, required String status});
  Future<void> updatePoliceReportStatus({required String id, required String status});
  Future<void> updateHospitalBeds({required String id, required int bedsAvailable});
  Future<void> updateAmbulanceStatus({required String id, required String status});
}
