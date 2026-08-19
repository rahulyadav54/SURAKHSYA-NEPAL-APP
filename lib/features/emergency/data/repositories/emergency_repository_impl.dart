import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../auth/domain/entities/user_role.dart';
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

    try {
      await docRef.set(model.toJson()).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Offline fallback
    }

    // Phase 3: Sync SOS dispatch event to Supabase emergency_events table
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('emergency_events').insert({
        'id': docRef.id,
        'user_id': userId,
        'event_type': 'SOS',
        'status': 'ACTIVE',
        'latitude': latitude,
        'longitude': longitude,
        'description': 'Pulsating SOS button triggered by citizen',
      }).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Offline fallback
    }
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

  @override
  Future<String> createEmergencyRequest({
    required ServiceType serviceType,
    required String emergencyType,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String photoUrl = '',
    String videoUrl = '',
    int peopleAffected = 1,
  }) async {
    final userId = _firebaseAuth.currentUser?.uid ?? 'anonymous';
    final supabase = Supabase.instance.client;

    // Generate unique request number
    final reqNumber = 'SRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Insert emergency request row in Supabase
    final result = await supabase.from('emergency_requests').insert({
      'request_number': reqNumber,
      'citizen_firebase_uid': userId,
      'service_type': serviceType.value,
      'emergency_type': emergencyType,
      'severity': severity,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'photo_url': photoUrl,
      'video_url': videoUrl,
      'people_affected': peopleAffected,
      'status': 'REQUESTED',
    }).select('id').single();

    final requestId = result['id'] as String;

    // Append timeline log to emergency_events table in Supabase
    try {
      await supabase.from('emergency_events').insert({
        'user_id': userId,
        'event_type': 'CREATE_REQUEST',
        'status': 'REQUESTED',
        'latitude': latitude,
        'longitude': longitude,
        'description': 'Emergency request $reqNumber ($emergencyType) submitted.',
      });
    } catch (_) {}

    return requestId;
  }

  @override
  Future<String?> uploadEmergencyMedia(String filePath, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final file = File(filePath);

      // Upload file to the 'emergency-media' storage bucket in Supabase
      final path = 'public/$fileName';
      await supabase.storage.from('emergency-media').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Fetch public link
      final publicUrl = supabase.storage.from('emergency-media').getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNearbyResponders({
    required double latitude,
    required double longitude,
    required ServiceType serviceType,
    int limit = 5,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.rpc('find_nearest_responders', params: {
        'emergency_lat': latitude,
        'emergency_lon': longitude,
        'service_type_val': serviceType.value,
        'limit_val': limit,
      });
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error finding nearest responders: $e');
      return [];
    }
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return EmergencyRepositoryImpl(firestore, auth);
});

