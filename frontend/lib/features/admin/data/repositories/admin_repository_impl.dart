import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../../domain/entities/admin_provider.dart';
import '../../domain/entities/booking_event.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> retryBooking(int bookingId, int adminId) async {
    try {
      await remoteDataSource.retryBooking(bookingId, adminId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forceCancelBooking(
    int bookingId,
    int adminId,
  ) async {
    try {
      await remoteDataSource.forceCancelBooking(bookingId, adminId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markBookingFailed(
    int bookingId,
    int adminId,
  ) async {
    try {
      await remoteDataSource.markBookingFailed(bookingId, adminId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forceAssignBooking(
    int bookingId,
    int providerId,
    int adminId,
  ) async {
    try {
      await remoteDataSource.forceAssignBooking(bookingId, providerId, adminId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignBooking(
    int bookingId,
    int providerId,
    int adminId,
  ) async {
    try {
      await remoteDataSource.assignBooking(bookingId, providerId, adminId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminProvider>>> getProviders(int adminId) async {
    try {
      final result = await remoteDataSource.getProviders(adminId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEventEntity>>> getEvents(
    int bookingId,
  ) async {
    try {
      final result = await remoteDataSource.getEvents(bookingId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
