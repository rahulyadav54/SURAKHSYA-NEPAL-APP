import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hospital.dart';
import '../../data/repositories/hospital_repository_impl.dart';

/// Provider that fetches the full directory of hospitals from database
final hospitalsListProvider = FutureProvider.autoDispose<List<Hospital>>((ref) async {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.fetchHospitals();
});
