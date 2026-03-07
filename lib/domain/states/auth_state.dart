// lib/domain/states/auth_state.dart
import '../entities/user_entity.dart';

abstract class AuthState {
  const AuthState();

  get user => null;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(UserEntity user) authenticated,
    required T Function() unauthenticated,
    required T Function(String error) error,
  }) {
    if (this is AuthInitial) {
      return initial();
    } else if (this is AuthLoading) {
      return loading();
    } else if (this is AuthAuthenticated) {
      return authenticated((this as AuthAuthenticated).user);
    } else if (this is AuthUnauthenticated) {
      return unauthenticated();
    } else if (this is AuthError) {
      return error((this as AuthError).message);
    } else {
      throw Exception('Unknown AuthState: $this');
    }
  }
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
