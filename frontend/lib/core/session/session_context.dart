import 'actor_role.dart';

class SessionContext {
  final ActorRole actorRole;
  final int actorId;
  final String? name;

  SessionContext({required this.actorRole, required this.actorId, this.name});
}
