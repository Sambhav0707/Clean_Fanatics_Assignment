import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  Future<Either<Failure, Booking>> createBooking({
    required int actorId,
    required String customerName,
  });

  Future<Either<Failure, Booking>> getBooking(int bookingId);
  Future<Either<Failure, void>> cancelBooking(int bookingId, int actorId);
}
