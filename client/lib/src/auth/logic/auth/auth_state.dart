import 'package:equatable/equatable.dart';

import '../../../domain/model/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.token,
    this.user,
    this.hasPassword = false,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated({
    required String token,
    required User? user,
    required bool hasPassword,
  }) : this._(
         status: AuthStatus.authenticated,
         token: token,
         user: user,
         hasPassword: hasPassword,
       );

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, token, user, hasPassword];
}
