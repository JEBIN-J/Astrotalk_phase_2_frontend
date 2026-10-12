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
      return 'http://10.242.54.136:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.242.54.136:5000/api/v1'; // Connects to local Flask backend from Android Emulator or USB Reverse Port
      }
    } catch (_) {}  
    return 'http://10.242.54.136:5000/api/v1';
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
  }) async {
    final uri = Uri.parse('$baseUrl/horoscope/kp');
    final Map<String, dynamic> bodyMap = {
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      'ayanamsa': ayanamsa,
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

  static Future<Map<String, dynamic>> getLifePathReport({
    required String dateOfBirth,
    String? name,
    String system = 'pythagorean',
  }) async {
    final candidateHosts = [
      baseUrl,
      'http://10.0.2.2:5000/api/v1',
      'http://127.0.0.1:5000/api/v1',
      'http://10.242.54.136:5000/api/v1',
    ];

    for (final host in candidateHosts) {
      try {
        final queryParams = {
          'dob': dateOfBirth,
          'system': system,
          if (name != null && name.isNotEmpty) 'name': name,
        };
        final uri = Uri.parse('$host/numerology/life-path').replace(queryParameters: queryParams);
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['status'] == 'success') {
            return data;
          }
        }
      } catch (e) {
        debugPrint('LifePath host attempt failed for $host: $e');
      }
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
    final candidateHosts = [
      baseUrl,
      'http://10.0.2.2:5000/api/v1',
      'http://127.0.0.1:5000/api/v1',
      'http://10.242.54.136:5000/api/v1',
    ];

    for (final host in candidateHosts) {
      try {
        final queryParams = {
          'dob': dateOfBirth,
          'system': system,
          if (name != null && name.isNotEmpty) 'name': name,
        };
        final uri = Uri.parse('$host/numerology/birth-day').replace(queryParameters: queryParams);
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['status'] == 'success') {
            return data;
          }
        }
      } catch (e) {
        debugPrint('BirthDay host attempt failed for $host: $e');
      }
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

  
  static Future<int> getHoraryRandomNumber() async {
    final uri = Uri.parse('$baseUrl/horary/generate_number');
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
  // LOCAL FALLBACK DATA
  // =========================================================================



  static final List<Map<String, dynamic>> _popularPlacesFallback = [
    {'name': 'New Delhi', 'state': 'Delhi', 'country': 'India', 'latitude': 28.6139, 'longitude': 77.2090, 'timezone': 5.5, 'formatted_name': 'New Delhi, Delhi, India'},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'country': 'India', 'latitude': 19.0760, 'longitude': 72.8777, 'timezone': 5.5, 'formatted_name': 'Mumbai, Maharashtra, India'},
  ];
}
