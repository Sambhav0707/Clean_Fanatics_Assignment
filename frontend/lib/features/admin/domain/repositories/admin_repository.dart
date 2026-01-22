import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_provider.dart';
import '../entities/booking_event.dart';

abstract class AdminRepository {
  Future<Either<Failure, void>> retryBooking(int bookingId, int adminId);
  Future<Either<Failure, void>> forceCancelBooking(int bookingId, int adminId);
  Future<Either<Failure, void>> markBookingFailed(int bookingId, int adminId);
  Future<Either<Failure, void>> forceAssignBooking(
    int bookingId,
    int providerId,
    int adminId,
  );
  Future<Either<Failure, void>> assignBooking(
    int bookingId,
    int providerId,
    int adminId,
  );
  Future<Either<Failure, List<AdminProvider>>> getProviders(int adminId);
  Future<Either<Failure, List<BookingEventEntity>>> getEvents(int bookingId);
}
