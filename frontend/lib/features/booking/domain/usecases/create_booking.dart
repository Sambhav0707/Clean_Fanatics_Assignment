import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/booking_repository.dart';
import '../entities/booking.dart';

class CreateBooking {
  final BookingRepository repository;
  CreateBooking(this.repository);

  Future<Either<Failure, Booking>> call({
    required int actorId,
    required String customerName,
  }) {
    return repository.createBooking(
      actorId: actorId,
      customerName: customerName,
    );
  }
}
