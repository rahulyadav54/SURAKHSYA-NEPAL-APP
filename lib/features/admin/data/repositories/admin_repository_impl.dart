import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
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
  final FirebaseFirestore _firestore;

  AdminRepositoryImpl(this._firestore);

  @override
  Future<List<UserProfile>> fetchProfiles() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => UserProfileModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<EmergencyEvent>> fetchEmergencies() async {
    final query = await _firestore.collection('emergencies').get();
    return query.docs.map((doc) => EmergencyModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<AmbulanceRequest>> fetchAmbulanceRequests() async {
    final query = await _firestore.collection('ambulance_requests').get();
    return query.docs.map((doc) => AmbulanceRequestModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<FireReport>> fetchFireReports() async {
    final query = await _firestore.collection('fire_reports').get();
    return query.docs.map((doc) => FireReportModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<PoliceReport>> fetchPoliceReports() async {
    final query = await _firestore.collection('police_reports').get();
    return query.docs.map((doc) => PoliceReportModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<Hospital>> fetchHospitals() async {
    final query = await _firestore.collection('hospitals').get();
    return query.docs.map((doc) => HospitalModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<Ambulance>> fetchAmbulances() async {
    final query = await _firestore.collection('ambulances').get();
    return query.docs.map((doc) => AmbulanceModel.fromJson(doc.data())).toList();
  }

  @override
  Future<void> updateEmergencyStatus({required String id, required String status}) async {
    await _firestore.collection('emergencies').doc(id).update({'status': status});
  }

  @override
  Future<void> updateAmbulanceRequestStatus({required String id, required String status}) async {
    await _firestore.collection('ambulance_requests').doc(id).update({'status': status});
  }

  @override
  Future<void> updateFireReportStatus({required String id, required String status}) async {
    await _firestore.collection('fire_reports').doc(id).update({'status': status});
  }

  @override
  Future<void> updatePoliceReportStatus({required String id, required String status}) async {
    await _firestore.collection('police_reports').doc(id).update({'status': status});
  }

  @override
  Future<void> updateHospitalBeds({required String id, required int bedsAvailable}) async {
    await _firestore.collection('hospitals').doc(id).update({'emergency_beds_available': bedsAvailable});
  }

  @override
  Future<void> updateAmbulanceStatus({required String id, required String status}) async {
    await _firestore.collection('ambulances').doc(id).update({'status': status});
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AdminRepositoryImpl(firestore);
});
