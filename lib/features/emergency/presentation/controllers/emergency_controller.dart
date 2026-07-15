import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../data/repositories/emergency_repository_impl.dart';

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

/// FutureProvider that fetches the list of past emergency events
final emergencyHistoryProvider = FutureProvider.autoDispose<List<EmergencyEvent>>((ref) async {
  final repository = ref.watch(emergencyRepositoryProvider);
  return repository.fetchEmergencyHistory();
});

/// Emergency trigger state machine classes
abstract class EmergencyTriggerState {
  const EmergencyTriggerState();
}

class EmergencyTriggerIdle extends EmergencyTriggerState {
  const EmergencyTriggerIdle();
}

class EmergencyTriggerLoading extends EmergencyTriggerState {
  const EmergencyTriggerLoading();
}

class EmergencyTriggerSuccess extends EmergencyTriggerState {
  const EmergencyTriggerSuccess();
}

class EmergencyTriggerError extends EmergencyTriggerState {
  final String message;
  const EmergencyTriggerError(this.message);
}

class EmergencyController extends StateNotifier<EmergencyTriggerState> {
  final EmergencyRepository _repository;
  final LocationService _locationService;
  final Ref _ref;

  EmergencyController({
    required EmergencyRepository repository,
    required LocationService locationService,
    required Ref ref,
  })  : _repository = repository,
        _locationService = locationService,
        _ref = ref,
        super(const EmergencyTriggerIdle());

  /// Triggers the full SOS workflow: GPS query -> Supabase entry -> refresh history
  Future<bool> triggerSosAlert() async {
    state = const EmergencyTriggerLoading();
    try {
      // 1. Fetch current GPS location coordinates
      final position = await _locationService.getCurrentLocation();
      
      // 2. Write emergency alert row to Supabase
      await _repository.triggerSosAlert(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      state = const EmergencyTriggerSuccess();
      
      // 3. Invalidate history provider to force a refresh of listings
      _ref.invalidate(emergencyHistoryProvider);
      return true;
    } catch (e) {
      state = EmergencyTriggerError(e.toString());
      return false;
    }
  }

  void reset() {
    state = const EmergencyTriggerIdle();
  }
}

final emergencyControllerProvider = StateNotifierProvider<EmergencyController, EmergencyTriggerState>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return EmergencyController(
    repository: repository,
    locationService: locationService,
    ref: ref,
  );
});
