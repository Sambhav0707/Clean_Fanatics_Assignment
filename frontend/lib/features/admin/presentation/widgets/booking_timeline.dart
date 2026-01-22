import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/booking_events_cubit.dart';
import '../../domain/entities/booking_event.dart';

class BookingTimeline extends StatelessWidget {
  final int bookingId;

  const BookingTimeline({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BookingEventsCubit(getBookingEvents: sl())..loadEvents(bookingId),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 400, // Fixed height for bottom sheet
        child: Column(
          children: [
            const Text(
              "Booking Timeline",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<BookingEventsCubit, BookingEventsState>(
                builder: (context, state) {
                  if (state is BookingEventsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is BookingEventsError) {
                    return Center(child: Text("Error: ${state.message}"));
                  } else if (state is BookingEventsLoaded) {
                    final events = state.events;
                    if (events.isEmpty) {
                      return const Center(child: Text("No events recorded."));
                    }
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _TimelineItem(
                          event: event,
                          isLast: index == events.length - 1,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BookingEventEntity event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final dt = event.createdAt.toLocal();
    final timeStr = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    final dateStr = "${dt.month}/${dt.day}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Line & Dot
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.toStatus,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${event.actorRole} ${event.actorId != null ? '(#${event.actorId})' : ''}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (event.fromStatus != null)
                    Text(
                      "Changed from ${event.fromStatus}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
