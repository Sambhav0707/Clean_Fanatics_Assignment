import '../../domain/entities/booking_event.dart';

class BookingEventModel extends BookingEventEntity {
  BookingEventModel({
    required int id,
    required int bookingId,
    String? fromStatus,
    required String toStatus,
    required String actorRole,
    int? actorId,
    required DateTime createdAt,
  }) : super(
         id: id,
         bookingId: bookingId,
         fromStatus: fromStatus,
         toStatus: toStatus,
         actorRole: actorRole,
         actorId: actorId,
         createdAt: createdAt,
       );

  factory BookingEventModel.fromJson(Map<String, dynamic> json) {
    return BookingEventModel(
      id: json['id'],
      bookingId: json['booking_id'],
      fromStatus: json['from_status'],
      toStatus: json['to_status'],
      actorRole: json['actor_role'],
      actorId: json['actor_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
