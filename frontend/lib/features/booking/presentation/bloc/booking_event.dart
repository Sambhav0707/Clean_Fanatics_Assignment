abstract class BookingEvent {}

class CreateBookingEvent extends BookingEvent {
  final String customerName;
  CreateBookingEvent(this.customerName);
  @override
  String toString() => 'CreateBookingEvent(name: $customerName)';
}

class LoadBookingsEvent extends BookingEvent {
  final int userId;
  LoadBookingsEvent(this.userId);
  @override
  List<Object> get props => [userId];
}

class CancelBookingEvent extends BookingEvent {
  final int bookingId;
  final int userId;
  CancelBookingEvent(this.bookingId, this.userId);
  @override
  List<Object> get props => [bookingId, userId];
}

class StartPollingEvent extends BookingEvent {
  final int bookingId;
  StartPollingEvent(this.bookingId);
  @override
  String toString() => 'StartPollingEvent(bookingId: $bookingId)';
}

class PollBookingEvent extends BookingEvent {
  @override
  String toString() => 'PollBookingEvent';
}
