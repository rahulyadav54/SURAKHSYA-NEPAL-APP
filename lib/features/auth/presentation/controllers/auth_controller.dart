import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/cache_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final CacheService _cacheService;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthController({
    required AuthRepository authRepository,
    required CacheService cacheService,
  })  : _authRepository = authRepository,
        _cacheService = cacheService,
        super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user;

      if (user == null) {
        state = const Unauthenticated();
      } else {
        await checkUserProfile(user.id, user.email, user.phone);
      }
    });
  }

  /// Tries loading user profile from Supabase.
  /// Falls back to local SharedPreferences cache on network timeouts/errors.
  Future<void> checkUserProfile(String userId, String? email, String? phone) async {
    state = const AuthLoading();
    try {
      final profile = await _authRepository.getUserProfile(userId);
      if (profile != null) {
        // Cache profile locally
        await _cacheService.cacheProfile(profile);
        state = Authenticated(profile);
      } else {
        state = NeedsProfileCreation(userId: userId, email: email, phone: phone);
      }
    } catch (e) {
      // Offline fallback: load cached profile
      final cached = _cacheService.getCachedProfile();
      if (cached != null && cached.id == userId) {
        state = Authenticated(cached);
      } else {
        // The user is authenticated but the profile could not be loaded
        // (e.g. network error, RLS policy, or missing table). Instead of
        // hard-failing and trapping the user at login, route them to profile
        // creation so they can continue into the app.
        state = NeedsProfileCreation(userId: userId, email: email, phone: phone);
      }
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    state = const AuthLoading();
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password);
      // Supabase requires email confirmation by default, so no session/auth
      // event fires here. Reset to a usable state so the UI does not hang
      // on a perpetual loading spinner.
      state = const Unauthenticated();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithOtp(String phone) async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithOtp(phone);
      state = const Unauthenticated();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String token) async {
    state = const AuthLoading();
    try {
      await _authRepository.verifyOtp(phone, token);
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithGoogle();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _authRepository.signOut();
      await _cacheService.clearCache();
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<bool> createUserProfile({
    required String fullName,
    required String bloodGroup,
    required String allergies,
    required String medicalNotes,
    required String emergencyContact1,
    required String emergencyContact2,
  }) async {
    final currentState = state;
    if (currentState is! NeedsProfileCreation) {
      state = const AuthError('Illegal state: User does not require profile creation.');
      return false;
    }

    state = const AuthLoading();
    try {
      final profile = UserProfile(
        id: currentState.userId,
        fullName: fullName,
        email: currentState.email ?? '',
        phone: currentState.phone ?? '',
        bloodGroup: bloodGroup,
        allergies: allergies,
        medicalNotes: medicalNotes,
        emergencyContact1: emergencyContact1,
        emergencyContact2: emergencyContact2,
      );

      await _authRepository.createUserProfile(profile);
      await _cacheService.cacheProfile(profile);
      state = Authenticated(profile);
      return true;
    } catch (e) {
      state = AuthError('Error creating profile: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  return AuthController(
    authRepository: repository,
    cacheService: cache,
  );
});
