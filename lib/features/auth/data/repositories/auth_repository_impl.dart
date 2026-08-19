import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  String? _verificationId;

  AuthRepositoryImpl({
    required fb_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithOtp(String phone) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          final msg = e.message ?? 'Phone verification failed';
          if (msg.contains('BILLING_NOT_ENABLED') ||
              msg.contains(' billing ')) {
            throw Exception(
              'Phone authentication requires a Firebase project with billing enabled. '
              'Please enable billing in your Firebase Console to use phone authentication.',
            );
          }
          if (msg.contains('invalid-phone-number')) {
            throw Exception('The phone number provided is not valid.');
          }
          if (msg.contains('quota')) {
            throw Exception(
              'SMS quota exceeded. Please try again later or contact support.',
            );
          }
          throw Exception(msg);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Phone verification failed';
      if (msg.contains('BILLING_NOT_ENABLED') || msg.contains(' billing ')) {
        throw Exception(
          'Phone authentication requires a Firebase project with billing enabled. '
          'Please enable billing in your Firebase Console to use phone authentication.',
        );
      }
      if (msg.contains('invalid-phone-number')) {
        throw Exception('The phone number provided is not valid.');
      }
      if (msg.contains('quota')) {
        throw Exception(
          'SMS quota exceeded. Please try again later or contact support.',
        );
      }
      throw Exception(msg);
    }
  }

  @override
  Future<void> verifyOtp(String phone, String token) async {
    if (_verificationId == null) {
      throw Exception(
        'Verification code has expired or is invalid. Please request a new OTP.',
      );
    }

    final credential = fb_auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: token,
    );

    try {
      await _firebaseAuth.signInWithCredential(credential);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw Exception(
          'The verification code entered is incorrect. Please check and try again.',
        );
      }
      if (e.code == 'invalid-credential') {
        throw Exception(
          'The verification code has expired. Please request a new OTP.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw Exception(
          'Anonymous sign-in is not enabled. Please enable it in Firebase Console.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = fb_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    // 1. Try querying Supabase profiles table first
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('firebase_uid', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        return UserProfileModel.fromJson(response);
      }
    } catch (_) {
      // Offline fallback
    }

    // 2. Fallback to Firestore if not found or Supabase connection issue
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfileModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);

    // 1. Persist to Supabase profiles table
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('profiles')
          .upsert({
            'firebase_uid': profile.id,
            'full_name': profile.fullName,
            'phone': profile.phone,
            'email': profile.email,
            'role': profile.role.value,
            'blood_group': profile.bloodGroup,
            'allergies': profile.allergies,
            'medical_notes': profile.medicalNotes,
            'emergency_contact_1': profile.emergencyContact1,
            'emergency_contact_2': profile.emergencyContact2,
            'profile_image': profile.profileImage,
            'fcm_token': profile.fcmToken,
          })
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 2. Persist to Firestore for offline fallback
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(model.toJson())
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);

    // 1. Update Supabase profiles table
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('profiles')
          .update({
            'full_name': profile.fullName,
            'phone': profile.phone,
            'email': profile.email,
            'role': profile.role.value,
            'blood_group': profile.bloodGroup,
            'allergies': profile.allergies,
            'medical_notes': profile.medicalNotes,
            'emergency_contact_1': profile.emergencyContact1,
            'emergency_contact_2': profile.emergencyContact2,
            'profile_image': profile.profileImage,
            'fcm_token': profile.fcmToken,
          })
          .eq('firebase_uid', profile.id)
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 2. Update Firestore fallback
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .update(model.toJson());
    } catch (_) {}
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepositoryImpl(firebaseAuth: firebaseAuth, firestore: firestore);
});
