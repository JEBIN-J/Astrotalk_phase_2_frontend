import 'package:flutter/material.dart';

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
