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
      return 'http://192.168.29.77:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.29.77:5000/api/v1'; // Connects to local Flask backend from Android Emulator or USB Reverse Port
      }
    } catch (_) {}  
    return 'http://192.168.29.77:5000/api/v1';
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
      'ngrok-skip-browser-warning': 'true', // Bypass ngrok HTML warning page
    };
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 30); // Increased for hosted backend (cold start + ngrok overhead)

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
  // 3. AYANAMSA DEGREES (fetched live from backend)
  // =========================================================================

  /// Fetches the live ayanamsa degree values for the given birth details.
  /// Backend endpoint: GET /astro/ayanamsa_degrees
  /// Returns e.g. { 'LAHIRI': 24.107, 'BV_RAMAN': 23.023, ... }
  static Future<Map<String, double>> getAyanamsaDegrees({
    required String dateOfBirth,
    required String timeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  }) async {
    final params = <String, String>{
      'date': dateOfBirth,
      'time': timeOfBirth,
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lon': longitude.toString(),
      if (timezone != null) 'tz': timezone.toString(),
    };
    final uri = Uri.parse('$baseUrl/horoscope/ayanamsa_degrees').replace(queryParameters: params);
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = (data is Map && data.containsKey('ayanamsa_degrees'))
            ? data['ayanamsa_degrees'] as Map
            : data as Map;
        return raw.map<String, double>(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        );
      }
    } catch (e) {
      debugPrint('AstroApiService getAyanamsaDegrees error: $e');
    }
    return {};
  }

  // =========================================================================
  // 4. HOROSCOPE / KUNDLI
  // =========================================================================

  static Future<Map<String, dynamic>> getKundli({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
    double? daysInYear,
    String? bhavaSystem,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/kundli');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (daysInYear != null) bodyMap['days_in_year'] = daysInYear;
    if (bhavaSystem != null) bodyMap['bhava_system'] = bhavaSystem;


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

  static Future<Map<String, dynamic>> getDasha({
    required String dashaType,
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
    double? daysInYear,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/dasha');
    final Map<String, dynamic> bodyMap = {
      'dasha_type': dashaType,
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (daysInYear != null) bodyMap['days_in_year'] = daysInYear;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Dasha: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getDasha: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getKpSystemData({
    String name = 'User',
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
    required String ayanamsa,
    double? customAyanamsa,
    double? transitLatitude,
    double? transitLongitude,
    double? transitTimezone,
    String? transitDatetime,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/kp');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      'ayanamsa': ayanamsa,
      'node_type': 'true',
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (transitLatitude != null) bodyMap['transit_latitude'] = transitLatitude;
    if (transitLongitude != null) bodyMap['transit_longitude'] = transitLongitude;
    if (transitTimezone != null) bodyMap['transit_timezone'] = transitTimezone;
    if (transitDatetime != null) bodyMap['transit_datetime'] = transitDatetime;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load KP System: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getKpSystemData: $e');
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
  // 4.5 NUMEROLOGY
  // =========================================================================
  static Future<Map<String, dynamic>> getNumerologyProfile({
    required String name,
    required String dateOfBirth,
    String system = 'pythagorean',
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/profile');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'dob': dateOfBirth,
      'system': system,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Numerology: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getNumerologyProfile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAstrologerWorkspace({
    required String name,
    required String dateOfBirth,
    String system = 'pythagorean',
    String? referenceDate,
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/astrologer-workspace');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'dob': dateOfBirth,
      'system': system,
      if (referenceDate != null && referenceDate.isNotEmpty) 'reference_date': referenceDate,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Astrologer Workspace: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getAstrologerWorkspace: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getChartWorkspace({
    required String name,
    required String dateOfBirth,
    String system = 'pythagorean',
    String? startDate,
    int durationYears = 10,
    String? endDate,
    String? referenceDate,
    int? parentDashaFilter,
    String gridType = 'vedic',
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/chart-workspace');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'dob': dateOfBirth,
      'system': system,
      'duration_years': durationYears,
      'grid_type': gridType,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (referenceDate != null && referenceDate.isNotEmpty) 'reference_date': referenceDate,
      if (parentDashaFilter != null) 'parent_dasha_filter': parentDashaFilter,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['message'] ?? 'Failed to load Chart Workspace: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getChartWorkspace: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getParyantardashasForYear({
    required String dateOfBirth,
    int? year,
    String? referenceDate,
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/dasha/paryantardashas');
    final Map<String, dynamic> bodyMap = {
      'dob': dateOfBirth,
      if (year != null) 'year': year,
      if (referenceDate != null && referenceDate.isNotEmpty) 'reference_date': referenceDate,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      } else {
        throw Exception('Failed to load Paryantardashas: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getParyantardashasForYear: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyDashas({
    required String dateOfBirth,
    String? centerDate,
    int spanDays = 14,
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/dasha/daily');
    final Map<String, dynamic> bodyMap = {
      'dob': dateOfBirth,
      if (centerDate != null && centerDate.isNotEmpty) 'center_date': centerDate,
      'span_days': spanDays,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      } else {
        throw Exception('Failed to load Daily Dashas: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getDailyDashas: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLifePathReport({
    required String dateOfBirth,
    String? name,
    String system = 'pythagorean',
  }) async {
    try {
      final queryParams = {
        'dob': dateOfBirth,
        'system': system,
        if (name != null && name.isNotEmpty) 'name': name,
      };
      final uri = Uri.parse('$baseUrl/numerology/life-path').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('LifePath request failed for $baseUrl: $e');
    }

    // Fallback: If network is offline, perform deterministic Pythagorean reduction locally
    return _generateLocalLifePathReport(dateOfBirth: dateOfBirth, name: name ?? 'Seeker', system: system);
  }

  static Map<String, dynamic> _generateLocalLifePathReport({
    required String dateOfBirth,
    required String name,
    String system = 'pythagorean',
  }) {
    final parts = dateOfBirth.split('-');
    int y = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 1998 : 1998;
    int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 12 : 12;
    int d = parts.length > 2 ? int.tryParse(parts[2]) ?? 16 : 16;

    int reduce(int n, bool keepMasters) {
      if (keepMasters && (n == 11 || n == 22 || n == 33)) return n;
      while (n > 9) {
        n = n.toString().split('').map(int.parse).reduce((a, b) => a + b);
        if (keepMasters && (n == 11 || n == 22 || n == 33)) return n;
      }
      return n;
    }

    final redM = reduce(m, true);
    final redD = reduce(d, true);
    final ySum = y.toString().split('').map(int.parse).reduce((a, b) => a + b);
    final redY = reduce(ySum, true);
    final combined = redM + redD + redY;
    final lp = reduce(combined, true);

    final titles = {
      1: "The Innovative Pioneer & Trailblazer",
      2: "The Harmonious Peacemaker & Intuitive Diplomat",
      3: "The Expressive Creator & Radiant Communicator",
      4: "The Master Builder & Systematic Strategist",
      5: "The Free-Spirited Catalyst & Dynamic Explorer",
      6: "The Nurturing Guardian & Compassionate Pillar",
      7: "The Analytical Seeker & Contemplative Mystic",
      8: "The Sovereign Achiever & Executive Manifestor",
      9: "The Compassionate Humanitarian & Universal Visionary",
      11: "The Illuminator & Master Intuitive Teacher",
      22: "The Master Architect & Visionary Builder",
      33: "The Master Healer & Universal Teacher",
    };

    final themes = {
      1: "Independence, authentic leadership, original thinking, and courageous initiative.",
      2: "Cooperation, emotional intelligence, peacemaking, and deep partnership.",
      3: "Creative self-expression, joyful vitality, communication, and optimism.",
      4: "Stability, structural integrity, steadfast discipline, and lasting foundations.",
      5: "Freedom, progressive change, versatility, and experiential wisdom.",
      6: "Loving service, family harmony, protective responsibility, and community care.",
      7: "Wisdom, analytical depth, philosophical inquiry, and spiritual truth.",
      8: "Material mastery, executive authority, abundance, and ethical power.",
      9: "Universal empathy, philanthropy, artistic wisdom, and selfless service.",
      11: "Spiritual illumination, heightened intuition, visionary inspiration, and guidance.",
      22: "Monumental achievements, practical idealism, and global structural impact.",
      33: "Selfless compassion, universal healing, spiritual teaching, and devotional love.",
    };

    return {
      "status": "success",
      "calculation_status": "completed",
      "user_name": name,
      "life_path_number": lp,
      "number_title": titles[lp] ?? "Life Path $lp",
      "core_theme": themes[lp] ?? "Destiny and personal vibration.",
      "is_master_number": lp == 11 || lp == 22 || lp == 33,
      "date_of_birth_used": dateOfBirth,
      "calculation_system": system,
      "method_version": "1.0.0",
      "content_version": "1.0.0",
      "calculation_trace": {
        "date_of_birth": dateOfBirth,
        "month": {"original": m, "reduced": redM, "steps": ["Month $m -> $redM"]},
        "day": {"original": d, "reduced": redD, "steps": ["Day $d -> $redD"]},
        "year": {"original": y, "reduced": redY, "steps": ["Year $y -> $redY"]},
        "combined_sum": combined,
        "reduction_steps": ["$redM (Month) + $redD (Day) + $redY (Year) = $combined", "$combined -> $lp"],
        "final_number": lp
      },
      "interpretation": {
        "overview": "Life Path $lp embodies ${themes[lp] ?? 'a unique path of purpose'}. People on this vibration are endowed with distinctive gifts designed to navigate opportunities and overcome challenges with grace.",
        "strengths": [
          "Natural initiative and authentic personal clarity",
          "Resilience in the face of complex transitions",
          "Visionary perspective and dependable integrity",
          "Charisma and motivational presence"
        ],
        "challenges": [
          "Impatience when others operate at a different tempo",
          "Reluctance to ask for assistance when overwhelmed",
          "Balancing personal independence with shared commitments"
        ],
        "relationships": "In partnerships, you value mutual respect, open communication, and shared values. Cultivating patience and active listening creates deeply fulfilling connections.",
        "career": "Excels in environments offering creative discretion, leadership opportunities, and clear strategic goals. Bureaucracy without purpose stifles your greatest output.",
        "personal_growth": "Practice daily mindfulness: anchor your energy each morning, celebrate collective achievements, and align actions with your core values.",
        "sections": [
          {
            "section_type": "overview",
            "heading": "The Core Archetype",
            "content": "Your life path represents your central trajectory. It acts as a compass guiding choices, learning milestones, and personal evolution."
          },
          {
            "section_type": "traditional",
            "heading": "Personality & Cognitive Flow",
            "content": "You process experiences with focus and intuition, naturally finding innovative ways through complicated situations."
          }
        ]
      },
      "timestamp": DateTime.now().toIso8601String()
    };
  }

  // =========================================================================
  // 4.6 BIRTH DAY NUMBER
  // =========================================================================
  static Future<Map<String, dynamic>> getBirthDayReport({
    required String dateOfBirth,
    String? name,
    String system = 'pythagorean',
  }) async {
    try {
      final queryParams = {
        'dob': dateOfBirth,
        'system': system,
        if (name != null && name.isNotEmpty) 'name': name,
      };
      final uri = Uri.parse('$baseUrl/numerology/birth-day').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('BirthDay request failed for $baseUrl: $e');
    }

    return _generateLocalBirthDayReport(dateOfBirth: dateOfBirth, name: name ?? 'Seeker', system: system);
  }

  static Map<String, dynamic> _generateLocalBirthDayReport({
    required String dateOfBirth,
    required String name,
    String system = 'pythagorean',
  }) {
    final parts = dateOfBirth.split('-');
    int d = parts.length > 2 ? int.tryParse(parts[2]) ?? 16 : 16;
    int root = d;
    if (d == 11 || d == 22) {
      root = d;
    } else {
      while (root > 9) {
        root = root.toString().split('').map(int.parse).reduce((a, b) => a + b);
        if (root == 11 || root == 22) break;
      }
    }

    final titles = {
      1: "The Independent Trailblazer",
      2: "The Sensitive Empath & Partner",
      3: "The Creative Enthusiast",
      4: "The Methodical Foundation-Builder",
      5: "The Adventurous Free Spirit",
      6: "The Compassionate Nurturer",
      7: "The Analytical Truth-Seeker",
      8: "The Executive Manifestor",
      9: "The Universal Humanitarian",
      10: "The Resolute Pioneer of New Beginnings",
      11: "The Master Intuitive & Visionary",
      12: "The Expressive Synthesizer",
      13: "The Disciplined Transformer",
      14: "The Adaptable Change Agent",
      15: "The Magnetic Harmonizer",
      16: "The Discerning Mystic & Philosopher",
      17: "The Insightful Financial Strategist",
      18: "The Compassionate Leader of Change",
      19: "The Radiant Sovereign Achiever",
      20: "The Intuitive Peacemaker",
      21: "The Inspired Social Catalyst",
      22: "The Master Builder & Structural Architect",
      23: "The Eloquent Quick-Minded Explorer",
      24: "The Loyal Family Pillar & Devoted Guardian",
      25: "The Observant Inward Explorer",
      26: "The Practical Visionary & Philanthropic Leader",
      27: "The Wise Counselor & Empathetic Teacher",
      28: "The Collaborative Diplomatic Pioneer",
      29: "The Inspired Conduit of Deep Insight",
      30: "The Charismatic Optimistic Artist",
      31: "The Steadfast Creative Architect"
    };

    final title = titles[d] ?? "Day $d Native";
    final theme = "Innate gifts, personal expression, and everyday demeanor associated with day $d.";

    return {
      "status": "success",
      "calculation_status": "completed",
      "user_name": name,
      "birth_day_number": d,
      "reduced_root": root,
      "number_title": title,
      "core_theme": theme,
      "is_master_day": d == 11 || d == 22,
      "date_of_birth_used": dateOfBirth,
      "calculation_system": system,
      "method_version": "1.0.0",
      "content_version": "1.0.0",
      "calculation_trace": {
        "date_of_birth": dateOfBirth,
        "calendar_day": d,
        "primary_rule": "Calendar day extracted as authoritative primary Birth Day Number: $d",
        "secondary_reduced_root": root,
        "root_reduction_steps": ["Day $d -> Root $root"]
      },
      "interpretation": {
        "overview": "Born on the ${d}th, your primary Birth Day Number is $d. In traditional numerology, your Birth Day Number represents your natural talents, spontaneous approach to challenges, and foundational toolkit.",
        "strengths": [
          "Authentic personal clarity and innate confidence",
          "Distinctive intuitive or analytical perception",
          "Reliable follow-through when inspired",
          "Charismatic and motivating demeanor"
        ],
        "challenges": [
          "Patience when working with slower-moving projects",
          "Remembering to take regular breaks to recharge energy",
          "Avoiding over-extending personal commitments"
        ],
        "personality": "Day $d natives demonstrate focused determination and reflective discernment, communicating clearly and authentically in social circles.",
        "relationships": "In romantic and close partnerships, you value loyalty, intellectual resonance, and mutual respect.",
        "career": "You thrive in roles providing autonomy, creative exploration, and clear goals.",
        "personal_growth": "Daily practice: Take five minutes each morning to center yourself and set clear, balanced intentions.",
        "quick_summary": {
          "key_traits": ["Focused Energy", "Authentic Demeanor", "Natural Capability"],
          "potential_challenge": "Pacing personal energy",
          "growth_suggestion": "Prioritize restorative balance alongside goals"
        },
        "sections": [
          {
            "section_type": "overview",
            "heading": "The Day's Core Archetype",
            "content": "Born on the ${d}th, you carry the distinctive vibration of $d, guiding your everyday decisions and natural reactions."
          }
        ]
      },
      "timestamp": DateTime.now().toIso8601String()
    };
  }

  // =========================================================================
  // 4.7 PERSONAL YEAR NUMBER
  // =========================================================================
  static Future<Map<String, dynamic>> getPersonalYearReport({
    required String dateOfBirth,
    int? year,
    String? name,
    String system = 'pythagorean',
  }) async {
    final queryParams = {
      'dob': dateOfBirth,
      'system': system,
      if (year != null) 'year': year.toString(),
      if (name != null && name.isNotEmpty) 'name': name,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/personal-year').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('PersonalYear request failed for $baseUrl: $e');
    }

    throw Exception('Failed to connect to backend server for Personal Year calculation.');
  }

  // =========================================================================
  // 4.8 NAME ANALYSIS
  // =========================================================================
  static Future<Map<String, dynamic>> getNameAnalysisReport({
    required String birthName,
    String? currentName,
    String system = 'pythagorean',
    String? dateOfBirth,
  }) async {
    final bodyData = {
      'birth_name': birthName,
      'system': system,
      if (currentName != null && currentName.isNotEmpty) 'current_name': currentName,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dob': dateOfBirth,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/name-analysis');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        try {
          final errData = jsonDecode(res.body) as Map<String, dynamic>;
          if (errData.containsKey('message')) {
            throw Exception(errData['message']);
          }
        } on Exception catch (e) {
          if (!e.toString().contains('FormatException')) {
            rethrow;
          }
        }
      }
    } on Exception catch (e) {
      if (!e.toString().contains('Connection refused') &&
          !e.toString().contains('SocketException') &&
          !e.toString().contains('TimeoutException') &&
          !e.toString().contains('ClientException')) {
        rethrow;
      }
      debugPrint('NameAnalysis request failed for $baseUrl: $e');
    }

    throw Exception('Failed to connect to backend server for Name Analysis. Ensure server is active on port 5000.');
  }

  // =========================================================================
  // 4.9 PERSONALITY & SOUL URGE NUMEROLOGY
  // =========================================================================
  static Future<Map<String, dynamic>> getPersonalitySoulReport({
    required String birthName,
    String yPolicy = 'always_consonant',
  }) async {
    final bodyData = {
      'birth_name': birthName,
      'y_policy': yPolicy,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/personality-soul');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        try {
          final errData = jsonDecode(res.body) as Map<String, dynamic>;
          if (errData.containsKey('message')) {
            throw Exception(errData['message']);
          }
        } on Exception catch (e) {
          if (!e.toString().contains('FormatException')) {
            rethrow;
          }
        }
      }
    } on Exception catch (e) {
      if (!e.toString().contains('Connection refused') &&
          !e.toString().contains('SocketException') &&
          !e.toString().contains('TimeoutException') &&
          !e.toString().contains('ClientException')) {
        rethrow;
      }
      debugPrint('PersonalitySoul request failed for $baseUrl: $e');
    }

    throw Exception('Failed to connect to backend server for Personality & Soul calculation. Ensure server is active on port 5000.');
  }

  // =========================================================================
  // 4.10 MISSING NUMBERS / KARMIC LESSONS NUMEROLOGY
  // =========================================================================
  static Future<Map<String, dynamic>> getMissingNumbersReport({
    required String birthName,
  }) async {
    final bodyData = {
      'birth_name': birthName,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/missing-numbers');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        try {
          final errData = jsonDecode(res.body) as Map<String, dynamic>;
          if (errData.containsKey('message')) {
            throw Exception(errData['message']);
          }
        } on Exception catch (e) {
          if (!e.toString().contains('FormatException')) {
            rethrow;
          }
        }
      }
    } on Exception catch (e) {
      if (!e.toString().contains('Connection refused') &&
          !e.toString().contains('SocketException') &&
          !e.toString().contains('TimeoutException') &&
          !e.toString().contains('ClientException')) {
        rethrow;
      }
      debugPrint('MissingNumbers request failed for $baseUrl: $e');
    }

    throw Exception('Failed to connect to backend server for Missing Numbers calculation. Ensure server is active on port 5000.');
  }

  // =========================================================================
  // REMEDIES & FIXES NUMEROLOGY (RULE ENGINE & DATABASE-DRIVEN GUIDANCE)
  // =========================================================================
  static Future<Map<String, dynamic>> getNumerologyRemedies({
    required String dateOfBirth,
    String? birthName,
    String system = 'pythagorean',
    String category = 'all',
    String focusArea = 'all',
    int? targetYear,
  }) async {
    final bodyData = <String, dynamic>{
      'dob': dateOfBirth,
      'system': system,
      'category': category,
      'focus_area': focusArea,
    };
    if (birthName != null && birthName.trim().isNotEmpty) {
      bodyData['birth_name'] = birthName.trim();
    }
    if (targetYear != null) {
      bodyData['year'] = targetYear;
    }

    try {
      final uri = Uri.parse('$baseUrl/numerology/remedies');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        try {
          final errData = jsonDecode(res.body) as Map<String, dynamic>;
          if (errData.containsKey('message')) {
            throw Exception(errData['message']);
          }
        } on Exception catch (e) {
          if (!e.toString().contains('FormatException')) {
            rethrow;
          }
        }
      }
    } on Exception catch (e) {
      if (!e.toString().contains('Connection refused') &&
          !e.toString().contains('SocketException') &&
          !e.toString().contains('TimeoutException') &&
          !e.toString().contains('ClientException')) {
        rethrow;
      }
      debugPrint('Remedies request failed for $baseUrl: $e');
    }

    throw Exception('Failed to connect to backend server for Remedies & Fixes. Ensure backend is running on port 5000.');
  }

  // =========================================================================
  // CRYSTAL MATCH NUMEROLOGY MODULE (DETERMINISTIC & DATABASE-DRIVEN)
  // =========================================================================
  static Future<Map<String, dynamic>> getCrystalMatchReport({
    required String dateOfBirth,
    String? birthName,
    String system = 'pythagorean',
    String intention = 'all',
  }) async {
    final bodyData = <String, dynamic>{
      'dob': dateOfBirth,
      'system': system,
      'intention': intention,
    };
    if (birthName != null && birthName.trim().isNotEmpty) {
      bodyData['birth_name'] = birthName.trim();
    }

    try {
      final uri = Uri.parse('$baseUrl/numerology/crystal-match');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        final errData = jsonDecode(res.body) as Map<String, dynamic>;
        if (errData.containsKey('message')) {
          throw Exception(errData['message']);
        }
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend crystal-match error: $e');
      rethrow;
    }
  }

  /// Fetches complete published crystal catalog directly from backend SQLite database.
  static Future<List<Map<String, dynamic>>> getCrystalCatalog() async {
    try {
      final uri = Uri.parse('$baseUrl/numerology/crystal-catalog');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['catalog'] is List) {
          return List<Map<String, dynamic>>.from(data['catalog']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching crystal catalog from backend: $e');
    }
    return [];
  }

  /// Fetches all intention filters dynamically from backend SQLite database.
  static Future<List<Map<String, dynamic>>> getCrystalIntentions() async {
    try {
      final uri = Uri.parse('$baseUrl/numerology/crystal-intentions');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['intentions'] is List) {
          return List<Map<String, dynamic>>.from(data['intentions']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching crystal intentions from backend: $e');
    }
    return [];
  }

  // =========================================================================
  // PHONE NUMBER / MOBILE NUMEROLOGY MODULE
  // =========================================================================
  static Future<Map<String, dynamic>> analyzePhoneNumber({
    required String phoneNumber,
    String countryCode = 'IN',
    String? dob,
    String system = 'pythagorean',
  }) async {
    final bodyData = <String, dynamic>{
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'system': system,
    };
    if (dob != null && dob.trim().isNotEmpty) {
      bodyData['dob'] = dob.trim();
    }

    try {
      final uri = Uri.parse('$baseUrl/numerology/phone-analysis');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        final errData = jsonDecode(res.body) as Map<String, dynamic>;
        if (errData.containsKey('message')) {
          throw Exception(errData['message']);
        }
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend phone-analysis error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // CHILD NUMEROLOGY & BABY NAME MODULE
  // =========================================================================
  static Future<Map<String, dynamic>> analyzeChildNumerology({
    required String childName,
    required String dob,
    String system = 'pythagorean',
    String? parentName,
    String? parentDob,
  }) async {
    final bodyData = <String, dynamic>{
      'child_name': childName,
      'dob': dob,
      'system': system,
    };
    if (parentName != null && parentName.trim().isNotEmpty) {
      bodyData['parent_name'] = parentName.trim();
    }
    if (parentDob != null && parentDob.trim().isNotEmpty) {
      bodyData['parent_dob'] = parentDob.trim();
    }

    try {
      final uri = Uri.parse('$baseUrl/numerology/child-analysis');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        final errData = jsonDecode(res.body) as Map<String, dynamic>;
        if (errData.containsKey('message')) {
          throw Exception(errData['message']);
        }
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend child-analysis error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> compareChildCandidateNames({
    required List<String> candidateNames,
    required String dob,
    String system = 'pythagorean',
  }) async {
    final bodyData = <String, dynamic>{
      'candidate_names': candidateNames,
      'dob': dob,
      'system': system,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/child-name-comparison');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        final errData = jsonDecode(res.body) as Map<String, dynamic>;
        if (errData.containsKey('message')) {
          throw Exception(errData['message']);
        }
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend child-name-comparison error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // ADVANCED NUMEROLOGY COMPATIBILITY MODULE
  // =========================================================================
  static Future<Map<String, dynamic>> calculateAdvancedCompatibility({
    required String personAName,
    required String personBName,
    String? personADob,
    String? personBDob,
    String relationshipType = 'romantic',
    String system = 'pythagorean',
  }) async {
    final bodyData = <String, dynamic>{
      'person_a_name': personAName.trim(),
      'person_b_name': personBName.trim(),
      'relationship_type': relationshipType.trim().toLowerCase(),
      'system': system.trim().toLowerCase(),
    };
    if (personADob != null && personADob.trim().isNotEmpty) {
      bodyData['person_a_dob'] = personADob.trim();
    }
    if (personBDob != null && personBDob.trim().isNotEmpty) {
      bodyData['person_b_dob'] = personBDob.trim();
    }

    try {
      final uri = Uri.parse('$baseUrl/numerology/advanced-compatibility');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        }
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        final errData = jsonDecode(res.body) as Map<String, dynamic>;
        if (errData.containsKey('message')) {
          throw Exception(errData['message']);
        }
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend advanced-compatibility error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveCompatibilityReport({
    String? userId,
    required String relationshipType,
    required String system,
    required String personALabel,
    required String personBLabel,
    required Map<String, dynamic> calculatedData,
  }) async {
    final bodyData = <String, dynamic>{
      'user_id': userId ?? 'guest',
      'relationship_type': relationshipType,
      'system': system,
      'person_a_label': personALabel,
      'person_b_label': personBLabel,
      'calculated_data': calculatedData,
    };

    try {
      final uri = Uri.parse('$baseUrl/numerology/compatibility/save-report');
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('Server returned status code: ${res.statusCode}');
    } catch (e) {
      debugPrint('Backend save-report error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLalKitab({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/lal-kitab');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Lal Kitab: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getLalKitab: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getBnn({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
    String? targetDateStr,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/bnn');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (targetDateStr != null) bodyMap['target_date_str'] = targetDateStr;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load BNN: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getBnn: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getDailyHoroscope(String rashi) async {
    try {
      final uri = Uri.parse('$baseUrl/horoscope/daily').replace(queryParameters: {'rashi': rashi});
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception(data['message'] ?? 'Failed to fetch daily horoscope');
      } else {
        throw Exception('Failed to fetch daily horoscope: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getDailyHoroscope: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCueCards() async {
    final uri = Uri.parse('$baseUrl/horoscope/cue_cards');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Cue Cards: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getCueCards: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getJaimini({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/jaimini');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Jaimini: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getJaimini: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getJaiminiSubDasha({
    required String parentSign,
    required String startDate,
    required String endDate,
    required String targetLevel,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/jaimini-sub-dasha');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'parent_sign': parentSign,
          'start_date': startDate,
          'end_date': endDate,
          'target_level': targetLevel,
        }),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['sub_dashas'] as List<dynamic>?) ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('API Error getJaiminiSubDasha: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getKotaChakra({
    String name = 'User',
    String dateOfBirth = '1998-12-13',
    String timeOfBirth = '09:30',
    String placeOfBirth = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
    String? transitDate,
    String? transitTime,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/kota-chakra');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (transitDate != null) bodyMap['transit_date'] = transitDate;
    if (transitTime != null) bodyMap['transit_time'] = transitTime;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Kota Chakra: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getKotaChakra: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPrashnaChart({
    required String questionDate,
    required String questionTime,
    String placeOfQuestion = 'Delhi, India',
    double? latitude,
    double? longitude,
    double? timezone,
    double? daysInYear,
  String? ayanamsa,
    double? customAyanamsa,
  }) async {
    final uri = Uri.parse('$baseUrl/prashna/chart');
    final Map<String, dynamic> bodyMap = {
      'question_date': questionDate,
      'question_time': questionTime,
      'place': placeOfQuestion,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (customAyanamsa != null) bodyMap['custom_ayanamsa'] = customAyanamsa;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (daysInYear != null) bodyMap['days_in_year'] = daysInYear;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Prashna Chart: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getPrashnaChart: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getHoraryChart({
    required String question,
    required String questionDate,
    required String questionTime,
    double? latitude,
    double? longitude,
    double? timezone,
    String? ayanamsa,
    int? horaryNumber,
    String? horaryMode,
  }) async {
    final uri = Uri.parse('$baseUrl/horary/chart');
    final Map<String, dynamic> bodyMap = {
      'question': question,
      'date': questionDate,
      'time': questionTime,
    };
    if (latitude != null) bodyMap['latitude'] = latitude;
    if (longitude != null) bodyMap['longitude'] = longitude;
    if (timezone != null) bodyMap['timezone'] = timezone;
    if (ayanamsa != null) bodyMap['ayanamsa'] = ayanamsa;
    if (horaryNumber != null) bodyMap['horary_number'] = horaryNumber;
    if (horaryMode != null) bodyMap['horary_mode'] = horaryMode;

    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(bodyMap)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Horary Chart: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getHoraryChart: $e');
      rethrow;
    }
  }

  static Future<int> getHoraryRandomNumber({String? mode}) async {
    final query = mode != null ? '?mode=$mode' : '';
    final uri = Uri.parse('$baseUrl/horary/generate_number$query');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data']['kp_number'] as int;
      } else {
        throw Exception('Failed to generate KP Number');
      }
    } catch (e) {
      debugPrint('API Error getHoraryRandomNumber: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getHoraryQuestions() async {
    final uri = Uri.parse('$baseUrl/horary/questions');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to load Horary Questions: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error getHoraryQuestions: $e');
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
      final res = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 45));
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
  // 5. AI VISION (FACE READING)
  // =========================================================================
  


  static Future<Map<String, dynamic>> readFace(String filePath) async {
    final uri = Uri.parse('$baseUrl/ai-vision/face-reading');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamedResponse);
      
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

  static Future<Map<String, dynamic>> getMuhurat({double lat = 28.6139, double lon = 77.209, double tz = 5.5, String? dateStr}) async {
    String url = '$baseUrl/content/muhurat?latitude=$lat&longitude=$lon&timezone=$tz';
    if (dateStr != null && dateStr.isNotEmpty) {
      url += '&date=$dateStr';
    }
    final uri = Uri.parse(url);
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

  static Future<List<String>> getMuhuratMonth(int year, int month, {double lat = 28.6139, double lon = 77.209, double tz = 5.5}) async {
    final uri = Uri.parse('$baseUrl/content/muhurat/month?year=$year&month=$month&latitude=$lat&longitude=$lon&timezone=$tz');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['auspicious_dates'] as List<dynamic>?;
        if (list != null) {
          return list.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error getMuhuratMonth: $e');
    }
    return [];
  }

  // =========================================================================
  // 7. ADMIN PANEL
  // =========================================================================

  static Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    final uri = Uri.parse('$baseUrl/admin/login');
    final body = jsonEncode({
      'username': username,
      'password': password,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 401) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to authenticate admin: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error adminLogin: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendNotification(String title, String message) async {
    final uri = Uri.parse('$baseUrl/admin/notifications/send');
    final body = jsonEncode({
      'title': title,
      'message': message,
    });

    try {
      final res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 400) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send notification: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error sendNotification: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

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
  // 9. PLACES GEOCODING
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
    } catch (_) {
      // Ignore network errors and fallback to popular places
    }
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
        'lat_val': lat,
        'lon_val': lon,
        'tz_val': tz.toString(),
        'isDefault': 'false',
      };
    }).toList();
  }

  // =========================================================================
  // 10. ANGEL NUMBERS MODULE API
  // =========================================================================

  static Future<Map<String, dynamic>> lookupAngelNumber(String sequence) async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/lookup');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'sequence': sequence}),
      ).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to lookup angel number');
      }
    } catch (e) {
      debugPrint('API Error lookupAngelNumber: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> calculatePersonalAngelNumber({
    required String method,
    String? dob,
    String? name,
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/personal-number');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'method': method,
          if (dob != null) 'dob': dob,
          if (name != null) 'name': name,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to calculate personal angel number');
      }
    } catch (e) {
      debugPrint('API Error calculatePersonalAngelNumber: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAngelNumberPatterns() async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/patterns');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        final list = data['data'] as List<dynamic>?;
        return list?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('API Error getAngelNumberPatterns: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPopularAngelNumbers() async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/popular');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        final list = data['data'] as List<dynamic>?;
        return list?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('API Error getPopularAngelNumbers: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMirrorHours() async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/mirror-hours');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        final list = data['data'] as List<dynamic>?;
        return list?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('API Error getMirrorHours: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDailyAngelReflection({String? date, String? timezone}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (timezone != null) queryParams['timezone'] = timezone;
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/daily').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('API Error getDailyAngelReflection: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getAngelSightings({String? userId, String? search}) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/journal').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to get angel sightings');
      }
    } catch (e) {
      debugPrint('API Error getAngelSightings: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addAngelSighting({
    required String observedSequence,
    String? userId,
    String? observedAt,
    String? timezone,
    String? contextCategory,
    String? personalNote,
    String? mood,
  }) async {
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/journal');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'observed_sequence': observedSequence,
          if (userId != null) 'user_id': userId,
          if (observedAt != null) 'observed_at': observedAt,
          if (timezone != null) 'timezone': timezone,
          if (contextCategory != null) 'context_category': contextCategory,
          if (personalNote != null) 'personal_note': personalNote,
          if (mood != null) 'mood': mood,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to record sighting');
      }
    } catch (e) {
      debugPrint('API Error addAngelSighting: $e');
      rethrow;
    }
  }

  static Future<bool> deleteAngelSighting(int sightingId, {String? userId}) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId;
    final uri = Uri.parse('$baseUrl/numerology/angel-numbers/journal/$sightingId').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final res = await http.delete(uri, headers: _headers).timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API Error deleteAngelSighting: $e');
      return false;
    }
  }

  // =========================================================================
  // MATCH MAKING (VEDIC KUNDLI MILAN & PORUTHAM)
  // =========================================================================

  static Future<Map<String, dynamic>> calculateMatchMaking({
    required Map<String, dynamic> boy,
    required Map<String, dynamic> girl,
    String tradition = 'both',
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/match-making');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'boy': boy,
          'girl': girl,
          'tradition': tradition,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to calculate match making');
      }
    } catch (e) {
      debugPrint('API Error calculateMatchMaking: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getMatchMakingMethods() async {
    final uri = Uri.parse('$baseUrl/horoscope/match-making/methods');
    try {
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['status'] == 'success') {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get match making methods');
      }
    } catch (e) {
      debugPrint('API Error getMatchMakingMethods: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveMatchMakingReport({
    required Map<String, dynamic> reportData,
    String? userId,
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/match-making/save-report');
    try {
      final res = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'report_data': reportData,
          if (userId != null) 'user_id': userId,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && data['status'] == 'success') {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to save report');
      }
    } catch (e) {
      debugPrint('API Error saveMatchMakingReport: $e');
      rethrow;
    }
  }

  // =========================================================================
  // LOCAL FALLBACK DATA
  // =========================================================================



  static final List<Map<String, dynamic>> _popularPlacesFallback = [
    {'name': 'New Delhi', 'state': 'Delhi', 'country': 'India', 'latitude': 28.6139, 'longitude': 77.2090, 'timezone': 5.5, 'formatted_name': 'New Delhi, Delhi, India'},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'country': 'India', 'latitude': 19.0760, 'longitude': 72.8777, 'timezone': 5.5, 'formatted_name': 'Mumbai, Maharashtra, India'},
  ];
}
