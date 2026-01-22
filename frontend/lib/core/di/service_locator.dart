import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';

import '../../features/booking/data/datasources/booking_remote_datasource.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/create_booking.dart';
import '../../features/booking/domain/usecases/get_booking.dart';
import '../../features/booking/domain/usecases/cancel_booking.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/provider/data/datasources/provider_remote_datasource.dart';
import '../../features/provider/data/repositories/provider_repository_impl.dart';
import '../../features/provider/domain/repositories/provider_repository.dart';
import '../../features/provider/domain/usecases/get_assigned_bookings.dart';
import '../../features/provider/domain/usecases/accept_booking.dart';
import '../../features/provider/domain/usecases/reject_booking.dart';
import '../../features/provider/domain/usecases/complete_booking.dart';
import '../../features/provider/presentation/bloc/provider_bloc.dart';
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/retry_booking.dart';
import '../../features/admin/domain/usecases/force_assign_booking.dart';
import '../../features/admin/domain/usecases/force_cancel_booking.dart';
import '../../features/admin/domain/usecases/mark_booking_failed.dart';
import '../../features/admin/domain/usecases/assign_booking.dart';
import '../../features/admin/domain/usecases/get_admin_providers.dart';
import '../../features/admin/domain/usecases/get_booking_events.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => http.Client());

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));

  // SessionContext is initialized after role selection (mock auth)

  // Features - Booking
  // Data
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl()),
  );

  // Domain
  sl.registerLazySingleton(() => CreateBooking(sl()));
  sl.registerLazySingleton(() => GetBooking(sl()));
  sl.registerLazySingleton(() => CancelBooking(sl()));

  // Presentation (Bloc)
  sl.registerFactory(
    () =>
        BookingBloc(createBooking: sl(), getBooking: sl(), cancelBooking: sl()),
  );

  // Features - Provider
  // Data
  sl.registerLazySingleton<ProviderRemoteDataSource>(
    () => ProviderRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProviderRepository>(
    () => ProviderRepositoryImpl(sl()),
  );

  // Domain
  sl.registerLazySingleton(() => GetAssignedBookings(sl()));
  sl.registerLazySingleton(() => AcceptBooking(sl()));
  sl.registerLazySingleton(() => RejectBooking(sl()));
  sl.registerLazySingleton(() => CompleteBooking(sl()));

  // Presentation (Bloc)
  sl.registerFactory(
    () => ProviderBloc(
      getAssignedBookings: sl(),
      acceptBooking: sl(),
      rejectBooking: sl(),
      completeBooking: sl(),
    ),
  );

  // Features - Admin
  // Data
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()));

  // Domain
  sl.registerLazySingleton(() => RetryBooking(sl()));
  sl.registerLazySingleton(() => ForceAssignBooking(sl()));
  sl.registerLazySingleton(() => ForceCancelBooking(sl()));
  sl.registerLazySingleton(() => MarkBookingFailed(sl()));
  sl.registerLazySingleton(() => AssignBooking(sl()));
  sl.registerLazySingleton(() => GetAdminProviders(sl()));
  sl.registerLazySingleton(() => GetBookingEvents(sl()));

  // Presentation
  sl.registerFactory(
    () => AdminBloc(
      getBooking: sl(),
      retryBooking: sl(),
      forceAssignBooking: sl(),
      forceCancelBooking: sl(),
      markBookingFailed: sl(),
      assignBooking: sl(),
    ),
  );
}
