import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../bloc/provider_selection_cubit.dart';

class ProviderSelectorModal extends StatelessWidget {
  final bool enableForce;

  const ProviderSelectorModal({super.key, this.enableForce = false});

  @override
  Widget build(BuildContext context) {
    final adminId = sl<SessionContext>().actorId;

    return BlocProvider(
      create: (_) =>
          ProviderSelectionCubit(getAdminProviders: sl(), adminId: adminId)
            ..loadProviders(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              AppBar(
                title: const Text("Select Provider"),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.black,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<ProviderSelectionCubit, ProviderSelectionState>(
                  builder: (context, state) {
                    if (state is ProviderSelectionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProviderSelectionError) {
                      return Center(child: Text("Error: ${state.message}"));
                    } else if (state is ProviderSelectionLoaded) {
                      final providers = state.providers;
                      if (providers.isEmpty) {
                        return const Center(child: Text("No providers found."));
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: providers.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final provider = providers[index];
                          final isBusy = provider.availability == "BUSY";
                          final isAvailable = !isBusy;
                          final canSelect = isAvailable || enableForce;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBusy
                                  ? Colors.red
                                  : Colors.green,
                              child: Icon(
                                isBusy ? Icons.access_time : Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              provider.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: canSelect ? Colors.black : Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              "ID: ${provider.id} • ${provider.availability}",
                              style: TextStyle(
                                color: isBusy ? Colors.red : Colors.green,
                              ),
                            ),
                            trailing: canSelect
                                ? const Icon(Icons.chevron_right)
                                : const Icon(Icons.lock, color: Colors.grey),
                            onTap: canSelect
                                ? () {
                                    Navigator.pop(context, provider.id);
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Provider is BUSY. Use Force Assign to override.",
                                        ),
                                      ),
                                    );
                                  },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
