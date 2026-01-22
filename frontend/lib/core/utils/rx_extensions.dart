import 'package:rxdart/rxdart.dart';
import 'either.dart';

extension RxEitherExtension<T> on Stream<T> {
  Stream<Either<Exception, T>> asEither() {
    return map<Either<Exception, T>>((value) {
      return Right(value);
    }).onErrorReturnWith((error, _) {
      return Left(error as Exception);
    });
  }
}
