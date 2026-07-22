import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../domain/entities/police_report.dart';
import '../../domain/repositories/police_repository.dart';
import '../models/police_report_model.dart';

class PoliceRepositoryImpl implements PoliceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  PoliceRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<String> reportIncident({
    required double latitude,
    required double longitude,
    required String category,
    required String description,
    String? evidencePath,
  }) async {
    final userId = _firebaseAuth.currentUser?.uid ?? 'anonymous';
    final docRef = _firestore.collection('police_reports').doc();
    final model = PoliceReportModel(
      id: docRef.id,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      category: category,
      description: description,
      evidencePath: evidencePath,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await docRef.set(model.toJson());
    return docRef.id;
  }

  @override
  Stream<PoliceReport> subscribeToPoliceReportUpdates(String reportId) {
    return _firestore
        .collection('police_reports')
        .doc(reportId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Report not found');
      }
      return PoliceReportModel.fromJson(snapshot.data()!);
    });
  }
}

final policeRepositoryProvider = Provider<PoliceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PoliceRepositoryImpl(firestore, auth);
});
