import 'package:equatable/equatable.dart';
import '../model/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final bool hasPassword;

  const AuthAuthenticated({required this.user, required this.hasPassword});

  @override
  List<Object?> get props => [user.userId, hasPassword];
}

class AuthUnauthenticated extends AuthState {}
