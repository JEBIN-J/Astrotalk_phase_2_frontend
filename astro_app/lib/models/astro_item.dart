import 'package:flutter/material.dart';

enum AstroCategory {
  all,
  vedicKundli,
  panchangaTransits,
  calculators,
  utilities,
}

extension AstroCategoryExtension on AstroCategory {
  String get title {
    switch (this) {
      case AstroCategory.all:
        return 'All Modules';
      case AstroCategory.vedicKundli:
        return 'Kundli & Vedic';
      case AstroCategory.panchangaTransits:
        return 'Panchang & Gochara';
      case AstroCategory.calculators:
        return 'Calculators';
      case AstroCategory.utilities:
        return 'Tools & Info';
    }
  }

  IconData get icon {
    switch (this) {
      case AstroCategory.all:
        return Icons.auto_awesome;
      case AstroCategory.vedicKundli:
        return Icons.grid_view_rounded;
      case AstroCategory.panchangaTransits:
        return Icons.wb_sunny_rounded;
      case AstroCategory.calculators:
        return Icons.calculate_rounded;
      case AstroCategory.utilities:
        return Icons.settings_suggest_rounded;
    }
  }
}

class AstroItem {
  final String id;
  final String title;
  final String subtitle;
  final String iconKey;
  final AstroCategory category;
  final Color primaryColor;
  final Color secondaryColor;
  final String? badge;
  final bool isPro;

  const AstroItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    this.badge,
    this.isPro = false,
  });

  static List<AstroItem> get items => [
    const AstroItem(
      id: 'horoscope',
      title: 'Horoscope',
      subtitle: 'Birth Chart (Kundli) & Planetary Positions',
      iconKey: 'horoscope',
      category: AstroCategory.vedicKundli,
      primaryColor: Color(0xFF4338CA),
      secondaryColor: Color(0xFF6366F1),
      badge: 'Popular',
    ),
    const AstroItem(
      id: 'panchanga_muhurta',
      title: 'Panchanga &\nMuhurta',
      subtitle: 'Tithi, Nakshatra, Yoga, Karana & Shubh Muhurta',
      iconKey: 'panchanga',
      category: AstroCategory.panchangaTransits,
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFF59E0B),
      badge: 'Today',
    ),
    const AstroItem(
      id: 'gochara',
      title: 'Gochara',
      subtitle: 'Real-time Daily Planetary Transits',
      iconKey: 'gochara',
      category: AstroCategory.panchangaTransits,
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFF38BDF8),
    ),
    const AstroItem(
      id: 'matching',
      title: 'Horoscope\nMatching',
      subtitle: '36 Guna Ashtakoota Milan & Manglik Dosh',
      iconKey: 'matching',
      category: AstroCategory.vedicKundli,
      primaryColor: Color(0xFFE11D48),
      secondaryColor: Color(0xFFFB7185),
      badge: '36 Guna',
    ),
    const AstroItem(
      id: 'calendar_panchanga',
      title: 'Panchanga\n(Month)',
      subtitle: 'Monthly Hindu Lunar Calendar & Vrats',
      iconKey: 'calendar_panchanga',
      category: AstroCategory.panchangaTransits,
      primaryColor: Color(0xFF0D9488),
      secondaryColor: Color(0xFF2DD4BF),
    ),
    const AstroItem(
      id: 'ephemeris',
      title: 'Ephemeris',
      subtitle: 'Precise Astronomical Planetary Longitudes',
      iconKey: 'ephemeris',
      category: AstroCategory.calculators,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFA78BFA),
    ),
    const AstroItem(
      id: 'gochara_year',
      title: 'Gochara\n(Year)',
      subtitle: 'Yearly Planetary Transits & Retrogrades',
      iconKey: 'gochara_year',
      category: AstroCategory.panchangaTransits,
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF60A5FA),
    ),
    const AstroItem(
      id: 'ayanamsa',
      title: 'Ayanamsa\nCalculator',
      subtitle: 'Lahiri, KP, Raman, Krishnamurti offsets',
      iconKey: 'ayanamsa',
      category: AstroCategory.calculators,
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF34D399),
    ),
    const AstroItem(
      id: 'widget',
      title: 'Widget',
      subtitle: 'Android Home Screen Astrology Widgets',
      iconKey: 'widget',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF4F46E5),
      secondaryColor: Color(0xFF818CF8),
    ),
    const AstroItem(
      id: 'settings',
      title: 'Settings',
      subtitle: 'North/South Chart, Language, Dark Mode',
      iconKey: 'settings',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF475569),
      secondaryColor: Color(0xFF94A3B8),
    ),
    const AstroItem(
      id: 'places',
      title: 'Add Places',
      subtitle: 'Manage custom cities & coordinates database',
      iconKey: 'places',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFFEA580C),
      secondaryColor: Color(0xFFFB923C),
    ),
    const AstroItem(
      id: 'about',
      title: 'About',
      subtitle: 'Vedic Algorithm, Calculations & Version Info',
      iconKey: 'about',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFF38BDF8),
    ),
    const AstroItem(
      id: 'rate',
      title: 'Rate App',
      subtitle: 'Leave a 5-star rating on Google Play Store',
      iconKey: 'rate',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFFCA8A04),
      secondaryColor: Color(0xFFFACC15),
    ),
    const AstroItem(
      id: 'share',
      title: 'Share App',
      subtitle: 'Share ABC App with friends & family',
      iconKey: 'share',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF0D9488),
      secondaryColor: Color(0xFF2DD4BF),
    ),
    const AstroItem(
      id: 'subscribe',
      title: 'Subscribe',
      subtitle: 'Unlock Unlimited Kundli PDFs & Premium Charts',
      iconKey: 'subscribe',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFC084FC),
      isPro: true,
      badge: 'PRO',
    ),
  ];
}
