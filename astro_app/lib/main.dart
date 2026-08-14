import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const AbcApp());
}

class AbcApp extends StatefulWidget {
  const AbcApp({super.key});

  @override
  State<AbcApp> createState() => _AbcAppState();
}

class _AbcAppState extends State<AbcApp> {
  ThemeMode _themeMode = ThemeMode.light;
  AppColorPalette _palette = AppColorPalette.midnightCosmic;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _selectPalette(AppColorPalette palette) {
    setState(() {
      _palette = palette;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'ABC App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(isDark: false, palette: _palette),
          darkTheme: AppTheme.getTheme(isDark: true, palette: _palette),
          themeMode: _themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.25,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: DashboardScreen(
            isDark: isDark,
            onToggleTheme: _toggleTheme,
            currentPalette: _palette,
            onSelectPalette: _selectPalette,
          ),
        );
      },
    );
  }
}
