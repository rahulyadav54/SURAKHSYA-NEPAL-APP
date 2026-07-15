import '../entities/hospital.dart';

abstract class HospitalRepository {
  Future<List<Hospital>> fetchHospitals();
}
