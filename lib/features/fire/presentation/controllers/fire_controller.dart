import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';
import '../../domain/entities/fire_report.dart';
import '../../domain/repositories/fire_repository.dart';
import '../../data/repositories/fire_repository_impl.dart';

/// StreamProvider that listens to updates on reported fires in real time
final activeFireStreamProvider = StreamProvider.family.autoDispose<FireReport, String>((ref, reportId) {
  final repository = ref.watch(fireRepositoryProvider);
  return repository.subscribeToFireReportUpdates(reportId);
});

/// Reporting flow state machine classes
abstract class FireReportSubmissionState {
  const FireReportSubmissionState();
}

class FireReportIdle extends FireReportSubmissionState {
  const FireReportIdle();
}

class FireReportLoading extends FireReportSubmissionState {
  const FireReportLoading();
}

class FireReportSuccess extends FireReportSubmissionState {
  final String reportId;
  const FireReportSuccess(this.reportId);
}

class FireReportError extends FireReportSubmissionState {
  final String message;
  const FireReportError(this.message);
}

class FireController extends StateNotifier<FireReportSubmissionState> {
  final FireRepository _repository;
  final LocationService _locationService;

  FireController({
    required FireRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService,
        super(const FireReportIdle());

  /// Simulates Gemini AI severity assessments on captured files and text
  Future<Map<String, String>> analyzeSeverityWithAi({
    required String? imagePath,
    required String description,
  }) async {
    // Artificial scanning delay
    await Future.delayed(const Duration(seconds: 2));

    final descLower = description.toLowerCase();
    if (descLower.contains('gas') || descLower.contains('cylinder') || descLower.contains('petrol') || descLower.contains('blast')) {
      return {
        'severity': 'HIGH',
        'reason': 'AI Alert: Chemical/Explosive hazards flagged. Structural fire risk is high. Recommend dispatching 3 Fire Tenders immediately.',
      };
    } else if (descLower.contains('short') || descLower.contains('wire') || descLower.contains('electric') || descLower.contains('transformer')) {
      return {
        'severity': 'MEDIUM',
        'reason': 'AI Alert: Electrical fire detected. Suggesting localized carbon-dioxide suppression and grid decoupling.',
      };
    } else {
      return {
        'severity': 'LOW',
        'reason': 'AI Alert: Confined dry grass or refuse fire. Standard localized chemical extinguishers recommended.',
      };
    }
  }

  /// Triggers user GPS lookups and submits a new fire report entry to Supabase
  Future<String?> submitFireReport({
    String? imagePath,
    String? videoPath,
    required String description,
    required String aiSeverity,
  }) async {
    state = const FireReportLoading();
    try {
      final position = await _locationService.getCurrentLocation();
      final reportId = await _repository.reportFire(
        latitude: position.latitude,
        longitude: position.longitude,
        imagePath: imagePath,
        videoPath: videoPath,
        description: description,
        aiSeverity: aiSeverity,
      );

      state = FireReportSuccess(reportId);
      return reportId;
    } catch (e) {
      state = FireReportError(e.toString());
      return null;
    }
  }

  void reset() {
    state = const FireReportIdle();
  }
}

final fireControllerProvider = StateNotifierProvider<FireController, FireReportSubmissionState>((ref) {
  final repository = ref.watch(fireRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return FireController(
    repository: repository,
    locationService: locationService,
  );
});
