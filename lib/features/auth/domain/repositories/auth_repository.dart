import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<void> signUpWithEmailAndPassword(String email, String password);
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signInWithOtp(String phone);
  Future<void> verifyOtp(String phone, String token);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> createUserProfile(UserProfile profile);
  Future<void> updateUserProfile(UserProfile profile);
}
