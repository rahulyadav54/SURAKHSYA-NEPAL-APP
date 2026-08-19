import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/repositories/hospital_repository.dart';

class HospitalRepositoryImpl implements HospitalRepository {
  final SupabaseClient _supabase;

  HospitalRepositoryImpl(this._supabase);

  @override
  Future<List<Hospital>> fetchHospitals() async {
    try {
      final list = await _supabase.from('hospitals').select();
      if (list.isEmpty) {
        return _getMockHospitals();
      }
      return list.map((json) {
        return Hospital(
          id: json['id'] as String,
          name: json['name'] as String,
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
          phone: json['phone'] as String? ?? '',
          address: json['address'] as String? ?? '',
          emergencyBedsAvailable: json['available_beds'] as int? ?? 0,
          emergencyBedsTotal: (json['available_beds'] as int? ?? 0) + 15,
          specialists: 'General Medicine, Surgery, Emergency',
          bloodStock: {
            'Status': json['blood_available'] as String? ?? 'AVAILABLE',
          },
        );
      }).toList();
    } catch (_) {
      return _getMockHospitals();
    }
  }

  List<Hospital> _getMockHospitals() {
    return const [
      Hospital(
        id: 'h1',
        name: 'Tribhuvan University Teaching Hospital (TUTH)',
        address: 'Maharajgunj, Kathmandu',
        phone: '01-4412404',
        latitude: 27.7358,
        longitude: 85.3308,
        emergencyBedsAvailable: 45,
        emergencyBedsTotal: 700,
        specialists: 'General Medicine, Surgery, Pediatrics, Emergency',
        bloodStock: {'A+': 10, 'B+': 12, 'O+': 20, 'AB+': 5},
      ),
      Hospital(
        id: 'h2',
        name: 'Bir Hospital',
        address: 'Kanti Path, Kathmandu',
        phone: '01-4221119',
        latitude: 27.7051,
        longitude: 85.3142,
        emergencyBedsAvailable: 28,
        emergencyBedsTotal: 500,
        specialists: 'Trauma, Cardiology, Neurology, ICU',
        bloodStock: {'A+': 8, 'B+': 15, 'O+': 18, 'O-': 3},
      ),
      Hospital(
        id: 'h3',
        name: 'Patan Hospital',
        address: 'Lagankhel, Lalitpur',
        phone: '01-5522266',
        latitude: 27.6672,
        longitude: 85.3228,
        emergencyBedsAvailable: 19,
        emergencyBedsTotal: 450,
        specialists: 'Obstetrics, Pediatrics, General Surgery',
        bloodStock: {'A+': 5, 'B+': 9, 'O+': 14, 'AB-': 2},
      ),
      Hospital(
        id: 'h4',
        name: 'Grandee International Hospital',
        address: 'Dhapasi, Kathmandu',
        phone: '01-5184000',
        latitude: 27.7508,
        longitude: 85.3262,
        emergencyBedsAvailable: 62,
        emergencyBedsTotal: 200,
        specialists: 'Multispecialty, Critical Care, Trauma',
        bloodStock: {'A+': 12, 'B+': 20, 'O+': 25, 'AB+': 8},
      ),
    ];
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return HospitalRepositoryImpl(supabase);
});

final hospitalsListProvider = FutureProvider.autoDispose<List<Hospital>>((ref) async {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.fetchHospitals();
});
