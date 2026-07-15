import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/ambulance.dart';
import '../../domain/entities/ambulance_request.dart';
import '../../domain/repositories/ambulance_repository.dart';
import '../models/ambulance_model.dart';
import '../models/ambulance_request_model.dart';

class AmbulanceRepositoryImpl implements AmbulanceRepository {
  final SupabaseClient _supabaseClient;

  AmbulanceRepositoryImpl(this._supabaseClient);

  @override
  Future<List<Ambulance>> fetchNearbyAmbulances() async {
    final response = await _supabaseClient
        .from('ambulances')
        .select()
        .eq('status', 'AVAILABLE');

    final list = response as List<dynamic>;
    return list.map((json) => AmbulanceModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> requestAmbulance({
    required double latitude,
    required double longitude,
    required String patientStatus,
  }) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user found for ambulance bookings.');
    }

    final response = await _supabaseClient.from('ambulance_requests').insert({
      'user_id': userId,
      'pickup_latitude': latitude,
      'pickup_longitude': longitude,
      'patient_status': patientStatus,
      'status': 'PENDING',
    }).select().single();

    return response['id'] as String;
  }

  @override
  Stream<AmbulanceRequest> subscribeToRequestUpdates(String requestId) {
    final controller = StreamController<AmbulanceRequest>();

    // Initial fetch to prime the stream
    _fetchAndEmit(requestId, controller);

    // Setup PostgreSQL realtime channel subscription
    final channel = _supabaseClient.channel('ambulance_req_updates_$requestId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ambulance_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: requestId,
      ),
      callback: (payload) {
        // Re-fetch the record with driver profile details
        _fetchAndEmit(requestId, controller);
      },
    ).subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmit(String requestId, StreamController<AmbulanceRequest> controller) async {
    try {
      final response = await _supabaseClient
          .from('ambulance_requests')
          .select('*, ambulances(*)')
          .eq('id', requestId)
          .single();

      final model = AmbulanceRequestModel.fromJson(response);
      if (!controller.isClosed) {
        controller.add(model);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
}

final ambulanceRepositoryProvider = Provider<AmbulanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AmbulanceRepositoryImpl(client);
});
