import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';

// Stream of all active emergency requests (not COMPLETED, CANCELLED, RESOLVED)
final activeEmergenciesStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> fetchLatest() async {
    try {
      final data = await supabase
          .from('emergency_requests')
          .select('*, responders(*, profiles(*))')
          .not('status', 'in', '("COMPLETED", "CANCELLED", "RESOLVED")')
          .order('created_at', ascending: false);
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  fetchLatest();

  final channel = supabase
      .channel('public:emergency_requests_dispatcher')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_requests',
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

// Stream of all responders who are ONLINE (AVAILABLE or EN_ROUTE or BUSY)
final activeRespondersStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> fetchLatest() async {
    try {
      final data = await supabase
          .from('responders')
          .select('*, profiles(*), vehicles(*)')
          .not('availability_status', 'eq', 'OFFLINE');
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  fetchLatest();

  final channel = supabase
      .channel('public:responders_dispatcher')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'responders',
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

// Stream of resources count summary
final resourcesSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final List<dynamic> responders = await supabase.from('responders').select('availability_status, vehicles(vehicle_type)');
    final List<dynamic> hospitals = await supabase.from('profiles').select('role').eq('role', 'HOSPITAL');

    int activeAmbulances = 0;
    int totalAmbulances = 0;
    int activePolice = 0;
    int totalPolice = 0;
    int activeFire = 0;
    int totalFire = 0;

    for (var r in responders) {
      final vehicle = r['vehicles'] as Map<String, dynamic>?;
      final type = vehicle?['vehicle_type'] as String? ?? '';
      final isOnline = r['availability_status'] != 'OFFLINE';

      if (type.toLowerCase().contains('ambulance')) {
        totalAmbulances++;
        if (isOnline) activeAmbulances++;
      } else if (type.toLowerCase().contains('police') || type.toLowerCase().contains('patrol')) {
        totalPolice++;
        if (isOnline) activePolice++;
      } else {
        totalFire++;
        if (isOnline) activeFire++;
      }
    }

    return {
      'ambulances': '$activeAmbulances / ${totalAmbulances > 0 ? totalAmbulances : 5}',
      'police': '$activePolice / ${totalPolice > 0 ? totalPolice : 8}',
      'fire': '$activeFire / ${totalFire > 0 ? totalFire : 3}',
      'hospitals': '${hospitals.length} Connected',
    };
  } catch (_) {
    return {
      'ambulances': '0 / 0',
      'police': '0 / 0',
      'fire': '0 / 0',
      'hospitals': '0 Connected',
    };
  }
});

class DispatcherController extends StateNotifier<bool> {
  final SupabaseClient _supabase;
  DispatcherController(this._supabase) : super(false);

  Future<bool> manuallyDispatch(String emergencyId, String responderId) async {
    state = true;
    try {
      // 1. Create a dispatch request entry
      await _supabase.from('dispatch_requests').insert({
        'emergency_id': emergencyId,
        'responder_id': responderId,
        'status': 'PENDING',
        'sent_at': DateTime.now().toIso8601String(),
      });

      // 2. Mark emergency status as DISPATCHING
      await _supabase.from('emergency_requests').update({
        'status': 'DISPATCHING',
      }).eq('id', emergencyId);

      state = false;
      return true;
    } catch (_) {
      state = false;
      return false;
    }
  }
}

final dispatcherControllerProvider = StateNotifierProvider.autoDispose<DispatcherController, bool>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DispatcherController(supabase);
});
