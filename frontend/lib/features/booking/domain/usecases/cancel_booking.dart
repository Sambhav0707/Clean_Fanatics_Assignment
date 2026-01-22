import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/booking_repository.dart';

class CancelBooking {
  final BookingRepository repository;

  CancelBooking(this.repository);

  Future<Either<Failure, void>> call(int bookingId, int actorId) async {
    return await repository.cancelBooking(bookingId, actorId);
  }
}
