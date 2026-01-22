import 'package:equatable/equatable.dart';
import '../../../booking/domain/entities/booking.dart';

abstract class ProviderState extends Equatable {
  const ProviderState();

  @override
  List<Object?> get props => [];
}

class ProviderInitial extends ProviderState {}

class ProviderLoading extends ProviderState {}

class ProviderLoaded extends ProviderState {
  final List<Booking> bookings;

  const ProviderLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class ProviderError extends ProviderState {
  final String message;

  const ProviderError(this.message);

  @override
  List<Object?> get props => [message];
}
