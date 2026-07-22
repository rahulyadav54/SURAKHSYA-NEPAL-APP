import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithOtp(String phone) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        throw Exception(e.message ?? 'Phone verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  @override
  Future<void> verifyOtp(String phone, String token) async {
    if (_verificationId == null) {
      throw Exception('Verification code has expired or is invalid. Please request a new OTP.');
    }
    final credential = fb_auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: token,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In was cancelled by user.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromJson(doc.data()!);
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(model.toJson())
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Fire-and-forget/offline write fallback to keep UI responsive
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await _firestore.collection('users').doc(profile.id).update(model.toJson());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepositoryImpl(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
});
