import 'package:equatable/equatable.dart';
import '../model/user.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  final bool isSmsMode;
  const LoginInitial({this.isSmsMode = true});

  @override
  List<Object?> get props => [isSmsMode];
}

class SmsSending extends LoginState {}

class SmsSent extends LoginState {
  final String code;
  const SmsSent({required this.code});

  @override
  List<Object?> get props => [code];
}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final LoginResult result;
  final User user;
  const LoginSuccess({required this.result, required this.user});

  @override
  List<Object?> get props => [result.userId];
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
