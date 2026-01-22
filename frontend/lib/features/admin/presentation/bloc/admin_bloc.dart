import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/booking/domain/entities/booking.dart';
import 'admin_event.dart';
import 'admin_state.dart';
import '../../../booking/domain/usecases/get_booking.dart';
import '../../domain/usecases/retry_booking.dart';
import '../../domain/usecases/force_cancel_booking.dart';
import '../../domain/usecases/mark_booking_failed.dart';
import '../../domain/usecases/force_assign_booking.dart';
import '../../domain/usecases/assign_booking.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetBooking getBooking;
  final RetryBooking retryBooking;
  final ForceCancelBooking forceCancelBooking;
  final MarkBookingFailed markBookingFailed;
  final ForceAssignBooking forceAssignBooking;
  final AssignBooking assignBooking;

  AdminBloc({
    required this.getBooking,
    required this.retryBooking,
    required this.forceCancelBooking,
    required this.markBookingFailed,
    required this.forceAssignBooking,
    required this.assignBooking,
  }) : super(AdminInitial()) {
    on<SearchBookingById>(_onSearchBookingById);
    on<RetryBookingEvent>(_onRetryBooking);
    on<AssignBookingEvent>(_onAssignBooking);
    on<ForceCancelBookingEvent>(_onForceCancelBooking);
    on<MarkBookingFailedEvent>(_onMarkBookingFailed);
    on<ForceAssignBookingEvent>(_onForceAssignBooking);
    on<PollBookingById>(_onPollBookingById);
  }

  Future<void> _onSearchBookingById(
    SearchBookingById event,
    Emitter<AdminState> emit,
  ) async {
    // Only emit loading if we are loading a DIFFERENT booking
    // or if we are not currently loaded.
    bool shouldShowLoader = true;
    if (state is AdminBookingLoaded) {
      final currentBooking = (state as AdminBookingLoaded).booking;
      if (currentBooking.id == event.bookingId) {
        shouldShowLoader = false;
      }
    }

    if (shouldShowLoader) {
      emit(AdminLoading());
    }

    await _fetchBooking(event.bookingId, emit);
  }

  Future<void> _onPollBookingById(
    PollBookingById event,
    Emitter<AdminState> emit,
  ) async {
    // Silent refresh - only emit if booking data changed
    final result = await getBooking(event.bookingId);
    result.fold(
      (failure) {
        // Only emit error if we're not already in an error state for this booking
        if (state is! AdminError ||
            (state is AdminError &&
                (state as AdminError).message != failure.message)) {
          emit(AdminError(failure.message));
        }
      },
      (booking) {
        // Only emit if booking data actually changed
        if (state is AdminBookingLoaded) {
          final currentBooking = (state as AdminBookingLoaded).booking;
          if (_hasBookingChanged(currentBooking, booking)) {
            emit(AdminBookingLoaded(booking));
          }
          // If booking hasn't changed, don't emit anything (silent update)
        } else {
          // If not currently loaded, emit the booking
          emit(AdminBookingLoaded(booking));
        }
      },
    );
  }

  bool _hasBookingChanged(Booking current, Booking updated) {
    return current.id != updated.id ||
        current.status != updated.status ||
        current.customerId != updated.customerId ||
        current.providerId != updated.providerId;
  }

  Future<void> _fetchBooking(int bookingId, Emitter<AdminState> emit) async {
    final result = await getBooking(bookingId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (booking) => emit(AdminBookingLoaded(booking)),
    );
  }

  Future<void> _onRetryBooking(
    RetryBookingEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await retryBooking(event.bookingId, event.adminId);
    result.fold((failure) => emit(AdminError(failure.message)), (
      success,
    ) async {
      // Reload booking to show updated state
      add(SearchBookingById(event.bookingId));
    });
  }

  Future<void> _onForceCancelBooking(
    ForceCancelBookingEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await forceCancelBooking(event.bookingId, event.adminId);
    result.fold((failure) => emit(AdminError(failure.message)), (
      success,
    ) async {
      add(SearchBookingById(event.bookingId));
    });
  }

  Future<void> _onMarkBookingFailed(
    MarkBookingFailedEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await markBookingFailed(event.bookingId, event.adminId);
    result.fold((failure) => emit(AdminError(failure.message)), (
      success,
    ) async {
      add(SearchBookingById(event.bookingId));
    });
  }

  Future<void> _onForceAssignBooking(
    ForceAssignBookingEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await forceAssignBooking(
      event.bookingId,
      event.providerId,
      event.adminId,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (
      success,
    ) async {
      add(SearchBookingById(event.bookingId));
    });
  }

  Future<void> _onAssignBooking(
    AssignBookingEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await assignBooking(
      event.bookingId,
      event.providerId,
      event.adminId,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (
      success,
    ) async {
      add(SearchBookingById(event.bookingId));
    });
  }
}
