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
  Map<String, dynamic>? _dailyData;
  bool _isLoading = false;
  String _errorMsg = '';

  void _fetchDailyHoroscope(String sign) async {
    setState(() {
      _selectedSign = sign;
      _isLoading = true;
      _errorMsg = '';
      _dailyData = null;
    });

    try {
      final res = await AstroApiService.getDailyHoroscope(sign);
      if (mounted) {
        setState(() {
          _dailyData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = "Error connecting to the cosmic energies for $sign. Please try again.";
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
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            gradient: AppTheme.getHeaderGradient(AppColorPalette.midnightCosmic, isDark),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  'Select your Moon Sign (Rashi) to read your personalized daily transit prediction.',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.w),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.80,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _signs.length,
            itemBuilder: (context, index) {
              final sign = _signs[index];
              // Determine Element Gradient
              LinearGradient elementGradient;
              if (['Aries', 'Leo', 'Sagittarius'].contains(sign['name'])) {
                elementGradient = const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]); // Fire
              } else if (['Taurus', 'Virgo', 'Capricorn'].contains(sign['name'])) {
                elementGradient = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]); // Earth
              } else if (['Gemini', 'Libra', 'Aquarius'].contains(sign['name'])) {
                elementGradient = const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]); // Air
              } else {
                elementGradient = const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]); // Water
              }

              return GestureDetector(
                onTap: () => _fetchDailyHoroscope(sign['name']),
                child: Container(
                  decoration: AppTheme.getGlassCardDecoration(
                    isDark: isDark,
                    accentColor: elementGradient.colors.first,
                    borderRadius: 24.r,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: elementGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: elementGradient.colors.first.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(sign['icon'], color: Colors.white, size: 28),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        sign['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        sign['rashi'],
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          color: elementGradient.colors.last.withValues(alpha: isDark ? 0.9 : 0.7),
                          fontWeight: FontWeight.w700,
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
      padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 60.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
            decoration: BoxDecoration(
              gradient: AppTheme.getHeaderGradient(AppColorPalette.midnightCosmic, isDark),
              borderRadius: BorderRadius.circular(24.r),
              image: DecorationImage(
                image: const AssetImage('assets/images/mandala_bg.png'),
                fit: BoxFit.cover,
                opacity: isDark ? 0.2 : 0.1,
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.dstIn),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: Icon(signData['icon'], size: 48, color: Colors.white),
                ),
                SizedBox(height: 16.h),
                Text(
                  '$_selectedSign Horoscope',
                  style: GoogleFonts.outfit(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.blur_on_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6.w),
                      Text(
                        'Dynamic Gochar Transit',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32.h),
          
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: CircularProgressIndicator(color: theme.primaryColor),
            )
          else if (_errorMsg.isNotEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: AppTheme.getGlassCardDecoration(isDark: isDark, accentColor: Colors.red),
              child: Text(_errorMsg, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 16.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            )
          else if (_dailyData != null)
            _buildMathematicalData(isDark, theme),
            
          SizedBox(height: 40.h),
          
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedSign = null),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text('Check Another Rashi', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              elevation: 8,
              shadowColor: theme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildMathematicalData(bool isDark, ThemeData theme) {
    final astro = _dailyData!['astronomical_values'];
    final preds = _dailyData!['predictions'];
    final lucky = _dailyData!['lucky_values'];
    final basic = _dailyData!['basic'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCard(basic, astro, preds['overall'], isDark, theme),
        SizedBox(height: 24.h),
        _buildPlanetaryTable(astro['transit_planets'], isDark, theme),
        SizedBox(height: 24.h),
        _buildPredictionsGrid(preds, isDark, theme),
        SizedBox(height: 24.h),
        _buildLuckyValuesGrid(lucky, isDark, theme),
      ],
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> basic, Map<String, dynamic> astro, String overall, bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: AppTheme.getTempleGoldCardDecoration(
        isDark: isDark,
        borderRadius: 24.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              SizedBox(width: 12.w),
              Text(
                'Cosmic Overview',
                style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 15.sp, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
              children: [
                const TextSpan(text: 'Today\'s transit pattern is ruled by the '),
                TextSpan(text: '${basic['element']} element', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                TextSpan(text: ' under the guidance of '),
                TextSpan(text: '${basic['rashi_lord']}. ', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                TextSpan(text: '\n\n$overall'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetaryTable(List<dynamic> planets, bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.getGlassCardDecoration(isDark: isDark, accentColor: theme.primaryColor, borderRadius: 24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Real-Time Transits',
                    style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: theme.primaryColor.withValues(alpha: 0.1), height: 1, thickness: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark ? Colors.black12 : const Color(0xFFF8FAFC)),
              dataRowMinHeight: 48.h,
              dataRowMaxHeight: 52.h,
              horizontalMargin: 20.w,
              columnSpacing: 24.w,
              dividerThickness: 0.5,
              columns: [
                DataColumn(label: Text('Graha', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black))),
                DataColumn(label: Text('Sign', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black))),
                DataColumn(label: Text('Degree', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black))),
                DataColumn(label: Text('Nakshatra', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black))),
                DataColumn(label: Text('House', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black))),
              ],
              rows: planets.map((p) => DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: theme.primaryColor),
                        SizedBox(width: 8.w),
                        Text(p['planet'], style: GoogleFonts.outfit(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      ],
                    )
                  ),
                  DataCell(Text(p['sign'], style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600))),
                  DataCell(Text(p['degree'], style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87))),
                  DataCell(Text('${p['nakshatra']} (${p['pada']})', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87))),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('${p['house_from_moon']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    )
                  ),
                ],
              )).toList(),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildPredictionsGrid(Map<String, dynamic> preds, bool isDark, ThemeData theme) {
    final keys = ['career', 'finance', 'love', 'health', 'family', 'education', 'travel', 'social'];
    final icons = {
      'career': Icons.work_rounded,
      'finance': Icons.monetization_on_rounded,
      'love': Icons.favorite_rounded,
      'health': Icons.monitor_heart_rounded,
      'family': Icons.family_restroom_rounded,
      'education': Icons.school_rounded,
      'travel': Icons.flight_takeoff_rounded,
      'social': Icons.people_alt_rounded
    };
    
    final gradients = {
      'career': const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      'finance': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      'love': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFE11D48)]),
      'health': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      'family': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      'education': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
      'travel': const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
      'social': const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFBE123C)]),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'Phaladesh (Predictions)',
            style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        ...keys.map((k) => preds.containsKey(k) ? Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            decoration: AppTheme.getGlassCardDecoration(
              isDark: isDark,
              accentColor: gradients[k]!.colors.first,
              borderRadius: 20.r,
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: gradients[k],
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: gradients[k]!.colors.first.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icons[k], color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          preds[k],
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) : const SizedBox()).toList(),
      ],
    );
  }

  Widget _buildLuckyValuesGrid(Map<String, dynamic> lucky, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'Auspicious Timing',
            style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          children: [
            _buildMetricCard(Icons.filter_7_rounded, 'Lucky Number', lucky['lucky_number'].toString(), const Color(0xFFEC4899), isDark),
            _buildMetricCard(Icons.color_lens_rounded, 'Lucky Color', lucky['lucky_color'].toString(), const Color(0xFF8B5CF6), isDark),
            _buildMetricCard(Icons.explore_rounded, 'Direction', lucky['lucky_direction'].toString(), const Color(0xFF10B981), isDark),
            _buildMetricCard(Icons.hourglass_bottom_rounded, 'Best Time', lucky['best_time'].toString(), const Color(0xFFF59E0B), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String value, Color accent, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.getGlassCardDecoration(
        isDark: isDark,
        accentColor: accent,
        borderRadius: 20.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
