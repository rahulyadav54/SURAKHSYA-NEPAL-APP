import '../entities/fire_report.dart';

abstract class FireRepository {
  Future<String> reportFire({
    required double latitude,
    required double longitude,
    String? imagePath,
    String? videoPath,
    required String description,
    required String aiSeverity,
  });
  Stream<FireReport> subscribeToFireReportUpdates(String reportId);
}
