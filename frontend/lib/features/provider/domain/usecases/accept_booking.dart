import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/provider_repository.dart';

class AcceptBooking {
  final ProviderRepository repository;

  AcceptBooking(this.repository);

  Future<Either<Failure, void>> call(int bookingId, int providerId) async {
    return await repository.acceptBooking(bookingId, providerId);
  }
}
