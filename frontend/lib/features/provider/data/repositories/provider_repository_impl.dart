import 'package:frontend/core/utils/either.dart';
import 'package:frontend/features/booking/data/repositories/booking_repository_impl.dart';
import '../../../../core/errors/failures.dart';
import '../../../booking/domain/entities/booking.dart';
import '../datasources/provider_remote_datasource.dart';
import '../../domain/repositories/provider_repository.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final ProviderRemoteDataSource remoteDataSource;

  ProviderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Booking>>> getAssignedBookings(
    int providerId,
  ) async {
    try {
      final models = await remoteDataSource.getAssignedBookings(providerId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptBooking(
    int bookingId,
    int providerId,
  ) async {
    try {
      await remoteDataSource.acceptBooking(bookingId, providerId);
      return  Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectBooking(
    int bookingId,
    int providerId,
  ) async {
    try {
      await remoteDataSource.rejectBooking(bookingId, providerId);
      return  Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeBooking(
    int bookingId,
    int providerId,
  ) async {
    try {
      await remoteDataSource.completeBooking(bookingId, providerId);
      return  Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
