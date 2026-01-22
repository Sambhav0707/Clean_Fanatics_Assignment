class BookingEventEntity {
  final int id;
  final int bookingId;
  final String? fromStatus;
  final String toStatus;
  final String actorRole;
  final int? actorId;
  final DateTime createdAt;

  BookingEventEntity({
    required this.id,
    required this.bookingId,
    this.fromStatus,
    required this.toStatus,
    required this.actorRole,
    this.actorId,
    required this.createdAt,
  });
}
