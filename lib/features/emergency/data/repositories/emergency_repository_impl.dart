import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../models/emergency_model.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  EmergencyRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<void> triggerSosAlert({required double latitude, required double longitude}) async {
    final userId = _firebaseAuth.currentUser?.uid ?? 'anonymous';
    final docRef = _firestore.collection('emergencies').doc();
    final model = EmergencyModel(
      id: docRef.id,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      status: 'active',
      createdAt: DateTime.now(),
    );

    await docRef.set(model.toJson());
  }

  @override
  Future<List<EmergencyEvent>> fetchEmergencyHistory() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return [];

    final query = await _firestore
        .collection('emergencies')
        .where('userId', isEqualTo: userId)
        .get();

    return query.docs
        .map((doc) => EmergencyModel.fromJson(doc.data()))
        .toList();
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return EmergencyRepositoryImpl(firestore, auth);
});
