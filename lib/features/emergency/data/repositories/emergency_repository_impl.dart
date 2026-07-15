import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../models/emergency_model.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final SupabaseClient _supabaseClient;

  EmergencyRepositoryImpl(this._supabaseClient);

  @override
  Future<void> triggerSosAlert({required double latitude, required double longitude}) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user found for triggering SOS alerts.');
    }

    final model = EmergencyModel(
      id: '',
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );

    await _supabaseClient.from('emergencies').insert(model.toJson());
  }

  @override
  Future<List<EmergencyEvent>> fetchEmergencyHistory() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user found for retrieving emergency histories.');
    }

    final response = await _supabaseClient
        .from('emergencies')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list.map((json) => EmergencyModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmergencyRepositoryImpl(client);
});
