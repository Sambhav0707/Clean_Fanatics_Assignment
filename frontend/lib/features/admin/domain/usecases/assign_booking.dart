import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class AssignBooking {
  final AdminRepository repository;

  AssignBooking(this.repository);

  Future<Either<Failure, void>> call(
    int bookingId,
    int providerId,
    int adminId,
  ) {
    return repository.assignBooking(bookingId, providerId, adminId);
  }
}
