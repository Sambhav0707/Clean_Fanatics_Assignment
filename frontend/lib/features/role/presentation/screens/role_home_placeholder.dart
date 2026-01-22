import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/actor_role.dart';
import '../../../booking/presentation/screens/customer_home_screen.dart';
import '../../../provider/presentation/screens/provider_home_screen.dart';
import '../../../admin/presentation/screens/admin_home_screen.dart';

class RoleHomePlaceholder extends StatelessWidget {
  const RoleHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<SessionContext>()) {
      return const Scaffold(body: Center(child: Text("Error: No Session")));
    }
    final session = sl<SessionContext>();

    switch (session.actorRole) {
      case ActorRole.CUSTOMER:
        return const CustomerHomeScreen();
      case ActorRole.PROVIDER:
        return const ProviderHomeScreen();
      case ActorRole.ADMIN:
        return const AdminHomeScreen();
    }
  }
}
