import '../../../../core/network/api_client.dart';
import '../../../booking/data/models/booking_model.dart';

abstract class ProviderRemoteDataSource {
  Future<List<BookingModel>> getAssignedBookings(int providerId);
  Future<void> acceptBooking(int bookingId, int providerId);
  Future<void> rejectBooking(int bookingId, int providerId);
  Future<void> completeBooking(int bookingId, int providerId);
}

class ProviderRemoteDataSourceImpl implements ProviderRemoteDataSource {
  final ApiClient client;

  ProviderRemoteDataSourceImpl(this.client);

  @override
  Future<List<BookingModel>> getAssignedBookings(int providerId) async {
    final response = await client.get('/providers/$providerId/bookings');
    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  @override
  Future<void> acceptBooking(int bookingId, int providerId) async {
    await client.post('/bookings/$bookingId/accept', {
      "actor_role": "PROVIDER",
      "actor_id": providerId,
    });
  }

  @override
  Future<void> rejectBooking(int bookingId, int providerId) async {
    await client.post('/bookings/$bookingId/reject', {
      "actor_role": "PROVIDER",
      "actor_id": providerId,
    });
  }

  @override
  Future<void> completeBooking(int bookingId, int providerId) async {
    await client.post('/bookings/$bookingId/complete', {
      "actor_role": "PROVIDER",
      "actor_id": providerId,
    });
  }
}
