import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../widgets/booking_timeline.dart';
import '../widgets/provider_selector_modal.dart';
import '../../../role/presentation/screens/role_selection_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>(),
      child: WillPopScope(
        onWillPop: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure you want to end your session?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), // Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate back or clear session if needed
                    // Note: Admin session clearing might be different, but for now we just exit.
                    // Ideally we should clear sl<SessionContext>()
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
            // For Admin, we probably just pop, but if we want to force back to Role Selection:
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
            title: const Text("Admin Ops Panel"),
            backgroundColor: Colors.blueGrey,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  Navigator.maybePop(context);
                },
              ),
            ],
          ),
          body: _AdminHomeView(),
        ),
      ),
    );
  }
}

class _AdminHomeView extends StatefulWidget {
  const _AdminHomeView();

  @override
  State<_AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<_AdminHomeView> {
  final _bookingIdController = TextEditingController();
  final _providerIdController =
      TextEditingController(); // For Force Assign to specific provider

  int get _adminId => sl<SessionContext>().actorId!;

  Timer? _timer;
  Booking?
  _lastLoadedBooking; // ### CHANGE THIS #### Preserve booking during polling

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _pollBooking();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bookingIdController.dispose();
    _providerIdController.dispose();
    super.dispose();
  }

  void _loadBooking() {
    final id = int.tryParse(_bookingIdController.text);
    if (id != null) {
      _lastLoadedBooking =
          null; // ### CHANGE THIS #### Clear when loading new booking
      context.read<AdminBloc>().add(SearchBookingById(id));
    }
  }

  void _pollBooking() {
    final id = int.tryParse(_bookingIdController.text);
    if (id != null) {
      context.read<AdminBloc>().add(PollBookingById(id));
    }
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("⚠️ This is an irreversible admin action."),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Make Safe (Cancel)"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text(
              "Proceed Anyway",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminError) {
          _lastLoadedBooking = null; // ### CHANGE THIS #### Clear on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${state.message}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        Booking? selectedBooking;
        if (state is AdminBookingLoaded) {
          selectedBooking = state.booking;
          _lastLoadedBooking =
              state.booking; // ### CHANGE THIS #### Update preserved booking
        } else if (state is AdminLoading && _lastLoadedBooking != null) {
          // ### CHANGE THIS #### Keep showing booking during loading if we have one (only for manual loads)
          selectedBooking = _lastLoadedBooking;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Input Area
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bookingIdController,
                      decoration: const InputDecoration(
                        labelText: "Booking ID",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loadBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text("Load"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Context / Status Area
              if (state is AdminLoading && selectedBooking == null)
                const Center(child: CircularProgressIndicator())
              else if (selectedBooking != null)
                _buildBookingContext(selectedBooking)
              else
                const Center(
                  child: Text(
                    "No Booking Loaded. Enter an ID to manage.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingContext(Booking booking) {
    return Card(
      elevation: 4,
      color: Colors.grey[50], // internal tool feel
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Booking #${booking.id}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _infoRow("Status", booking.status),
            _infoRow("Customer ID", booking.customerId.toString()),
            _infoRow(
              "Provider ID",
              booking.providerId?.toString() ?? "Unassigned",
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("View Event Timeline"),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BookingTimeline(bookingId: booking.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Operational Actions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    return Column(
      children: [
        // ASSIGN PROVIDER (Normal)
        if (booking.status == "PENDING" || booking.status == "REJECTED") ...[
          _ActionButton(
            label: "Assign Provider",
            color: Colors.green,
            icon: Icons.person_add,
            onPressed: () async {
              final selectedProviderId = await showModalBottomSheet<int>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ProviderSelectorModal(),
              );

              if (selectedProviderId != null && context.mounted) {
                context.read<AdminBloc>().add(
                  AssignBookingEvent(booking.id, selectedProviderId, _adminId),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],

        // RETRY (Only if REJECTED or FAILED)
        if (booking.status == "REJECTED" || booking.status == "FAILED")
          _ActionButton(
            label: "Retry Booking",
            color: Colors.orange,
            icon: Icons.refresh,
            onPressed: () => _confirmAction(
              "Retry Booking #${booking.id}",
              "This will reset the booking status to PENDING.",
              () {
                context.read<AdminBloc>().add(
                  RetryBookingEvent(booking.id, _adminId),
                );
              },
            ),
          ),

        // FORCE ASSIGN (Only if PENDING, REJECTED, or maybe ASSIGNED/IN_PROGRESS?)
        // Backend overrides any state except COMPLETED.
        if (booking.status != "COMPLETED") ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _providerIdController,
                  decoration: const InputDecoration(
                    labelText: "Target Provider ID",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: "Force Assign",
                color: Colors.blue,
                icon: Icons.assignment_ind,
                isShort: true,
                onPressed: () {
                  final providerId = int.tryParse(_providerIdController.text);
                  if (providerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter a valid Provider ID"),
                      ),
                    );
                    return;
                  }
                  _confirmAction(
                    "Force Assign Booking #${booking.id}",
                    "This will assign the booking to Provider #$providerId regardless of availability.",
                    () {
                      context.read<AdminBloc>().add(
                        ForceAssignBookingEvent(
                          booking.id,
                          providerId,
                          _adminId,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],

        // FORCE CANCEL (Active states)
        if (booking.status != "COMPLETED" && booking.status != "CANCELLED") ...[
          const SizedBox(height: 8),
          _ActionButton(
            label: "Force Cancel",
            color: Colors.red,
            icon: Icons.cancel,
            onPressed: () => _confirmAction(
              "Force Cancel Booking #${booking.id}",
              "This will immediately CANCEL the active booking.",
              () {
                context.read<AdminBloc>().add(
                  ForceCancelBookingEvent(booking.id, _adminId),
                );
              },
            ),
          ),
        ],

        // MARK FAILED (Active states)
        if (booking.status != "COMPLETED" && booking.status != "FAILED") ...[
          const SizedBox(height: 8),
          _ActionButton(
            label: "Mark As Failed",
            color: Colors.deepOrangeAccent,
            icon: Icons.error_outline,
            onPressed: () => _confirmAction(
              "Mark Booking #${booking.id} FAILED",
              "This will mark the booking as FAILED (e.g. system error).",
              () {
                context.read<AdminBloc>().add(
                  MarkBookingFailedEvent(booking.id, _adminId),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isShort;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
    this.isShort = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );

    if (isShort) {
      return ElevatedButton.icon(
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
