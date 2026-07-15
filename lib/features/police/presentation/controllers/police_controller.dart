import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';
import '../../domain/entities/police_report.dart';
import '../../domain/repositories/police_repository.dart';
import '../../data/repositories/police_repository_impl.dart';

/// StreamProvider that listens to updates on police reports in real time
final activePoliceStreamProvider = StreamProvider.family.autoDispose<PoliceReport, String>((ref, reportId) {
  final repository = ref.watch(policeRepositoryProvider);
  return repository.subscribeToPoliceReportUpdates(reportId);
});

/// Submission flow state machine classes
abstract class PoliceReportSubmissionState {
  const PoliceReportSubmissionState();
}

class PoliceReportIdle extends PoliceReportSubmissionState {
  const PoliceReportIdle();
}

class PoliceReportLoading extends PoliceReportSubmissionState {
  const PoliceReportLoading();
}

class PoliceReportSuccess extends PoliceReportSubmissionState {
  final String reportId;
  const PoliceReportSuccess(this.reportId);
}

class PoliceReportError extends PoliceReportSubmissionState {
  final String message;
  const PoliceReportError(this.message);
}

class PoliceController extends StateNotifier<PoliceReportSubmissionState> {
  final PoliceRepository _repository;
  final LocationService _locationService;

  PoliceController({
    required PoliceRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService,
        super(const PoliceReportIdle());

  /// Triggers user GPS lookup and submits a new police emergency incident report to Supabase
  Future<String?> submitPoliceReport({
    required String category,
    required String description,
    String? evidencePath,
  }) async {
    state = const PoliceReportLoading();
    try {
      final position = await _locationService.getCurrentLocation();
      final reportId = await _repository.reportIncident(
        latitude: position.latitude,
        longitude: position.longitude,
        category: category,
        description: description,
        evidencePath: evidencePath,
      );

      state = PoliceReportSuccess(reportId);
      return reportId;
    } catch (e) {
      state = PoliceReportError(e.toString());
      return null;
    }
  }

  void reset() {
    state = const PoliceReportIdle();
  }
}

final policeControllerProvider = StateNotifierProvider<PoliceController, PoliceReportSubmissionState>((ref) {
  final repository = ref.watch(policeRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return PoliceController(
    repository: repository,
    locationService: locationService,
  );
});
