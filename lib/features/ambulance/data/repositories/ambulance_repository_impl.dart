import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../domain/entities/ambulance.dart';
import '../../domain/entities/ambulance_request.dart';
import '../../domain/repositories/ambulance_repository.dart';
import '../models/ambulance_request_model.dart';

class AmbulanceRepositoryImpl implements AmbulanceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  AmbulanceRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<List<Ambulance>> fetchNearbyAmbulances() async {
    return const [
      Ambulance(
        id: 'amb_1',
        driverName: 'Ram Bahadur',
        licensePlate: 'BA 1 PA 1234',
        phone: '9841000001',
        latitude: 27.7172,
        longitude: 85.3240,
        status: 'available',
      ),
      Ambulance(
        id: 'amb_2',
        driverName: 'Sita Shrestha',
        licensePlate: 'BA 2 PA 5678',
        phone: '9841000002',
        latitude: 27.7051,
        longitude: 85.3142,
        status: 'available',
      ),
    ];
  }

  @override
  Future<String> requestAmbulance({
    required double latitude,
    required double longitude,
    required String patientStatus,
  }) async {
    final userId = _firebaseAuth.currentUser?.uid ?? 'anonymous';
    final docRef = _firestore.collection('ambulance_requests').doc();
    final model = AmbulanceRequestModel(
      id: docRef.id,
      userId: userId,
      pickupLatitude: latitude,
      pickupLongitude: longitude,
      patientStatus: patientStatus,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await docRef.set(model.toJson());
    return docRef.id;
  }

  @override
  Stream<AmbulanceRequest> subscribeToRequestUpdates(String requestId) {
    return _firestore
        .collection('ambulance_requests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Request not found');
      }
      return AmbulanceRequestModel.fromJson(snapshot.data()!);
    });
  }
}

final ambulanceRepositoryProvider = Provider<AmbulanceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return AmbulanceRepositoryImpl(firestore, auth);
});
