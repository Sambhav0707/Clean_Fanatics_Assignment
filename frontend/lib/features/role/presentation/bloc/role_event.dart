import '../../../../core/session/actor_role.dart';

abstract class RoleEvent {}

class SelectRoleEvent extends RoleEvent {
  final ActorRole role;
  SelectRoleEvent(this.role);
}

class SubmitSessionEvent extends RoleEvent {
  final int actorId;
  final String? name;

  SubmitSessionEvent({required this.actorId, this.name});
}
