import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class MarkBookingFailed {
  final AdminRepository repository;

  MarkBookingFailed(this.repository);

  Future<Either<Failure, void>> call(int bookingId, int adminId) async {
    return await repository.markBookingFailed(bookingId, adminId);
  }
}
