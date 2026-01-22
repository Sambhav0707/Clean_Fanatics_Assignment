import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/entities/booking.dart';
import '../../data/models/booking_model.dart'; // Needed for toEntity (if we had a mapper, but doing manual or model access)

extension BookingModelMapper on BookingModel {
  Booking toEntity() {
    return Booking(
      id: bookingId,
      status: status,
      customerId: customerId,
      providerId: providerId,
    );
  }
}

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remote;

  BookingRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, Booking>> createBooking({
    required int actorId,
    required String customerName,
  }) async {
    try {
      final model = await remote.createBooking(
        actorId: actorId,
        customerName: customerName,
      );
      return Right(model.toEntity());
    } catch (e) {
      // Very basic error handling for Phase 3
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBooking(int bookingId) async {
    try {
      final model = await remote.getBooking(bookingId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(
    int bookingId,
    int actorId,
  ) async {
    try {
      await remote.cancelBooking(bookingId, actorId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
