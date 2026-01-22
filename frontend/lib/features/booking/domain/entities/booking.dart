class Booking {
  final int id;
  final String status;
  final int customerId;
  final int? providerId;

  Booking({
    required this.id,
    required this.status,
    required this.customerId,
    this.providerId,
  });
}
