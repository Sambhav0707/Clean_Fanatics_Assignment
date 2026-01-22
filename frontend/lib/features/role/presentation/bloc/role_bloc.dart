import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/actor_role.dart';
import 'role_event.dart';
import 'role_state.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  ActorRole? _selectedRole;

  RoleBloc() : super(RoleInitial()) {
    on<SelectRoleEvent>((event, emit) {
      _selectedRole = event.role;
      emit(RoleSelected(event.role));
    });

    on<SubmitSessionEvent>((event, emit) {
      final session = SessionContext(
        actorRole: _selectedRole!,
        actorId: event.actorId,
        name: event.name,
      );

      // Unregister if already present (for hot reload/restart safety)
      if (sl.isRegistered<SessionContext>()) {
        sl.unregister<SessionContext>();
      }

      sl.registerSingleton<SessionContext>(session);

      emit(SessionReady());
    });
  }
}
