import 'package:flutter/material.dart';
import '../models/astro_item.dart';
import '../models/astro_models.dart';
import 'horoscope_screen.dart';
import 'prashna_screen.dart';
import 'ai_calling_screen.dart';
import 'ai_chat_screen.dart';
import 'vision_reading_screen.dart';
import 'notifications_screen.dart';
import 'muhurat_screen.dart';
import 'subscribe_screen.dart';
import 'daily_horoscope_screen.dart';

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
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle, initialTabIndex: 0);
        break;
      case 'kp_system':
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle, initialTabIndex: 1, isSingleTabMode: true, appBarTitle: 'KP System');
        break;
      case 'lal_kitab':
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle, initialTabIndex: 2, isSingleTabMode: true, appBarTitle: 'Lal Kitab');
        break;
      case 'bnn_nadi':
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle, initialTabIndex: 3, isSingleTabMode: true, appBarTitle: 'BNN System');
        break;
      case 'jaimini':
        targetScreen = HoroscopeScreen(initialChartStyle: defaultChartStyle, initialTabIndex: 4, isSingleTabMode: true, appBarTitle: 'Jaimini System');
        break;
      case 'muhurat':
        targetScreen = const MuhuratScreen();
        break;
      case 'daily_horoscope':
        targetScreen = const DailyHoroscopeScreen();
        break;
      case 'ai_calling':
        targetScreen = const AiCallingScreen();
        break;
      case 'chat_bot':
        targetScreen = const AiChatScreen();
        break;
      case 'face_reading':
        targetScreen = const VisionReadingScreen();
        break;
      case 'daily_quotes':
        // Show as a snackbar or popup for now since it's simple
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading daily quotes...')),
        );
        return;
      case 'notifications':
        targetScreen = const NotificationsScreen();
        break;
      case 'prashna':
        targetScreen = const PrashnaScreen();
        break;
      case 'subscribe':
        targetScreen = const SubscribeScreen();
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
