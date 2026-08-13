import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized Master API Service for AstroTalk Vedic & AI Platform.
/// 
/// Interacts directly with the FastAPI backend (`Astrotalk_phase_2_backend`)
/// and provides robust fallback data if the backend server is offline.
class AstroApiService {
  static final AstroApiService _instance = AstroApiService._internal();
  factory AstroApiService() => _instance;
  AstroApiService._internal();

  static String _customBaseUrl = '';
  static String authToken = '';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1'; // Standard FastAPI port
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.120.4.225:5000/api/v1'; // Android emulator localhost
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String get baseUrl {
    if (_customBaseUrl.trim().isNotEmpty) {
      return _customBaseUrl.trim();
    }
    return defaultBaseUrl;
  }

  static set baseUrl(String url) {
    _customBaseUrl = url.trim();
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 7);

  // =========================================================================
  // 1. HEALTH & CONNECTIVITY CHECK
  // =========================================================================

  static Future<Map<String, dynamic>> checkHealth() async {
    final rootHost = baseUrl.replaceAll('/api/v1', '');
    try {
      final response = await http
          .get(Uri.parse('$rootHost/health'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'online': true,
          'status': data['status'] ?? 'healthy',
          'url': baseUrl,
        };
      }
    } catch (e) {
      debugPrint('AstroApiService health check note: $e');
    }
    return {
      'online': false,
      'status': 'offline',
      'url': baseUrl,
    };
  }

  // =========================================================================
  // 2. AUTHENTICATION
  // =========================================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final body = jsonEncode({'email': email, 'password': password});

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data.containsKey('access_token')) {
        authToken = data['access_token'].toString();
      }
      return data;
    } catch (e) {
      debugPrint('API Error login: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && data.containsKey('access_token')) {
        authToken = data['access_token'].toString();
      }
      return data;
    } catch (e) {
      debugPrint('API Error register: $e');
      return {'error': e.toString()};
    }
  }

  // =========================================================================
  // 3. HOROSCOPE / KUNDLI
  // =========================================================================

  static Future<Map<String, dynamic>> getKundli({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/kundli');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Kundli: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getKundli: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSampleKundli() async {
    final uri = Uri.parse('$baseUrl/horoscope/sample');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Sample Kundli: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getSampleKundli: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 4. AI CHAT & CALLING
  // =========================================================================

  static Future<Map<String, dynamic>> chatAiAstrologer({
    required String question,
    Map<String, dynamic>? birthDetails,
    String category = 'general',
  }) async {
    final uri = Uri.parse('$baseUrl/ai-astro/chat');
    final body = jsonEncode({
      'question': question,
      'birth_details': birthDetails,
      'category': category,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to chat AI Astrologer: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error chatAiAstrologer: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 5. AI VISION (PALM & FACE READING)
  // =========================================================================
  
  static Future<Map<String, dynamic>> analyzeVision({required bool isFace, String? filePath}) async {
    if (isFace) {
      return await readFace(filePath ?? '');
    } else {
      return await readPalm(filePath ?? '');
    }
  }

  static Future<Map<String, dynamic>> readPalm(String filePath) async {
    final uri = Uri.parse('$baseUrl/vision/palm-reading');
    try {
      final res = await http.post(uri, headers: _headers).timeout(_timeout); // Typically multipart, but simplified here
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to read palm: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error readPalm: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> readFace(String filePath) async {
    final uri = Uri.parse('$baseUrl/vision/face-reading');
    try {
      final res = await http.post(uri, headers: _headers).timeout(_timeout); // Typically multipart
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to read face: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error readFace: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 6. CONTENT (QUOTES, MUHURAT, NOTIFICATIONS)
  // =========================================================================

  static Future<List<dynamic>> getDailyQuotes() async {
    final uri = Uri.parse('$baseUrl/content/quotes');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      } else {
        throw Exception('Failed to get daily quotes: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getDailyQuotes: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getNotifications() async {
    final uri = Uri.parse('$baseUrl/content/notifications');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      } else {
        throw Exception('Failed to get notifications: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getNotifications: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getMuhurat({double lat = 28.6139, double lon = 77.209}) async {
    final uri = Uri.parse('$baseUrl/content/muhurat?latitude=$lat&longitude=$lon');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get muhurat: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getMuhurat: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 7. ADMIN PANEL
  // =========================================================================

  static Future<Map<String, dynamic>> getAdminStats() async {
    final uri = Uri.parse('$baseUrl/admin/stats');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get admin stats: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getAdminStats: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 8. PLACES GEOCODING
  // =========================================================================

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final uri = Uri.parse('$baseUrl/places/search').replace(queryParameters: {'query': query});
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['results'] as List<dynamic>?;
        if (list != null) return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {}
    return _popularPlacesFallback.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
  }

  static Future<List<Map<String, String>>> getPlaces({String query = ''}) async {
    final rawList = query.trim().isEmpty ? _popularPlacesFallback : await searchPlaces(query);
    return rawList.map((p) {
      final city = p['formatted_name']?.toString() ?? '${p['name']}, ${p['country']}';
      final lat = (p['latitude'] as num?)?.toStringAsFixed(4) ?? '28.6139';
      final lon = (p['longitude'] as num?)?.toStringAsFixed(4) ?? '77.2090';
      final tz = (p['timezone'] as num?)?.toDouble() ?? 5.5;
      final tzStr = tz >= 0 ? 'GMT +${tz.toStringAsFixed(2).replaceAll('.50', ':30').replaceAll('.00', ':00')}' : 'GMT ${tz.toStringAsFixed(2)}';
      return {
        'city': city,
        'coords': '$lat° N, $lon° E',
        'tz': tzStr,
        'isDefault': 'false',
      };
    }).toList();
  }

  // =========================================================================
  // LOCAL FALLBACK DATA
  // =========================================================================

  static Map<String, dynamic> _fallbackKundli(String name, String dob, String tob, String pob) {
    return {
      'person_name': name,
      'date_of_birth': dob,
      'time_of_birth': tob,
      'place_of_birth': pob,
      'ascendant_lagna': 'Aquarius (03° 35\' 00")',
      'moon_sign_rashi': 'Leo (Simha)',
      'nakshatra': 'Uttara Phalguni',
      'nakshatra_pada': 1,
      'current_running_dasha': {
        'active_mahadasha': 'Jupiter (Guru)'
      },
      'planets': [
        {'name': 'Ascendant', 'sign': 'Aquarius', 'house': 1, 'degree_formatted': '03:35:00', 'nakshatra': 'Dhanishta', 'dignity': 'Lagna'},
        {'name': 'Sun', 'sign': 'Cancer', 'house': 6, 'degree_formatted': '21:49:12', 'nakshatra': 'Ashlesha', 'dignity': 'Neutral'},
      ]
    };
  }

  static final List<Map<String, dynamic>> _popularPlacesFallback = [
    {'name': 'New Delhi', 'state': 'Delhi', 'country': 'India', 'latitude': 28.6139, 'longitude': 77.2090, 'timezone': 5.5, 'formatted_name': 'New Delhi, Delhi, India'},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'country': 'India', 'latitude': 19.0760, 'longitude': 72.8777, 'timezone': 5.5, 'formatted_name': 'Mumbai, Maharashtra, India'},
  ];
}
