import 'dart:convert';
import 'package:http/http.dart' as http;
import 'astro_api_service.dart';

class TarotService {
  final String _baseUrl = '${AstroApiService.baseUrl}/tarot';

  Future<Map<String, dynamic>> getDailyReading(double timezoneOffset) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/daily'),
      headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
      body: jsonEncode({'timezone': timezoneOffset}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get daily reading: ${response.body}');
  }

  Future<Map<String, dynamic>> drawSpread(String spreadEndpoint, {String? question, String? seed}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$spreadEndpoint'),
      headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
      body: jsonEncode({
        if (question != null) 'question': question,
        if (seed != null) 'seed': seed,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to draw spread: ${response.body}');
  }

  Future<Map<String, dynamic>> getAstroTarotReading(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/astro'),
      headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get astro tarot reading: ${response.body}');
  }

  Future<List<dynamic>> getHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history'),
      headers: {'X-User-Id': 'test_user'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['history'];
    }
    throw Exception('Failed to load history');
  }

  Future<List<dynamic>> getLibrary() async {
    final response = await http.get(Uri.parse('$_baseUrl/cards'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cards'];
    }
    throw Exception('Failed to load library');
  }
}
