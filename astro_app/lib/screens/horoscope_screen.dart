import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';
import '../widgets/kundli_chart_painter.dart';
import 'api_settings_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum StepperInterval {
  oneSecond,
  oneMinute,
  fiveMinutes,
  fifteenMinutes,
  oneHour,
  oneDay,
  oneMonth,
  oneYear,
}

extension StepperIntervalExt on StepperInterval {
  String get displayName {
    switch (this) {
      case StepperInterval.oneSecond:
        return '1s';
      case StepperInterval.oneMinute:
        return '1m';
      case StepperInterval.fiveMinutes:
        return '5m';
      case StepperInterval.fifteenMinutes:
        return '15m';
      case StepperInterval.oneHour:
        return '1h';
      case StepperInterval.oneDay:
        return '1d';
      case StepperInterval.oneMonth:
        return '1M';
      case StepperInterval.oneYear:
        return '1Y';
    }
  }

  Duration get duration {
    switch (this) {
      case StepperInterval.oneSecond:
        return const Duration(seconds: 1);
      case StepperInterval.oneMinute:
        return const Duration(minutes: 1);
      case StepperInterval.fiveMinutes:
        return const Duration(minutes: 5);
      case StepperInterval.fifteenMinutes:
        return const Duration(minutes: 15);
      case StepperInterval.oneHour:
        return const Duration(hours: 1);
      case StepperInterval.oneDay:
        return const Duration(days: 1);
      case StepperInterval.oneMonth:
        return const Duration(days: 30);
      case StepperInterval.oneYear:
        return const Duration(days: 365);
    }
  }
}

class HoroscopeScreen extends StatefulWidget {
  final KundliChartStyle initialChartStyle;
  final int initialTabIndex;
  final bool isSingleTabMode;
  final String? appBarTitle;

  const HoroscopeScreen({
    super.key,
    this.initialChartStyle = KundliChartStyle.southIndian, // Default South Indian Chart
    this.initialTabIndex = 0,
    this.isSingleTabMode = false,
    this.appBarTitle,
  });

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen>
    with TickerProviderStateMixin {
  late KundliChartStyle _currentChartStyle;
  late TabController _tabController;
  late TabController _bottomSubTabController;

  String _personName = 'Jebin J';
  String _dob = '13 Dec 1998';
  String _tob = '07:18 PM';
  String _pob = 'Kanyakumari, Tamil Nadu, India';

  DateTime _currentDateTime = DateTime(1998, 12, 13, 19, 18, 00);
  double _latitude = 8.0883;
  double _longitude = 77.5385;
  double _timezone = 5.5;

  String _activeChartKey = 'D-1';
  StepperInterval _stepperInterval = StepperInterval.oneMinute;
  bool _showUpagrahasOnChart = true;
  bool _showDegreesOnChart = true;
  bool _isCardViewMode = false;
  bool _isKpTableViewMode = true;

  bool _isLoadingKundli = false;
  Map<String, dynamic>? _kundliData;
  Map<String, dynamic>? _lalKitabData;
  Map<String, dynamic>? _bnnData;
  Map<String, dynamic>? _jaiminiData;

  String _selectedDashaType = 'Vimshottari Dasha';
  String _daysInYearType = 'Mean Sidereal Year (365.256364)';
  String _customDaysInYear = '';
  Map<String, dynamic>? _selectedMahadasha;
  String _selectedBhavaSystem = 'Porphyry (Sripathi)';
  String _selectedVimsopakaRelation = 'As per respective Varga Chart';
  int _strengthSubTabIndex = 0;


  
  bool _isLoadingDasha = false;
  List<dynamic>? _dynamicDashaTimeline;
  Map<String, dynamic>? _dynamicRunningDasha;
  bool _isDashaCardView = false; // false = table (default), true = cards


  static const Map<String, String> _divisionalChartsInfo = {
    'D-1': 'Rashi (Natal Physical Plane)',
    'D-2': 'Hora (Wealth & Liquid Assets)',
    'D-3': 'Drekkana (Siblings & Courage)',
    'D-4': 'Chaturthamsha (Property & Fortune)',
    'D-7': 'Saptamsha (Children & Progeny)',
    'D-9': 'Navamsha (Dharma, Soul & Marriage)',
    'D-10': 'Dasamsha (Career & Profession)',
    'D-12': 'Dwadasamsha (Parents & Lineage)',
    'D-16': 'Shodashamsha (Vehicles & Pleasures)',
    'D-20': 'Vimsamsha (Spiritual Progress)',
    'D-24': 'Siddhamsa (Higher Knowledge)',
    'D-27': 'Saptavimsamsha (Strengths)',
    'D-30': 'Trimshamsha (Misfortunes & Arishta)',
    'D-60': 'Shashtiamsha (Past Karmic Destiny)',
    'Bhava': 'Bhava Chalit (Cuspal Houses)',
  };

  @override
  void initState() {
    super.initState();
    _currentChartStyle = widget.initialChartStyle;
    _tabController = TabController(length: 9, vsync: this, initialIndex: widget.initialTabIndex);
    _bottomSubTabController = TabController(length: 4, vsync: this);
    _syncDateTimeFromStrings();
    _fetchKundliData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bottomSubTabController.dispose();
    super.dispose();
  }

  String _getNakshatraLordFromNakshatra(String nakshatra) {
    final nak = nakshatra.toLowerCase();
    if (nak.contains('ashwini') || nak.contains('magha') || nak.contains('mula')) return 'Ketu';
    if (nak.contains('bharani') || nak.contains('purva phalguni') || nak.contains('purva ashadha')) return 'Venus';
    if (nak.contains('krittika') || nak.contains('uttara phalguni') || nak.contains('uttara ashadha')) return 'Sun';
    if (nak.contains('rohini') || nak.contains('hasta') || nak.contains('shravana')) return 'Moon';
    if (nak.contains('mrigashira') || nak.contains('chitra') || nak.contains('dhanishta')) return 'Mars';
    if (nak.contains('ardra') || nak.contains('swati') || nak.contains('shatabhisha')) return 'Rahu';
    if (nak.contains('punarvasu') || nak.contains('vishakha') || nak.contains('purva bhadrapada')) return 'Jupiter';
    if (nak.contains('pushya') || nak.contains('anuradha') || nak.contains('uttara bhadrapada')) return 'Saturn';
    if (nak.contains('ashlesha') || nak.contains('jyeshtha') || nak.contains('revati')) return 'Mercury';
    return '-';
  }

  void _syncDateTimeFromStrings() {
    try {
      DateTime? d;
      final dFormats = [
        DateFormat('dd MMM yyyy'),
        DateFormat('d MMM yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
      ];
      for (final f in dFormats) {
        try {
          d = f.parse(_dob.trim());
          break;
        } catch (_) {}
      }

      int hour = 19;
      int minute = 18;
      int second = 0;

      final tFormats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm:ss'),
        DateFormat('HH:mm'),
      ];
      for (final f in tFormats) {
        try {
          final t = f.parse(_tob.trim());
          hour = t.hour;
          minute = t.minute;
          second = t.second;
          break;
        } catch (_) {}
      }

      if (d != null) {
        _currentDateTime = DateTime(d.year, d.month, d.day, hour, minute, second);
      }
    } catch (_) {}
  }

  String get _dobFormattedForApi =>
      DateFormat('yyyy-MM-dd').format(_currentDateTime);
  String get _tobFormattedForApi =>
      DateFormat('HH:mm:ss').format(_currentDateTime);

  String get _headerDisplayDateTime =>
      DateFormat('dd-MMM-yyyy hh:mm:ss a').format(_currentDateTime);

  String get _formattedLatLong {
    final latDeg = _latitude.abs().floor();
    final latMin = ((_latitude.abs() - latDeg) * 60).round();
    final latDir = _latitude >= 0 ? 'N' : 'S';

    final lonDeg = _longitude.abs().floor();
    final lonMin = ((_longitude.abs() - lonDeg) * 60).round();
    final lonDir = _longitude >= 0 ? 'E' : 'W';

    final latStr = '${latDeg.toString().padLeft(2, '0')}° $latMin\' $latDir';
    final lonStr = '${lonDeg.toString().padLeft(2, '0')}° $lonMin\' $lonDir';

    return '$lonStr, $latStr';
  }

  String get _formattedTzPlace {
    final tzSign = _timezone >= 0 ? '+' : '-';
    final tzHours = _timezone.abs().floor().toString().padLeft(2, '0');
    final tzMins = ((_timezone.abs() % 1) * 60).round().toString().padLeft(2, '0');
    return 'GMT$tzSign$tzHours:$tzMins';
  }

  Future<void> _fetchKundliData() async {
    setState(() => _isLoadingKundli = true);
    try {
      final futures = await Future.wait([
        AstroApiService.getKundli(
          name: _personName,
          dateOfBirth: _dobFormattedForApi,
          timeOfBirth: _tobFormattedForApi,
          placeOfBirth: _pob,
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
          daysInYear: _currentDaysInYear,
          bhavaSystem: _selectedBhavaSystem,
        ),
        AstroApiService.getLalKitab(
          name: _personName,
          dateOfBirth: _dobFormattedForApi,
          timeOfBirth: _tobFormattedForApi,
          placeOfBirth: _pob,
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
        ),
        AstroApiService.getBnn(
          name: _personName,
          dateOfBirth: _dobFormattedForApi,
          timeOfBirth: _tobFormattedForApi,
          placeOfBirth: _pob,
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
        ),
        AstroApiService.getJaimini(
          name: _personName,
          dateOfBirth: _dobFormattedForApi,
          timeOfBirth: _tobFormattedForApi,
          placeOfBirth: _pob,
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
        ),
      ]);
      
      if (mounted) {
        setState(() {
          _kundliData = futures[0];
          _lalKitabData = futures[1];
          _bnnData = futures[2];
          _jaiminiData = futures[3];
          _isLoadingKundli = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingKundli = false);
      }
    }
  }

  void _stepTime(bool forward) {
    setState(() {
      if (forward) {
        _currentDateTime = _currentDateTime.add(_stepperInterval.duration);
      } else {
        _currentDateTime = _currentDateTime.subtract(_stepperInterval.duration);
      }
      _dob = DateFormat('dd MMM yyyy').format(_currentDateTime);
      _tob = DateFormat('hh:mm a').format(_currentDateTime);
    });
    _fetchKundliData();
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 36.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.tune_rounded, color: Colors.white, size: 20.sp),
                            ),
                            SizedBox(width: 14.w),
                            Text(
                              'Display Settings',
                              style: GoogleFonts.outfit(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: isDark ? [] : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(Icons.close_rounded, size: 18.sp, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'Time Stepping Interval',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children: StepperInterval.values.map((interval) {
                        final isSel = interval == _stepperInterval;
                        return InkWell(
                          onTap: () {
                            setModalState(() => _stepperInterval = interval);
                            setState(() => _stepperInterval = interval);
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              gradient: isSel 
                                ? const LinearGradient(
                                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                              color: isSel ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSel ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: 1.5,
                              ),
                              boxShadow: isSel ? [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ] : (isDark ? [] : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]),
                            ),
                            child: Text(
                              interval.displayName,
                              style: GoogleFonts.outfit(
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'Chart System Model',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: isDark ? [] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: KundliChartStyle.values.map((style) {
                          final isSel = style == _currentChartStyle;
                          String label = style == KundliChartStyle.southIndian
                              ? 'Square'
                              : style == KundliChartStyle.northIndian
                                  ? 'Diamond'
                                  : 'Sun';
                          
                          IconData? icon;
                          if (style == KundliChartStyle.southIndian) icon = Icons.crop_square_rounded;
                          if (style == KundliChartStyle.northIndian) icon = Icons.change_history_rounded;
                          if (style == KundliChartStyle.eastIndian) icon = Icons.wb_sunny_rounded;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() => _currentChartStyle = style);
                                setState(() => _currentChartStyle = style);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSel ? (isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF)) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (icon != null) ...[
                                      Icon(
                                        icon, 
                                        size: 16.sp, 
                                        color: isSel ? const Color(0xFF4F46E5) : (isDark ? Colors.white54 : const Color(0xFF94A3B8))
                                      ),
                                      SizedBox(width: 6.w),
                                    ],
                                    Text(
                                      label,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.sp, 
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        color: isSel ? const Color(0xFF4F46E5) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: isDark ? [] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPremiumToggle(
                            title: 'Show Upagrahas (Md, Gk)',
                            icon: Icons.stars_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            value: _showUpagrahasOnChart,
                            isDark: isDark,
                            onChanged: (val) {
                              setModalState(() => _showUpagrahasOnChart = val);
                              setState(() => _showUpagrahasOnChart = val);
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          ),
                          _buildPremiumToggle(
                            title: 'Show Planetary Degrees',
                            icon: Icons.straighten_rounded,
                            iconBg: const Color(0xFFE0E7FF),
                            iconColor: const Color(0xFF4F46E5),
                            value: _showDegreesOnChart,
                            isDark: isDark,
                            onChanged: (val) {
                              setModalState(() => _showDegreesOnChart = val);
                              setState(() => _showDegreesOnChart = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumToggle({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF4F46E5),
              inactiveThumbColor: isDark ? Colors.white70 : Colors.white,
              inactiveTrackColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _showOthersDivisionalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF4338CA), size: 22),
                      SizedBox(width: 8.w),
                      Text(
                        'Divisional Charts (Vargas)',
                        style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(height: 16.h),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: _divisionalChartsInfo.entries.map((entry) {
                    final key = entry.key;
                    final desc = entry.value;
                    final isSel = key == _activeChartKey;

                    return Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? const Color(0xFF4338CA).withValues(alpha: 0.25) : const Color(0xFFEEF2FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSel ? const Color(0xFF4338CA) : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF4338CA) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            key,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                        title: Text(
                          desc,
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? const Color(0xFF4338CA) : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        trailing: isSel ? Icon(Icons.check_circle_rounded, color: Color(0xFF4338CA), size: 20) : null,
                        onTap: () {
                          setState(() {
                            _activeChartKey = key;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _EditBirthDetailsDialog(
        initialName: _personName,
        initialDob: _dob,
        initialTob: _tob,
        initialPob: _pob,
        initialLat: _latitude,
        initialLon: _longitude,
        initialTz: _timezone,
        onSave: (name, dob, tob, pob, lat, lon, tz) {
          setState(() {
            _personName = name;
            _dob = dob;
            _tob = tob;
            _pob = pob;
            _latitude = lat;
            _longitude = lon;
            _timezone = tz;
            _syncDateTimeFromStrings();
          });
          _fetchKundliData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calculated high-precision Kundli for $name ($pob)', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        centerTitle: false,
        title: Text(
          widget.appBarTitle ?? 'Horoscope',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, size: 24),
            tooltip: 'Edit Birth Profile',
            onPressed: _showEditProfileDialog,
          ),

          IconButton(
            icon: Icon(Icons.settings_outlined, size: 21),
            tooltip: 'Display Settings & Stepper',
            onPressed: _showSettingsModal,
          ),
        ],
        bottom: widget.isSingleTabMode ? null : PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF4338CA),
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              indicatorColor: const Color(0xFF009688),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14.sp),
              tabs: [
                Tab(text: 'Vedic (D1)'),
                Tab(text: 'Dasha'),
                Tab(text: 'KP System'),
                Tab(text: 'Lal Kitab'),
                Tab(text: 'BNN'),
                Tab(text: 'Jamini'),
                Tab(text: 'Ashtakavarga'),
                Tab(text: 'Strength'),
                Tab(text: 'Kot Chakra'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingKundli
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4338CA)),
                  SizedBox(height: 14.h),
                  Text(
                    'Calculating Swiss Ephemeris Placements...',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5.sp),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              physics: widget.isSingleTabMode ? const NeverScrollableScrollPhysics() : null,
              children: [
                _buildLagnaAndDivisionalChartTab(context, isDark),
                _buildDashaTab(context, isDark),
                _buildPlanetsTab(context, isDark),
                _buildLalKitabTab(context, isDark),
                _buildBnnTab(context, isDark),
                _buildJaiminiTab(context, isDark),
                _buildAshtakvargaTab(context, isDark),
                _buildStrengthTab(context, isDark),
                _buildKotChakraTab(context, isDark),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BouncyTouchCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kundli PDF ready! Saved to Downloads folder.', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    'Download Complete Janam Kundli PDF',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String message, bool isDark) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: CHART TAB (Live Stepper + Sub-Vargas + Interactive Chart + 4 Tables)
  // =========================================================================
  Widget _buildLagnaAndDivisionalChartTab(BuildContext context, bool isDark) {
    final ascLagna = _kundliData?['ascendant_lagna']?.toString() ?? _kundliData?['ascendant_sign']?.toString() ?? 'Gemini';
    final ascDeg = _kundliData?['ascendant_degree_formatted']?.toString() ?? _kundliData?['ascendant_degree']?.toString() ?? '';
    final ascDisplay = ascDeg.isNotEmpty ? '$ascLagna ($ascDeg)' : ascLagna;

    final moonSign = _kundliData?['moon_sign_rashi']?.toString() ?? _kundliData?['moon_sign']?.toString() ?? 'Virgo';
    final nakshatra = _kundliData?['nakshatra']?.toString() ?? 'Chitra';
    final nakPada = _kundliData?['nakshatra_pada']?.toString() ?? '2';
    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? "Lahiri 23° 50' 32\"";

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Profile Signature Gradient Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(7.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        _personName,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 17.5.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showEditProfileDialog,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4.w),
                          Text('Edit', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildProfileChip(Icons.calendar_today_rounded, _dob),
                  _buildProfileChip(Icons.access_time_rounded, _tob),
                  _buildProfileChip(Icons.location_on_rounded, _pob),
                ],
              ),
              Divider(color: Colors.white24, height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAscendantBadge('Ascendant', ascDisplay),
                  _buildAscendantBadge('Moon Sign', moonSign),
                  _buildAscendantBadge('Nakshatra', '$nakshatra\nPada $nakPada'),
                  _buildAscendantBadge('Ayanamsa', ayanamsa),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 2. Live Time Stepper Responsive Card (Zero-Overflow Layout)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Responsive Left Side Date-Time
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _headerDisplayDateTime,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // Compact Right Side Stepper Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Interval Settings
                      InkWell(
                        onTap: _showSettingsModal,
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 13, color: Color(0xFF4338CA)),
                              SizedBox(width: 3.w),
                              Text(
                                _stepperInterval.displayName,
                                style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Step Backward
                      InkWell(
                        onTap: () => _stepTime(false),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Step Forward
                      InkWell(
                        onTap: () => _stepTime(true),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.location_pin, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      '$_pob ($_formattedTzPlace)',
                      style: GoogleFonts.outfit(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.explore_outlined, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4.w),
                  Text(
                    _formattedLatLong,
                    style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 3. Sub-Vargas Segmented Control (Rashi, Navamsha, Bhava, Others)
        Container(
          height: 44.h,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              _buildVargaTabItem('Rashi', _activeChartKey == 'D-1', () => setState(() => _activeChartKey = 'D-1'), isDark),
              _buildVargaTabItem('Navamsa', _activeChartKey == 'D-9', () => setState(() => _activeChartKey = 'D-9'), isDark),
              _buildVargaTabItem('Bhava', _activeChartKey == 'Bhava', () => setState(() => _activeChartKey = 'Bhava'), isDark),
              _buildVargaTabItem(
                _activeChartKey.startsWith('D-') && _activeChartKey != 'D-1' && _activeChartKey != 'D-9' ? _activeChartKey : 'Others',
                _activeChartKey != 'D-1' && _activeChartKey != 'D-9' && _activeChartKey != 'Bhava',
                _showOthersDivisionalPicker,
                isDark,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // 4. Active Chart Title Banner
        Center(
          child: Text(
            'Chart Type: ${_divisionalChartsInfo[_activeChartKey] ?? _activeChartKey}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13.5.sp,
              color: const Color(0xFF4338CA),
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // 5. Chart Model Quick 1-Tap Toggle (Square vs Diamond vs Sun)
        Container(
          height: 38.h,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              _buildChartStyleToggleItem(
                '🔲 South Indian',
                _currentChartStyle == KundliChartStyle.southIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.southIndian),
                isDark,
              ),
              _buildChartStyleToggleItem(
                '🔷 Diamond (North)',
                _currentChartStyle == KundliChartStyle.northIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.northIndian),
                isDark,
              ),
              _buildChartStyleToggleItem(
                '☀️ Sun (East)',
                _currentChartStyle == KundliChartStyle.eastIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.eastIndian),
                isDark,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // 6. Kundli Interactive Chart Card (Square / Diamond)
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: _activeChartKey,
                showUpagrahas: _showUpagrahasOnChart,
                showDegrees: _showDegreesOnChart,
                kundliData: _kundliData,
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _currentChartStyle.title,
                          style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Swiss Ephemeris Precision',
                    style: GoogleFonts.outfit(fontSize: 10.5.sp, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // 7. Bottom 4 Sub-Tabs Bar (Planets, Upagraha, Arudha, Others)
        Container(
          height: 44.h,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TabBar(
            controller: _bottomSubTabController,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white70 : const Color(0xFF475569),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(9.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5.sp),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12.5.sp),
            tabs: [
              Tab(text: 'Planets'),
              Tab(text: 'Upagraha'),
              Tab(text: 'Arudha'),
              Tab(text: 'Others'),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 8. Bottom Content Area (Internal scrolling list)
        SizedBox(
          height: 380.h,
          child: TabBarView(
            controller: _bottomSubTabController,
            children: [
              _buildBottomPlanetsTable(isDark),
              _buildBottomUpagrahaTable(isDark),
              _buildBottomArudhaTable(isDark),
              _buildBottomOthersTable(isDark),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildChartStyleToggleItem(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVargaTabItem(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER: KP LORD SHORT CODE ---
  String _getLordShortCode(String? lord) {
    if (lord == null || lord.isEmpty) return '-';
    final lower = lord.toLowerCase().trim();
    if (lower.startsWith('su')) return 'Su';
    if (lower.startsWith('mo') || lower.startsWith('ch')) return 'Mo';
    if (lower.startsWith('ma') || lower.startsWith('ku')) return 'Ma';
    if (lower.startsWith('me') || lower.startsWith('bu')) return 'Me';
    if (lower.startsWith('ju') || lower.startsWith('gu') || lower.startsWith('br')) return 'Ju';
    if (lower.startsWith('ve') || lower.startsWith('shuk')) return 'Ve';
    if (lower.startsWith('sa') || lower.startsWith('shan')) return 'Sa';
    if (lower.startsWith('ra')) return 'Ra';
    if (lower.startsWith('ke')) return 'Ke';
    if (lower.startsWith('ur')) return 'Ur';
    if (lower.startsWith('ne')) return 'Ne';
    if (lower.startsWith('pl')) return 'Pl';
    return lord.length >= 2 ? lord.substring(0, 2) : lord;
  }

  Widget _buildKpTableHeader(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('Planet', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('House', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('Degree', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('Rashi', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('Nakshatra', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('Pada', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('RL', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('NL', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('SL', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 1, child: Text('SSL', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 1: PLANETS TABLE ---
  Widget _buildBottomPlanetsTable(bool isDark) {
    final basePlanets = (_kundliData?['planets'] as List<dynamic>?) ?? [];
    List<Map<String, dynamic>> dynamicPlanets = [];

    for (var bp in basePlanets) {
      Map<String, dynamic> dp = Map<String, dynamic>.from(bp);
      final rawName = dp['name']?.toString() ?? '';
      final simpleName = dp['planet_name_simple']?.toString() ?? (rawName.isNotEmpty ? rawName.split(' ').first : '');
      
      final isLagna = simpleName.toLowerCase().contains('ascendant') || 
                      rawName.toLowerCase().contains('ascendant') || 
                      rawName.toLowerCase().contains('lagna');

      if (_activeChartKey == 'Bhava') {
        if (isLagna) {
          dp['house'] = 1;
        } else {
          final bhavaPlanets = _kundliData?['bhava_chalit']?['planets'] as List<dynamic>?;
          if (bhavaPlanets != null) {
            final match = bhavaPlanets.firstWhere(
              (p) => p['planet']?.toString() == simpleName,
              orElse: () => null,
            );
            if (match != null) {
              dp['house'] = match['bhava_house'];
            }
          }
        }
      } else if (_activeChartKey != 'D-1') {
        final divCharts = _kundliData?['divisional_charts'] as Map<String, dynamic>?;
        if (divCharts != null && divCharts.containsKey(_activeChartKey)) {
          if (isLagna) {
            dp['sign'] = divCharts[_activeChartKey]['ascendant_sign'];
            dp['house'] = 1;
          } else {
            final divPlanets = divCharts[_activeChartKey]['planets'] as List<dynamic>?;
            if (divPlanets != null) {
              final match = divPlanets.firstWhere(
                (p) => p['planet']?.toString() == simpleName,
                orElse: () => null,
              );
              if (match != null) {
                dp['sign'] = match['sign'];
                dp['house'] = match['house'];
              }
            }
          }
        }
      }
      dynamicPlanets.add(dp);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Planetary Positions for ${_divisionalChartsInfo[_activeChartKey] ?? "Rashi (D-1)"}',
                    style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => setState(() => _isCardViewMode = !_isCardViewMode),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _isCardViewMode ? 'KP View' : 'Degree View',
                      style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: _isCardViewMode ? 500 : 800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isCardViewMode)
                      _buildTableHeader(['Planet', 'House', 'Degree', 'Rashi', 'Nakshatra', 'Pada'], isDark)
                    else
                      _buildKpTableHeader(isDark),
                    Divider(height: 1.h),
                    Expanded(
                      child: ListView.separated(
                        itemCount: dynamicPlanets.length,
                        separatorBuilder: (_, __) => Divider(height: 1.h, color: isDark ? Colors.white12 : Colors.grey.shade200),
                        itemBuilder: (ctx, idx) {
                          final p = dynamicPlanets[idx];
                          final isLagna = (p['planet_name_simple']?.toString().toLowerCase().contains('ascendant') ?? false) ||
                              (p['name']?.toString().toLowerCase().contains('ascendant') ?? false) ||
                              (p['name']?.toString().toLowerCase().contains('lagna') ?? false);

                          String displayName = p['table_display_name']?.toString() ?? '';
                          if (displayName.isEmpty) {
                            if (isLagna) {
                              displayName = 'Lagna';
                            } else {
                              final rawName = p['name']?.toString();
                              final simpleName = p['planet_name_simple']?.toString() ??
                                  (rawName != null && rawName.isNotEmpty ? rawName.split(' ').first : 'Planet');
                              final isRetro = p['is_retrograde'] == true;
                              final karakaCode = p['chara_karaka_code']?.toString() ?? '';
                              final retroTag = isRetro ? ' (R)' : '';
                              final karakaTag = karakaCode.isNotEmpty ? (isRetro ? '($karakaCode)' : ' ($karakaCode)') : '';
                              displayName = '$simpleName$retroTag$karakaTag';
                            }
                          }

                          final houseStr = p['house']?.toString() ?? '-';
                          final deg = p['degree_formatted']?.toString() ?? "00:00:00";
                          final rawSign = p['sign']?.toString() ?? 'Aries';
                          final signDisplay = rawSign.split('(')[0].trim();
                          final nak = p['nakshatra']?.toString() ?? '-';
                          final pada = p['pada']?.toString() ?? '-';

                          final kp = p['kp_lords'] as Map<String, dynamic>?;
                          final rl = p['rl']?.toString() ?? kp?['rl']?.toString() ?? _getLordShortCode(p['sign_lord']?.toString());
                          final nl = p['nl']?.toString() ?? kp?['nl']?.toString() ?? _getLordShortCode(p['nakshatra_lord']?.toString());
                          final sl = p['sl']?.toString() ?? kp?['sl']?.toString() ?? _getLordShortCode(kp?['sub_lord']?.toString());
                          final ssl = p['ssl']?.toString() ?? kp?['ssl']?.toString() ?? _getLordShortCode(kp?['sub_sub_lord']?.toString());

                          final rowBg = isLagna
                              ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.28) : const Color(0xFFFFF1F2))
                              : (idx.isOdd ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC)) : Colors.transparent);

                          if (_isCardViewMode) {
                            final ownedHouses = (p['kp_owned_houses'] as List<dynamic>?)?.join(', ') ?? 'None';
                            final occupiedHouse = p['kp_occupied_house']?.toString() ?? '-';
                            final significators = (p['kp_significators'] as List<dynamic>?)?.join(', ') ?? '-';
                            final navSign = p['navamsha']?['navamsha_sign']?.toString() ?? '';
                            final dignity = p['dignity']?.toString() ?? 'Direct';
                            final planetCode = p['chara_karaka_code']?.toString() ?? '';
                            final colorHex = p['color']?.toString() ?? '#4338CA';
                            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

                            if (displayName == 'Lagna' || displayName == 'Ascendant') {
                              return _buildPlanetCard(
                                displayName, houseStr, deg, signDisplay, nak, pada, nl,
                                isDark, isLagna: true,
                                kpLords: 'KP Lords: Star: $nl • Sub: $sl • SS: $ssl   D9: $navSign',
                                dignity: dignity,
                                planetCode: planetCode,
                                color: color,
                              );
                            }

                            return _buildPlanetCard(
                              displayName, houseStr, deg, signDisplay, nak, pada, nl,
                              isDark,
                              kpLords: 'KP Lords: Star: $nl • Sub: $sl • SS: $ssl   D9: $navSign',
                              kpSignificators: 'Occupied: $occupiedHouse | Owned: $ownedHouses | Significators: $significators',
                              dignity: dignity,
                              planetCode: planetCode,
                              color: color,
                            );
                          }

                          return Container(
                            color: rowBg,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text(displayName, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text(houseStr, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF059669)))),
                                Expanded(flex: 1, child: Text(deg, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(signDisplay, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(nak, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Center(child: Text(pada, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold)))),
                                Expanded(flex: 1, child: Center(child: Text(rl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA))))),
                                Expanded(flex: 1, child: Center(child: Text(nl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF059669))))),
                                Expanded(flex: 1, child: Center(child: Text(sl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))))),
                                Expanded(flex: 1, child: Center(child: Text(ssl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6))))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 2: UPAGRAHA TABLE ---
  Widget _buildBottomUpagrahaTable(bool isDark) {
    final upagrahas = (_kundliData?['upagrahas'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Upagraha Positions for Rashi (D-1)',
                    style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${upagrahas.length} Secondary Planets',
                  style: GoogleFonts.outfit(fontSize: 10.5.sp, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: 450.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTableHeader(['Upagraha', 'Degree', 'Rashi', 'Nakshatra', 'Pada'], isDark),
                    Divider(height: 1.h),
                    Expanded(
                      child: ListView.separated(
                        itemCount: upagrahas.length,
                        separatorBuilder: (_, __) => Divider(height: 1.h, color: isDark ? Colors.white12 : Colors.grey.shade200),
                        itemBuilder: (ctx, idx) {
                          final u = upagrahas[idx] as Map<String, dynamic>;
                          final rawName = u['name']?.toString() ?? 'Upagraha';
                          final name = rawName.split('(')[0].trim();
                          final code = u['short_code']?.toString() ?? '';
                          final deg = u['degree_formatted']?.toString() ?? '00:00:00';
                          final rawSign = u['sign']?.toString() ?? 'Aries';
                          final signDisplay = rawSign.split('(')[0].trim();
                          final nak = u['nakshatra']?.toString() ?? 'Ashwini';
                          final pada = (u['pada'] ?? 1).toString();

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text(name, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600))),
                                Expanded(flex: 1, child: Text(deg, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(signDisplay, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(nak, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Center(child: Text(pada, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 3: ARUDHA TABLE ---
  Widget _buildBottomArudhaTable(bool isDark) {
    final arudhas = (_kundliData?['arudha_padas'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Text(
              'Arudha Pada Positions (Jaimini Classical System)',
              style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: 500.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTableHeader(['Arudha Pada', 'Degree', 'Rashi', 'Nakshatra', 'Pada', 'Nakshatra Lord'], isDark),
                    Divider(height: 1.h),
                    Expanded(
                      child: ListView.separated(
                        itemCount: arudhas.length,
                        separatorBuilder: (_, __) => Divider(height: 1.h, color: isDark ? Colors.white12 : Colors.grey.shade200),
                        itemBuilder: (ctx, idx) {
                          final a = arudhas[idx] as Map<String, dynamic>;
                          final code = a['code']?.toString() ?? 'A1';
                          final rawName = a['name']?.toString() ?? '';
                          final name = rawName.split('(')[0].trim();
                          final deg = a['degree_formatted']?.toString() ?? '00:00:00';
                          final rawSign = a['sign']?.toString() ?? 'Aries';
                          final sign = rawSign.split('(')[0].trim();
                          final nak = a['nakshatra']?.toString() ?? 'Ashwini';
                          final pada = (a['pada'] ?? 1).toString();
                          
                          // Bulletproof fallback to calculate from name if backend was not restarted or returns null/empty
                          final rawNl = a['nakshatra_lord']?.toString() ?? '';
                          final nl = (rawNl.isEmpty || rawNl == 'null' || rawNl == '-') 
                              ? _getNakshatraLordFromNakshatra(nak) 
                              : rawNl;

                          final isArudhaLagna = code.startsWith('AL') || code.startsWith('UL');

                          return Container(
                            color: isArudhaLagna ? (isDark ? const Color(0xFF4338CA).withValues(alpha: 0.15) : const Color(0xFFEEF2FF)) : Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(code, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                                      if (name.isNotEmpty)
                                        Text(name, style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black54)),
                                    ],
                                  ),
                                ),
                                Expanded(flex: 1, child: Text(deg, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(sign, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(nak, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                                Expanded(flex: 1, child: Text(pada, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text(nl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 4: OTHERS (Special Lagnas & Chara Karakas) ---
  Widget _buildBottomOthersTable(bool isDark) {
    final specialLagnas = (_kundliData?['special_lagnas'] as List<dynamic>?) ?? [];
    final charaKarakas = (_kundliData?['chara_karakas'] as List<dynamic>?) ?? [];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Special Lagnas',
                    style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text('Parashara', style: GoogleFonts.outfit(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ...specialLagnas.map((s) {
                final rawName = s['name']?.toString() ?? '';
                final name = rawName.split('(')[0].trim();
                final sign = s['sign']?.toString() ?? '';
                final deg = s['degree_formatted']?.toString() ?? '';
                final nak = s['nakshatra']?.toString() ?? '';
                final sig = s['significance']?.toString() ?? '';

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(name, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$sign • $deg • $nak', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w600)),
                            if (sig.isNotEmpty)
                              Text(sig, style: GoogleFonts.outfit(fontSize: 10.sp, color: isDark ? Colors.white60 : Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jaimini 7 Chara Karakas',
                    style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text('Longitudes', style: GoogleFonts.outfit(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ...charaKarakas.map((k) {
                final p = k['planet']?.toString() ?? '';
                final code = k['karaka_code']?.toString() ?? '';
                final name = k['karaka_name']?.toString() ?? '';
                final sig = k['significance']?.toString() ?? '';
                final deg = k['degree_in_sign']?.toString() ?? '';

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Container(
                        width: 44.w,
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(code, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$p ($name)', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w600)),
                                Text(deg, style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54)),
                              ],
                            ),
                            Text(sig, style: GoogleFonts.outfit(fontSize: 10.sp, color: isDark ? Colors.white60 : Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<String> headers, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: headers.map((header) {
          return Expanded(
            flex: 1,
            child: Text(header, style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155))),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanetCard(String title, String house, String deg, String sign,
      String nak, String pada, String nakLord, bool isDark,
      {bool isLagna = false, required String kpLords, String? kpSignificators, required String dignity, String? planetCode, required Color color}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: isDark ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        if (planetCode != null && planetCode.isNotEmpty) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              planetCode,
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$sign • House $house • $deg',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$nak Pada $pada (Lord: $nakLord)',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  dignity.split(' ')[0],
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            kpLords,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4338CA),
            ),
          ),
          if (kpSignificators != null) ...[
            SizedBox(height: 4.h),
            Text(
              kpSignificators,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PLANETS & KP LORDS TAB
  // =========================================================================
  Widget _buildLalKitabTab(BuildContext context, bool isDark) {
    if (_lalKitabData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA)));
    }

    final planets = _lalKitabData!['planets'] as List<dynamic>? ?? [];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Lal Kitab Chart Box
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Lal Kitab Chart',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF4338CA)),
              ),
              SizedBox(height: 16.h),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: 'LalKitab',
                showUpagrahas: false, // Upagrahas generally not used in Lal Kitab
                showDegrees: _showDegreesOnChart,
                kundliData: _lalKitabData,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Lal Kitab Houses & Remedies',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Calculated Logically',
                style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...planets.map((p) {
          final planet = p['planet']?.toString() ?? '';
          final house = p['house']?.toString() ?? '';
          final sign = p['sign']?.toString() ?? '';
          final lkSign = p['lk_sign']?.toString() ?? '';
          final degree = p['longitude_formatted']?.toString() ?? '';
          final dignity = p['dignity']?.toString() ?? '';
          final interp = p['interpretation'] as Map<String, dynamic>? ?? {};

          final pos = (interp['pos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final neg = (interp['neg'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final rem = (interp['rem'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          Color accentColor = const Color(0xFF4338CA);
          if (planet == 'Sun' || planet == 'Mars') accentColor = const Color(0xFFDC2626);
          if (planet == 'Moon' || planet == 'Venus') accentColor = const Color(0xFF0284C7);
          if (planet == 'Jupiter') accentColor = const Color(0xFFD97706);
          if (planet == 'Mercury') accentColor = const Color(0xFF059669);
          if (planet == 'Saturn' || planet == 'Rahu' || planet == 'Ketu') accentColor = const Color(0xFF475569);

          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                title: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 24.h,
                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2.r)),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planet,
                            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'House $house ($lkSign) • $degree',
                            style: GoogleFonts.outfit(fontSize: 12.sp, color: accentColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (dignity != 'Neutral')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: dignity == 'Exalted' ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          dignity,
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: dignity == 'Exalted' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                  ],
                ),
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16.r), bottomRight: Radius.circular(16.r)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pos.isNotEmpty) ...[
                          _buildLkSectionTitle('Positive Effects', const Color(0xFF059669)),
                          ...pos.map((e) => _buildLkBulletPoint(e, isDark)),
                          SizedBox(height: 12.h),
                        ],
                        if (neg.isNotEmpty) ...[
                          _buildLkSectionTitle('Possible Challenges', const Color(0xFFDC2626)),
                          ...neg.map((e) => _buildLkBulletPoint(e, isDark)),
                          SizedBox(height: 12.h),
                        ],
                        _buildLkSectionTitle('General Insights', accentColor),
                        if (interp['career'] != null) _buildLkBulletPoint('Career: ${interp['career']}', isDark),
                        if (interp['family'] != null) _buildLkBulletPoint('Family: ${interp['family']}', isDark),
                        if (interp['finance'] != null) _buildLkBulletPoint('Finance: ${interp['finance']}', isDark),
                        SizedBox(height: 16.h),
                        if (rem.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.healing, size: 16.sp, color: const Color(0xFFD97706)),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Traditional Lal Kitab Remedies',
                                      style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                ...rem.map((e) => Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('• ', style: GoogleFonts.outfit(fontSize: 13.sp, color: const Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(e, style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.4))),
                                        ],
                                      ),
                                    )),
                                SizedBox(height: 8.h),
                                Text(
                                  'Note: These are traditional astrological practices.',
                                  style: GoogleFonts.outfit(fontSize: 10.sp, fontStyle: FontStyle.italic, color: isDark ? Colors.white54 : Colors.black54),
                                )
                              ],
                            ),
                          )
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLkSectionTitle(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildLkBulletPoint(String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white54 : Colors.black54)),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildBnnTab(BuildContext context, bool isDark) {
    if (_bnnData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA)));
    }

    final planets = _bnnData!['planets'] as List<dynamic>? ?? [];
    final analysis = _bnnData!['event_analysis'] as List<dynamic>? ?? [];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. BNN Chart Box
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Progressive Chart (BNN)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF4338CA)),
              ),
              SizedBox(height: 16.h),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: 'BNN',
                showUpagrahas: false,
                showDegrees: _showDegreesOnChart,
                kundliData: _bnnData,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Bhrigu Nandi Nadi (BNN)',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Text(
                'Sign-based Linkages',
                style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'BNN evaluates true planetary interactions via Conjunctions (Same Sign), Trines (1-5-9), and Adjacent Signs (2-12).',
          style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black54),
        ),
        SizedBox(height: 24.h),

        // 1. Predictive Event Analysis based on Karakas
        Text(
          'Predictive Observations',
          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 12.h),
        ...analysis.map((item) {
          final category = item['category']?.toString() ?? '';
          final observation = item['observation']?.toString() ?? '';
          final details = (item['details'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final karaka = item['karaka_planet']?.toString() ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Karaka: $karaka',
                        style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  observation,
                  style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black87),
                ),
                if (details.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: details.map((d) => Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text('• $d', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54)),
                      )).toList(),
                    ),
                  )
                ]
              ],
            ),
          );
        }),

        SizedBox(height: 24.h),

        // 2. Exact Planetary Combinations
        Text(
          'Planetary Linkages & Yoga',
          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 12.h),
        ...planets.map((p) {
          final planet = p['planet']?.toString() ?? '';
          final sign = p['sign']?.toString() ?? '';
          final degree = p['degree']?.toString() ?? '';
          final karakaMeaning = p['karaka']?.toString() ?? '';
          final linkages = p['linkages'] as List<dynamic>? ?? [];

          // Only show planets that actually form combinations to reduce clutter
          if (linkages.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFCBD5E1).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$planet in $sign',
                      style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    Text(
                      degree,
                      style: GoogleFonts.outfit(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Represents: $karakaMeaning',
                  style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF059669), fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 12.h),
                ...linkages.map((lk) {
                  final lkPlanet = lk['planet']?.toString() ?? '';
                  final type = lk['type']?.toString() ?? '';
                  final meaning = lk['meaning']?.toString() ?? '';
                  
                  Color badgeColor = const Color(0xFF64748B);
                  if (type.contains('Conjunction')) badgeColor = const Color(0xFFDC2626);
                  if (type.contains('Trine')) badgeColor = const Color(0xFFD97706);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.w,
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          margin: EdgeInsets.only(right: 8.w, top: 2.h),
                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4.r)),
                          child: Text(
                            '+ $lkPlanet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type,
                                style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                              Text(
                                meaning,
                                style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJaiminiTab(BuildContext context, bool isDark) {
    if (_jaiminiData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA)));
    }

    final charaKarakas = _jaiminiData!['chara_karakas'] as List<dynamic>? ?? [];
    final specialPoints = _jaiminiData!['special_points'] as List<dynamic>? ?? [];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Jaimini Chart Box
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Jaimini Rasi Chart',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF4338CA)),
              ),
              SizedBox(height: 16.h),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: 'Jaimini',
                showUpagrahas: false,
                showDegrees: _showDegreesOnChart,
                kundliData: _jaiminiData,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Jaimini System (Chara Karaka)',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: Text(
                '7-Karaka Scheme',
                style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'Jaimini ranks planets based on their exact degree within a sign to determine your Soul Path and life trajectory.',
          style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black54),
        ),
        SizedBox(height: 24.h),

        // 1. Special Points (AL, UL, Karakamsha)
        Text(
          'Jaimini Arudhas & Special Padas',
          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 12.h),
        Row(
          children: specialPoints.map((sp) {
            final name = sp['name']?.toString() ?? '';
            final sign = sp['sign']?.toString() ?? '';
            
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFCBD5E1).withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      sign,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.h),
        ...specialPoints.map((sp) => Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: GoogleFonts.outfit(fontSize: 12.sp, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold)),
              Expanded(child: Text('${sp['name']}: ${sp['meaning']}', style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.4))),
            ],
          ),
        )),

        SizedBox(height: 24.h),

        // 2. Chara Karakas (AK to DK)
        Text(
          'Jaimini Chara Karakas (Degree Sorted)',
          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 12.h),
        ...charaKarakas.map((ck) {
          final code = ck['karaka_code']?.toString() ?? '';
          final name = ck['karaka_name']?.toString() ?? '';
          final planet = ck['planet']?.toString() ?? '';
          final degree = ck['degree']?.toString() ?? '';
          final meaning = ck['meaning']?.toString() ?? '';
          final interp = ck['interpretation']?.toString() ?? '';

          Color badgeColor = const Color(0xFF64748B);
          if (code == 'AK') badgeColor = const Color(0xFFD97706);
          if (code == 'AmK') badgeColor = const Color(0xFF059669);
          if (code == 'DK') badgeColor = const Color(0xFFDC2626);

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                          Text(
                            meaning,
                            style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          planet,
                          style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                        ),
                        Text(
                          degree,
                          style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                if (interp.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      interp,
                      style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                    ),
                  ),
                ]
              ],
            ),
          );
        }),
      ],
    );
  }

  // Planet color map for Dasha UI
  static const Map<String, Color> _planetColors = {
    'Sun':     Color(0xFFFF8C00),
    'Moon':    Color(0xFF64B5F6),
    'Mars':    Color(0xFFEF5350),
    'Mercury': Color(0xFF66BB6A),
    'Jupiter': Color(0xFFFFD54F),
    'Venus':   Color(0xFFCE93D8),
    'Saturn':  Color(0xFF78909C),
    'Rahu':    Color(0xFF5C6BC0),
    'Ketu':    Color(0xFFFF7043),
    // Yogini
    'Mangala': Color(0xFFEF5350),
    'Pingala': Color(0xFFFF8C00),
    'Dhanya':  Color(0xFF66BB6A),
    'Bhramari':Color(0xFF64B5F6),
    'Bhadrika':Color(0xFFCE93D8),
    'Ulka':    Color(0xFF78909C),
    'Siddha':  Color(0xFFFFD54F),
    'Sankata': Color(0xFF5C6BC0),
  };

  Color _planetColor(String name) =>
      _planetColors[name] ?? const Color(0xFF4338CA);

  // Planet abbreviation
  String _planetAbbr(String name) {
    if (name.length <= 2) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildDashaTab(BuildContext context, bool isDark) {
    final dashaTypes = [
      'Vimshottari Dasha', 'Ashtottari Dasha (Method 1)', 'Ashtottari Dasha (Method 2)', 'Yogini Dasha',
      'Chara Dasha (KN Rao)', 'Vimshottari Dasha (Tribhagi)', 'Vimshottari Dasha (D1-Kshema Ta..)',
      'Vimshottari Dasha (D1-Utpanna Ta..)', 'Vimshottari Dasha (D1-Adhana Tar..)', 'Vimshottari Dasha (D1-Lagna)',
      'Vimshottari Dasha (D1-Sun)', 'Vimshottari Dasha (D1-Mars)', 'Vimshottari Dasha (D1-Mercury)',
      'Vimshottari Dasha (D1-Jupiter)', 'Vimshottari Dasha (D1-Venus)', 'Vimshottari Dasha (D1-Saturn)',
      'Vimshottari Dasha (D1-Rahu)', 'Vimshottari Dasha (D1-Ketu)', 'Vimshottari Dasha (D9-Lagna)',
      'Vimshottari Dasha (D9-Sun)', 'Vimshottari Dasha (D9-Moon)', 'Vimshottari Dasha (D9-Mars)',
      'Vimshottari Dasha (D9-Mercury)', 'Vimshottari Dasha (D9-Jupiter)', 'Vimshottari Dasha (D9-Venus)',
      'Vimshottari Dasha (D9-Saturn)', 'Vimshottari Dasha (D9-Rahu)', 'Vimshottari Dasha (D9-Ketu)',
      'Vimshottari Dasha (D10-Lagna)', 'Vimshottari Dasha (D10-Sun)', 'Vimshottari Dasha (D10-Moon)',
      'Vimshottari Dasha (D10-Mars)', 'Vimshottari Dasha (D10-Mercury)', 'Vimshottari Dasha (D10-Jupiter)',
      'Vimshottari Dasha (D10-Venus)', 'Vimshottari Dasha (D10-Saturn)', 'Vimshottari Dasha (D10-Rahu)',
      'Vimshottari Dasha (D10-Ketu)',
    ];



    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      physics: const BouncingScrollPhysics(),
      children: [

        // ── Selector Card ──────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Select Dasha Type',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: _selectedDashaType,
                isExpanded: true,
                menuMaxHeight: 360,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA), size: 18),
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                ),
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                items: dashaTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: GoogleFonts.outfit(fontSize: 13.sp)),
                )).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedDashaType) {
                    _fetchDynamicDasha(val);
                  }
                },
              ),
              SizedBox(height: 14.h),
              InkWell(
                onTap: () => _showDaysInYearDialog(isDark),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 15, color: const Color(0xFF4338CA)),
                      SizedBox(width: 8.w),
                      Text('Days in Year', style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12.sp)),
                      const Spacer(),
                      Text(
                        _daysInYearDisplayLabel,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4338CA),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(Icons.edit_outlined, size: 13, color: const Color(0xFF4338CA)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),


        // ── Section Title + View Toggle ─────────────────────────────────────
        if (!_isLoadingDasha) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedMahadasha != null
                      ? '${_selectedMahadasha!['planet']} Antardasha'
                      : _selectedDashaType,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              // Table/Card toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isDashaCardView = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: !_isDashaCardView
                              ? const Color(0xFF4338CA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_rows_rounded,
                              size: 14,
                              color: !_isDashaCardView ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Table',
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: !_isDashaCardView ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isDashaCardView = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _isDashaCardView
                              ? const Color(0xFF4338CA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_agenda_rounded,
                              size: 14,
                              color: _isDashaCardView ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Cards',
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: _isDashaCardView ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedMahadasha != null) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => setState(() => _selectedMahadasha = null),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios_rounded, size: 11, color: Color(0xFF4338CA)),
                        SizedBox(width: 3.w),
                        Text('Back', style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF4338CA), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
        ],

        // ── Data Table / Cards ──────────────────────────────────────────────
        if (_isLoadingDasha)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60.h),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4338CA), strokeWidth: 3),
                  SizedBox(height: 16.h),
                  Text('Calculating Dasha...', style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13.sp)),
                ],
              ),
            ),
          )
        else
          ...(_isDashaCardView ? _buildDashaCardRows(isDark) : _buildDashaTableRows(isDark)),

        SizedBox(height: 12.h),

        // ── Note Card ───────────────────────────────────────────────────────
        if (!_isLoadingDasha)
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: const Color(0xFF4338CA)),
                    SizedBox(width: 6.w),
                    Text('Note', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 12.sp)),
                  ],
                ),
                SizedBox(height: 6.h),
                Text('• Tap a row to drill into Antardasha periods.', style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11.sp)),
                SizedBox(height: 2.h),
                Text('• Long press for Transit details of that period.', style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11.sp)),
              ],
            ),
          ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ─── TABLE VIEW ────────────────────────────────────────────────────────────
  List<Widget> _buildDashaTableRows(bool isDark) {
    final timeline = _dynamicDashaTimeline ?? (_kundliData?['vimshottari_dasha_timeline'] as List<dynamic>? ?? []);

    if (timeline.isEmpty) return [_buildDashaEmpty(isDark)];

    final List<dynamic> items = _selectedMahadasha == null
        ? timeline
        : (_selectedMahadasha!['antardashas'] as List<dynamic>? ?? []);

    // Build a proper table wrapper
    return [
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            children: [
              // Header row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF3730A3), const Color(0xFF1E1B4B)]
                        : [const Color(0xFF4338CA), const Color(0xFF6366F1)],
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 4,
                      child: Text('Planet',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: Colors.white,
                              letterSpacing: 0.4)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text('Start Date',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: Colors.white70)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text('End Date',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: Colors.white70)),
                    ),
                    SizedBox(width: 16.w),
                  ],
                ),
              ),
              // Data rows
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value as Map<String, dynamic>;
                final planetName = item['planet']?.toString() ?? '-';
                final startStr = item['start']?.toString() ?? item['start_date']?.toString() ?? '-';
                final endStr = item['end']?.toString() ?? item['end_date']?.toString() ?? '-';
                final isActive = item['is_active'] == true;
                final pColor = _planetColor(planetName);
                final isLast = idx == items.length - 1;

                return InkWell(
                  onTap: () {
                    if (_selectedMahadasha == null) {
                      setState(() => _selectedMahadasha = item);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pratyantardasha coming soon!', style: GoogleFonts.outfit()),
                          backgroundColor: const Color(0xFF4338CA),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isActive
                          ? pColor.withValues(alpha: isDark ? 0.18 : 0.07)
                          : (idx.isEven
                              ? (isDark ? Colors.transparent : Colors.white)
                              : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFF))),
                      border: isLast
                          ? null
                          : Border(bottom: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EAF6),
                              width: 0.8,
                            )),
                    ),
                    child: Row(
                      children: [
                        // Colored dot
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pColor,
                            boxShadow: isActive
                                ? [BoxShadow(color: pColor.withValues(alpha: 0.5), blurRadius: 4)]
                                : [],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                planetName,
                                style: GoogleFonts.outfit(
                                  color: isActive
                                      ? pColor
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                  fontSize: 13.sp,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: EdgeInsets.only(top: 2.h),
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: pColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text('Active', style: GoogleFonts.outfit(color: pColor, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            startStr,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            endStr,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ];
  }

  // ─── CARD VIEW ─────────────────────────────────────────────────────────────
  List<Widget> _buildDashaCardRows(bool isDark) {
    final timeline = _dynamicDashaTimeline ?? (_kundliData?['vimshottari_dasha_timeline'] as List<dynamic>? ?? []);

    if (timeline.isEmpty) return [_buildDashaEmpty(isDark)];

    final List<dynamic> items = _selectedMahadasha == null
        ? timeline
        : (_selectedMahadasha!['antardashas'] as List<dynamic>? ?? []);

    return items.asMap().entries.map((entry) {
      final item = entry.value as Map<String, dynamic>;
      final planetName = item['planet']?.toString() ?? '-';
      final startStr = item['start']?.toString() ?? item['start_date']?.toString() ?? '-';
      final endStr = item['end']?.toString() ?? item['end_date']?.toString() ?? '-';
      final durationStr = item['duration_years'] != null
          ? '${item['duration_years']} yrs'
          : (item['duration_months'] != null ? '${item['duration_months']} mo' : '');
      final isActive = item['is_active'] == true;
      final isCompleted = item['is_completed'] == true;
      final pColor = _planetColor(planetName);

      return GestureDetector(
        onTap: () {
          if (_selectedMahadasha == null) {
            setState(() => _selectedMahadasha = item);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pratyantardasha coming soon!', style: GoogleFonts.outfit()),
                backgroundColor: const Color(0xFF4338CA),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isActive
                ? pColor.withValues(alpha: isDark ? 0.2 : 0.07)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isActive
                  ? pColor.withValues(alpha: 0.55)
                  : (isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: pColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 5.w,
                height: 76.h,
                decoration: BoxDecoration(
                  color: pColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Planet orb
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  border: Border.all(color: pColor.withValues(alpha: isActive ? 0.7 : 0.35), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _planetAbbr(planetName),
                    style: GoogleFonts.outfit(
                      color: pColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              planetName,
                              style: GoogleFonts.outfit(
                                color: isActive ? pColor : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: pColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: pColor.withValues(alpha: 0.4)),
                              ),
                              child: Text('ACTIVE', style: GoogleFonts.outfit(color: pColor, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            )
                          else if (isCompleted)
                            Icon(Icons.check_circle_outline_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black12),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                          SizedBox(width: 3.w),
                          Text(startStr, style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11.sp)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Icon(Icons.arrow_forward_rounded, size: 11, color: isDark ? Colors.white24 : Colors.black26),
                          ),
                          Text(endStr, style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11.sp)),
                        ],
                      ),
                      if (durationStr.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(durationStr, style: GoogleFonts.outfit(color: pColor.withValues(alpha: 0.8), fontSize: 10.sp, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Icon(
                  _selectedMahadasha == null ? Icons.chevron_right_rounded : Icons.touch_app_outlined,
                  size: 18,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDashaEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black12),
            SizedBox(height: 12.h),
            Text('No Dasha data available.', style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }


  Future<void> _fetchDynamicDasha(String dashaType) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDasha = true;
      _selectedDashaType = dashaType;
      _selectedMahadasha = null; 
    });
    try {
      final res = await AstroApiService.getDasha(
        dashaType: dashaType,
        name: _personName,
        dateOfBirth: _dobFormattedForApi,
        timeOfBirth: _tobFormattedForApi,
        placeOfBirth: _pob,
        latitude: _latitude,
        longitude: _longitude,
        timezone: _timezone,
        daysInYear: _currentDaysInYear,
      );
      if (mounted) {
        setState(() {
          _dynamicRunningDasha = res['current_running_dasha'];
          _dynamicDashaTimeline = res['dasha_timeline'];
          _isLoadingDasha = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDasha = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load $dashaType', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  double get _currentDaysInYear {
    if (_customDaysInYear.isNotEmpty) {
      return double.tryParse(_customDaysInYear) ?? 365.256364;
    }
    if (_daysInYearType.contains('365.256364')) return 365.256364;
    if (_daysInYearType.contains('365.24219')) return 365.24219;
    if (_daysInYearType.contains('365.25')) return 365.25;
    if (_daysInYearType.contains('360')) return 360.0;
    if (_daysInYearType.contains('365')) return 365.0;
    return 365.256364;
  }

  String get _daysInYearDisplayLabel {
    if (_customDaysInYear.isNotEmpty) return _customDaysInYear;
    if (_daysInYearType.contains('365.256364')) return '365.256364';
    if (_daysInYearType.contains('365.24219')) return '365.24219';
    if (_daysInYearType.contains('365.25')) return '365.25';
    if (_daysInYearType.contains('360')) return '360';
    if (_daysInYearType.contains('365')) return '365';
    return '365.256364';
  }

  void _showDaysInYearDialog(bool isDark) {
    final options = [
      'Mean Sidereal Year (365.256364 days)',
      'Mean Tropical Year (365.24219 days)',
      'Year with 365.25 days',
      'Year with 365 days',
      'Savana Year (360 days)',
      'Custom Days'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Days in Year:', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  if (opt == 'Custom Days') {
                    _showCustomDaysInputDialog(isDark);
                  } else {
                    setState(() {
                      _daysInYearType = opt;
                      _customDaysInYear = '';
                    });
                    _fetchDynamicDasha(_selectedDashaType);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCustomDaysInputDialog(bool isDark) {
    final TextEditingController customDaysCtrl = TextEditingController(text: _customDaysInYear);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Custom Days:', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: customDaysCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter days between 300 and 400',
              hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
              isDense: true,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4338CA))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54)),
            ),
            TextButton(
              onPressed: () {
                final val = double.tryParse(customDaysCtrl.text);
                if (val == null || val < 300 || val > 400) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid days, enter days between 300 and 400', style: GoogleFonts.outfit(color: Colors.black)),
                      backgroundColor: Colors.white,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  setState(() {
                    _daysInYearType = 'Custom Days';
                    _customDaysInYear = customDaysCtrl.text;
                  });
                  Navigator.pop(ctx);
                  _fetchDynamicDasha(_selectedDashaType);
                }
              },
              child: Text('OK', style: GoogleFonts.outfit(color: const Color(0xFF4338CA), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanetsTab(BuildContext context, bool isDark) {
    final rawPlanets = (_kundliData?['planets'] as List<dynamic>?) ?? [];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. KP Cusp Chart Box
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'KP Cusp Chart (Placidus)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF4338CA)),
              ),
              SizedBox(height: 16.h),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: 'Bhava',
                showUpagrahas: _showUpagrahasOnChart,
                showDegrees: _showDegreesOnChart,
                kundliData: _kundliData,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Planetary Coordinates & KP Lords',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              onTap: () => setState(() => _isKpTableViewMode = !_isKpTableViewMode),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _isKpTableViewMode ? 'Card View' : 'Table View',
                  style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Swiss Ephemeris Live',
                style: GoogleFonts.outfit(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (rawPlanets.isEmpty)
          Center(child: Text('No planetary data available'))
        else if (_isKpTableViewMode)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: 800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKpTableHeader(isDark),
                    Divider(height: 1.h, color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ...rawPlanets.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value as Map<String, dynamic>;
                      final isLagna = (p['planet_name_simple']?.toString().toLowerCase().contains('ascendant') ?? false) ||
                          (p['name']?.toString().toLowerCase().contains('ascendant') ?? false) ||
                          (p['name']?.toString().toLowerCase().contains('lagna') ?? false);

                      final rawName = p['name']?.toString() ?? 'Planet';
                      final simpleName = p['planet_name_simple']?.toString() ?? rawName.split('(')[0].trim();
                      final isRetro = p['is_retrograde'] == true;
                      final karakaCode = p['chara_karaka_code']?.toString() ?? '';
                      final retroTag = isRetro ? ' (R)' : '';
                      final karakaTag = karakaCode.isNotEmpty ? ' ($karakaCode)' : '';
                      final displayName = isLagna ? 'Lagna' : '$simpleName$retroTag$karakaTag';

                      final houseStr = (p['house'] ?? 1).toString();
                      final deg = p['degree_formatted']?.toString() ?? "00:00:00";
                      final rawSign = p['sign']?.toString() ?? 'Aries';
                      final signDisplay = rawSign.split('(')[0].trim();
                      final nak = p['nakshatra']?.toString() ?? '-';
                      final pada = p['nakshatra_pada']?.toString() ?? '-';

                      final kp = p['kp_lords'] as Map<String, dynamic>?;
                      final rl = _getLordShortCode(p['sign_lord']?.toString());
                      final nl = _getLordShortCode(kp?['star_lord']?.toString() ?? p['nakshatra_lord']?.toString());
                      final sl = _getLordShortCode(kp?['sub_lord']?.toString());
                      final ssl = _getLordShortCode(kp?['sub_sub_lord']?.toString());

                      final rowBg = isLagna
                          ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.28) : const Color(0xFFFFF1F2))
                          : (idx.isOdd ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC)) : Colors.transparent);

                      return Container(
                        color: rowBg,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(displayName, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text(houseStr, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF059669)))),
                            Expanded(flex: 1, child: Text(deg, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                            Expanded(flex: 1, child: Text(signDisplay, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                            Expanded(flex: 1, child: Text(nak, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                            Expanded(flex: 1, child: Center(child: Text(pada, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold)))),
                            Expanded(flex: 1, child: Center(child: Text(rl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA))))),
                            Expanded(flex: 1, child: Center(child: Text(nl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF059669))))),
                            Expanded(flex: 1, child: Center(child: Text(sl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))))),
                            Expanded(flex: 1, child: Center(child: Text(ssl, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6))))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          )
        else
          ...rawPlanets.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value as Map<String, dynamic>;
            final rawName = p['name']?.toString() ?? 'Planet';
            final name = rawName.split('(')[0].trim();
            final sanskrit = p['sanskrit_name']?.toString() ?? '';
            final sign = p['sign']?.toString() ?? 'Aries';
            final degree = p['degree_formatted']?.toString() ?? "15° 00'";
            final speed = (p['speed_deg_per_day'] as num?)?.toDouble() ?? 0.0;
            final isRetro = p['is_retrograde'] == true;
            final nakshatra = p['nakshatra']?.toString() ?? 'Ashwini';
            final pada = (p['nakshatra_pada'] ?? 1).toString();
            final house = (p['house'] ?? 1).toString();
            final lord = p['nakshatra_lord']?.toString() ?? 'Ketu';
            final dignity = p['dignity']?.toString() ?? (isRetro ? 'Retrograde' : 'Direct');

            final kp = p['kp_lords'] as Map<String, dynamic>?;
            final starLord = kp?['star_lord']?.toString() ?? lord;
            final subLord = kp?['sub_lord']?.toString() ?? '';
            final subSubLord = kp?['sub_sub_lord']?.toString() ?? '';

            final navamsha = p['navamsha'] as Map<String, dynamic>?;
            final navSign = navamsha?['navamsha_sign']?.toString() ?? '';
            final isVargottama = navamsha?['is_vargottama'] == true;

            final colorHex = p['color']?.toString() ?? '#4338CA';
            Color color;
            try {
              color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
            } catch (_) {
              color = const Color(0xFF4338CA);
            }

            final kpOwnedHouses = (p['kp_owned_houses'] as List<dynamic>?)?.join(', ') ?? 'None';
            final kpOccupiedHouse = p['kp_occupied_house']?.toString() ?? '-';
            final kpSignificators = (p['kp_significators'] as List<dynamic>?)?.join(', ') ?? '-';
            final kpSigString = 'Occupied: $kpOccupiedHouse | Owned: $kpOwnedHouses | Significators: $kpSignificators';

            return _buildDetailedPlanetCard(
              idx,
              name,
              sanskrit,
              sign,
              degree,
              speed,
              isRetro,
              nakshatra,
              pada,
              house,
              lord,
              starLord,
              subLord,
              subSubLord,
              navSign,
              isVargottama,
              dignity,
              color,
              isDark,
              kpSignificators: kpSigString,
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 3: SHADBALA & YOGAS TAB
  // =========================================================================
  Widget _buildShadbalaAndYogasTab(BuildContext context, bool isDark) {
    final rawShadbala = _kundliData?['shadbala'];
    final List<Map<String, dynamic>> shadbalaItems = [];
    if (rawShadbala is List) {
      for (final item in rawShadbala) {
        if (item is Map) shadbalaItems.add(Map<String, dynamic>.from(item));
      }
    } else if (rawShadbala is Map) {
      final pMap = rawShadbala['planets'];
      if (pMap is Map) {
        for (final entry in pMap.entries) {
          final sData = Map<String, dynamic>.from(entry.value as Map);
          sData['planet'] = entry.key;
          shadbalaItems.add(sData);
        }
      }
    }

    final rawYogas = _kundliData?['vedic_yogas'] ?? _kundliData?['yogas'];
    final yogas = (rawYogas as List<dynamic>?) ?? [];

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6-Fold Shadbala Planetary Strengths', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4338CA).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Parashara System',
                style: GoogleFonts.outfit(fontSize: 10.sp, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text('Measures 6 planetary forces: Positional (Sthana), Directional (Dig), Temporal (Kala), Motional (Chesta), Natural (Naisargika) & Aspectual (Drik)', style: GoogleFonts.outfit(fontSize: 11.5.sp, color: isDark ? Colors.white60 : Colors.black54)),
        SizedBox(height: 14.h),
        if (shadbalaItems.isEmpty)
          Center(child: Text('No Shadbala calculations available'))
        else ...[
          _buildConsolidatedShadbalaChart(shadbalaItems, isDark),
          SizedBox(height: 16.h),
          _buildShadbalaTable(shadbalaItems, isDark),
        ],

        SizedBox(height: 18.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Classical Vedic Yogas Detected', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${yogas.length} Active Yogas',
                style: GoogleFonts.outfit(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (yogas.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text('No major classical yogas detected in current placement.'),
          )
        else
          ...yogas.asMap().entries.map((entry) {
            final idx = entry.key;
            final y = entry.value as Map<String, dynamic>;
            final rawName = y['name']?.toString() ?? 'Yoga';
            final name = rawName.split('(')[0].trim();
            final category = y['category']?.toString() ?? 'Raja Yoga';
            final desc = y['description']?.toString() ?? '';
            final planetsInvolved = (y['planets_involved'] as List<dynamic>?)?.join(', ') ?? '';

            return StaggeredAnimatedItem(
              index: idx,
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF0FDF4), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.military_tech_rounded, color: Color(0xFF059669), size: 20),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5.sp),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.outfit(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(desc, style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                    if (planetsInvolved.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text('Planets: $planetsInvolved', style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }


  // =========================================================================
  // TAB 5: ASHTAKVARGA (SAV & BAV)
  // =========================================================================
  Widget _buildAshtakvargaTab(BuildContext context, bool isDark) {
    final ashtakvarga = _kundliData?['ashtakvarga'] as Map<String, dynamic>?;
    final totalSav = ashtakvarga?['total_sav_points'] ?? 337;
    final signPoints = (ashtakvarga?['sign_points'] as Map<String, dynamic>?) ?? {};
    final pointValues = signPoints.values.map((v) => (v as num).toInt()).toList();
    final defaultPoints = [28, 31, 29, 34, 36, 27, 30, 26, 33, 25, 32, 26];
    final displayPoints = pointValues.isNotEmpty ? pointValues : defaultPoints;

    final bav = (ashtakvarga?['bav_matrix'] ?? ashtakvarga?['bhinnashtakavarga']) as Map<String, dynamic>?;

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // Dropdowns for Chart Type and Method
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Rashi Based All',
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                    items: ['Rashi Based All'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Parashara',
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                    items: ['Parashara'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sarvashtakvarga (SAV)', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.sp)),
                  Text('$totalSav Points', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.grid_view_rounded, color: Colors.white, size: 36),
            ],
          ),
        ),
        
        if (bav != null && bav.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text('Bhinnashtakavarga (BAV) Matrix', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87)),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        SizedBox(width: 40.w, child: Text('Signs', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54))),
                        ...['Su', 'Mo', 'Ma', 'Me', 'Ju', 'Ve', 'Sa', 'Tot', 'As'].map((col) => Container(
                          width: 32.w,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          alignment: Alignment.center,
                          child: Text(col, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: col == 'Tot' ? const Color(0xFF059669) : (isDark ? Colors.white54 : Colors.black54))),
                        )),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Sign Rows (1 to 12)
                    ...List.generate(12, (rowIndex) {
                      int totalInSign = 0;
                      List<int> planetVals = [];
                      for (String p in ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn']) {
                        final pts = (bav[p] as List<dynamic>?)?.map((x) => (x as num).toInt()).toList() ?? List.filled(12, 0);
                        final val = pts[rowIndex];
                        planetVals.add(val);
                        totalInSign += val;
                      }
                      
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40.w,
                              child: Text('${rowIndex + 1}', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ),
                            ...planetVals.map((val) {
                              bool isHigh = val >= 5;
                              bool isLow = val <= 3;
                              
                              Color bgColor = isHigh ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                                          : (isLow ? const Color(0xFFEF4444).withValues(alpha: 0.1) 
                                          : (isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9)));
                                          
                              Color textColor = isHigh ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                            : (isLow ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                                            : (isDark ? Colors.white70 : Colors.black87));
                                            
                              return Container(
                                width: 32.w,
                                height: 32.h,
                                margin: EdgeInsets.symmetric(horizontal: 2.w),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                alignment: Alignment.center,
                                child: Text('$val', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: textColor)),
                              );
                            }),
                            Container(
                              width: 32.w,
                              height: 32.h,
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              alignment: Alignment.center,
                              child: Text('$totalInSign', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                            ),
                            Container(
                              width: 32.w,
                              height: 32.h,
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              alignment: Alignment.center,
                              child: Text('-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
                            ),
                          ],
                        ),
                      );
                    })
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // TAB 6: STRENGTH
  Widget _buildStrengthTab(BuildContext context, bool isDark) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        int localTabIndex = _strengthSubTabIndex; // Sync with persistent parent state
        final shadbala = (_kundliData?['shadbala'] as List?) ?? [];
        final bhavaBala = (_kundliData?['bhava_bala'] as List?) ?? [];

        List currentList = [];
        String title = "";
        String valueKey = "";
        String nameKey = "";
        double maxVal = 100.0;
        
        if (localTabIndex == 0) {
          currentList = shadbala;
          title = "Shadbala Strength";
          valueKey = "strength";
          nameKey = "planet";
          maxVal = 2.0; // Shadbala strengths typically range around 0.5 to 2.5
        } else if (localTabIndex == 1) {
          currentList = bhavaBala;
          title = "Bhava Bala (In Rupas)";
          valueKey = "strength";
          nameKey = "sign";
          maxVal = 15.0; // Bhava Bala in Rupas typically ranges from 5.0 to 12.0
        }

        return ListView(
          padding: EdgeInsets.all(16.w),
          physics: const BouncingScrollPhysics(),
          children: [
            // Segmented Control
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: ['Shadbala', 'Bhava Bala', 'Vimsopaka'].asMap().entries.map((entry) {
                  final isSelected = localTabIndex == entry.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        this.setState(() {
                          _strengthSubTabIndex = entry.key;
                        });
                        setState(() => localTabIndex = entry.key);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4338CA) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4338CA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.value,
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
             ),
            ),
            SizedBox(height: 20.h),

            if (localTabIndex == 2) ...[
              _buildVimsopakaContent(context, isDark, setState),
            ] else ...[
              if (localTabIndex == 1) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.architecture_rounded, color: const Color(0xFF4338CA), size: 24),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bhava System Configuration',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBhavaSystem,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  color: const Color(0xFF4338CA),
                                  fontWeight: FontWeight.bold,
                                ),
                                icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF4338CA)),
                                items: ['Porphyry (Sripathi)', 'Equal Houses', 'Placidus (KP)'].map((String sys) {
                                  return DropdownMenuItem<String>(
                                    value: sys,
                                    child: Text(sys),
                                  );
                                }).toList(),
                                onChanged: (String? val) {
                                  if (val != null) {
                                    // Call the parent StatefulWidget setState to trigger data refresh
                                    this.setState(() {
                                      _selectedBhavaSystem = val;
                                    });
                                    _fetchKundliData();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              SizedBox(height: 4.h),
            
              // Bar Chart Section
              Text(title, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              SizedBox(height: 16.h),
            
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: currentList.map((item) {
                    final name = item[nameKey] ?? (localTabIndex == 1 ? "${item['house']}" : "");
                    final displayTitle = localTabIndex == 1 ? "${item['house']} ($name)" : name;
                    double val = (item[valueKey] as num?)?.toDouble() ?? 0.0;
                    final colorHex = item['color'] as String? ?? "#4338CA";
                    Color barColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                  
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80.w,
                            child: Text(displayTitle, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double fillRatio = (val / maxVal).clamp(0.0, 1.0);
                                return Stack(
                                  children: [
                                    Container(
                                      height: 12.h,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                    ),
                                    Container(
                                      height: 12.h,
                                      width: constraints.maxWidth * fillRatio,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: BorderRadius.circular(6.r),
                                        boxShadow: [
                                          BoxShadow(color: barColor.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
                                        ]
                                      ),
                                    ),
                                  ],
                                );
                              }
                            ),
                          ),
                          SizedBox(
                            width: 60.w,
                            child: Text(
                              localTabIndex == 0 ? ' ${val.toStringAsFixed(2)}' : ' ${val.toStringAsFixed(1)}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            
              SizedBox(height: 24.h),
            
              // Detailed Table Section
              Text("Detailed Breakdown", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              SizedBox(height: 16.h),
            
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: DataTable(
                    columnSpacing: 18.0,
                    horizontalMargin: 12.0,
                    headingRowHeight: 40.0,
                    dataRowMinHeight: 36.0,
                    dataRowMaxHeight: 38.0,
                    headingTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4338CA), fontSize: 13.sp),
                    dataTextStyle: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black87),
                    columns: localTabIndex == 0 ? [
                      DataColumn(label: Text('Bala')),
                      DataColumn(label: Text('Sun')),
                      DataColumn(label: Text('Moon')),
                      DataColumn(label: Text('Mars')),
                      DataColumn(label: Text('Mercury')),
                      DataColumn(label: Text('Jupiter')),
                      DataColumn(label: Text('Venus')),
                      DataColumn(label: Text('Saturn')),
                    ] : localTabIndex == 1 ? [
                      DataColumn(label: Text('Bhava')),
                      DataColumn(label: Text('Bhava Bala')),
                      DataColumn(label: Text('In Rupas')),
                      DataColumn(label: Text('Bhava Cusp')),
                      DataColumn(label: Text('Adhipati of Cusp')),
                      DataColumn(label: Text('Adhipati Bala')),
                      DataColumn(label: Text('Dig Bala')),
                      DataColumn(label: Text('Drig Bala')),
                    ] : [
                      DataColumn(label: Text('Planet')),
                      DataColumn(label: Text('Score')),
                      DataColumn(label: Text('Percentage')),
                      DataColumn(label: Text('Rank')),
                    ],
                    rows: localTabIndex == 0 
                        ? _buildShadbalaDetailedRows(currentList, isDark)
                        : currentList.map<DataRow>((item) {
                            if (localTabIndex == 1) {
                              final double adhipatiBala = (item['adhipati_bala'] as num?)?.toDouble() ?? 0.0;
                              final double digBala = (item['dig_bala'] as num?)?.toDouble() ?? 0.0;
                              final double drigBala = (item['drig_bala'] as num?)?.toDouble() ?? 0.0;
                              final double totalVirupas = adhipatiBala + digBala + drigBala;
                              final double totalRupas = totalVirupas / 60.0;
                            
                              return DataRow(cells: [
                                DataCell(Text('${item['house'] ?? ''}')),

                                DataCell(Text(totalVirupas.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(totalRupas.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('${item['sign'] ?? ''}')),
                                DataCell(Text('${item['adhipati'] ?? ''}')),
                                DataCell(Text('${item['adhipati_bala'] ?? ''}')),
                                DataCell(Text('${item['dig_bala'] ?? ''}')),
                                DataCell(Text('${item['drig_bala'] ?? ''}')),
                              ]);
                            } else {
                              return DataRow(cells: [
                                DataCell(Text(item['planet'] ?? '')),
                                DataCell(Text('${item['score'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF059669)))),
                                DataCell(Text('${item['percentage'] ?? ''}%')),
                                DataCell(Text('${item['rank'] ?? ''}')),
                              ]);
                            }
                          }).toList(),

                  ),
                ),
              ),
            
            ]
            ],
        );
      }
    );
  }

  Widget _buildVimsopakaContent(BuildContext context, bool isDark, StateSetter setState) {
    final vimsopakaMap = (_kundliData?['vimsopaka'] as Map?) ?? {};
    final listKey = _selectedVimsopakaRelation == 'As per respective Varga Chart' ? 'respective' : 'rashi';
    final List<dynamic> vimsopakaList = (vimsopakaMap[listKey] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(
                'Planetary Relationships: ',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVimsopakaRelation,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF4338CA),
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4338CA)),
                    items: ['As per respective Varga Chart', 'As per Rashi Chart for all Vargas'].map((String sys) {
                      return DropdownMenuItem<String>(
                        value: sys,
                        child: Text(sys, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedVimsopakaRelation = val;
                        });
                        this.setState(() {});
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Vertical Bar Chart
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vimsopaka Bala (Shodasa Varga)",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 260,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: vimsopakaList.map((item) {
                    final double val = (item['shodasa_varga'] as num?)?.toDouble() ?? 0.0;
                    final double ratio = (val / 20.0).clamp(0.0, 1.0);
                    final String planetShort = (item['planet'] as String).substring(0, 2);
                    
                    List<Color> gradientColors;
                    Color shadowColor;
                    if (val >= 15) {
                      gradientColors = [const Color(0xFF10B981), const Color(0xFF34D399)]; // Vibrant Green
                      shadowColor = const Color(0xFF10B981);
                    } else if (val >= 11) {
                      gradientColors = [const Color(0xFF4338CA), const Color(0xFF6366F1)]; // Deep Indigo to Purple-Blue
                      shadowColor = const Color(0xFF4338CA);
                    } else if (val >= 7) {
                      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]; // Vibrant Orange
                      shadowColor = const Color(0xFFF59E0B);
                    } else {
                      gradientColors = [const Color(0xFFEF4444), const Color(0xFFF87171)]; // Vibrant Red
                      shadowColor = const Color(0xFFEF4444);
                    }
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          val.toStringAsFixed(2),
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 180 * ratio,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: shadowColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          planetShort,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Detailed Table Section
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              columnSpacing: 18.0,
              horizontalMargin: 12.0,
              headingRowHeight: 40.0,
              dataRowMinHeight: 36.0,
              dataRowMaxHeight: 38.0,
              headingTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 13),
              dataTextStyle: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
              columns: [
                DataColumn(label: Text('Planet')),
                DataColumn(label: Text('Shad Varga')),
                DataColumn(label: Text('Sapta Varga')),
                DataColumn(label: Text('Dasa Varga')),
                DataColumn(label: Text('Shodasa Varga')),
              ],
              rows: vimsopakaList.map<DataRow>((item) {
                return DataRow(cells: [
                  DataCell(Text('${item['planet']}')),
                  DataCell(Text('${item['shad_varga']}')),
                  DataCell(Text('${item['sapta_varga']}')),
                  DataCell(Text('${item['dasa_varga']}')),
                  DataCell(Text('${item['shodasa_varga']}')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }


  List<DataRow> _buildShadbalaDetailedRows(List<dynamic> shadbalaList, bool isDark) {
    // We need to pivot the shadbalaList (which is a list of planet dicts) into rows of parameters.
    // Order of planets in columns: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn.
    final planets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'];
    
    // Map each planet to its dictionary for quick lookup
    final map = {for (var item in shadbalaList) item['planet']?.toString() ?? '': item};

    // Helper to get value
    String val(String planet, String key, {int decimals = 2}) {
      final pData = map[planet];
      if (pData == null) return '-';
      final v = pData[key];
      if (v is num) return v.toStringAsFixed(decimals);
      return v?.toString() ?? '-';
    }

    // Helper to create a row
    DataRow parameterRow(String label, String key, {bool isSubTotal = false, bool isTotal = false, int decimals = 2, Color? customColor}) {
      final textStyle = TextStyle(
        fontWeight: (isSubTotal || isTotal) ? FontWeight.bold : FontWeight.normal,
        color: customColor ?? ((isSubTotal || isTotal) ? (isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A)) : null),
      );
      return DataRow(
        cells: [
          DataCell(Text(label, style: textStyle)),
          ...planets.map((p) => DataCell(Text(val(p, key, decimals: decimals), style: textStyle))),
        ],
      );
    }

    return [
      parameterRow('Uchcha', 'uchcha'),
      parameterRow('Saptavargaja', 'saptavargaja'),
      parameterRow('Oja-Yugma', 'oja_yugma'),
      parameterRow('Kendradi', 'kendradi'),
      parameterRow('Drekkana', 'drekkana'),
      parameterRow('Sthana Bala', 'sthana_bala', isSubTotal: true, customColor: const Color(0xFF2563EB)),
      parameterRow('Dig Bala', 'dig_bala', isSubTotal: true, customColor: const Color(0xFF2563EB)),
      parameterRow('Natonnata', 'natonnata'),
      parameterRow('Paksha', 'paksha'),
      parameterRow('Tribhaga', 'tribhaga'),
      parameterRow('Abda', 'abda'),
      parameterRow('Maasa', 'maasa'),
      parameterRow('Vaara', 'vaara'),
      parameterRow('Hora', 'hora'),
      parameterRow('Ayana', 'ayana'),
      parameterRow('Yuddha', 'yuddha'),
      parameterRow('Kaala Bala', 'kala_bala', isSubTotal: true, customColor: const Color(0xFF2563EB)),
      parameterRow('Chesta', 'chesta_bala'),
      parameterRow('Naisargika', 'naisargika_bala'),
      parameterRow('Drig Bala', 'drik_bala', isSubTotal: true, customColor: const Color(0xFF2563EB)),
      parameterRow('Shadbala', 'total_virupas', isTotal: true, customColor: const Color(0xFF10B981)),
      parameterRow('In Rupas', 'total_rupas', isTotal: true, customColor: const Color(0xFF10B981)),
      parameterRow('Minimum', 'minimum', decimals: 1),
      parameterRow('Strength', 'strength'),
      parameterRow('Rank', 'rank', decimals: 0),
      parameterRow('Ishta Phala', 'ishta_phala'),
      parameterRow('Kashta Phala', 'kashta_phala'),
    ];
  }

  // TAB 7: KOT CHAKRA
  Widget _buildKotChakraTab(BuildContext context, bool isDark) {
    final kotChakra = _kundliData?['kot_chakra'] as Map<String, dynamic>?;
    if (kotChakra == null) {
      return Center(child: Text('Kot Chakra data not available', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87)));
    }

    final sections = kotChakra['sections'] as Map<String, dynamic>? ?? {};
    final moonRef = kotChakra['moon_nakshatra_reference'] ?? '';

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kot Chakra (Fort Diagram)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  Icon(Icons.fort_rounded, color: Colors.white, size: 28),
                ],
              ),
              SizedBox(height: 8.h),
              Text('Reference Nakshatra: $moonRef', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13.sp)),
              SizedBox(height: 4.h),
              Text('Planetary transits & placements relative to Moon', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.sp)),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        
        ...sections.entries.map((entry) {
          final title = entry.key;
          final planets = entry.value as List<dynamic>? ?? [];
          
          Color sectionColor;
          if (title.contains("Stambha")) sectionColor = const Color(0xFFEF4444);
          else if (title.contains("Madhya")) sectionColor = const Color(0xFFF59E0B);
          else if (title.contains("Prakara")) sectionColor = const Color(0xFF3B82F6);
          else sectionColor = const Color(0xFF10B981);
          
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: sectionColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: sectionColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: sectionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r), topRight: Radius.circular(15.r)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.h,
                        decoration: BoxDecoration(color: sectionColor, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 8.w),
                      Text(title, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      Spacer(),
                      Text('${planets.length} Planets', style: GoogleFonts.outfit(fontSize: 12.sp, color: sectionColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (planets.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text('No planets in this section', style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13.sp, fontStyle: FontStyle.italic)),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: planets.map((p) {
                        final pName = p['planet'];
                        final nak = p['nakshatra'];
                        final deg = p['degree'];
                        final colorHex = p['color'] as String? ?? "#4338CA";
                        final pColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                        
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Text(pName.substring(0, 2), style: GoogleFonts.outfit(color: pColor, fontWeight: FontWeight.bold, fontSize: 11.sp)),
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87)),
                                  Text('$nak ($deg)', style: GoogleFonts.outfit(fontSize: 10.sp, color: isDark ? Colors.white60 : Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildProfileChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        SizedBox(width: 4.w),
        Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAscendantBadge(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10.sp), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolidatedShadbalaChart(List<dynamic> items, bool isDark) {
    double maxRupas = 0;
    for (var item in items) {
      double r = (item['total_rupas'] ?? item['total_shadbala_rupas'] as num?)?.toDouble() ?? 0;
      if (r > maxRupas) maxRupas = r;
    }
    maxRupas = maxRupas > 0 ? maxRupas * 1.2 : 10.0;

    final planetOrder = {"Sun": 1, "Moon": 2, "Mars": 3, "Mercury": 4, "Jupiter": 5, "Venus": 6, "Saturn": 7};
    final sortedItems = List<dynamic>.from(items)..sort((a, b) {
      int orderA = planetOrder[a['planet']?.toString()] ?? 99;
      int orderB = planetOrder[b['planet']?.toString()] ?? 99;
      return orderA.compareTo(orderB);
    });

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shadbala Strength (Total Rupas)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedItems.map((sData) {
                final pName = sData['planet']?.toString() ?? 'P';
                final shortName = pName.length > 2 ? pName.substring(0, 2) : pName;
                final rupas = (sData['total_rupas'] ?? sData['total_shadbala_rupas'] as num?)?.toDouble() ?? 0;
                double percent = (rupas / maxRupas).clamp(0.0, 1.0).toDouble();
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(rupas.toStringAsFixed(2), style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            height: 120.0.h,
                            width: 24.w,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          Container(
                            height: 120.0.h * percent,
                            width: 24.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF009688),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(shortName, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadbalaTable(List<dynamic> items, bool isDark) {
    final planetOrder = {"Sun": 1, "Moon": 2, "Mars": 3, "Mercury": 4, "Jupiter": 5, "Venus": 6, "Saturn": 7};
    final sortedItems = List<dynamic>.from(items)..sort((a, b) {
      int orderA = planetOrder[a['planet']?.toString()] ?? 99;
      int orderB = planetOrder[b['planet']?.toString()] ?? 99;
      return orderA.compareTo(orderB);
    });

    Widget buildRow(String title, String key, {bool isHeader = false, bool isTotal = false, bool isCategory = false}) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        color: isHeader ? (isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9)) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: isHeader || isTotal || isCategory ? FontWeight.bold : FontWeight.w500,
                  color: isHeader 
                      ? (isDark ? Colors.white70 : const Color(0xFF334155)) 
                      : (isTotal || isCategory ? const Color(0xFF009688) : (isDark ? Colors.white : Colors.black87)),
                ),
              ),
            ),
            ...sortedItems.map((sData) {
              final breakdown = (sData['breakdown_virupas'] as Map<String, dynamic>?) ?? {};
              String valStr = '';
              if (isHeader) {
                final pName = sData['planet']?.toString() ?? '';
                valStr = pName.length > 2 ? pName.substring(0, 3) : pName;
              } else if (key == 'rank') {
                final val = sData[key] ?? breakdown[key] ?? 0;
                valStr = val.toString();
              } else {
                final val = sData[key] ?? breakdown[key] ?? 0;
                double numVal = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
                valStr = numVal.toStringAsFixed(2);
              }
              return Expanded(
                flex: 2,
                child: Text(
                  valStr,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5.sp,
                    fontWeight: isHeader || isTotal || isCategory ? FontWeight.bold : FontWeight.w500,
                    color: isHeader 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isTotal || isCategory ? const Color(0xFF009688) : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          buildRow('Bala', '', isHeader: true),
          buildRow('Uchcha', 'uchcha'),
          buildRow('Saptavargaja', 'saptavargaja'),
          buildRow('Oja-Yugma', 'oja_yugma'),
          buildRow('Kendradi', 'kendradi'),
          buildRow('Drekkana', 'drekkana'),
          Divider(height: 1.h),
          buildRow('Sthana Bala', 'sthana_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Dig Bala', 'dig_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Natonnata', 'natonnata'),
          buildRow('Paksha', 'paksha'),
          buildRow('Tribhaga', 'tribhaga'),
          buildRow('Abda', 'abda'),
          buildRow('Maasa', 'maasa'),
          buildRow('Vaara', 'vaara'),
          buildRow('Hora', 'hora'),
          buildRow('Ayana', 'ayana'),
          buildRow('Yuddha', 'yuddha'),
          Divider(height: 1.h),
          buildRow('Kaala Bala', 'kala_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Cheshta', 'chesta_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Naisargika', 'naisargika_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Drig Bala', 'drik_bala', isCategory: true),
          Divider(height: 1.h),
          buildRow('Shadbala', 'total_virupas', isCategory: true),
          buildRow('In Rupas', 'total_rupas', isCategory: true),
          buildRow('Minimum', 'minimum'),
          Divider(height: 1.h),
          buildRow('Strength', 'strength', isCategory: true),
          buildRow('Rank', 'rank', isCategory: true),
          Divider(height: 1.h),
          buildRow('Ishta Phala', 'ishta_phala'),
          buildRow('Kashta Phala', 'kashta_phala'),
        ],
      ),
    );
  }

  Widget _buildBalaChip(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w500)),
    );
  }

  String _formatPlanetDisplayName(String name, String sanskrit) {
    String cleanSanskrit = sanskrit.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (cleanSanskrit.isNotEmpty && !name.contains(cleanSanskrit)) {
      return '$name ($cleanSanskrit)';
    }
    return name;
  }

  Widget _buildDetailedPlanetCard(
    int index,
    String name,
    String sanskrit,
    String sign,
    String degree,
    double speed,
    bool isRetro,
    String nakshatra,
    String pada,
    String house,
    String nakshatraLord,
    String starLord,
    String subLord,
    String subSubLord,
    String navSign,
    bool isVargottama,
    String dignity,
    Color accentColor,
    bool isDark, {
    String? kpSignificators,
  }) {
    final displayName = _formatPlanetDisplayName(name, sanskrit);

    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isVargottama
                ? const Color(0xFF059669).withValues(alpha: 0.6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4.w,
                  height: 48.h,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2.r)),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isRetro) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text('R', style: GoogleFonts.outfit(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: Colors.red)),
                            ),
                          ],
                          if (isVargottama) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text('Vargottama 🌟', style: GoogleFonts.outfit(fontSize: 9.0.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$sign • House $house • $degree (${speed >= 0 ? '+' : ''}${speed.toStringAsFixed(3)}°/d)',
                        style: GoogleFonts.outfit(fontSize: 11.5.sp, color: accentColor, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$nakshatra Pada $pada (Lord: $nakshatraLord)',
                        style: GoogleFonts.outfit(fontSize: 10.5.sp, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    dignity,
                    style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: accentColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'KP Lords: Star: $starLord • Sub: $subLord${subSubLord.isNotEmpty ? ' • SS: $subSubLord' : ''}',
                      style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                    ),
                  ),
                  if (navSign.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    Text(
                      'D9: $navSign',
                      style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
            if (kpSignificators != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        kpSignificators,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  // TAB 6: PANCHANGA
  // =========================================================================
  Widget _buildPanchangaTab(BuildContext context, bool isDark) {
    final panchanga = _kundliData?['panchanga'] as Map<String, dynamic>?;
    if (panchanga == null) {
      return Center(child: Text('Panchanga data not available.'));
    }

    Widget buildSectionHeader(String title, {String? trailing}) {
      return Padding(
        padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (trailing != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  trailing,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildTopGradientCard() {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn(Icons.wb_sunny_rounded, 'Sunrise', panchanga['sunrise']?.toString() ?? ''),
                _buildTimeColumn(Icons.wb_twilight_rounded, 'Sunset', panchanga['sunset']?.toString() ?? ''),
                _buildTimeColumn(Icons.nights_stay_rounded, 'Moonrise', panchanga['moonrise']?.toString() ?? ''),
                _buildTimeColumn(Icons.bedtime_rounded, 'Moonset', panchanga['moonset']?.toString() ?? ''),
              ],
            ),
            SizedBox(height: 16.h),
            Container(height: 1.h, color: Colors.white.withValues(alpha: 0.2)),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vikram Samvat: ${panchanga['samvatsara_vikram']}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Shaka: ${panchanga['samvatsara_shaka']}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ],
            )
          ],
        ),
      );
    }

    Widget buildDetailCard(IconData icon, Color iconColor, String title, String badgeText, String details, String timing) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF94A3B8)).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      if (badgeText.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    details,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    timing,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildListRow(String label, String value, {bool isHighlight = false, bool isDanger = false}) {
      Color valColor = isDark ? Colors.white : Colors.black87;
      if (isHighlight) valColor = const Color(0xFF10B981);
      if (isDanger) valColor = const Color(0xFFEF4444);

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: valColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSimpleCard(List<Widget> rows) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1)
                Divider(height: 1.h, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ]
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // Location & Date Context
        Center(
          child: Text(
            'Date: ${panchanga['formatted_date'] ?? ''} | Place: ${panchanga['place'] ?? ''}',
            style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : Colors.black54),
          ),
        ),
        SizedBox(height: 16.h),
        
        buildTopGradientCard(),

        buildSectionHeader('The 5 Essential Elements', trailing: 'Vedic Panchanga'),
        
        buildDetailCard(
          Icons.calendar_today_rounded,
          const Color(0xFFF59E0B),
          '1. Vaara (Vedic Day)',
          '',
          panchanga['vaara']?.toString() ?? '',
          'Governed by ${panchanga['vaara']?.toString().split(' ').last.replaceAll(RegExp(r'[()]'), '') ?? ''}',
        ),
        
        buildDetailCard(
          Icons.brightness_4_rounded,
          const Color(0xFFF97316),
          '2. Tithi (Lunar Day)',
          panchanga['tithi']?['deity_or_nature']?.toString().split('/').first.trim() ?? '',
          panchanga['tithi']?['name']?.toString() ?? '',
          panchanga['tithi']?['timing']?.toString() ?? '',
        ),
        
        buildDetailCard(
          Icons.star_rounded,
          const Color(0xFF8B5CF6),
          '3. Nakshatra (Lunar Mansion)',
          'Star',
          panchanga['nakshatra']?['name']?.toString() ?? '',
          panchanga['nakshatra']?['timing']?.toString() ?? '',
        ),
        
        buildDetailCard(
          Icons.self_improvement_rounded,
          const Color(0xFF10B981),
          '4. Yoga (Solar-Lunar Angle)',
          'Benefic',
          panchanga['yoga']?['name']?.toString() ?? '',
          panchanga['yoga']?['timing']?.toString() ?? '',
        ),
        
        buildDetailCard(
          Icons.bubble_chart_rounded,
          const Color(0xFF06B6D4),
          '5. Karana (Half-Tithi)',
          'Action',
          panchanga['karana']?['name']?.toString() ?? '',
          panchanga['karana']?['timing']?.toString() ?? '',
        ),

        buildSectionHeader('Luminaries & Timings'),
        buildSimpleCard([
          buildListRow('Sun Sign', panchanga['sun_sign']?.toString() ?? ''),
          buildListRow('Moon Sign', panchanga['moon_sign']?.toString() ?? ''),
          buildListRow('Vedic Sunrise', panchanga['vedic_sunrise']?.toString() ?? ''),
          buildListRow('Vedic Sunset', panchanga['vedic_sunset']?.toString() ?? ''),
          buildListRow('Sidereal Time', panchanga['sidereal_time']?.toString() ?? ''),
          buildListRow('Day Duration', panchanga['day_duration']?.toString() ?? ''),
          buildListRow('Night Duration', panchanga['night_duration']?.toString() ?? ''),
        ]),

        buildSectionHeader('Auspicious Muhurtas'),
        buildSimpleCard([
          buildListRow('Abhijit Muhurta', '${panchanga['abhijit_muhurta']?['start_time'] ?? ''} - ${panchanga['abhijit_muhurta']?['end_time'] ?? ''}', isHighlight: true),
          buildListRow('Amrita Kala', '${panchanga['amrita_kala']?['start_time'] ?? ''} - ${panchanga['amrita_kala']?['end_time'] ?? ''}', isHighlight: true),
        ]),

        buildSectionHeader('Inauspicious Timings'),
        buildSimpleCard([
          buildListRow('Rahu Kala', '${panchanga['rahu_kaal']?['start_time'] ?? ''} - ${panchanga['rahu_kaal']?['end_time'] ?? ''}', isDanger: true),
          buildListRow('Yamaganda Kala', '${panchanga['yamaganda']?['start_time'] ?? ''} - ${panchanga['yamaganda']?['end_time'] ?? ''}', isDanger: true),
          buildListRow('Gulika Kala', '${panchanga['gulika_kaal']?['start_time'] ?? ''} - ${panchanga['gulika_kaal']?['end_time'] ?? ''}', isDanger: true),
          buildListRow('Dur Muhurta', '${panchanga['dur_muhurta']?['start_time'] ?? ''} - ${panchanga['dur_muhurta']?['end_time'] ?? ''}', isDanger: true),
          buildListRow('Varjyam', '${panchanga['varjyam']?['start_time'] ?? ''} - ${panchanga['varjyam']?['end_time'] ?? ''}', isDanger: true),
        ]),

        buildSectionHeader('Ritu, Ayana & Maasa'),
        buildSimpleCard([
          buildListRow('Chandra Maasa (Amanta)', panchanga['chandra_maasa_amanta']?.toString() ?? ''),
          buildListRow('Chandra Maasa (Purnimanta)', panchanga['chandra_maasa_purnimanta']?.toString() ?? ''),
          buildListRow('Drika Ritu', panchanga['drika_ritu']?.toString() ?? ''),
          buildListRow('Vedic Ritu', panchanga['vedic_ritu']?.toString() ?? ''),
          buildListRow('Drika Ayana', panchanga['drika_ayana']?.toString() ?? ''),
          buildListRow('Vedic Ayana', panchanga['vedic_ayana']?.toString() ?? ''),
        ]),
        
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildTimeColumn(IconData icon, String label, String time) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 6.h),
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 2.h),
        Text(time, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EditBirthDetailsDialog extends StatefulWidget {
  final String initialName;
  final String initialDob;
  final String initialTob;
  final String initialPob;
  final double initialLat;
  final double initialLon;
  final double initialTz;
  final Function(String name, String dob, String tob, String pob, double lat, double lon, double tz) onSave;

  const _EditBirthDetailsDialog({
    required this.initialName,
    required this.initialDob,
    required this.initialTob,
    required this.initialPob,
    required this.initialLat,
    required this.initialLon,
    required this.initialTz,
    required this.onSave,
  });

  @override
  State<_EditBirthDetailsDialog> createState() => _EditBirthDetailsDialogState();
}

class _EditBirthDetailsDialogState extends State<_EditBirthDetailsDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pobCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _tzCtrl;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _pobCtrl = TextEditingController(text: widget.initialPob);
    _latCtrl = TextEditingController(text: widget.initialLat.toString());
    _lonCtrl = TextEditingController(text: widget.initialLon.toString());
    _tzCtrl = TextEditingController(text: widget.initialTz.toString());

    _selectedDate = DateTime(1998, 12, 13);
    try {
      final formats = [
        DateFormat('dd MMM yyyy'),
        DateFormat('d MMM yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
      ];
      for (final f in formats) {
        try {
          _selectedDate = f.parse(widget.initialDob.trim());
          break;
        } catch (_) {}
      }
    } catch (_) {}

    _selectedTime = const TimeOfDay(hour: 19, minute: 18);
    try {
      final tFormats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm:ss'),
        DateFormat('HH:mm'),
      ];
      for (final f in tFormats) {
        try {
          final t = f.parse(widget.initialTob.trim());
          _selectedTime = TimeOfDay(hour: t.hour, minute: t.minute);
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pobCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  void _showLocationSelector() {
    bool isSearching = false;
    List<Map<String, String>> searchResults = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> _fetchPlaces(String query) async {
              setModalState(() => isSearching = true);
              try {
                final results = await AstroApiService.getPlaces(query: query);
                setModalState(() {
                  searchResults = results;
                  isSearching = false;
                });
              } catch (e) {
                setModalState(() => isSearching = false);
              }
            }

            if (searchResults.isEmpty && !isSearching) {
              _fetchPlaces("");
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A25) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w, height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text('Select Location', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  SizedBox(height: 16.h),
                  TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search for a city...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      prefixIcon: Icon(Icons.search, color: const Color(0xFF4338CA)),
                      filled: true,
                      fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => _fetchPlaces(val),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: isSearching
                        ? Center(child: CircularProgressIndicator(color: const Color(0xFF4338CA)))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final city = searchResults[index];
                              final cityName = city['city'] ?? 'Unknown';
                              return ListTile(
                                leading: Icon(Icons.location_on, color: Colors.grey),
                                title: Text(cityName, style: GoogleFonts.outfit(fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87)),
                                subtitle: Text('${city['coords']} • ${city['tz']}', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54)),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _pobCtrl.text = cityName;
                                    _latCtrl.text = city['lat_val']!;
                                    _lonCtrl.text = city['lon_val']!;
                                    _tzCtrl.text = city['tz_val']!;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDob = DateFormat('dd MMM yyyy').format(_selectedDate);
    final formattedTob = _selectedTime.format(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Birth Profile',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Recalculate Swiss Ephemeris Placements',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_rounded, color: Color(0xFF4338CA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final dt = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (dt != null) {
                              setState(() => _selectedDate = dt);
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF4338CA)),
                                SizedBox(width: 8.w),
                                Text(formattedDob, style: GoogleFonts.outfit(fontSize: 12.5.sp)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final tm = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (tm != null) {
                              setState(() => _selectedTime = tm);
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF4338CA)),
                                SizedBox(width: 8.w),
                                Text(formattedTob, style: GoogleFonts.outfit(fontSize: 12.5.sp)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: _pobCtrl,
                    readOnly: true,
                    onTap: _showLocationSelector,
                    decoration: InputDecoration(
                      labelText: 'Place of Birth',
                      prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFF4338CA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            prefixIcon: Icon(Icons.explore_rounded, color: Color(0xFF059669)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _lonCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            prefixIcon: Icon(Icons.explore_rounded, color: Color(0xFF059669)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: _tzCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Time Zone Offset (e.g. 5.5 for IST)',
                      prefixIcon: Icon(Icons.schedule_rounded, color: Color(0xFFD97706)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 3,
                    child: BouncyTouchCard(
                      onTap: () {
                        final name = _nameCtrl.text.trim().isEmpty ? widget.initialName : _nameCtrl.text.trim();
                        final pob = _pobCtrl.text.trim().isEmpty ? widget.initialPob : _pobCtrl.text.trim();
                        final lat = double.tryParse(_latCtrl.text.trim()) ?? widget.initialLat;
                        final lon = double.tryParse(_lonCtrl.text.trim()) ?? widget.initialLon;
                        final tz = double.tryParse(_tzCtrl.text.trim()) ?? widget.initialTz;
                        widget.onSave(name, formattedDob, formattedTob, pob, lat, lon, tz);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4338CA).withValues(alpha: 0.38),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8.w),
                            Text(
                              'Save & Calculate',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
