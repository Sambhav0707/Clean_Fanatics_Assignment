import 'package:frontend/features/booking/domain/entities/booking.dart';

class BookingModel {
  final int bookingId;
  final String status;
  final int customerId;
  final int? providerId;

  BookingModel({
    required this.bookingId,
    required this.status,
    required this.customerId,
    this.providerId,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId:
          json["id"], // Backend returns "id", not "booking_id" in response schema
      status: json["status"],
      customerId: json["customer_id"],
      providerId: json["provider_id"],
    );
  }

  Booking toEntity() {
    return Booking(
      id: bookingId,
      status: status,
      customerId: customerId,
      providerId: providerId,
    );
  }
}
