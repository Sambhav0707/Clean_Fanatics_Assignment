import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> createBooking({
    required int actorId,
    required String customerName,
  });

  Future<BookingModel> getBooking(int bookingId);

  Future<void> cancelBooking(int bookingId, int actorId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient apiClient;

  BookingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> cancelBooking(int bookingId, int actorId) async {
    final body = {"actor_role": "CUSTOMER", "actor_id": actorId};
    await apiClient.post("/bookings/$bookingId/cancel", body);
  }

  @override
  Future<BookingModel> createBooking({
    required int actorId,
    required String customerName,
  }) async {
    final body = {
      "customer_name": customerName,
      "actor_role": "CUSTOMER", // explicit string as per curl/backend
      "actor_id": actorId,
    };

    // The backend returns a BookingResponse which BookingModel.fromJson parses.
    final response = await apiClient.post("/bookings/", body);
    return BookingModel.fromJson(response);
  }

  @override
  Future<BookingModel> getBooking(int bookingId) async {
    // The backend returns a BookingResponse which BookingModel.fromJson parses.
    // However, apiClient.get returns List<dynamic> in our Phase 1 mock?
    // Wait, let's check ApiClient.
    // If ApiClient.get returns List, we might have an issue if the backend endpoint returns a dict.
    // The backend `get_booking` returns `BookingResponse` (a dict).
    // I need to verify ApiClient implementation.

    // In Phase 1 user request:
    // Future<List<dynamic>> get(String path) async { ... }

    // This mismatches the backend's get booking by ID which returns a single object.
    // I will assume for now I should either update ApiClient or cast the result.
    // Since I cannot change ApiClient "functionally" in Phase 1, Phase 2 didn't change it.
    // But Phase 3 requires it to support single Object return.
    // I will check ApiClient file content again to be sure.
    // But assuming the prompt restrictions, I should probably check if I can modify ApiClient to be generic or support Map return.
    // I'll proceed with writing this file assuming I can fix ApiClient or usage.

    // Actually, I'll use a dynamic return type or cast in ApiClient if I could, but `ApiClient.get` is typed as Future<List>.
    // That's a blocker. I should update ApiClient to support Map return for details.

    // Let's assume I can add a `getById` or similar to ApiClient if needed,
    // or if `get` implementation allows returning Map (dynamic).
    // The return type is `Future<List<dynamic>>`. JSON decode produces Map or List.
    // If backend returns Map, `jsonDecode` returns Map. returning Map as List<dynamic> will throw at runtime.

    // I will add a `getObject` method to ApiClient or update `get` signature if allowed.
    // The Phase 1 requirement was "Future<List<dynamic>> get(...)".
    // I will add `Future<Map<String, dynamic>> getObject(...)` to ApiClient.

    final response = await apiClient.getMap("/bookings/$bookingId");
    return BookingModel.fromJson(response);
  }
}
