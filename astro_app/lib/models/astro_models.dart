import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual Dashboard Layout Styles / Models
enum DashboardStyle {
  bentoModern,      // Modern Astrotalk Bento Grid (Hero cards + quick tiles)
  glassmorphicGrid, // Celestial 3-Column Glassmorphic Cards
  classicVedicTiles,// Clean White/Dark 3-Column Vedic Icon Grid
  sacredGoldMandala,// Spiritual Saffron & Gold Temple Motif Cards
  categorizedList,  // Full-width Categorized Cards with Subtext
}

extension DashboardStyleExtension on DashboardStyle {
  String get title {
    switch (this) {
      case DashboardStyle.bentoModern:
        return 'Astrotalk Bento';
      case DashboardStyle.glassmorphicGrid:
        return 'Cosmic Glass';
      case DashboardStyle.classicVedicTiles:
        return '3-Column Tiles';
      case DashboardStyle.sacredGoldMandala:
        return 'Sacred Temple';
      case DashboardStyle.categorizedList:
        return 'Detailed List';
    }
  }

  String get description {
    switch (this) {
      case DashboardStyle.bentoModern:
        return 'Dynamic bento grid with featured hero modules';
      case DashboardStyle.glassmorphicGrid:
        return 'Neon glowing glass tiles with celestial aura';
      case DashboardStyle.classicVedicTiles:
        return 'Classic 3-column elevated cards (Screenshot evolution)';
      case DashboardStyle.sacredGoldMandala:
        return 'Ornate saffron & gold Vedic temple aesthetics';
      case DashboardStyle.categorizedList:
        return 'Comprehensive list with full details & badges';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardStyle.bentoModern:
        return Icons.dashboard_rounded;
      case DashboardStyle.glassmorphicGrid:
        return Icons.auto_awesome_rounded;
      case DashboardStyle.classicVedicTiles:
        return Icons.grid_view_rounded;
      case DashboardStyle.sacredGoldMandala:
        return Icons.brightness_7_rounded;
      case DashboardStyle.categorizedList:
        return Icons.view_agenda_rounded;
    }
  }
}

/// Astrological Chart Format / Presentation Models
enum KundliChartStyle {
  northIndian, // Diamond Chart (House fixed, Signs rotate)
  southIndian, // Square Box Chart (Signs fixed, Houses rotate)
  eastIndian,  // Bengali Sun Chart (Diagonal diamond boxes)
}

extension KundliChartStyleExtension on KundliChartStyle {
  String get title {
    switch (this) {
      case KundliChartStyle.northIndian:
        return 'North Indian';
      case KundliChartStyle.southIndian:
        return 'South Indian';
      case KundliChartStyle.eastIndian:
        return 'East Indian';
    }
  }
}

/// Quick Daily Insight Card Model
class DailyAstroInsight {
  final String title;
  final String description;
  final String timing;
  final IconData icon;
  final Color color;

  const DailyAstroInsight({
    required this.title,
    required this.description,
    required this.timing,
    required this.icon,
    required this.color,
  });

  static List<DailyAstroInsight> get sampleInsights => [
    const DailyAstroInsight(
      title: 'Abhijit Muhurta Active',
      description: 'Highly auspicious period for new beginnings, contracts & travels.',
      timing: '11:58 AM - 12:49 PM',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFD97706),
    ),
    const DailyAstroInsight(
      title: 'Moon in Exalted Rohini',
      description: 'Promotes clarity of mind, financial planning, and creativity.',
      timing: 'All Day Today',
      icon: Icons.brightness_2_rounded,
      color: Color(0xFF6366F1),
    ),
    const DailyAstroInsight(
      title: 'Jupiter Trine Sun (Guru Drishti)',
      description: 'Spiritual blessings and wisdom in decision making today.',
      timing: 'Transit Influences',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF0D9488),
    ),
  ];
}

/// Singleton to hold the globally shared birth profile details across all sections
class GlobalBirthProfile {
  static final GlobalBirthProfile _instance = GlobalBirthProfile._internal();
  factory GlobalBirthProfile() => _instance;

  String personName = 'User';
  late String dob;
  late String tob;
  String pob = 'New Delhi, Delhi, India';
  double latitude = 28.6139;
  double longitude = 77.2090;
  double timezone = 5.5;
  late DateTime currentDateTime;
  bool isProfileSet = false;

  String selectedAyanamsa = 'LAHIRI';
  double? customAyanamsa;

  GlobalBirthProfile._internal() {
    final now = DateTime.now();
    currentDateTime = now;
    dob = DateFormat('dd MMM yyyy').format(now);
    tob = DateFormat('hh:mm a').format(now);
  }

  Future<void> updateProfile({
    required String name,
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    required double lat,
    required double lon,
    required double tz,
    required DateTime dateTime,
  }) async {
    personName = name;
    dob = dateOfBirth;
    tob = timeOfBirth;
    pob = placeOfBirth;
    latitude = lat;
    longitude = lon;
    timezone = tz;
    currentDateTime = dateTime;
    isProfileSet = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('global_person_name', name);
      await prefs.setString('global_dob', dateOfBirth);
      await prefs.setString('global_tob', timeOfBirth);
      await prefs.setString('global_pob', placeOfBirth);
      await prefs.setDouble('global_lat', lat);
      await prefs.setDouble('global_lon', lon);
      await prefs.setDouble('global_tz', tz);
      await prefs.setString('global_dt', dateTime.toIso8601String());
      await prefs.setBool('global_is_profile_set', true);
    } catch (_) {}
  }

  Future<void> loadSavedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasProfile = prefs.getBool('global_is_profile_set') ?? false;
      if (hasProfile) {
        final savedName = prefs.getString('global_person_name') ?? '';
        final savedPob = prefs.getString('global_pob') ?? '';
        personName = savedName.isNotEmpty ? savedName : 'User';
        dob = prefs.getString('global_dob') ?? DateFormat('dd MMM yyyy').format(DateTime.now());
        tob = prefs.getString('global_tob') ?? DateFormat('hh:mm a').format(DateTime.now());
        pob = savedPob.isNotEmpty ? savedPob : 'New Delhi, Delhi, India';
        latitude = prefs.getDouble('global_lat') ?? 28.6139;
        longitude = prefs.getDouble('global_lon') ?? 77.2090;
        timezone = prefs.getDouble('global_tz') ?? 5.5;
        final dtStr = prefs.getString('global_dt');
        if (dtStr != null) {
          currentDateTime = DateTime.tryParse(dtStr) ?? DateTime.now();
        }
        isProfileSet = true;
      }
    } catch (_) {}
  }

  Future<void> updateAyanamsa(String ayanamsa, [double? custom]) async {
    selectedAyanamsa = ayanamsa;
    customAyanamsa = custom;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('global_selected_ayanamsa', ayanamsa);
      if (custom != null) {
        await prefs.setDouble('global_custom_ayanamsa', custom);
      } else {
        await prefs.remove('global_custom_ayanamsa');
      }
    } catch (_) {}
  }

  Future<void> loadSavedAyanamsa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('global_selected_ayanamsa');
      if (saved != null && saved.isNotEmpty) {
        selectedAyanamsa = saved;
      }
      if (prefs.containsKey('global_custom_ayanamsa')) {
        customAyanamsa = prefs.getDouble('global_custom_ayanamsa');
      }
    } catch (_) {}
  }
}
