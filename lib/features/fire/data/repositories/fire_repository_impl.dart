import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../domain/entities/fire_report.dart';
import '../../domain/repositories/fire_repository.dart';
import '../models/fire_report_model.dart';

class FireRepositoryImpl implements FireRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  FireRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<String> reportFire({
    required double latitude,
    required double longitude,
    String? imagePath,
    String? videoPath,
    required String description,
    required String aiSeverity,
  }) async {
    final userId = _firebaseAuth.currentUser?.uid ?? 'anonymous';
    final docRef = _firestore.collection('fire_reports').doc();
    final model = FireReportModel(
      id: docRef.id,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      imagePath: imagePath,
      videoPath: videoPath,
      description: description,
      aiPredictedSeverity: aiSeverity,
      createdAt: DateTime.now(),
      status: 'dispatched',
    );

    await docRef.set(model.toJson());
    return docRef.id;
  }

  @override
  Stream<FireReport> subscribeToFireReportUpdates(String reportId) {
    return _firestore
        .collection('fire_reports')
        .doc(reportId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Report not found');
      }
      return FireReportModel.fromJson(snapshot.data()!);
    });
  }
}

final fireRepositoryProvider = Provider<FireRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FireRepositoryImpl(firestore, auth);
});
