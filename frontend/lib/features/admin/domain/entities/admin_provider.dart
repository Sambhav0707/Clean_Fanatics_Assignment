class AdminProvider {
  final int id;
  final String name;
  final String availability; // "AVAILABLE" or "BUSY"

  AdminProvider({
    required this.id,
    required this.name,
    required this.availability,
  });
}
