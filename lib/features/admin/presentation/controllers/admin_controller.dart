import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../emergency/domain/entities/emergency_event.dart';
import '../../../ambulance/domain/entities/ambulance.dart';
import '../../../ambulance/domain/entities/ambulance_request.dart';
import '../../../fire/domain/entities/fire_report.dart';
import '../../../police/domain/entities/police_report.dart';
import '../../../hospital/domain/entities/hospital.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../../ai_assistant/presentation/controllers/ai_chat_controller.dart';

import '../../../responder/data/repositories/responder_repository.dart';

/// FutureProviders to load the administrator details lists
final adminProfilesProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchProfiles();
});

final adminEmergenciesProvider = FutureProvider.autoDispose<List<EmergencyEvent>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchEmergencies();
});

final adminAmbulanceReqsProvider = FutureProvider.autoDispose<List<AmbulanceRequest>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAmbulanceRequests();
});

final adminFireReportsProvider = FutureProvider.autoDispose<List<FireReport>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchFireReports();
});

final adminPoliceReportsProvider = FutureProvider.autoDispose<List<PoliceReport>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchPoliceReports();
});

final adminHospitalsProvider = FutureProvider.autoDispose<List<Hospital>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchHospitals();
});

final adminAmbulancesProvider = FutureProvider.autoDispose<List<Ambulance>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAmbulances();
});

final adminRespondersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(responderRepositoryProvider).fetchAllResponders();
});

/// AI forecasting trend predictor provider inside Admin Module
final adminAnalyticsPredictionProvider = FutureProvider.autoDispose<String>((ref) async {
  final gemini = ref.watch(geminiServiceProvider);
  final emergencies = await ref.watch(adminEmergenciesProvider.future);
  final ambulanceRequests = await ref.watch(adminAmbulanceReqsProvider.future);

  final prompt = '''
You are an AI Disaster and Safety analyst for Suraksha Nepal.
Analyze these metrics:
- Active SOS emergencies: ${emergencies.length}
- Ambulance requests: ${ambulanceRequests.length}

Generate a concise prediction analysis (max 3 short bullet points) in Nepali and English about:
1. Expected seasonal risks (monsoon landslides/dry fires).
2. Resource dispatch recommendations.
''';

  return gemini.queryGemini(prompt);
});

class AdminController {
  final AdminRepository _repository;
  final Ref _ref;

  AdminController(this._repository, this._ref);

  Future<void> updateEmergencyStatus(String id, String status) async {
    await _repository.updateEmergencyStatus(id: id, status: status);
    _ref.invalidate(adminEmergenciesProvider);
  }

  Future<void> updateAmbulanceRequestStatus(String id, String status) async {
    await _repository.updateAmbulanceRequestStatus(id: id, status: status);
    _ref.invalidate(adminAmbulanceReqsProvider);
  }

  Future<void> updateFireReportStatus(String id, String status) async {
    await _repository.updateFireReportStatus(id: id, status: status);
    _ref.invalidate(adminFireReportsProvider);
  }

  Future<void> updatePoliceReportStatus(String id, String status) async {
    await _repository.updatePoliceReportStatus(id: id, status: status);
    _ref.invalidate(adminPoliceReportsProvider);
  }

  Future<void> updateHospitalBeds(String id, int beds) async {
    await _repository.updateHospitalBeds(id: id, bedsAvailable: beds);
    _ref.invalidate(adminHospitalsProvider);
  }

  Future<void> updateAmbulanceStatus(String id, String status) async {
    await _repository.updateAmbulanceStatus(id: id, status: status);
    _ref.invalidate(adminAmbulancesProvider);
  }

  Future<void> verifyResponder(String id, String status) async {
    await _ref.read(responderRepositoryProvider).verifyResponder(id, status);
    _ref.invalidate(adminRespondersProvider);
  }
}

final adminControllerProvider = Provider((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminController(repo, ref);
});

class AdminChartStats {
  final int sosCount;
  final int ambulanceCount;
  final int fireCount;
  final int policeCount;
  final Map<String, int> severityDistribution;
  final double averageResponseMinutes;

  const AdminChartStats({
    this.sosCount = 0,
    this.ambulanceCount = 0,
    this.fireCount = 0,
    this.policeCount = 0,
    this.severityDistribution = const {},
    this.averageResponseMinutes = 0.0,
  });
}

final adminChartStatsProvider = Provider.autoDispose<AdminChartStats>((ref) {
  final emergencies = ref.watch(adminEmergenciesProvider).value ?? [];
  final ambulanceRequests = ref.watch(adminAmbulanceReqsProvider).value ?? [];
  final fireReports = ref.watch(adminFireReportsProvider).value ?? [];
  final policeReports = ref.watch(adminPoliceReportsProvider).value ?? [];

  final severities = <String, int>{'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0};
  for (final item in fireReports) {
    final sev = item.aiPredictedSeverity.toUpperCase();
    severities[sev] = (severities[sev] ?? 0) + 1;
  }
  for (final item in ambulanceRequests) {
    final sev = item.patientStatus.toUpperCase();
    severities[sev] = (severities[sev] ?? 0) + 1;
  }

  return AdminChartStats(
    sosCount: emergencies.length,
    ambulanceCount: ambulanceRequests.length,
    fireCount: fireReports.length,
    policeCount: policeReports.length,
    severityDistribution: severities,
    averageResponseMinutes: 12.5,
  );
});

