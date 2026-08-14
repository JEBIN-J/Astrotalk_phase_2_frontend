import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class DailyHoroscopeScreen extends StatefulWidget {
  const DailyHoroscopeScreen({super.key});

  @override
  State<DailyHoroscopeScreen> createState() => _DailyHoroscopeScreenState();
}

class _DailyHoroscopeScreenState extends State<DailyHoroscopeScreen> {
  final List<Map<String, dynamic>> _signs = [
    {"name": "Aries", "icon": Icons.local_fire_department_rounded, "rashi": "Mesha"},
    {"name": "Taurus", "icon": Icons.terrain_rounded, "rashi": "Vrishabha"},
    {"name": "Gemini", "icon": Icons.air_rounded, "rashi": "Mithuna"},
    {"name": "Cancer", "icon": Icons.water_drop_rounded, "rashi": "Karka"},
    {"name": "Leo", "icon": Icons.local_fire_department_rounded, "rashi": "Simha"},
    {"name": "Virgo", "icon": Icons.terrain_rounded, "rashi": "Kanya"},
    {"name": "Libra", "icon": Icons.air_rounded, "rashi": "Tula"},
    {"name": "Scorpio", "icon": Icons.water_drop_rounded, "rashi": "Vrishchika"},
    {"name": "Sagittarius", "icon": Icons.local_fire_department_rounded, "rashi": "Dhanu"},
    {"name": "Capricorn", "icon": Icons.terrain_rounded, "rashi": "Makara"},
    {"name": "Aquarius", "icon": Icons.air_rounded, "rashi": "Kumbha"},
    {"name": "Pisces", "icon": Icons.water_drop_rounded, "rashi": "Meena"},
  ];

  String? _selectedSign;
  String _analysis = '';
  List<String> _predictions = [];
  List<String> _remedies = [];
  String _luckyGemstone = '';
  String _luckyColor = '';
  String _luckyDay = '';
  String _auspiciousTime = '';
  bool _isLoading = false;

  void _getPrediction(String sign) async {
    setState(() {
      _selectedSign = sign;
      _isLoading = true;
    });

    try {
      final res = await AstroApiService.chatAiAstrologer(question: "What is the daily horoscope for $sign?", category: "general");
      if (mounted) {
        setState(() {
          _analysis = res['analysis'] ?? res['answer'] ?? "The cosmos are aligning for $sign. Maintain positivity.";
          if (res['predictions'] != null && res['predictions'] is List) {
            _predictions = (res['predictions'] as List).map((e) => e.toString()).toList();
          } else {
            _predictions = [];
          }
          if (res['remedies'] != null && res['remedies'] is List) {
            _remedies = (res['remedies'] as List).map((e) => e.toString()).toList();
          } else {
            _remedies = [];
          }
          _luckyGemstone = res['lucky_gemstone']?.toString() ?? '';
          _luckyColor = res['lucky_color']?.toString() ?? '';
          _luckyDay = res['lucky_day']?.toString() ?? '';
          _auspiciousTime = res['auspicious_time']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysis = "Error connecting to the cosmic energies for $sign. Please try again.";
          _predictions = [];
          _remedies = [];
          _luckyGemstone = '';
          _luckyColor = '';
          _luckyDay = '';
          _auspiciousTime = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Daily Horoscope', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _selectedSign == null
            ? _buildSignSelector(isDark)
            : _buildPredictionView(isDark),
      ),
    );
  }

  Widget _buildSignSelector(bool isDark) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 24),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Select your Moon Sign (Rashi) to read your personalized daily cosmic prediction.',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _signs.length,
            itemBuilder: (context, index) {
              final sign = _signs[index];
              return GestureDetector(
                onTap: () => _getPrediction(sign['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(sign['icon'], color: Colors.white, size: 28),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        sign['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        sign['rashi'],
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionView(bool isDark) {
    final signData = _signs.firstWhere((s) => s['name'] == _selectedSign);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 60.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(signData['icon'], size: 56, color: Colors.white),
                ),
                SizedBox(height: 20.h),
                Text(
                  '$_selectedSign Horoscope',
                  style: GoogleFonts.outfit(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Daily Prediction',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          if (_isLoading)
            CircularProgressIndicator(color: theme.primaryColor)
          else
            _buildPredictionCard(isDark, theme),
          SizedBox(height: 40.h),
          TextButton.icon(
            onPressed: () => setState(() => _selectedSign = null),
            icon: Icon(Icons.arrow_back_rounded),
            label: Text('Choose Another Sign'),
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryColor,
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: AppTheme.getGlassCardDecoration(
        isDark: isDark,
        accentColor: theme.primaryColor,
        borderRadius: 24.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primaryColor, size: 20),
              SizedBox(width: 8.w),
              Text(
                'Cosmic Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _analysis,
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (_predictions.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Divider(color: theme.primaryColor.withValues(alpha: 0.2)),
            SizedBox(height: 24.h),
            Row(
              children: [
                Icon(Icons.insights_rounded, color: theme.primaryColor, size: 20),
                SizedBox(width: 8.w),
                Text(
                  'Key Predictions',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ..._predictions.map((pred) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Icon(Icons.circle, size: 8, color: theme.primaryColor),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          pred,
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (_luckyColor.isNotEmpty || _luckyDay.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Divider(color: theme.primaryColor.withValues(alpha: 0.2)),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.stars_rounded, color: theme.primaryColor, size: 20),
                SizedBox(width: 8.w),
                Text(
                  'Daily Cosmic Metrics',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              children: [
                if (_luckyColor.isNotEmpty) _buildMetricChip(Icons.color_lens_rounded, 'Lucky Color', _cleanColor(_luckyColor), theme, isDark),
                if (_luckyGemstone.isNotEmpty) _buildMetricChip(Icons.diamond_rounded, 'Gemstone', _luckyGemstone, theme, isDark),
                if (_luckyDay.isNotEmpty) _buildMetricChip(Icons.calendar_today_rounded, 'Lucky Day', _luckyDay, theme, isDark),
                if (_auspiciousTime.isNotEmpty) _buildMetricChip(Icons.access_time_rounded, 'Auspicious Time', _auspiciousTime.split('(')[0].trim(), theme, isDark),
              ],
            ),
          ],
          if (_remedies.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Divider(color: theme.primaryColor.withValues(alpha: 0.2)),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.healing_rounded, color: theme.primaryColor, size: 20),
                SizedBox(width: 8.w),
                Text(
                  'Recommended Remedies',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ..._remedies.map((rem) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Icon(Icons.check_circle_outline, size: 14, color: theme.primaryColor),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          rem,
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _cleanColor(String color) {
    if (color.contains('(') && color.contains(')')) {
      return color.substring(color.indexOf('(') + 1, color.indexOf(')'));
    }
    return color;
  }

  Widget _buildMetricChip(IconData icon, String title, String value, ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
