import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../booking/domain/entities/booking.dart';

abstract class ProviderRepository {
  Future<Either<Failure, List<Booking>>> getAssignedBookings(int providerId);
  Future<Either<Failure, void>> acceptBooking(int bookingId, int providerId);
  Future<Either<Failure, void>> rejectBooking(int bookingId, int providerId);
  Future<Either<Failure, void>> completeBooking(int bookingId, int providerId);
}
