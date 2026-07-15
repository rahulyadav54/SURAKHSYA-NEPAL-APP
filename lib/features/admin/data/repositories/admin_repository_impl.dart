import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/data/models/user_profile_model.dart';
import '../../../emergency/domain/entities/emergency_event.dart';
import '../../../emergency/data/models/emergency_model.dart';
import '../../../ambulance/domain/entities/ambulance.dart';
import '../../../ambulance/data/models/ambulance_model.dart';
import '../../../ambulance/domain/entities/ambulance_request.dart';
import '../../../ambulance/data/models/ambulance_request_model.dart';
import '../../../fire/domain/entities/fire_report.dart';
import '../../../fire/data/models/fire_report_model.dart';
import '../../../police/domain/entities/police_report.dart';
import '../../../police/data/models/police_report_model.dart';
import '../../../hospital/domain/entities/hospital.dart';
import '../../../hospital/data/models/hospital_model.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final SupabaseClient _supabaseClient;

  AdminRepositoryImpl(this._supabaseClient);

  @override
  Future<List<UserProfile>> fetchProfiles() async {
    final response = await _supabaseClient.from('profiles').select().order('full_name', ascending: true);
    final list = response as List<dynamic>;
    return list.map((json) => UserProfileModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<EmergencyEvent>> fetchEmergencies() async {
    final response = await _supabaseClient.from('emergencies').select().order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((json) => EmergencyModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AmbulanceRequest>> fetchAmbulanceRequests() async {
    final response = await _supabaseClient.from('ambulance_requests').select('*, ambulances(*)').order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((json) => AmbulanceRequestModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<FireReport>> fetchFireReports() async {
    final response = await _supabaseClient.from('fire_reports').select().order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((json) => FireReportModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PoliceReport>> fetchPoliceReports() async {
    final response = await _supabaseClient.from('police_reports').select().order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((json) => PoliceReportModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Hospital>> fetchHospitals() async {
    final response = await _supabaseClient.from('hospitals').select().order('name', ascending: true);
    final list = response as List<dynamic>;
    return list.map((json) => HospitalModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Ambulance>> fetchAmbulances() async {
    final response = await _supabaseClient.from('ambulances').select().order('driver_name', ascending: true);
    final list = response as List<dynamic>;
    return list.map((json) => AmbulanceModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> updateEmergencyStatus({required String id, required String status}) async {
    await _supabaseClient.from('emergencies').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> updateAmbulanceRequestStatus({required String id, required String status}) async {
    await _supabaseClient.from('ambulance_requests').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> updateFireReportStatus({required String id, required String status}) async {
    await _supabaseClient.from('fire_reports').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> updatePoliceReportStatus({required String id, required String status}) async {
    await _supabaseClient.from('police_reports').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> updateHospitalBeds({required String id, required int bedsAvailable}) async {
    await _supabaseClient.from('hospitals').update({'emergency_beds_available': bedsAvailable}).eq('id', id);
  }

  @override
  Future<void> updateAmbulanceStatus({required String id, required String status}) async {
    await _supabaseClient.from('ambulances').update({'status': status}).eq('id', id);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminRepositoryImpl(client);
});
