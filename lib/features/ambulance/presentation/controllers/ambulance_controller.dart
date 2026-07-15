import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';
import '../../domain/entities/ambulance.dart';
import '../../domain/entities/ambulance_request.dart';
import '../../domain/repositories/ambulance_repository.dart';
import '../../data/repositories/ambulance_repository_impl.dart';

/// Provider that fetches active available ambulance units
final nearbyAmbulancesProvider = FutureProvider.autoDispose<List<Ambulance>>((ref) async {
  final repository = ref.watch(ambulanceRepositoryProvider);
  return repository.fetchNearbyAmbulances();
});

/// StreamProvider family that listens to active request updates dynamically
final activeRequestStreamProvider = StreamProvider.family.autoDispose<AmbulanceRequest, String>((ref, requestId) {
  final repository = ref.watch(ambulanceRepositoryProvider);
  return repository.subscribeToRequestUpdates(requestId);
});

/// Booking controller state definitions
abstract class AmbulanceBookingState {
  const AmbulanceBookingState();
}

class BookingIdle extends AmbulanceBookingState {
  const BookingIdle();
}

class BookingLoading extends AmbulanceBookingState {
  const BookingLoading();
}

class BookingSuccess extends AmbulanceBookingState {
  final String requestId;
  const BookingSuccess(this.requestId);
}

class BookingError extends AmbulanceBookingState {
  final String message;
  const BookingError(this.message);
}

class AmbulanceController extends StateNotifier<AmbulanceBookingState> {
  final AmbulanceRepository _repository;
  final LocationService _locationService;

  AmbulanceController({
    required AmbulanceRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService,
        super(const BookingIdle());

  /// Triggers user GPS lookup and logs a new ambulance request entry inside Supabase
  Future<String?> requestAmbulance(String patientStatus) async {
    state = const BookingLoading();
    try {
      // 1. Resolve current coordinates
      final position = await _locationService.getCurrentLocation();

      // 2. Submit booking request
      final requestId = await _repository.requestAmbulance(
        latitude: position.latitude,
        longitude: position.longitude,
        patientStatus: patientStatus,
      );

      state = BookingSuccess(requestId);
      return requestId;
    } catch (e) {
      state = BookingError(e.toString());
      return null;
    }
  }

  void reset() {
    state = const BookingIdle();
  }
}

final ambulanceControllerProvider = StateNotifierProvider<AmbulanceController, AmbulanceBookingState>((ref) {
  final repository = ref.watch(ambulanceRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return AmbulanceController(
    repository: repository,
    locationService: locationService,
  );
});
