import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/services/cache_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final CacheService _cacheService;
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSubscription;

  AuthController({
    required AuthRepository authRepository,
    required CacheService cacheService,
    required FirebaseAuth firebaseAuth,
  }) : _authRepository = authRepository,
       _cacheService = cacheService,
       _firebaseAuth = firebaseAuth,
       super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) async {
      if (user == null) {
        state = const Unauthenticated();
      } else {
        await checkUserProfile(user.uid, user.email, user.phoneNumber);
      }
    });
  }

  String _authenticationMessage(Object error) {
    final text = error.toString();
    if (text.contains('admin-restricted-operation')) {
      return 'Email/password sign-in is disabled for this Firebase project.';
    }
    if (text.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled yet. Please contact support.';
    }
    if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in is not configured for this Android app yet.';
    }
    if (text.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> checkUserProfile(
    String userId,
    String? email,
    String? phone,
  ) async {
    state = const AuthLoading();
    try {
      final profile = await _authRepository.getUserProfile(userId);
      if (profile != null) {
        await _cacheService.cacheProfile(profile);
        state = Authenticated(profile);
      } else {
        state = NeedsProfileCreation(
          userId: userId,
          email: email,
          phone: phone,
        );
      }
    } catch (e) {
      final cached = _cacheService.getCachedProfile();
      if (cached != null && cached.id == userId) {
        state = Authenticated(cached);
      } else {
        state = NeedsProfileCreation(
          userId: userId,
          email: email,
          phone: phone,
        );
      }
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    state = const AuthLoading();
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      state = AuthError(_authenticationMessage(e));
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      state = AuthError(_authenticationMessage(e));
      return false;
    }
  }

  Future<bool> signInWithOtp(String phone) async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithOtp(phone);
      // For mock/demo mode, we don't need to wait for auth state changes
      // The verification ID is already set in the repository
      state = const Unauthenticated();
      return true;
    } catch (e) {
      state = AuthError(_authenticationMessage(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String token) async {
    state = const AuthLoading();
    try {
      await _authRepository.verifyOtp(phone, token);
      // After successful OTP verification, the auth state listener will
      // automatically handle the transition to Authenticated or NeedsProfileCreation
      // We don't need to manually set the state here
      return true;
    } catch (e) {
      state = AuthError(_authenticationMessage(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      await _authRepository.signInWithGoogle();
      return true;
    } catch (e) {
      state = AuthError(_authenticationMessage(e));
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
    UserRole role = UserRole.citizen,
    ServiceType? serviceType,
  }) async {
    final currentState = state;
    String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    String? email;
    String? phone;

    if (currentState is NeedsProfileCreation) {
      userId = currentState.userId;
      email = currentState.email;
      phone = currentState.phone;
    }

    state = const AuthLoading();
    try {
      final profile = UserProfile(
        id: userId,
        fullName: fullName,
        email: email ?? '',
        phone: phone ?? '',
        bloodGroup: bloodGroup,
        allergies: allergies,
        medicalNotes: medicalNotes,
        emergencyContact1: emergencyContact1,
        emergencyContact2: emergencyContact2,
        role: role,
        serviceType: serviceType,
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

  /// Switch user role for testing / portal access
  Future<void> switchRole(UserRole newRole, {ServiceType? serviceType}) async {
    final currentState = state;
    if (currentState is Authenticated) {
      final updatedProfile = currentState.profile.copyWith(
        role: newRole,
        serviceType: serviceType ?? currentState.profile.serviceType,
      );
      await _authRepository.updateUserProfile(updatedProfile);
      await _cacheService.cacheProfile(updatedProfile);
      state = Authenticated(updatedProfile);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    final cache = ref.watch(cacheServiceProvider);
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    return AuthController(
      authRepository: repository,
      cacheService: cache,
      firebaseAuth: firebaseAuth,
    );
  },
);
