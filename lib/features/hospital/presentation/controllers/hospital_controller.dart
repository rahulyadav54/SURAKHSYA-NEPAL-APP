import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

class HospitalState {
  final Map<String, dynamic>? hospital;
  final List<Map<String, dynamic>> incomingAmbulances;
  final bool isLoading;
  final String? errorMessage;

  const HospitalState({
    this.hospital,
    this.incomingAmbulances = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HospitalState copyWith({
    Map<String, dynamic>? hospital,
    List<Map<String, dynamic>>? incomingAmbulances,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HospitalState(
      hospital: hospital ?? this.hospital,
      incomingAmbulances: incomingAmbulances ?? this.incomingAmbulances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HospitalController extends StateNotifier<HospitalState> {
  final SupabaseClient _supabase;
  final Ref _ref;
  RealtimeChannel? _hospitalSubscription;
  RealtimeChannel? _emergenciesSubscription;

  HospitalController(this._supabase, this._ref) : super(const HospitalState()) {
    _init();
  }

  void _init() async {
    final authState = _ref.read(authControllerProvider);
    if (authState is Authenticated) {
      final firebaseUid = authState.profile.id;
      await _fetchHospital(firebaseUid);
    }
  }

  Future<void> _fetchHospital(String firebaseUid) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _supabase
          .from('hospitals')
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (data != null) {
        state = state.copyWith(hospital: data, isLoading: false);
        _subscribeToHospitalChanges(data['id'] as String);
        _subscribeToIncomingAmbulances(data['id'] as String);
      } else {
        // Fallback: If no hospital record exists for this portal user, create a default one
        final authState = _ref.read(authControllerProvider);
        final name = authState is Authenticated ? authState.profile.fullName : 'Emergency Medical Center';
        final newHospital = await _supabase.from('hospitals').insert({
          'firebase_uid': firebaseUid,
          'name': name,
          'phone': authState is Authenticated ? authState.profile.phone : '+977-1-4410123',
          'address': 'Kathmandu, Nepal',
          'latitude': 27.7172,
          'longitude': 85.3240,
          'emergency_available': true,
          'ambulance_available': true,
          'icu_available': true,
          'available_beds': 15,
          'icu_beds': 5,
          'blood_available': 'AVAILABLE',
        }).select().single();

        state = state.copyWith(hospital: newHospital, isLoading: false);
        _subscribeToHospitalChanges(newHospital['id'] as String);
        _subscribeToIncomingAmbulances(newHospital['id'] as String);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void _subscribeToHospitalChanges(String hospitalId) {
    _hospitalSubscription = _supabase
        .channel('public:hospitals:$hospitalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'hospitals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: hospitalId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              state = state.copyWith(hospital: record);
            }
          },
        )
        .subscribe();
  }

  void _subscribeToIncomingAmbulances(String hospitalId) {
    _emergenciesSubscription = _supabase
        .channel('public:incoming_ambulances:$hospitalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'emergency_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assigned_hospital_id',
            value: hospitalId,
          ),
          callback: (payload) {
            _fetchIncomingAmbulances(hospitalId);
          },
        )
        .subscribe();

    _fetchIncomingAmbulances(hospitalId);
  }

  Future<void> _fetchIncomingAmbulances(String hospitalId) async {
    try {
      final list = await _supabase
          .from('emergency_requests')
          .select('*, responders(*, profiles(*), vehicles(*))')
          .eq('assigned_hospital_id', hospitalId)
          .not('status', 'in', '("COMPLETED", "CANCELLED", "RESOLVED")');

      state = state.copyWith(incomingAmbulances: List<Map<String, dynamic>>.from(list));
    } catch (_) {}
  }

  Future<void> updateCapacity({
    bool? erAvailable,
    int? availableBeds,
    int? icuBeds,
    String? bloodAvailable,
  }) async {
    final hospital = state.hospital;
    if (hospital == null) return;

    final hospitalId = hospital['id'] as String;
    final updates = <String, dynamic>{};
    if (erAvailable != null) updates['emergency_available'] = erAvailable;
    if (availableBeds != null) updates['available_beds'] = availableBeds;
    if (icuBeds != null) updates['icu_beds'] = icuBeds;
    if (bloodAvailable != null) updates['blood_available'] = bloodAvailable;

    try {
      await _supabase.from('hospitals').update(updates).eq('id', hospitalId);
    } catch (_) {}
  }

  Future<void> updateEmergencyStatus(String emergencyId, String status) async {
    try {
      await _supabase.from('emergency_requests').update({
        'status': status,
        if (status == 'ARRIVED') 'arrived_at': DateTime.now().toIso8601String(),
        if (status == 'COMPLETED') 'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', emergencyId);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_hospitalSubscription != null) _supabase.removeChannel(_hospitalSubscription!);
    if (_emergenciesSubscription != null) _supabase.removeChannel(_emergenciesSubscription!);
    super.dispose();
  }
}

final hospitalControllerProvider =
    StateNotifierProvider.autoDispose<HospitalController, HospitalState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return HospitalController(supabase, ref);
});
