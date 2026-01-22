import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class ForceCancelBooking {
  final AdminRepository repository;

  ForceCancelBooking(this.repository);

  Future<Either<Failure, void>> call(int bookingId, int adminId) async {
    return await repository.forceCancelBooking(bookingId, adminId);
  }
}
