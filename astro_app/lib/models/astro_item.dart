import 'package:flutter/material.dart';

enum AstroCategory {
  all,
  vedicKundli,
  aiTools,
  utilities,
}

extension AstroCategoryExtension on AstroCategory {
  String get title {
    switch (this) {
      case AstroCategory.all:
        return 'All Modules';
      case AstroCategory.vedicKundli:
        return 'Kundli & Vedic';
      case AstroCategory.aiTools:
        return 'AI Astrologer';
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
      case AstroCategory.aiTools:
        return Icons.psychology_rounded;
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
      title: 'Kundli',
      subtitle: 'Vedic, KP, Lal Kitab & BNN Charts',
      iconKey: 'horoscope',
      category: AstroCategory.vedicKundli,
      primaryColor: Color(0xFF4338CA),
      secondaryColor: Color(0xFF6366F1),
      badge: 'Popular',
    ),
    const AstroItem(
      id: 'daily_horoscope',
      title: 'Horoscope',
      subtitle: 'Daily Sun Sign Predictions',
      iconKey: 'horoscope_daily', // Doesn't matter if there's no exact asset, we use icons anyway in the dashboard but wait, dashboard uses svg assets!
      category: AstroCategory.vedicKundli,
      primaryColor: Color(0xFF0EA5E9),
      secondaryColor: Color(0xFF38BDF8),
    ),
    const AstroItem(
      id: 'muhurat',
      title: 'Muhurat',
      subtitle: 'Auspicious Timings & Daily Panchang',
      iconKey: 'panchanga',
      category: AstroCategory.vedicKundli,
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFF59E0B),
      badge: 'Today',
    ),
    const AstroItem(
      id: 'ai_calling',
      title: 'AI Calling',
      subtitle: 'Voice Call with Vedic AI Astrologer',
      iconKey: 'ai_calling',
      category: AstroCategory.aiTools,
      primaryColor: Color(0xFFE11D48),
      secondaryColor: Color(0xFFFB7185),
      badge: 'New',
    ),
    const AstroItem(
      id: 'chat_bot',
      title: 'Chat Bot',
      subtitle: 'Instant AI Astrology Consultation',
      iconKey: 'chat_bot',
      category: AstroCategory.aiTools,
      primaryColor: Color(0xFF0D9488),
      secondaryColor: Color(0xFF2DD4BF),
    ),
    const AstroItem(
      id: 'palm_reading',
      title: 'Palm Reading',
      subtitle: 'AI Vision Palmistry Analysis',
      iconKey: 'palm_reading',
      category: AstroCategory.aiTools,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFA78BFA),
      badge: 'AI',
    ),
    const AstroItem(
      id: 'face_reading',
      title: 'Face Reading',
      subtitle: 'AI Vision Facial Feature Astrology',
      iconKey: 'face_reading',
      category: AstroCategory.aiTools,
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF60A5FA),
      badge: 'AI',
    ),
    const AstroItem(
      id: 'daily_quotes',
      title: 'Daily Quotes',
      subtitle: 'Motivation & Cosmic Wisdom',
      iconKey: 'quotes',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF34D399),
    ),
    const AstroItem(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Alerts & Planetary Transits',
      iconKey: 'notifications',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFFEA580C),
      secondaryColor: Color(0xFFFB923C),
    ),
    const AstroItem(
      id: 'admin_panel',
      title: 'Admin Panel',
      subtitle: 'Manage Users & Subscriptions',
      iconKey: 'admin',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF475569),
      secondaryColor: Color(0xFF94A3B8),
    ),
    const AstroItem(
      id: 'subscribe',
      title: 'Subscribe',
      subtitle: 'Unlock Unlimited AI & Premium Charts',
      iconKey: 'subscribe',
      category: AstroCategory.utilities,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFC084FC),
      isPro: true,
      badge: 'PRO',
    ),
  ];
}
