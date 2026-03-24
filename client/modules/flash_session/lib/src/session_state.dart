import 'package:equatable/equatable.dart';
import 'model/user.dart';

enum SessionStatus { unknown, active, ended }

class SessionState extends Equatable {
  final SessionStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;

  const SessionState._({
    this.status = SessionStatus.unknown,
    this.token,
    this.user,
    this.hasPassword = false,
  });

  const SessionState.unknown() : this._();

  const SessionState.active({
    required String token,
    User? user,
    required bool hasPassword,
  }) : this._(
         status: SessionStatus.active,
         token: token,
         user: user,
         hasPassword: hasPassword,
       );

  const SessionState.ended() : this._(status: SessionStatus.ended);

  @override
  List<Object?> get props => [status, token, user, hasPassword];
}
