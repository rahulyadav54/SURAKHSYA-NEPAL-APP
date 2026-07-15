import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required SupabaseClient supabaseClient,
    GoogleSignIn? googleSignIn,
  })  : _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // Get this from Supabase > Authentication > Providers > Google > Web Client ID
              // Or from Google Cloud Console > APIs & Services > Credentials
              serverClientId:
                  '265929694424-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
              scopes: ['email', 'profile'],
            );

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _supabaseClient.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _supabaseClient.auth
        .signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithOtp(String phone) async {
    await _supabaseClient.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<void> verifyOtp(String phone, String token) async {
    await _supabaseClient.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // Sign out any previous session to avoid stale tokens
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google Sign In was cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw const AuthException(
            'Failed to retrieve Google authentication tokens.');
      }

      await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (response == null) return null;
    return UserProfileModel.fromJson(response);
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await _supabaseClient.from('profiles').insert(model.toJson());
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await _supabaseClient
        .from('profiles')
        .update(model.toJson())
        .eq('id', profile.id);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(supabaseClient: supabaseClient);
});
