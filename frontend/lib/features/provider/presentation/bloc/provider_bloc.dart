import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_assigned_bookings.dart';
import '../../domain/usecases/accept_booking.dart';
import '../../domain/usecases/reject_booking.dart';
import '../../domain/usecases/complete_booking.dart';
import 'provider_event.dart';
import 'provider_state.dart';

class ProviderBloc extends Bloc<ProviderEvent, ProviderState> {
  final GetAssignedBookings getAssignedBookings;
  final AcceptBooking acceptBooking;
  final RejectBooking rejectBooking;
  final CompleteBooking completeBooking;
  Timer? _timer;

  ProviderBloc({
    required this.getAssignedBookings,
    required this.acceptBooking,
    required this.rejectBooking,
    required this.completeBooking,
  }) : super(ProviderInitial()) {
    on<LoadAssignedBookings>(_onLoadAssignedBookings);
    on<StartPolling>(_onStartPolling);
    on<PollBookings>(_onPollBookings);
    on<AcceptBookingEvent>(_onAcceptBooking);
    on<RejectBookingEvent>(_onRejectBooking);
    on<CompleteBookingEvent>(_onCompleteBooking);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> _onLoadAssignedBookings(
    LoadAssignedBookings event,
    Emitter<ProviderState> emit,
  ) async {
    emit(ProviderLoading());
    await _fetchBookings(event.providerId, emit);
    add(StartPolling(event.providerId));
  }

  Future<void> _onStartPolling(
    StartPolling event,
    Emitter<ProviderState> emit,
  ) async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(PollBookings(event.providerId));
    });
  }

  Future<void> _onPollBookings(
    PollBookings event,
    Emitter<ProviderState> emit,
  ) async {
    // Silent update (don't emit Loading)
    await _fetchBookings(event.providerId, emit);
  }

  Future<void> _fetchBookings(
    int providerId,
    Emitter<ProviderState> emit,
  ) async {
    final result = await getAssignedBookings(providerId);
    result.fold((failure) => emit(ProviderError(failure.message)), (bookings) {
      debugPrint("ProviderBloc: Loaded ${bookings.length} bookings");
      for (var b in bookings) {
        debugPrint(" - Booking ${b.id}: ${b.status}");
      }
      emit(ProviderLoaded(bookings));

      // Stop polling if no bookings or all are in terminal/read-only states (COMPLETED, REJECTED, CANCELLED, FAILED)
      // Actually, requirement says: Display read-only.
      // If list is empty, maybe stop polling? But new bookings might be assigned.
      // Logic: "Assign Provider" creates ASSIGNED booking.
      // So we MUST poll to see NEW assignments. Use Case: "Log in -> View bookings assigned".
      // If I stop polling when list is empty, I verify nothing.
      // I should ALWAYS poll unless explicitly stopped or error.
      // Wait, earlier plan said: "Stop polling if: Provider has no ASSIGNED / IN_PROGRESS bookings"
      // But if I have nothing, I might get something.
      // Let's stick to ALWAYS POLLING for now, or maybe only stop if error?
      // Let's keep it simple: Poll active.
    });
  }

  Future<void> _onAcceptBooking(
    AcceptBookingEvent event,
    Emitter<ProviderState> emit,
  ) async {
    // Optimistic or waiting? Let's wait.
    final result = await acceptBooking(event.bookingId, event.providerId);
    result.fold(
      (failure) => emit(ProviderError(failure.message)),
      (_) => add(LoadAssignedBookings(event.providerId)), // Refresh immediately
    );
  }

  Future<void> _onRejectBooking(
    RejectBookingEvent event,
    Emitter<ProviderState> emit,
  ) async {
    final result = await rejectBooking(event.bookingId, event.providerId);
    result.fold(
      (failure) => emit(ProviderError(failure.message)),
      (_) => add(LoadAssignedBookings(event.providerId)),
    );
  }

  Future<void> _onCompleteBooking(
    CompleteBookingEvent event,
    Emitter<ProviderState> emit,
  ) async {
    final result = await completeBooking(event.bookingId, event.providerId);
    result.fold(
      (failure) => emit(ProviderError(failure.message)),
      (_) => add(LoadAssignedBookings(event.providerId)),
    );
  }
}
