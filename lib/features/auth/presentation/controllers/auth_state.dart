import '../../domain/entities/user_profile.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  final UserProfile profile;
  const Authenticated(this.profile);
}

class NeedsProfileCreation extends AuthState {
  final String userId;
  final String? email;
  final String? phone;
  const NeedsProfileCreation({required this.userId, this.email, this.phone});
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
