import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../../../role/presentation/screens/role_selection_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>(),
      child: const _CustomerHomeView(),
    );
  }
}

class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView();

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Logout?"),
            content: const Text(
              "If you go back, all booking data will be removed.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  // Clear session
                  if (sl.isRegistered<SessionContext>()) {
                    sl.unregister<SessionContext>();
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<SessionContext>()) return const SizedBox.shrink();
    final session = sl<SessionContext>();

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await _onWillPop(context);
        if (shouldLogout) {
          // Navigate to Role Selection cleanly
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
          return false; // Prevent default pop since we pushed replacement
        }
        return false;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name ?? "Guest",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "ID: ${session.actorId}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Create Booking"),
                Tab(text: "My Bookings"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_CreateBookingTab(), _MyBookingsTab()],
          ),
        ),
      ),
    );
  }
}

class _CreateBookingTab extends StatelessWidget {
  const _CreateBookingTab();

  @override
  Widget build(BuildContext context) {
    // Session should be available if we are here
    final session = sl<SessionContext>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Ready to Book?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "Booking as: ${session.name}",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<BookingBloc>().add(
                CreateBookingEvent(session.name ?? "Customer"),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking Request Sent")),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Create New Booking"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyBookingsTab extends StatefulWidget {
  const _MyBookingsTab();

  @override
  State<_MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<_MyBookingsTab> {
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
      default:
        return Colors.black;
    }
  }

  bool _canCancel(String status) {
    return status == "PENDING" ||
        status == "ASSIGNED" ||
        status == "IN_PROGRESS";
  }

  Future<void> _confirmCancel(BuildContext context, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text(
          "⚠️ This action cannot be undone. The booking will be permanently cancelled.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Booking"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (sl.isRegistered<SessionContext>()) {
        final userId = sl<SessionContext>().actorId;
        context.read<BookingBloc>().add(CancelBookingEvent(bookingId, userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingError) {
          // Optional: Show snackbar on error, but avoid spamming if polling
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Sync Error: ${state.message}")),
          // );
        }
      },
      builder: (context, state) {
        if (state is BookingLoading && state is! BookingListLoaded) {
          // Only show full loader if we have NO data yet.
          // If we have data (BookingListLoaded), we just stay there while background refreshing (or handle 'isLoading' flag differently if we want a subtle indicator)
          // For simple BLoC logic often 'BookingLoading' replaces the state.
          // If your Bloc emits Loading -> Loaded every time, the UI will flicker.
          // Ideally, polling should use a separate event or a 'silent' load.
          // For this MVP, we will accept the loader or check if we have data.
          // IF the Bloc clears data on Load, it flickers.
          // Let's assume standard behavior: Loading state replaces content.
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookingListLoaded) {
          final bookings =
              state.bookings; // Show ALL bookings, including CANCELLED

          if (bookings.isEmpty) {
            return const Center(child: Text("No active bookings."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              // Show newest first
              final booking = bookings[bookings.length - 1 - index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: _getStatusColor(booking.status),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Booking #${booking.id}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Provider: ${booking.providerId ?? 'Pending Assign'}\nStatus: ${booking.status}",
                        ),
                        trailing: _canCancel(booking.status)
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                ),
                                tooltip: "Cancel Booking",
                                onPressed: () =>
                                    _confirmCancel(context, booking.id),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is BookingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Error: ${state.message}",
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (sl.isRegistered<SessionContext>()) {
                      final userId = sl<SessionContext>().actorId;
                      context.read<BookingBloc>().add(
                        LoadBookingsEvent(userId),
                      );
                    }
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text("No bookings loaded"));
      },
    );
  }
}
