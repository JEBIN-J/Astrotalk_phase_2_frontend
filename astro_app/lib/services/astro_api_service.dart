import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized Master API Service for AstroTalk Vedic & AI Platform.
/// 
/// Interacts directly with the Flask backend (`Astrotalk_phase_2_backend`)
/// and provides robust fallback data if the backend server is offline.
class AstroApiService {
  static final AstroApiService _instance = AstroApiService._internal();
  factory AstroApiService() => _instance;
  AstroApiService._internal();

  /// Default API Root URL
  static String _customBaseUrl = '';
  static String authToken = '';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator loops back to host via 10.0.2.2
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {}
    return 'http://127.0.0.1:5000/api/v1';
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

  /// Checks if the Flask backend server is alive and responding
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
          'version': data['version'] ?? '2.0.0',
          'url': baseUrl,
        };
      }
    } catch (e) {
      debugPrint('AstroApiService health check note: $e (Falling back gracefully)');
    }
    return {
      'online': false,
      'status': 'offline',
      'version': '2.0.0 (Local Engine)',
      'url': baseUrl,
    };
  }

  // =========================================================================
  // 2. PANCHANGA & MUHURTA APIS
  // =========================================================================

  /// GET /api/v1/panchang/today
  static Future<Map<String, dynamic>> getTodayPanchang({
    double latitude = 28.6139,
    double longitude = 77.2090,
    double timezone = 5.5,
    String place = 'New Delhi',
  }) async {
    final uri = Uri.parse('$baseUrl/panchang/today').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone.toString(),
      'place': place,
    });

    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getTodayPanchang: $e');
    }

    // Dynamic Fallback
    final now = DateTime.now();
    return _fallbackPanchang(now, place, latitude, longitude);
  }

  /// POST /api/v1/panchang/daily
  static Future<Map<String, dynamic>> getDailyPanchang({
    String? date,
    double latitude = 28.6139,
    double longitude = 77.2090,
    double timezone = 5.5,
    String placeName = 'New Delhi',
  }) async {
    final uri = Uri.parse('$baseUrl/panchang/daily');
    final body = jsonEncode({
      'date': date,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'place_name': placeName,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getDailyPanchang: $e');
    }

    final target = date != null ? DateTime.tryParse(date) ?? DateTime.now() : DateTime.now();
    return _fallbackPanchang(target, placeName, latitude, longitude);
  }

  /// GET /api/v1/panchang/muhurta
  static Future<Map<String, dynamic>> getMuhurta({
    double latitude = 28.6139,
    double longitude = 77.2090,
    double timezone = 5.5,
  }) async {
    final uri = Uri.parse('$baseUrl/panchang/muhurta').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone.toString(),
    });

    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getMuhurta: $e');
    }

    return {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'abhijit_muhurta': '11:58 AM - 12:49 PM (Shubh)',
      'rahu_kaal': '12:28 PM - 02:08 PM (Ashubh)',
      'yamaganda': '07:28 AM - 09:08 AM',
      'gulika_kaal': '09:08 AM - 10:48 AM',
      'sunrise': '05:48 AM',
      'sunset': '07:08 PM',
    };
  }

  // =========================================================================
  // 3. HOROSCOPE & JANAM KUNDLI APIS
  // =========================================================================

  /// POST /api/v1/horoscope/kundli
  static Future<Map<String, dynamic>> getKundli({
    String name = 'Jebin J',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Kanyakumari, India',
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
    final body = jsonEncode(bodyMap);


    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getKundli: $e');
    }

    return _fallbackKundli(name, dateOfBirth, timeOfBirth, placeOfBirth);
  }

  /// GET /api/v1/horoscope/sample
  static Future<Map<String, dynamic>> getSampleKundli() async {
    final uri = Uri.parse('$baseUrl/horoscope/sample');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getSampleKundli: $e');
    }
    return _fallbackKundli('Rahul Sharma', '1995-08-15', '06:30', 'New Delhi, India');
  }

  /// POST /api/v1/horoscope/dasha
  static Future<Map<String, dynamic>> getDashaTimeline({
    String name = 'User',
    String dateOfBirth = '1995-08-15',
    String timeOfBirth = '06:30',
    String placeOfBirth = 'New Delhi, India',
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/dasha');
    final body = jsonEncode({
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getDashaTimeline: $e');
    }

    final k = _fallbackKundli(name, dateOfBirth, timeOfBirth, placeOfBirth);
    return {
      'current_running_dasha': k['current_running_dasha'],
      'vimshottari_dasha_timeline': k['vimshottari_dasha_timeline'],
    };
  }

  /// POST /api/v1/horoscope/ashtakvarga
  static Future<Map<String, dynamic>> getAshtakvarga({
    String name = 'User',
    String dateOfBirth = '1995-08-15',
    String timeOfBirth = '06:30',
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/ashtakvarga');
    final body = jsonEncode({
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getAshtakvarga: $e');
    }

    final k = _fallbackKundli(name, dateOfBirth, timeOfBirth, 'New Delhi');
    return k['ashtakvarga'] as Map<String, dynamic>;
  }

  // =========================================================================
  // 4. HOROSCOPE MATCHING (36 GUNA MILAN)
  // =========================================================================

  /// POST /api/v1/matching/ashtakoota
  static Future<Map<String, dynamic>> matchAshtakoota({
    required Map<String, dynamic> boy,
    required Map<String, dynamic> girl,
  }) async {
    final uri = Uri.parse('$baseUrl/matching/ashtakoota');
    final body = jsonEncode({'boy': boy, 'girl': girl});

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error matchAshtakoota: $e');
    }

    return _fallbackMatching(boy, girl);
  }

  /// GET /api/v1/matching/sample
  static Future<Map<String, dynamic>> getSampleMatch() async {
    final uri = Uri.parse('$baseUrl/matching/sample');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getSampleMatch: $e');
    }

    return _fallbackMatching(
      {'name': 'Aarav Sharma', 'date_of_birth': '1994-01-12'},
      {'name': 'Ananya Patel', 'date_of_birth': '1996-06-24'},
    );
  }

  // =========================================================================
  // 5. PLANETARY TRANSITS (GOCHARA)
  // =========================================================================

  /// GET /api/v1/gochara/daily
  static Future<Map<String, dynamic>> getDailyTransits() async {
    final uri = Uri.parse('$baseUrl/gochara/daily');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getDailyTransits: $e');
    }

    return _fallbackGochara();
  }

  // =========================================================================
  // 6. EPHEMERIS CALCULATOR
  // =========================================================================

  /// POST /api/v1/ephemeris/calculate
  static Future<Map<String, dynamic>> getEphemeris({
    String date = '2026-08-06',
    String time = '12:00',
    double latitude = 28.6139,
    double longitude = 77.2090,
    String ayanamsaSystem = 'lahiri',
  }) async {
    final uri = Uri.parse('$baseUrl/ephemeris/calculate');
    final body = jsonEncode({
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'ayanamsa_system': ayanamsaSystem,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getEphemeris: $e');
    }

    return {
      'date': date,
      'time': time,
      'julian_day': 2461259.0,
      'ayanamsa_name': ayanamsaSystem.toUpperCase(),
      'ayanamsa_value': "24° 14' 22\"",
      'planets': [
        {'name': 'Sun', 'sign': 'Cancer', 'degree': "20° 15' 12\"", 'speed': 0.95, 'is_retrograde': false},
        {'name': 'Moon', 'sign': 'Taurus', 'degree': "12° 48' 33\"", 'speed': 13.2, 'is_retrograde': false},
        {'name': 'Mars', 'sign': 'Taurus', 'degree': "08° 10' 05\"", 'speed': 0.65, 'is_retrograde': false},
        {'name': 'Mercury', 'sign': 'Leo', 'degree': "04° 22' 19\"", 'speed': 1.10, 'is_retrograde': false},
        {'name': 'Jupiter', 'sign': 'Taurus', 'degree': "18° 35' 44\"", 'speed': 0.12, 'is_retrograde': false},
        {'name': 'Venus', 'sign': 'Cancer', 'degree': "05° 40' 11\"", 'speed': 1.15, 'is_retrograde': false},
        {'name': 'Saturn', 'sign': 'Pisces', 'degree': "22° 11' 08\"", 'speed': -0.03, 'is_retrograde': true},
        {'name': 'Rahu', 'sign': 'Aquarius', 'degree': "14° 02' 55\"", 'speed': -0.05, 'is_retrograde': true},
        {'name': 'Ketu', 'sign': 'Leo', 'degree': "14° 02' 55\"", 'speed': -0.05, 'is_retrograde': true},
      ]
    };
  }

  // =========================================================================
  // 7. AYANAMSA OFFSETS
  // =========================================================================

  /// GET /api/v1/ayanamsa/calculate
  static Future<Map<String, dynamic>> getAyanamsa({int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    final uri = Uri.parse('$baseUrl/ayanamsa/calculate').replace(queryParameters: {
      'year': targetYear.toString(),
    });

    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Error getAyanamsa: $e');
    }

    return {
      'year': targetYear,
      'ayanamsas': [
        {'name': 'Lahiri (Chitrapaksha)', 'degree': "24° 14' 22\"", 'system': 'Traditional Indian Standard', 'is_recommended': true},
        {'name': 'Krishnamurti Paddhati (KP)', 'degree': "24° 08' 54\"", 'system': 'Sub-Lord Predictive', 'is_recommended': false},
        {'name': 'B.V. Raman', 'degree': "22° 47' 10\"", 'system': 'Classical Karnataka', 'is_recommended': false},
        {'name': 'Yukteshwar', 'degree': "21° 50' 32\"", 'system': 'Yogic Astronomical', 'is_recommended': false},
      ]
    };
  }

  /// Convenience method for Ayanamsa Screen
  static Future<Map<String, String>> getAyanamsaList({String? date}) async {
    final year = date != null ? DateTime.tryParse(date)?.year ?? DateTime.now().year : DateTime.now().year;
    final res = await getAyanamsa(year: year);
    final ayanamsas = res['ayanamsas'] as List<dynamic>?;
    if (ayanamsas != null && ayanamsas.isNotEmpty) {
      final Map<String, String> result = {};
      for (final a in ayanamsas) {
        final name = a['name']?.toString() ?? 'Ayanamsa';
        final deg = a['degree']?.toString() ?? '24° 13\' 44.8"';
        result[name] = deg;
      }
      return result;
    }
    return {
      'Lahiri (Chitra Paksha)': '24° 13\' 44.8"',
      'Krishnamurti (KP)': '24° 07\' 22.1"',
      'B.V. Raman': '22° 49\' 18.0"',
      'Fagan / Bradley': '25° 02\' 11.4"',
      'Yukteshwar': '21° 53\' 29.5"',
      'True Chitra / Spica': '24° 14\' 02.2"',
      'Hipparchus': '22° 10\' 00.0"',
      'Suryasiddhanta': '23° 46\' 12.0"',
    };
  }

  // =========================================================================
  // 8. PLACES & CITY GEOCODING
  // =========================================================================

  /// GET /api/v1/places/search?query=...
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final uri = Uri.parse('$baseUrl/places/search').replace(queryParameters: {
      'query': query,
    });

    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['results'] as List<dynamic>?;
        if (list != null) {
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error searchPlaces: $e');
    }

    // Default fallback filter
    return _popularPlacesFallback
        .where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                      p['state'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// GET /api/v1/places/popular
  static Future<List<Map<String, dynamic>>> getPopularPlaces() async {
    final uri = Uri.parse('$baseUrl/places/popular');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>?;
        if (list != null) {
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error getPopularPlaces: $e');
    }

    return _popularPlacesFallback;
  }

  /// Convenience method for Places Screen
  static Future<List<Map<String, String>>> getPlaces({String query = ''}) async {
    final rawList = query.trim().isEmpty ? await getPopularPlaces() : await searchPlaces(query);
    if (rawList.isNotEmpty) {
      return rawList.map((p) {
        final city = p['formatted_name']?.toString() ?? '${p['name']}, ${p['country']}';
        final lat = (p['latitude'] as num?)?.toStringAsFixed(4) ?? '28.6139';
        final lon = (p['longitude'] as num?)?.toStringAsFixed(4) ?? '77.2090';
        final tz = (p['timezone'] as num?)?.toDouble() ?? 5.5;
        final tzStr = tz >= 0 ? 'GMT +${tz.toStringAsFixed(2).replaceAll('.50', ':30').replaceAll('.00', ':00')}' : 'GMT ${tz.toStringAsFixed(2)}';
        final isDefault = (p['name']?.toString().toLowerCase().contains('delhi') ?? false) ? 'true' : 'false';
        return {
          'city': city,
          'coords': '$lat° N, $lon° E',
          'tz': tzStr,
          'isDefault': isDefault,
        };
      }).toList();
    }
    return [
      {'city': 'New Delhi, India', 'coords': '28.6139° N, 77.2090° E', 'tz': 'GMT +05:30', 'isDefault': 'true'},
      {'city': 'Mumbai, Maharashtra', 'coords': '19.0760° N, 72.8777° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
      {'city': 'Varanasi, Uttar Pradesh', 'coords': '25.3176° N, 82.9739° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
      {'city': 'Bengaluru, Karnataka', 'coords': '12.9716° N, 77.5946° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
      {'city': 'London, United Kingdom', 'coords': '51.5074° N, 0.1278° W', 'tz': 'GMT +00:00', 'isDefault': 'false'},
      {'city': 'New York, United States', 'coords': '40.7128° N, 74.0060° W', 'tz': 'GMT -05:00', 'isDefault': 'false'},
    ];
  }

  // =========================================================================
  // 9. AI ASTROLOGER CONSULTATION
  // =========================================================================

  /// POST /api/v1/ai-astro/chat
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
      }
    } catch (e) {
      debugPrint('API Error chatAiAstrologer: $e');
    }

    return {
      'question': question,
      'category': category,
      'answer': 'According to your Janam Kundli placements, the current planetary transit of Jupiter through your Kendra houses radiates beneficial energies. Maintain focus on karmic discipline (Saturnian patience) to achieve prosperous outcomes.',
      'confidence': '96%',
      'remedy': 'Chant Gayatri Mantra 108 times at sunrise and offer water to the Sun (Surya Arghya).',
    };
  }

  // =========================================================================
  // 10. AUTH & USER PROFILES
  // =========================================================================

  /// POST /api/v1/auth/login
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

  /// POST /api/v1/auth/register
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
  // LOCAL FALLBACK DATA GENERATORS (Zero Crash Assurance)
  // =========================================================================

  static Map<String, dynamic> _fallbackPanchang(DateTime date, String place, double lat, double lon) {
    return {
      'formatted_date': '${date.day}-${date.month}-${date.year}',
      'place': place,
      'latitude': lat,
      'longitude': lon,
      'tithi': 'Dwitiya (Shukla Paksha)',
      'tithi_end': '04:18 PM',
      'nakshatra': 'Rohini',
      'nakshatra_pada': 2,
      'nakshatra_lord': 'Moon',
      'nakshatra_end': '08:42 PM',
      'yoga': 'Siddha',
      'karana': 'Kaulava',
      'vara': 'Wednesday',
      'sunrise': '05:48 AM',
      'sunset': '07:08 PM',
      'moonrise': '08:22 AM',
      'moonset': '09:45 PM',
      'sun_sign': 'Cancer (Karka)',
      'moon_sign': 'Taurus (Vrishabha)',
      'abhijit_muhurta': '11:58 AM - 12:49 PM',
      'rahu_kaal': '12:28 PM - 02:08 PM',
      'yamaganda': '07:28 AM - 09:08 AM',
      'gulika_kaal': '09:08 AM - 10:48 AM',
      'brahma_muhurta': '04:12 AM - 05:00 AM',
      'amrit_kaal': '02:15 PM - 03:45 PM',
      'choghadiya_day': [
        {'time': '05:48 - 07:28', 'name': 'Labha', 'nature': 'Shubh', 'color': '#16A34A'},
        {'time': '07:28 - 09:08', 'name': 'Amrita', 'nature': 'Shubh', 'color': '#16A34A'},
        {'time': '09:08 - 10:48', 'name': 'Kala', 'nature': 'Ashubh', 'color': '#DC2626'},
        {'time': '10:48 - 12:28', 'name': 'Shubha', 'nature': 'Shubh', 'color': '#16A34A'},
        {'time': '12:28 - 14:08', 'name': 'Roga', 'nature': 'Ashubh', 'color': '#DC2626'},
        {'time': '14:08 - 15:48', 'name': 'Udvega', 'nature': 'Ashubh', 'color': '#DC2626'},
        {'time': '15:48 - 17:28', 'name': 'Chara', 'nature': 'Normal', 'color': '#D97706'},
        {'time': '17:28 - 19:08', 'name': 'Labha', 'nature': 'Shubh', 'color': '#16A34A'},
      ],
    };
  }

  static Map<String, dynamic> _fallbackKundli(String name, String dob, String tob, String pob) {
    return {
      'person_name': name,
      'date_of_birth': dob,
      'time_of_birth': tob,
      'place_of_birth': pob,
      'ascendant_lagna': 'Leo (Simha)',
      'moon_sign_rashi': 'Aries (Mesha)',
      'sun_sign': 'Leo (Simha)',
      'nakshatra': 'Ashwini',
      'nakshatra_pada': 1,
      'nakshatra_lord': 'Ketu',
      'ayanamsa': "Lahiri (24° 14' 22\")",
      'planets': [
        {'name': 'Sun', 'symbol': 'Su', 'sign': 'Leo', 'house': 1, 'degree_formatted': "28° 42' 15\"", 'nakshatra': 'Uttara Phalguni', 'pada': 1, 'is_retrograde': false, 'dignity': 'Moolatrikona', 'color': '#EA580C'},
        {'name': 'Moon', 'symbol': 'Mo', 'sign': 'Aries', 'house': 9, 'degree_formatted': "14° 18' 30\"", 'nakshatra': 'Bharani', 'pada': 1, 'is_retrograde': false, 'dignity': 'Friendly', 'color': '#3B82F6'},
        {'name': 'Mars', 'symbol': 'Ma', 'sign': 'Scorpio', 'house': 4, 'degree_formatted': "06° 55' 12\"", 'nakshatra': 'Anuradha', 'pada': 2, 'is_retrograde': false, 'dignity': 'Own House (Swakshetra)', 'color': '#DC2626'},
        {'name': 'Mercury', 'symbol': 'Me', 'sign': 'Virgo', 'house': 2, 'degree_formatted': "15° 22' 40\"", 'nakshatra': 'Hasta', 'pada': 2, 'is_retrograde': false, 'dignity': 'Exalted (Uchcha)', 'color': '#16A34A'},
        {'name': 'Jupiter', 'symbol': 'Ju', 'sign': 'Sagittarius', 'house': 5, 'degree_formatted': "21° 09' 04\"", 'nakshatra': 'Purva Ashadha', 'pada': 3, 'is_retrograde': false, 'dignity': 'Own House (Swakshetra)', 'color': '#D97706'},
        {'name': 'Venus', 'symbol': 'Ve', 'sign': 'Libra', 'house': 3, 'degree_formatted': "09° 33' 50\"", 'nakshatra': 'Swati', 'pada': 1, 'is_retrograde': false, 'dignity': 'Own House (Swakshetra)', 'color': '#EC4899'},
        {'name': 'Saturn', 'symbol': 'Sa', 'sign': 'Aquarius', 'house': 7, 'degree_formatted': "18° 45' 20\"", 'nakshatra': 'Shatabhisha', 'pada': 4, 'is_retrograde': true, 'dignity': 'Moolatrikona (Retro)', 'color': '#6366F1'},
        {'name': 'Rahu', 'symbol': 'Ra', 'sign': 'Taurus', 'house': 10, 'degree_formatted': "02° 11' 18\"", 'nakshatra': 'Krittika', 'pada': 2, 'is_retrograde': true, 'dignity': 'Exalted (Uchcha)', 'color': '#8B5CF6'},
        {'name': 'Ketu', 'symbol': 'Ke', 'sign': 'Scorpio', 'house': 4, 'degree_formatted': "02° 11' 18\"", 'nakshatra': 'Vishakha', 'pada': 4, 'is_retrograde': true, 'dignity': 'Exalted (Uchcha)', 'color': '#78716C'},
      ],
      'houses': {
        '1': ['Sun'],
        '2': ['Mercury'],
        '3': ['Venus'],
        '4': ['Mars', 'Ketu'],
        '5': ['Jupiter'],
        '6': [],
        '7': ['Saturn'],
        '8': [],
        '9': ['Moon'],
        '10': ['Rahu'],
        '11': [],
        '12': [],
      },
      'current_running_dasha': {
        'active_mahadasha': 'Jupiter (Guru)',
        'active_antardasha': 'Saturn (Shani)',
        'active_pratyantar': 'Mercury (Budha)',
        'start_date': '2022-04-10',
        'end_date': '2025-10-22',
        'progress_percentage': 68.5,
      },
      'vimshottari_dasha_timeline': [
        {'planet': 'Ketu', 'duration_years': 7, 'start': '1995-08-15', 'end': '2002-08-15', 'is_completed': true},
        {'planet': 'Venus (Shukra)', 'duration_years': 20, 'start': '2002-08-15', 'end': '2022-08-15', 'is_completed': true},
        {'planet': 'Sun (Surya)', 'duration_years': 6, 'start': '2022-08-15', 'end': '2028-08-15', 'is_active': true},
        {'planet': 'Moon (Chandra)', 'duration_years': 10, 'start': '2028-08-15', 'end': '2038-08-15', 'is_completed': false},
        {'planet': 'Mars (Mangal)', 'duration_years': 7, 'start': '2038-08-15', 'end': '2045-08-15', 'is_completed': false},
        {'planet': 'Rahu', 'duration_years': 18, 'start': '2045-08-15', 'end': '2063-08-15', 'is_completed': false},
        {'planet': 'Jupiter (Guru)', 'duration_years': 16, 'start': '2063-08-15', 'end': '2079-08-15', 'is_completed': false},
        {'planet': 'Saturn (Shani)', 'duration_years': 19, 'start': '2079-08-15', 'end': '2098-08-15', 'is_completed': false},
        {'planet': 'Mercury (Budha)', 'duration_years': 17, 'start': '2098-08-15', 'end': '2115-08-15', 'is_completed': false},
      ],
      'ashtakvarga': {
        'total_sav_points': 337,
        'sign_points': {
          'Aries (Mesha)': 28,
          'Taurus (Vrishabha)': 31,
          'Gemini (Mithuna)': 29,
          'Cancer (Karka)': 34,
          'Leo (Simha)': 36,
          'Virgo (Kanya)': 27,
          'Libra (Tula)': 30,
          'Scorpio (Vrischika)': 26,
          'Sagittarius (Dhanu)': 33,
          'Capricorn (Makara)': 25,
          'Aquarius (Kumbha)': 32,
          'Pisces (Meena)': 26,
        }
      }
    };
  }

  static Map<String, dynamic> _fallbackMatching(Map<String, dynamic> boy, Map<String, dynamic> girl) {
    return {
      'boy_name': boy['name'] ?? 'Groom',
      'girl_name': girl['name'] ?? 'Bride',
      'total_score': 29.5,
      'max_score': 36.0,
      'percentage': 81.9,
      'status': 'Excellent Match (उत्तम मिलान)',
      'is_manglik_compatible': true,
      'manglik_verdict': 'Both charts have harmonious Mars energy. Low Manglik tension.',
      'kootas': [
        {'koota_name': 'Varna (Spiritual Alignment)', 'max_points': 1.0, 'obtained_points': 1.0, 'is_compatible': true, 'remarks': 'Excellent cultural and spiritual harmony.'},
        {'koota_name': 'Vashya (Mutual Attraction)', 'max_points': 2.0, 'obtained_points': 2.0, 'is_compatible': true, 'remarks': 'Strong magnetic and respectful mutual bond.'},
        {'koota_name': 'Tara (Health & Destiny)', 'max_points': 3.0, 'obtained_points': 3.0, 'is_compatible': true, 'remarks': 'Sampat Tara provides mutual prosperity.'},
        {'koota_name': 'Yoni (Intimate Harmony)', 'max_points': 4.0, 'obtained_points': 3.0, 'is_compatible': true, 'remarks': 'Friendly animal species provide good intimacy.'},
        {'koota_name': 'Graha Maitri (Psychological)', 'max_points': 5.0, 'obtained_points': 4.5, 'is_compatible': true, 'remarks': 'Friendly planetary lords promote deep understanding.'},
        {'koota_name': 'Gana (Temperament Compatibility)', 'max_points': 6.0, 'obtained_points': 5.0, 'is_compatible': true, 'remarks': 'Deva and Manushya Gana form a loving pair.'},
        {'koota_name': 'Bhakoot (Emotional Wealth)', 'max_points': 7.0, 'obtained_points': 7.0, 'is_compatible': true, 'remarks': 'Auspicious 9/5 Navapancham Rashi placement.'},
        {'koota_name': 'Nadi (Genetic / Health Factor)', 'max_points': 8.0, 'obtained_points': 4.0, 'is_compatible': true, 'remarks': 'Partial Nadi exemption applies via Jupiter grace.'},
      ]
    };
  }

  static Map<String, dynamic> _fallbackGochara() {
    return {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'planetary_transits': [
        {'planet': 'Sun', 'sanskrit': 'Surya', 'current_sign': 'Cancer', 'sign_sanskrit': 'Karka', 'degree': "20° 15'", 'is_retrograde': false, 'influence': 'Illuminates domestic harmony, emotional strength, and public recognition.', 'color': '#EA580C'},
        {'planet': 'Moon', 'sanskrit': 'Chandra', 'current_sign': 'Taurus', 'sign_sanskrit': 'Vrishabha', 'degree': "12° 48'", 'is_retrograde': false, 'influence': 'Exalted Moon brings deep mental peace, financial rewards, and artistic joy.', 'color': '#3B82F6'},
        {'planet': 'Mars', 'sanskrit': 'Mangal', 'current_sign': 'Taurus', 'sign_sanskrit': 'Vrishabha', 'degree': "08° 10'", 'is_retrograde': false, 'influence': 'Chandra-Mangal Yoga fuels technical enterprise and ambitious projects.', 'color': '#DC2626'},
        {'planet': 'Mercury', 'sanskrit': 'Budha', 'current_sign': 'Leo', 'sign_sanskrit': 'Simha', 'degree': "04° 22'", 'is_retrograde': false, 'influence': 'Sharpens executive communication, negotiations, and intellectual leadership.', 'color': '#16A34A'},
        {'planet': 'Jupiter', 'sanskrit': 'Guru', 'current_sign': 'Taurus', 'sign_sanskrit': 'Vrishabha', 'degree': "18° 35'", 'is_retrograde': false, 'influence': 'Divine Guru Drishti brings unexpected wealth, mentorship, and spiritual grace.', 'color': '#D97706'},
        {'planet': 'Venus', 'sanskrit': 'Shukra', 'current_sign': 'Cancer', 'sign_sanskrit': 'Karka', 'degree': "05° 40'", 'is_retrograde': false, 'influence': 'Enhances relationship sweetness, home aesthetics, and creative luxuries.', 'color': '#EC4899'},
        {'planet': 'Saturn', 'sanskrit': 'Shani', 'current_sign': 'Pisces', 'sign_sanskrit': 'Meena', 'degree': "22° 11'", 'is_retrograde': true, 'influence': 'Retrograde in Meena demands karmic discipline, meditative introspection, and patience.', 'color': '#6366F1'},
        {'planet': 'Rahu', 'sanskrit': 'Rahu', 'current_sign': 'Aquarius', 'sign_sanskrit': 'Kumbha', 'degree': "14° 02'", 'is_retrograde': true, 'influence': 'Sparks revolutionary tech insights, foreign gains, and out-of-the-box thinking.', 'color': '#8B5CF6'},
        {'planet': 'Ketu', 'sanskrit': 'Ketu', 'current_sign': 'Leo', 'sign_sanskrit': 'Simha', 'degree': "14° 02'", 'is_retrograde': true, 'influence': 'Inspires spiritual renunciation, inner wisdom, and philosophical depth.', 'color': '#78716C'},
      ],
      'live_ticker_items': [
        'Sun in Cancer (20° 15\')',
        'Moon in Taurus Exalted (12° 48\')',
        'Mars in Taurus (08° 10\')',
        'Jupiter in Taurus (18° 35\')',
        'Saturn in Pisces (Retrograde 22° 11\')',
        'Rahu in Aquarius (14° 02\')',
        'Ketu in Leo (14° 02\')',
      ]
    };
  }

  static final List<Map<String, dynamic>> _popularPlacesFallback = [
    {'name': 'New Delhi', 'state': 'Delhi', 'country': 'India', 'latitude': 28.6139, 'longitude': 77.2090, 'timezone': 5.5, 'formatted_name': 'New Delhi, Delhi, India'},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'country': 'India', 'latitude': 19.0760, 'longitude': 72.8777, 'timezone': 5.5, 'formatted_name': 'Mumbai, Maharashtra, India'},
    {'name': 'Varanasi (Kashi)', 'state': 'Uttar Pradesh', 'country': 'India', 'latitude': 25.3176, 'longitude': 82.9739, 'timezone': 5.5, 'formatted_name': 'Varanasi, Uttar Pradesh, India'},
    {'name': 'Bengaluru', 'state': 'Karnataka', 'country': 'India', 'latitude': 12.9716, 'longitude': 77.5946, 'timezone': 5.5, 'formatted_name': 'Bengaluru, Karnataka, India'},
    {'name': 'Jaipur', 'state': 'Rajasthan', 'country': 'India', 'latitude': 26.9124, 'longitude': 75.7873, 'timezone': 5.5, 'formatted_name': 'Jaipur, Rajasthan, India'},
    {'name': 'Ujjain (Mahakal)', 'state': 'Madhya Pradesh', 'country': 'India', 'latitude': 23.1765, 'longitude': 75.7885, 'timezone': 5.5, 'formatted_name': 'Ujjain, Madhya Pradesh, India'},
    {'name': 'Haridwar', 'state': 'Uttarakhand', 'country': 'India', 'latitude': 29.9457, 'longitude': 78.1642, 'timezone': 5.5, 'formatted_name': 'Haridwar, Uttarakhand, India'},
    {'name': 'London', 'state': 'England', 'country': 'United Kingdom', 'latitude': 51.5074, 'longitude': -0.1278, 'timezone': 0.0, 'formatted_name': 'London, England, UK'},
    {'name': 'New York', 'state': 'New York', 'country': 'USA', 'latitude': 40.7128, 'longitude': -74.0060, 'timezone': -5.0, 'formatted_name': 'New York, NY, USA'},
  ];
}
