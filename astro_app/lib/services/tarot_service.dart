import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'astro_api_service.dart';

class TarotService {
  String get _baseUrl => '${AstroApiService.baseUrl}/tarot';

  static String? activeUserId;

  /// Retrieves the active profile name / user ID dynamically from SharedPreferences,
  /// falling back to [explicitUserId] or a default session identifier.
  static Future<String> resolveUserId([String? explicitUserId]) async {
    if (explicitUserId != null && explicitUserId.trim().isNotEmpty) {
      return explicitUserId.trim();
    }
    if (activeUserId != null && activeUserId!.trim().isNotEmpty) {
      return activeUserId!.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('numerology_user_name');
      if (savedName != null && savedName.trim().isNotEmpty) {
        return savedName.trim();
      }
    } catch (_) {}
    return 'seeker';
  }

  /// Builds unified HTTP headers consistent with AstroApiService.
  Future<Map<String, String>> _headers([String? explicitUserId]) async {
    final uid = await resolveUserId(explicitUserId);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'X-User-Id': uid,
    };
    if (AstroApiService.authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${AstroApiService.authToken}';
    }
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> getDailyReading(double timezoneOffset, {String? userId}) async {
    final headers = await _headers(userId);
    final response = await http.post(
      Uri.parse('$_baseUrl/daily'),
      headers: headers,
      body: jsonEncode({'timezone': timezoneOffset}),
    ).timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get daily reading: ${response.body}');
  }

  Future<Map<String, dynamic>> drawSpread(String spreadEndpoint, {String? question, String? seed, String? userId}) async {
    try {
      final headers = await _headers(userId);
      final response = await http.post(
        Uri.parse('$_baseUrl/$spreadEndpoint'),
        headers: headers,
        body: jsonEncode({
          if (question != null) 'question': question,
          if (seed != null) 'seed': seed,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to draw spread: ${response.body}');
    } catch (e) {
      throw Exception('Could not reach backend: $e');
    }
  }

  Future<Map<String, dynamic>> getAstroTarotReading(Map<String, dynamic> data, {String? userId}) async {
    final headers = await _headers(userId);
    final response = await http.post(
      Uri.parse('$_baseUrl/astro'),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get astro tarot reading: ${response.body}');
  }

  Future<List<dynamic>> getHistory({String? userId}) async {
    try {
      final headers = await _headers(userId);
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
        headers: headers,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['history'];
      }
      return [];
    } catch (e) {
      return []; // Return empty list gracefully instead of crashing the UI
    }
  }

  Future<List<dynamic>> getLibrary() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/cards'),
      headers: headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cards'];
    }
    throw Exception('Failed to load library');
  }
}
