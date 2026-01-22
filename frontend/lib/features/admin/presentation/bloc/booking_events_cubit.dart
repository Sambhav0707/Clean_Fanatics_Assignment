import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking_event.dart';
import '../../domain/usecases/get_booking_events.dart';

abstract class BookingEventsState {}

class BookingEventsInitial extends BookingEventsState {}

class BookingEventsLoading extends BookingEventsState {}

class BookingEventsLoaded extends BookingEventsState {
  final List<BookingEventEntity> events;
  BookingEventsLoaded(this.events);
}

class BookingEventsError extends BookingEventsState {
  final String message;
  BookingEventsError(this.message);
}

class BookingEventsCubit extends Cubit<BookingEventsState> {
  final GetBookingEvents getBookingEvents;

  BookingEventsCubit({required this.getBookingEvents})
    : super(BookingEventsInitial());

  Future<void> loadEvents(int bookingId) async {
    emit(BookingEventsLoading());
    final result = await getBookingEvents(bookingId);
    result.fold(
      (failure) => emit(BookingEventsError(failure.message)),
      (events) => emit(BookingEventsLoaded(events)),
    );
  }
}
