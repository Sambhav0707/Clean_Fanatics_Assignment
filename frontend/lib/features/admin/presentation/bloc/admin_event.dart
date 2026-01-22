import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class SearchBookingById extends AdminEvent {
  final int bookingId;

  const SearchBookingById(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class PollBookingById extends AdminEvent {
  final int bookingId;

  const PollBookingById(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class RetryBookingEvent extends AdminEvent {
  final int bookingId;
  final int adminId;

  const RetryBookingEvent(this.bookingId, this.adminId);

  @override
  List<Object> get props => [bookingId, adminId];
}

class AssignBookingEvent extends AdminEvent {
  final int bookingId;
  final int providerId;
  final int adminId;

  const AssignBookingEvent(this.bookingId, this.providerId, this.adminId);

  @override
  List<Object> get props => [bookingId, providerId, adminId];
}

class ForceAssignBookingEvent extends AdminEvent {
  final int bookingId;
  final int providerId;
  final int adminId;

  const ForceAssignBookingEvent(this.bookingId, this.providerId, this.adminId);

  @override
  List<Object> get props => [bookingId, providerId, adminId];
}

class ForceCancelBookingEvent extends AdminEvent {
  final int bookingId;
  final int adminId;

  const ForceCancelBookingEvent(this.bookingId, this.adminId);

  @override
  List<Object> get props => [bookingId, adminId];
}

class MarkBookingFailedEvent extends AdminEvent {
  final int bookingId;
  final int adminId;

  const MarkBookingFailedEvent(this.bookingId, this.adminId);

  @override
  List<Object> get props => [bookingId, adminId];
}
