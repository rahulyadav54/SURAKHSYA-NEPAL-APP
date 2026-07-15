import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../models/hospital_model.dart';

class HospitalRepositoryImpl implements HospitalRepository {
  final SupabaseClient _supabaseClient;

  HospitalRepositoryImpl(this._supabaseClient);

  @override
  Future<List<Hospital>> fetchHospitals() async {
    final response = await _supabaseClient
        .from('hospitals')
        .select()
        .order('name', ascending: true);

    final list = response as List<dynamic>;
    return list.map((json) => HospitalModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HospitalRepositoryImpl(client);
});
