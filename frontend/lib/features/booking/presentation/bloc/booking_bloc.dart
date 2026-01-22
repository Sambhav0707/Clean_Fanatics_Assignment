import 'dart:async';
import '../../domain/usecases/cancel_booking.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_context.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/get_booking.dart';
import '../../domain/entities/booking.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateBooking createBooking;
  final GetBooking getBooking;
  final CancelBooking cancelBooking;

  // Store multiple bookings: bookingId -> Booking
  final Map<int, Booking> _bookings = {};
  Timer? _pollingTimer;

  BookingBloc({
    required this.createBooking,
    required this.getBooking,
    required this.cancelBooking,
  }) : super(BookingInitial()) {
    on<CreateBookingEvent>(_onCreateBooking);
    on<StartPollingEvent>(_onStartPolling);
    on<PollBookingEvent>(_onPollBooking);
    on<CancelBookingEvent>(_onCancelBooking);
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    // Show loading if first booking? Or just proceed.
    // If we have data, we just stay in Loaded state ideally, but we need to emit new state.
    // Let's emit Loading only if empty.
    if (_bookings.isEmpty) emit(BookingLoading());

    // Get actor info from session
    final session = sl<SessionContext>(); // Assume it's registered

    final result = await createBooking(
      actorId: session.actorId,
      customerName: event.customerName,
    );

    result.fold((failure) => emit(BookingError(failure.message)), (booking) {
      _bookings[booking.id] = booking;
      // Emit updated list
      emit(BookingListLoaded(_bookings.values.toList()));
      // Auto-start polling after creation
      add(StartPollingEvent(booking.id));
    });
  }

  void _onStartPolling(StartPollingEvent event, Emitter<BookingState> emit) {
    // We don't need to track just one ID anymore.
    // Just ensure timer is running.
    if (_pollingTimer == null || !_pollingTimer!.isActive) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        add(PollBookingEvent());
      });
    }
  }

  Future<void> _onPollBooking(
    PollBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_bookings.isEmpty) return;

    // ### CHANGE THIS ####
    // Poll *all* known bookings (except COMPLETED), so the UI can recover if the backend
    // transitions a "terminal-looking" status like CANCELLED back to ASSIGNED.
    // If your business rule is "cancelled/failed are terminal", filter them out here.
    final idsToPoll = _bookings.values
        .where((b) => b.status != "COMPLETED")
        .map((b) => b.id)
        .toList();

    if (idsToPoll.isEmpty) return;

    // Poll each
    for (final id in idsToPoll) {
      final result = await getBooking(id);
      result.fold(
        (failure) {
          /* ignore transient errors during poll */
        },
        (updated) {
          _bookings[updated.id] = updated;
        },
      );
    }

    emit(BookingListLoaded(_bookings.values.toList()));
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    // We don't want to emit global loading for a single item cancel if we can avoid it,
    // but for simplicity, let's keep it simple or just rely on the reloading.
    // Ideally: Optimistic update or show loading overlay?
    // Let's just emit Loading for safety.
    emit(BookingLoading());
    final result = await cancelBooking(event.bookingId, event.userId);
    result.fold((failure) => emit(BookingError(failure.message)), (success) {
      // Reload list
      add(LoadBookingsEvent(event.userId));
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
