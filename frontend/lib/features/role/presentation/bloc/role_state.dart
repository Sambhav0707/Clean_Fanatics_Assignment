import '../../../../core/session/actor_role.dart';

abstract class RoleState {}

class RoleInitial extends RoleState {}

class RoleSelected extends RoleState {
  final ActorRole role;
  RoleSelected(this.role);
}

class SessionReady extends RoleState {}
