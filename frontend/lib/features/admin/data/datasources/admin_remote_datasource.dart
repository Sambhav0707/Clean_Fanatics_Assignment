import '../../../../core/network/api_client.dart';
import '../models/admin_provider_model.dart';
import '../models/booking_event_model.dart';

abstract class AdminRemoteDataSource {
  Future<void> retryBooking(int bookingId, int adminId);
  Future<void> forceCancelBooking(int bookingId, int adminId);
  Future<void> markBookingFailed(int bookingId, int adminId);
  Future<void> forceAssignBooking(int bookingId, int providerId, int adminId);
  Future<void> assignBooking(int bookingId, int providerId, int adminId);
  Future<List<AdminProviderModel>> getProviders(int adminId);
  Future<List<BookingEventModel>> getEvents(int bookingId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient client;

  AdminRemoteDataSourceImpl(this.client);

  @override
  Future<void> retryBooking(int bookingId, int adminId) async {
    await client.post('/bookings/$bookingId/retry', {
      "actor_role": "ADMIN",
      "actor_id": adminId,
    });
  }

  @override
  Future<void> forceCancelBooking(int bookingId, int adminId) async {
    await client.post('/bookings/$bookingId/force-cancel', {
      "actor_role": "ADMIN",
      "actor_id": adminId,
    });
  }

  @override
  Future<void> markBookingFailed(int bookingId, int adminId) async {
    await client.post('/bookings/$bookingId/mark-failed', {
      "actor_role": "ADMIN",
      "actor_id": adminId,
    });
  }

  @override
  Future<void> forceAssignBooking(
    int bookingId,
    int providerId,
    int adminId,
  ) async {
    // Note: If this endpoint returns 404 on the backend, ApiClient or this method
    // will throw an exception which will be caught by the repository.
    await client.post('/bookings/$bookingId/force-assign', {
      "actor_role": "ADMIN",
      "actor_id": adminId,
      "provider_id": providerId,
    });
  }

  @override
  Future<void> assignBooking(int bookingId, int providerId, int adminId) async {
    await client.post('/bookings/$bookingId/assign', {
      "provider_id": providerId,
      "actor_role": "ADMIN",
      "actor_id": adminId,
    });
  }

  @override
  Future<List<AdminProviderModel>> getProviders(int adminId) async {
    final response = await client.get('/admin/providers?actor_role=ADMIN');
    return response.map((e) => AdminProviderModel.fromJson(e)).toList();
  }

  @override
  Future<List<BookingEventModel>> getEvents(int bookingId) async {
    final response = await client.get('/bookings/$bookingId/events');
    return response.map((e) => BookingEventModel.fromJson(e)).toList();
  }
}
