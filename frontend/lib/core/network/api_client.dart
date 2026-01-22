import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
// import '../utils/either.dart'; // Future use
// import '../errors/failures.dart'; // Future use

class ApiClient {
  final http.Client client;

  ApiClient(this.client);

  // TODO (Phase 3): Wrap responses in Either<Failure, Map<String, dynamic>>
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await client.post(
      Uri.parse("${ApiConstants.baseUrl}$path"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      final decoded = jsonDecode(response.body);
      throw Exception(
        decoded['detail'] ?? "Server Error: ${response.statusCode}",
      );
    }

    return jsonDecode(response.body);
  }

  // TODO (Phase 3): Wrap responses in Either<Failure, List<dynamic>>
  Future<List<dynamic>> get(String path) async {
    final response = await client.get(
      Uri.parse("${ApiConstants.baseUrl}$path"),
    );

    if (response.statusCode >= 400) {
      final decoded = jsonDecode(response.body);
      throw Exception(
        decoded['detail'] ?? "Server Error: ${response.statusCode}",
      );
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final response = await client.get(
      Uri.parse("${ApiConstants.baseUrl}$path"),
    );

    if (response.statusCode >= 400) {
      final decoded = jsonDecode(response.body);
      throw Exception(
        decoded['detail'] ?? "Server Error: ${response.statusCode}",
      );
    }

    return jsonDecode(response.body);
  }
}
