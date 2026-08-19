import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/config/demo_mode.dart';
import '../../../auth/domain/entities/user_role.dart';
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
      
      final isDemoActive = _ref.read(demoModeProvider);

      // 2. Write emergency alert row to Supabase
      await _repository.triggerSosAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        isDemo: isDemoActive,
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

  /// Submits a details emergency request with optional media attachments
  Future<String?> submitCustomEmergency({
    required ServiceType serviceType,
    required String emergencyType,
    required String severity,
    required String description,
    required String address,
    String? localPhotoPath,
    String? localVideoPath,
    int peopleAffected = 1,
    String fireType = '',
    String buildingType = '',
    bool explosionRisk = false,
    bool gasElectricalRisk = false,
  }) async {
    state = const EmergencyTriggerLoading();
    try {
      final position = await _locationService.getCurrentLocation();
      
      String photoUrl = '';
      String videoUrl = '';

      if (localPhotoPath != null) {
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploaded = await _repository.uploadEmergencyMedia(localPhotoPath, fileName);
        if (uploaded != null) photoUrl = uploaded;
      }

      if (localVideoPath != null) {
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final uploaded = await _repository.uploadEmergencyMedia(localVideoPath, fileName);
        if (uploaded != null) videoUrl = uploaded;
      }

      String resolvedAddress = address.trim();
      if (resolvedAddress.isEmpty) {
        try {
          final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            resolvedAddress = '${pm.street ?? pm.name ?? ''}, ${pm.locality ?? pm.subAdministrativeArea ?? ''}, ${pm.country ?? 'Nepal'}';
          }
        } catch (_) {
          resolvedAddress = 'Coordinates: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        }
      }

      final isDemoActive = _ref.read(demoModeProvider);
      final finalDesc = isDemoActive ? '[DEMO] $description' : description;
      final finalType = isDemoActive ? '[DEMO] $emergencyType' : emergencyType;

      final requestId = await _repository.createEmergencyRequest(
        serviceType: serviceType,
        emergencyType: finalType,
        severity: severity,
        description: finalDesc,
        latitude: position.latitude,
        longitude: position.longitude,
        address: resolvedAddress,
        photoUrl: photoUrl,
        videoUrl: videoUrl,
        peopleAffected: peopleAffected,
        fireType: fireType,
        buildingType: buildingType,
        explosionRisk: explosionRisk,
        gasElectricalRisk: gasElectricalRisk,
      );

      state = const EmergencyTriggerSuccess();
      _ref.invalidate(emergencyHistoryProvider);
      return requestId;
    } catch (e) {
      state = EmergencyTriggerError(e.toString());
      return null;
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

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// StreamProvider that listens to updates on a specific emergency request in real-time
final emergencyRequestStreamProvider = StreamProvider.family.autoDispose<Map<String, dynamic>, String>((ref, requestId) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<Map<String, dynamic>>();

  Future<void> fetchLatest() async {
    try {
      final data = await supabase
          .from('emergency_requests')
          .select('*, responders(*, profiles(*), vehicles(*))')
          .eq('id', requestId)
          .maybeSingle();
      if (data != null && !controller.isClosed) {
        controller.add(data);
      }
    } catch (_) {}
  }

  fetchLatest();

  final channel = supabase
      .channel('public:emergency_requests_track:$requestId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: requestId,
        ),
        callback: (payload) {
          fetchLatest();
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// StreamProvider that listens to GPS updates of a specific responder in real-time
final responderLocationStreamProvider = StreamProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, responderId) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<Map<String, dynamic>?>();

  Future<void> fetchLatest() async {
    try {
      final data = await supabase
          .from('responders')
          .select('current_latitude, current_longitude, current_heading, availability_status')
          .eq('id', responderId)
          .maybeSingle();
      if (data != null && !controller.isClosed) {
        controller.add(data);
      }
    } catch (_) {}
  }

  fetchLatest();

  final channel = supabase
      .channel('public:responders_loc:$responderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'responders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: responderId,
        ),
        callback: (payload) {
          fetchLatest();
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// StreamProvider that listens to emergency timeline events in real-time
final emergencyEventsStreamProvider = StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, requestId) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> fetchLatest() async {
    try {
      final data = await supabase
          .from('emergency_events')
          .select()
          .eq('emergency_id', requestId)
          .order('created_at', ascending: true);
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  final subscription = supabase
      .channel('public:emergency_events:$requestId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'emergency_id',
          value: requestId,
        ),
        callback: (payload) {
          fetchLatest();
        },
      )
      .subscribe();

  fetchLatest();

  ref.onDispose(() {
    subscription.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

