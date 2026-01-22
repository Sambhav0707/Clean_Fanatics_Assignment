import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/role_bloc.dart';
import '../bloc/role_event.dart';
import '../bloc/role_state.dart';
import '../../../../core/session/actor_role.dart';
import 'role_home_placeholder.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoleBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Select Role")),
        body: BlocListener<RoleBloc, RoleState>(
          listener: (context, state) {
            if (state is SessionReady) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleHomePlaceholder()),
              );
            }
          },
          child: const _RoleSelectionView(),
        ),
      ),
    );
  }
}

class _RoleSelectionView extends StatefulWidget {
  const _RoleSelectionView();

  @override
  State<_RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<_RoleSelectionView> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit(ActorRole role) {
    int? actorId;
    String name = _nameController.text.trim();

    if (role == ActorRole.CUSTOMER) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your Name to continue")),
        );
        return;
      }
      // Generate ID for Customer
      actorId = DateTime.now().millisecondsSinceEpoch;
    } else {
      // Provider / Admin: ID is mandatory, Name is optional
      actorId = int.tryParse(_idController.text);
      if (actorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid numeric ID")),
        );
        return;
      }
    }

    context.read<RoleBloc>().add(
      SubmitSessionEvent(actorId: actorId, name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        if (state is RoleInitial) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoleButton(
                  role: ActorRole.CUSTOMER,
                  label: "Customer",
                  onTap: () => context.read<RoleBloc>().add(
                    SelectRoleEvent(ActorRole.CUSTOMER),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  role: ActorRole.PROVIDER,
                  label: "Provider",
                  onTap: () => context.read<RoleBloc>().add(
                    SelectRoleEvent(ActorRole.PROVIDER),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  role: ActorRole.ADMIN,
                  label: "Admin",
                  onTap: () => context.read<RoleBloc>().add(
                    SelectRoleEvent(ActorRole.ADMIN),
                  ),
                ),
              ],
            ),
          );
        } else if (state is RoleSelected) {
          final isCustomer = state.role == ActorRole.CUSTOMER;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Selected Role: ${state.role.name}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Show ID field only if NOT customer
                if (!isCustomer) ...[
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: "Enter Actor ID (int)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],

                // Show Name field if Customer or Admin (optional/required logic)
                // Provider: No name field as per requirements.
                if (state.role != ActorRole.PROVIDER &&
                    state.role != ActorRole.ADMIN) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: isCustomer
                          ? "Enter Name (Required)"
                          : "Enter Name (Optional)",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Just spacing for Provider
                  const SizedBox(height: 24),
                ],

                ElevatedButton(
                  onPressed: () => _submit(state.role),
                  child: Text(isCustomer ? "Login" : "Start Session"),
                ),

                // Button to go back to selection
                TextButton(
                  onPressed: () {
                    // Since we don't have a 'Reset' event, we can rebuild the screen?
                    // Or just push replacement to self to reset.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  child: const Text("Back to Role Selection"),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _RoleButton extends StatelessWidget {
  final ActorRole role;
  final String label;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
      child: Text(label),
    );
  }
}
