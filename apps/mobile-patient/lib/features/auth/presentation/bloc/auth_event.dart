import 'package:equatable/equatable.dart';

/// Base auth event
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Login with email and password
class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Sign up with email and password
class SignUpWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const SignUpWithEmailEvent({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in with Google
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Sign in with Facebook
class SignInWithFacebookEvent extends AuthEvent {
  const SignInWithFacebookEvent();
}

/// Sign in with Apple
class SignInWithAppleEvent extends AuthEvent {
  const SignInWithAppleEvent();
}

/// Logout
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Check authentication status
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Send password reset email
class SendPasswordResetEmailEvent extends AuthEvent {
  final String email;

  const SendPasswordResetEmailEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
