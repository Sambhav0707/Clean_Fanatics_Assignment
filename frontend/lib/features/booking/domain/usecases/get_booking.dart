import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/booking_repository.dart';
import '../entities/booking.dart';

class GetBooking {
  final BookingRepository repository;
  GetBooking(this.repository);

  Future<Either<Failure, Booking>> call(int bookingId) {
    return repository.getBooking(bookingId);
  }
}
