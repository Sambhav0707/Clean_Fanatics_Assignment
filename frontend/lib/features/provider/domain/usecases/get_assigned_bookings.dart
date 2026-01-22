import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../booking/domain/entities/booking.dart';
import '../repositories/provider_repository.dart';

class GetAssignedBookings {
  final ProviderRepository repository;

  GetAssignedBookings(this.repository);

  Future<Either<Failure, List<Booking>>> call(int providerId) async {
    return await repository.getAssignedBookings(providerId);
  }
}
