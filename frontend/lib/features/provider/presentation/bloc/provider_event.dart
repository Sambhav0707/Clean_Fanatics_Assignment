import 'package:equatable/equatable.dart';

abstract class ProviderEvent extends Equatable {
  const ProviderEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssignedBookings extends ProviderEvent {
  final int providerId;
  const LoadAssignedBookings(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class StartPolling extends ProviderEvent {
  final int providerId;
  const StartPolling(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class PollBookings extends ProviderEvent {
  final int providerId;
  const PollBookings(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class AcceptBookingEvent extends ProviderEvent {
  final int bookingId;
  final int providerId;
  const AcceptBookingEvent(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class RejectBookingEvent extends ProviderEvent {
  final int bookingId;
  final int providerId;
  const RejectBookingEvent(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class CompleteBookingEvent extends ProviderEvent {
  final int bookingId;
  final int providerId;
  const CompleteBookingEvent(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}
