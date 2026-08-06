import 'package:flutter/material.dart';
import '../models/astro_item.dart';
import '../models/astro_models.dart';
import 'horoscope_screen.dart';
import 'panchanga_screen.dart';
import 'matching_screen.dart';
import 'gochara_screen.dart';
import 'calendar_screen.dart';
import 'ephemeris_screen.dart';
import 'ayanamsa_screen.dart';
import 'widget_settings_screen.dart';
import 'settings_screen.dart';
import 'places_screen.dart';
import 'subscribe_screen.dart';
import 'about_screen.dart';
import 'rate_screen.dart';
import 'share_screen.dart';

class AstroFeatureDialogs {
  /// Navigates to the dedicated full-screen Page with specialized functionality
  static void openFeature(
    BuildContext context,
    AstroItem item, {
    KundliChartStyle defaultChartStyle = KundliChartStyle.northIndian,
    VoidCallback? onToggleTheme,
    bool isDark = false,
  }) {
    Widget targetScreen;

    switch (item.id) {
      case 'horoscope':
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle);
        break;
      case 'panchanga_muhurta':
        targetScreen = const PanchangaScreen();
        break;
      case 'matching':
        targetScreen = const MatchingScreen();
        break;
      case 'gochara':
        targetScreen = const GocharaScreen(isYearly: false);
        break;
      case 'gochara_year':
        targetScreen = const GocharaScreen(isYearly: true);
        break;
      case 'calendar_panchanga':
        targetScreen = const CalendarScreen();
        break;
      case 'ephemeris':
        targetScreen = const EphemerisScreen();
        break;
      case 'ayanamsa':
        targetScreen = const AyanamsaScreen();
        break;
      case 'widget':
        targetScreen = const WidgetSettingsScreen();
        break;
      case 'settings':
        targetScreen = SettingsScreen(onToggleTheme: onToggleTheme, isDark: isDark);
        break;
      case 'places':
        targetScreen = const PlacesScreen();
        break;
      case 'subscribe':
        targetScreen = const SubscribeScreen();
        break;
      case 'about':
        targetScreen = const AboutScreen();
        break;
      case 'rate':
        targetScreen = const RateScreen();
        break;
      case 'share':
        targetScreen = const ShareScreen();
        break;
      default:
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }
}
