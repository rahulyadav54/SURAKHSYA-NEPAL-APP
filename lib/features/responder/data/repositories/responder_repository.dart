import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/domain/entities/user_role.dart';

class ResponderRepository {
  final SupabaseClient _supabase;

  ResponderRepository(this._supabase);

  /// Registers a new responder and their vehicle in Supabase
  Future<void> registerResponder({
    required String firebaseUid,
    required String employeeId,
    required String vehicleNumber,
    required String vehicleType,
    required ServiceType serviceType,
  }) async {
    // 1. Fetch the user profile ID matching the firebaseUid
    final profileResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception('User profile not found. Please create a profile first.');
    }
    final profileId = profileResponse['id'] as String;

    // Update profile role to RESPONDER
    await _supabase
        .from('profiles')
        .update({'role': 'RESPONDER'})
        .eq('firebase_uid', firebaseUid);

    // 2. Insert new vehicle record
    final vehicleInsert = await _supabase
        .from('vehicles')
        .insert({
          'vehicle_number': vehicleNumber,
          'vehicle_type': vehicleType,
          'service_type': serviceType.value,
          'status': 'ACTIVE',
        })
        .select('id')
        .single();

    final vehicleId = vehicleInsert['id'] as String;

    // 3. Insert responder record
    final responderInsert = await _supabase
        .from('responders')
        .insert({
          'firebase_uid': firebaseUid,
          'profile_id': profileId,
          'service_type': serviceType.value,
          'employee_id': employeeId,
          'verification_status': 'PENDING',
          'availability_status': 'OFFLINE',
          'vehicle_id': vehicleId,
        })
        .select('id')
        .single();

    final responderId = responderInsert['id'] as String;

    // 4. Update vehicle to point back to the responder (circular reference link)
    await _supabase
        .from('vehicles')
        .update({'responder_id': responderId})
        .eq('id', vehicleId);
  }

  /// Checks the verification status of a responder
  Future<Map<String, dynamic>?> getResponderStatus(String firebaseUid) async {
    final response = await _supabase
        .from('responders')
        .select('id, verification_status, availability_status, service_type')
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();
    return response;
  }

  /// Updates availability status of a responder
  Future<void> updateAvailability(String firebaseUid, String status) async {
    await _supabase
        .from('responders')
        .update({'availability_status': status})
        .eq('firebase_uid', firebaseUid);
  }

  /// Fetches all responders, including registration details and profile info
  Future<List<Map<String, dynamic>>> fetchAllResponders() async {
    final response = await _supabase
        .from('responders')
        .select('*, profiles(*), vehicles(*)');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Admin approval/rejection method
  Future<void> verifyResponder(String responderId, String status) async {
    await _supabase
        .from('responders')
        .update({'verification_status': status})
        .eq('id', responderId);
  }
}

final responderRepositoryProvider = Provider<ResponderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ResponderRepository(supabase);
});
