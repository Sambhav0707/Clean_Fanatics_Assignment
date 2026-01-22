import '../../domain/entities/booking.dart';

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingListLoaded extends BookingState {
  final List<Booking> bookings;
  BookingListLoaded(this.bookings);
}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}
