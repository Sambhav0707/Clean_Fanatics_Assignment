import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../../../booking/domain/entities/booking.dart';
import '../bloc/provider_bloc.dart';
import '../bloc/provider_event.dart';
import '../bloc/provider_state.dart';
import '../../../role/presentation/screens/role_selection_screen.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<SessionContext>()) {
      return const Scaffold(body: Center(child: Text("Error: No Session")));
    }
    final session = sl<SessionContext>();
    final providerId = session.actorId!;

    return BlocProvider(
      create: (_) => sl<ProviderBloc>()..add(LoadAssignedBookings(providerId)),
      child: WillPopScope(
        onWillPop: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure you want to end your session?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (sl.isRegistered<SessionContext>()) {
                      sl.unregister<SessionContext>();
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
            return false;
          }
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("Provider Portal (ID: $providerId)"),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Trigger the same dialog logic manually or basically just use pop
                  // which triggers onWillPop if using Navigator.maybePop(context)
                  // BUT Navigator.pop(context) might NOT trigger onWillPop depending on implementation.
                  // It's safer to just replicate the dialog call or call a shared method.
                  // For now, let's just do maybePop which often delegates to WillPopScope if it's the top route.
                  Navigator.maybePop(context);
                },
              ),
            ],
          ),
          body: _ProviderHomeContent(providerId: providerId),
        ),
      ),
    );
  }
}

class _ProviderHomeContent extends StatefulWidget {
  final int providerId;
  const _ProviderHomeContent({required this.providerId});

  @override
  State<_ProviderHomeContent> createState() => _ProviderHomeContentState();
}

class _ProviderHomeContentState extends State<_ProviderHomeContent> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderBloc, ProviderState>(
      listener: (context, state) {
        if (state is ProviderError) {
          // Optional: SnackBar
        }
      },
      builder: (context, state) {
        if (state is ProviderLoading && state is! ProviderLoaded) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProviderLoaded) {
          final activeBooking = state.bookings.isNotEmpty
              ? state.bookings.first
              : null;
          final isBusy = activeBooking != null;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: isBusy ? Colors.red.shade100 : Colors.green.shade100,
                child: Column(
                  children: [
                    Text(
                      "Status: ${isBusy ? 'BUSY' : 'AVAILABLE'}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isBusy ? Colors.red : Colors.green,
                      ),
                    ),
                    if (activeBooking != null)
                      Text(
                        "Current Assignment: Booking #${activeBooking.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: state.bookings.isEmpty
                    ? const Center(child: Text("No bookings assigned."))
                    : ListView.builder(
                        itemCount: state.bookings.length,
                        itemBuilder: (context, index) {
                          final booking = state.bookings[index];
                          return _BookingCard(
                            booking: booking,
                            providerId: widget.providerId,
                          );
                        },
                      ),
              ),
            ],
          );
        } else if (state is ProviderError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        return const Center(child: Text("Initializing..."));
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final int providerId;

  const _BookingCard({required this.booking, required this.providerId});

  Color _getStatusColor(String status) {
    switch (status) {
      case "PENDING":
        return Colors.orange;
      case "ASSIGNED":
        return Colors.blue;
      case "IN_PROGRESS":
        return Colors.purple;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.grey;
      case "FAILED":
        return Colors.red;
      case "REJECTED":
        return Colors.redAccent;
      default:
        return Colors.black;
    }
  }

  void _confirmAction(
    BuildContext context,
    String action,
    String warningMessage,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $action"),
        content: Text(warningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Redundant check removed. Backend handles filtering.
    // Debug print
    debugPrint("Rendering Booking Card: ${booking.id} - ${booking.status}");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking #${booking.id}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(booking.status)),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Customer ID: ${booking.customerId}"),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (booking.status == "ASSIGNED") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _confirmAction(
              context,
              "Reject",
              "This action cannot be undone.",
              () {
                context.read<ProviderBloc>().add(
                  RejectBookingEvent(booking.id, providerId),
                );
              },
            ),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Reject"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _confirmAction(
              context,
              "Accept",
              "Once accepted, you must complete this booking.",
              () {
                context.read<ProviderBloc>().add(
                  AcceptBookingEvent(booking.id, providerId),
                );
              },
            ),
            child: const Text("Accept"),
          ),
        ],
      );
    } else if (booking.status == "IN_PROGRESS") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => _confirmAction(
              context,
              "Complete",
              "This will mark the job as finished.",
              () {
                context.read<ProviderBloc>().add(
                  CompleteBookingEvent(booking.id, providerId),
                );
              },
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Complete Job"),
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // Read-only for other states
  }
}
