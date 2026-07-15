import '../entities/police_report.dart';

abstract class PoliceRepository {
  Future<String> reportIncident({
    required double latitude,
    required double longitude,
    required String category,
    required String description,
    String? evidencePath,
  });
  Stream<PoliceReport> subscribeToPoliceReportUpdates(String reportId);
}
