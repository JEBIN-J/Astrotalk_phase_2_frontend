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
    {"name": "Aries", "icon": Icons.local_fire_department_rounded, "date": "Mar 21 - Apr 19"},
    {"name": "Taurus", "icon": Icons.terrain_rounded, "date": "Apr 20 - May 20"},
    {"name": "Gemini", "icon": Icons.air_rounded, "date": "May 21 - Jun 20"},
    {"name": "Cancer", "icon": Icons.water_drop_rounded, "date": "Jun 21 - Jul 22"},
    {"name": "Leo", "icon": Icons.local_fire_department_rounded, "date": "Jul 23 - Aug 22"},
    {"name": "Virgo", "icon": Icons.terrain_rounded, "date": "Aug 23 - Sep 22"},
    {"name": "Libra", "icon": Icons.air_rounded, "date": "Sep 23 - Oct 22"},
    {"name": "Scorpio", "icon": Icons.water_drop_rounded, "date": "Oct 23 - Nov 21"},
    {"name": "Sagittarius", "icon": Icons.local_fire_department_rounded, "date": "Nov 22 - Dec 21"},
    {"name": "Capricorn", "icon": Icons.terrain_rounded, "date": "Dec 22 - Jan 19"},
    {"name": "Aquarius", "icon": Icons.air_rounded, "date": "Jan 20 - Feb 18"},
    {"name": "Pisces", "icon": Icons.water_drop_rounded, "date": "Feb 19 - Mar 20"},
  ];

  String? _selectedSign;
  String _analysis = '';
  List<String> _predictions = [];
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysis = "Error connecting to the cosmic energies for $sign. Please try again.";
          _predictions = [];
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
        Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Text(
            'Select your Sun Sign to read your personalized daily cosmic prediction.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
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
                  decoration: AppTheme.getGlassCardDecoration(
                    isDark: isDark,
                    accentColor: Theme.of(context).primaryColor,
                    borderRadius: 16.r,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sign['icon'], color: Theme.of(context).primaryColor, size: 28),
                      ),
                      SizedBox(height: 12.h),
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
                        sign['date'],
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white54 : Colors.black54,
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
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(signData['icon'], size: 64, color: Colors.white),
          ),
          SizedBox(height: 24.h),
          Text(
            '$_selectedSign Horoscope',
            style: GoogleFonts.outfit(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Today',
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
