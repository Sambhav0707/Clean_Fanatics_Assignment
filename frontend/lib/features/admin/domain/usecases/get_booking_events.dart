import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';
import '../entities/booking_event.dart';

class GetBookingEvents {
  final AdminRepository repository;

  GetBookingEvents(this.repository);

  Future<Either<Failure, List<BookingEventEntity>>> call(int bookingId) {
    return repository.getEvents(bookingId);
  }
}
