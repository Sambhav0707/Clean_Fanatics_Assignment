import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class ForceAssignBooking {
  final AdminRepository repository;

  ForceAssignBooking(this.repository);

  Future<Either<Failure, void>> call(
    int bookingId,
    int providerId,
    int adminId,
  ) async {
    return await repository.forceAssignBooking(bookingId, providerId, adminId);
  }
}
