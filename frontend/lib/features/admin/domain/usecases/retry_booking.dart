import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class RetryBooking {
  final AdminRepository repository;

  RetryBooking(this.repository);

  Future<Either<Failure, void>> call(int bookingId, int adminId) async {
    return await repository.retryBooking(bookingId, adminId);
  }
}
