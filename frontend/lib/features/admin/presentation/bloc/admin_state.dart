import 'package:equatable/equatable.dart';
import 'package:frontend/features/booking/domain/entities/booking.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminBookingLoaded extends AdminState {
  final Booking booking;

  const AdminBookingLoaded(this.booking);

  @override
  List<Object> get props => [booking];
}

// State to show a transient success message (e.g. via specific state or listener)
// However, since actions update the booking state, typically we just reload the booking.
// But we might want to show a Snackbar "Action Successful".
// Let's stick to a generic "message" state or better, just re-emit Loaded with new data?
// Actually, for actions, we often want to show loading -> success/error.
class AdminActionSuccess extends AdminState {
  final String message;

  const AdminActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object> get props => [message];
}
