import '../../domain/entities/admin_provider.dart';

class AdminProviderModel extends AdminProvider {
  AdminProviderModel({
    required int id,
    required String name,
    required String availability,
  }) : super(id: id, name: name, availability: availability);

  factory AdminProviderModel.fromJson(Map<String, dynamic> json) {
    return AdminProviderModel(
      id: json['id'],
      name: json['name'],
      // Default to AVAILABLE if missing to be safe, though backend guarantees it now
      availability: json['availability'] ?? 'AVAILABLE',
    );
  }
}
