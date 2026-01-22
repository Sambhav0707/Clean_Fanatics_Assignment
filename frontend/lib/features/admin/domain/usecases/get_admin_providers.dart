import 'package:frontend/core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';
import '../entities/admin_provider.dart';

class GetAdminProviders {
  final AdminRepository repository;

  GetAdminProviders(this.repository);

  Future<Either<Failure, List<AdminProvider>>> call(int adminId) {
    return repository.getProviders(adminId);
  }
}
