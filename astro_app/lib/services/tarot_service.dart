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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$spreadEndpoint'),
        headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
        body: jsonEncode({
          if (question != null) 'question': question,
          if (seed != null) 'seed': seed,
        }),
      ).timeout(const Duration(seconds: 4)); // Reduced timeout for faster fallback
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to draw spread: ${response.body}');
    } catch (e) {
      // Return a beautiful mocked reading for physical devices without a backend
      final bool isSingle = spreadEndpoint.contains('yes') || spreadEndpoint.contains('daily') || spreadEndpoint.contains('one');
      return {
        'spread_type': spreadEndpoint.replaceAll('-', ' ').toUpperCase(),
        'positions': [
          {
            'position_name': isSingle ? 'Your Answer' : 'Past',
            'meaning': isSingle ? 'The core of your situation.' : 'The foundation of the situation.',
            'card': {
              'name': 'The Star',
              'name_short': 'ar17',
              'value': '17',
              'value_int': 17,
              'type': 'major',
              'meaning_up': 'Hope, faith, purpose, renewal, spirituality',
              'desc': 'The Star brings hope, renewed power, and strength to carry on with life. It shows how abundantly blessed you are by the universe.'
            }
          },
          if (!isSingle) ...[
            {
              'position_name': 'Present',
              'meaning': 'Where you are right now.',
              'card': {
                'name': 'The Magician',
                'name_short': 'ar01',
                'value': '1',
                'value_int': 1,
                'type': 'major',
                'meaning_up': 'Manifestation, resourcefulness, power, inspired action',
                'desc': 'The Magician represents your ability to manifest your desires into reality through focus, will, and determination.'
              }
            },
            {
              'position_name': 'Future',
              'meaning': 'The most likely outcome.',
              'card': {
                'name': 'The Sun',
                'name_short': 'ar19',
                'value': '19',
                'value_int': 19,
                'type': 'major',
                'meaning_up': 'Positivity, fun, warmth, success, vitality',
                'desc': 'The Sun represents success, radiance and abundance. It gives you strength and tells you that no matter where you go or what you do, your positive and radiant energy will follow you.'
              }
            }
          ]
        ]
      };
    }
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
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
        headers: {'X-User-Id': 'test_user'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['history'];
      }
      return [];
    } catch (e) {
      return []; // Return empty list gracefully instead of crashing the UI
    }
  }

  Future<List<dynamic>> getLibrary() async {
    final response = await http.get(Uri.parse('$_baseUrl/cards'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cards'];
    }
    throw Exception('Failed to load library');
  }
}
