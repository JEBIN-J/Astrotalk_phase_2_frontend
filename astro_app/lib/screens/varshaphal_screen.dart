import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kundli_chart_painter.dart';

class VarshaphalScreen extends StatefulWidget {
  final bool isDark;
  final AppColorPalette currentPalette;

  const VarshaphalScreen({
    super.key,
    this.isDark = false,
    this.currentPalette = AppColorPalette.midnightCosmic,
  });

  @override
  State<VarshaphalScreen> createState() => _VarshaphalScreenState();
}

class _VarshaphalScreenState extends State<VarshaphalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Birth details
  String _personName = 'User';
  String _dob = '1998-12-13';
  String _tob = '09:30:00';
  String _pob = 'New Delhi, Delhi, India';
  double _latitude = 28.6139;
  double _longitude = 77.2090;
  double _timezone = 5.5;

  // Varshaphal target year
  int _targetYear = 2026;

  // Return location
  bool _useBirthplaceForReturn = true;
  String _returnPlace = 'New Delhi, Delhi, India';
  double _returnLatitude = 28.6139;
  double _returnLongitude = 77.2090;
  final double _returnTimezone = 5.5;

  // Settings
  final String _selectedAyanamsa = 'LAHIRI';
  final String _selectedHouseSystem = 'Sripathi';
  KundliChartStyle _chartStyle = KundliChartStyle.northIndian;
  String _selectedChartTypeKey = 'D-1';

  // State
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _varshaphalData;

  // Maitri sub-selector: 'compound', 'temporary', 'natural'
  String _maitriMode = 'compound';

  final List<String> _tabTitles = [
    'Overview',
    'Varsh Kundli',
    'Varshesha & Muntha',
    'Strengths',
    'Mudda Dasha',
    'Nav Tara',
    'Graha Maitri',
    'Sahams',
    'Tajika Yogas',
    'Tripataki & Monthly'
  ];

  @override
  void initState() {
    super.initState();
    final profile = GlobalBirthProfile();
    final isStaleHajipur = profile.pob.toLowerCase().contains('hajipur');
    if (profile.isProfileSet && !isStaleHajipur) {
      _personName = profile.personName;
      _dob = AstroApiService.normalizeDate(profile.dob, fallback: profile.currentDateTime);
      _tob = AstroApiService.normalizeTime(profile.tob, fallback: profile.currentDateTime);
      _pob = profile.pob;
      _latitude = profile.latitude;
      _longitude = profile.longitude;
      _timezone = profile.timezone;
      _returnPlace = profile.pob;
      _returnLatitude = profile.latitude;
      _returnLongitude = profile.longitude;
    } else {
      _personName = (profile.personName.isNotEmpty && !isStaleHajipur) ? profile.personName : 'User';
      _dob = AstroApiService.normalizeDate(profile.dob, fallback: profile.currentDateTime);
      _tob = AstroApiService.normalizeTime(profile.tob, fallback: profile.currentDateTime);
      _pob = (profile.pob.isNotEmpty && !isStaleHajipur) ? profile.pob : 'New Delhi, Delhi, India';
      _latitude = (!isStaleHajipur && profile.latitude != 0.0) ? profile.latitude : 28.6139;
      _longitude = (!isStaleHajipur && profile.longitude != 0.0) ? profile.longitude : 77.2090;
      _timezone = profile.timezone != 0.0 ? profile.timezone : 5.5;
      _returnPlace = _pob;
      _returnLatitude = _latitude;
      _returnLongitude = _longitude;
    }
    _targetYear = DateTime.now().year;
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _loadVarshaphal();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVarshaphal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getVarshaphal(
        name: _personName,
        dateOfBirth: _dob,
        timeOfBirth: _tob,
        placeOfBirth: _pob,
        latitude: _latitude,
        longitude: _longitude,
        timezone: _timezone,
        targetYear: _targetYear,
        returnPlace: _useBirthplaceForReturn ? _pob : _returnPlace,
        returnLatitude: _useBirthplaceForReturn ? _latitude : _returnLatitude,
        returnLongitude: _useBirthplaceForReturn ? _longitude : _returnLongitude,
        returnTimezone: _useBirthplaceForReturn ? _timezone : _returnTimezone,
        ayanamsa: _selectedAyanamsa,
        houseSystem: _selectedHouseSystem,
      );

      if (mounted) {
        setState(() {
          _varshaphalData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _targetYear += delta;
    });
    _loadVarshaphal();
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final headerGradient = AppTheme.getHeaderGradient(widget.currentPalette, isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF040133) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: headerGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Varshaphal Kundli',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Birth & Return Details',
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: _showEditConfigDialog,
          ),
          IconButton(
            tooltip: 'Recalculate',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadVarshaphal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(88.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Info & Year Selector Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_rounded, color: const Color(0xFFFFD54F), size: 12.sp),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                '$_personName • $_pob',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Year Selector
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _changeYear(-1),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              '$_targetYear - ${_targetYear + 1}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFFD54F),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.sp,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _changeYear(1),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Segmented TabBar
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 6.h),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    labelColor: const Color(0xFF0F172A),
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelPadding: EdgeInsets.symmetric(horizontal: 14.w),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: _tabTitles.map((title) => Tab(
                      height: 30.h,
                      child: Text(title),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _errorMessage != null
              ? _buildErrorView()
              : _varshaphalData == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildVarshKundliTab(),
                        _buildVarsheshaAndMunthaTab(),
                        _buildStrengthsTab(),
                        _buildMuddaDashaTab(),
                        _buildNavTaraTab(),
                        _buildGrahaMaitriTab(),
                        _buildSahamsTab(),
                        _buildTajikaYogasTab(),
                        _buildTripatakiAndMonthlyTab(),
                      ],
                    ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER SUMMARY CHIPS
  // ---------------------------------------------------------------------------

  Widget _buildTopPraveshaSummaryChips() {
    final pravesha = _varshaphalData?['pravesha_details'] as Map<String, dynamic>? ?? {};
    final muntha = _varshaphalData?['muntha'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildHeaderChip(
            'Pravesh: ${pravesha['date'] ?? ''} ${pravesha['time'] ?? ''}',
            Icons.access_time_filled_rounded,
            const Color(0xFF38BDF8),
          ),
          SizedBox(width: 8.w),
          _buildHeaderChip(
            'Lagna: ${pravesha['varsha_lagna'] ?? ''} (${pravesha['varsha_lagna_degree'] ?? ''})',
            Icons.explore_rounded,
            const Color(0xFF34D399),
          ),
          SizedBox(width: 8.w),
          _buildHeaderChip(
            'Varshesha: ${pravesha['varshesha'] ?? ''}',
            Icons.military_tech_rounded,
            const Color(0xFFFBBF24),
          ),
          SizedBox(width: 8.w),
          _buildHeaderChip(
            'Muntha: ${muntha['sign_name'] ?? ''} (H${muntha['house'] ?? ''})',
            Icons.auto_graph_rounded,
            const Color(0xFFF472B6),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String text, IconData icon, Color color) {
    final isDark = widget.isDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12.sp),
          ),
          SizedBox(width: 7.w),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 11.5.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLE STYLING HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildTableCard({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF312E81) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }

  WidgetStateProperty<Color> _tableHeaderColor(bool isDark) {
    return WidgetStateProperty.all(
      isDark ? const Color(0xFF1E1B4B) : const Color(0xFF312E81),
    );
  }

  TextStyle _tableHeaderStyle(bool isDark) {
    return GoogleFonts.outfit(
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      color: isDark ? const Color(0xFFFFD54F) : Colors.white,
      letterSpacing: 0.2,
    );
  }

  WidgetStateProperty<Color?> _tableRowColor(int index, bool isDark, {bool isSelected = false}) {
    if (isSelected) {
      return WidgetStateProperty.all(
        const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.15),
      );
    }
    return WidgetStateProperty.all(
      index.isEven
          ? (isDark ? Colors.transparent : Colors.white)
          : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
    );
  }

  Widget _buildPlanetCell(String name, {bool isRetro = false, bool isCombust = false, bool isDark = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12.5.sp,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        if (isRetro) ...[
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Text('R', style: TextStyle(color: const Color(0xFFEF4444), fontSize: 9.sp, fontWeight: FontWeight.w800)),
          ),
        ],
        if (isCombust) ...[
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Text('C', style: TextStyle(color: const Color(0xFFD97706), fontSize: 9.sp, fontWeight: FontWeight.w800)),
          ),
        ],
      ],
    );
  }

  Widget _buildHousePill(dynamic house, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF4338CA).withValues(alpha: isDark ? 0.25 : 0.10),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
      ),
      child: Text(
        'H$house',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
          color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
        ),
      ),
    );
  }

  Widget _buildDignityPill(String dignity, bool isDark) {
    Color color = const Color(0xFF64748B);
    final d = dignity.toLowerCase();
    if (d.contains('own') || d.contains('swakshetra') || d.contains('exalt') || d.contains('uchcha') || d.contains('moola')) {
      color = const Color(0xFF10B981);
    } else if (d.contains('debilit') || d.contains('neecha') || d.contains('enemy') || d.contains('shatru')) {
      color = const Color(0xFFEF4444);
    } else if (d.contains('friend') || d.contains('mitra')) {
      color = const Color(0xFF0EA5E9);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        dignity,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    Color color = const Color(0xFF10B981);
    if (status == 'Retrograde') {
      color = const Color(0xFFEF4444);
    } else if (status == 'Combust') {
      color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab() {
    final isDark = widget.isDark;
    final pravesha = _varshaphalData?['pravesha_details'] as Map<String, dynamic>? ?? {};
    final muntha = _varshaphalData?['muntha'] as Map<String, dynamic>? ?? {};
    final varsheshaInfo = _varshaphalData?['panchadhikari_and_varshesha'] as Map<String, dynamic>? ?? {};
    final dasha = _varshaphalData?['mudda_dasha'] as Map<String, dynamic>? ?? {};
    final currentMudda = dasha['current_period'] as Map<String, dynamic>? ?? {};
    final isDayReturn = pravesha['is_day_return'] == true;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Horizontal Quick Insight Ribbon
        _buildTopPraveshaSummaryChips(),
        SizedBox(height: 14.h),

        // 2. Varshapravesha Master Card (Annual Pravesha Instant)
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark ? const Color(0xFF312E81) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF4338CA).withValues(alpha: 0.22)
                    : const Color(0xFF4338CA).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annual Pravesha Instant',
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Solar Return Moment & Ascendant',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: isDayReturn
                          ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                          : (isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE)),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDayReturn
                            ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFFCD34D))
                            : (isDark ? const Color(0xFF6366F1) : const Color(0xFFC7D2FE)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDayReturn ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          size: 13.sp,
                          color: isDayReturn
                              ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                              : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isDayReturn ? 'Day Return' : 'Night Return',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDayReturn
                                ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                                : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // 2x2 Metric Tiles
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Solar Return Date',
                      value: '${pravesha['date'] ?? '-'}',
                      subvalue: pravesha['day_of_week'] != null ? '(${pravesha['day_of_week']})' : null,
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Return Time',
                      value: '${pravesha['time'] ?? '-'}',
                      subvalue: 'IST (Exact Moment)',
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Varsha Lagna',
                      value: '${pravesha['varsha_lagna'] ?? '-'}',
                      subvalue: '${pravesha['varsha_lagna_degree'] ?? ''}',
                      icon: Icons.explore_rounded,
                      iconColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Lagna Lord',
                      value: '${pravesha['varsha_lagna_lord'] ?? '-'}',
                      subvalue: 'Varsha Asc Ruler',
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 3. Varshesha (Year Lord) Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFFFDE68A),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
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
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.military_tech_rounded, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Varshesha (Year Lord)',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Supreme Lord',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${varsheshaInfo['varshesha'] ?? 'Unknown'}',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (varsheshaInfo['varshesha_role'] != null)
                Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14.sp, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 6.w),
                      Text(
                        'Role: ${varsheshaInfo['varshesha_role']}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                varsheshaInfo['selection_explanation']?.toString() ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 4. Muntha in House & Sign Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFEC4899).withValues(alpha: 0.35)
                  : const Color(0xFFFCE7F3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.15 : 0.07),
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
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muntha in House ${muntha['house']} (${muntha['sign_name']})',
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Muntha Lord: ${muntha['muntha_lord']} (in House ${muntha['muntha_lord_house']})',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFEC4899),
                      width: 3.5,
                    ),
                  ),
                ),
                child: Text(
                  muntha['prediction']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    height: 1.48,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 5. Active Mudda Dasha Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : const Color(0xFFD1FAE5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.07),
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
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Mudda Dasha: ${currentMudda['lord'] ?? 'Current'}',
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range_rounded, size: 12.sp, color: const Color(0xFF10B981)),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${currentMudda['start_date'] ?? ''} — ${currentMudda['end_date'] ?? ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentMudda['duration_days'] != null) ...[
                              SizedBox(width: 6.w),
                              Text(
                                '(${currentMudda['duration_days']} d)',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                currentMudda['prediction']?.toString() ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? subvalue,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 13.sp, color: iconColor),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subvalue != null && subvalue.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              subvalue,
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: VARSH KUNDLI (CHARTS)
  // ---------------------------------------------------------------------------

  Widget _buildVarshKundliTab() {
    final isDark = widget.isDark;
    final annualChart = _varshaphalData?['annual_chart'] as Map<String, dynamic>? ?? {};
    final annualPlanets = (_varshaphalData?['annual_chart']?['planets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final natalPlanets = (_varshaphalData?['natal_chart']?['planets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final natalMap = {for (var p in natalPlanets) p['planet']: p};

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // Style and Chart Selectors
        Row(
          children: [
            // Chart Type Switcher (D1, Chalit, D9)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A034D) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChartTypeKey,
                    dropdownColor: isDark ? const Color(0xFF0A034D) : Colors.white,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'D-1', child: Text('Varsh Lagna (D-1)')),
                      DropdownMenuItem(value: 'Bhava', child: Text('Bhava Chalit')),
                      DropdownMenuItem(value: 'D-9', child: Text('Navamsha (D-9)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedChartTypeKey = val);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Chart Layout Style Switcher
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A034D) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<KundliChartStyle>(
                  value: _chartStyle,
                  dropdownColor: isDark ? const Color(0xFF0A034D) : Colors.white,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: KundliChartStyle.northIndian, child: Text('North Indian')),
                    DropdownMenuItem(value: KundliChartStyle.southIndian, child: Text('South Indian')),
                    DropdownMenuItem(value: KundliChartStyle.eastIndian, child: Text('East Indian')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _chartStyle = val);
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Interactive Chart Canvas
        Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 420.w, maxHeight: 420.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070238) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: KundliInteractiveChart(
              chartStyle: _chartStyle,
              isDark: isDark,
              chartTypeKey: _selectedChartTypeKey,
              kundliData: annualChart,
              showDegrees: true,
              showUpagrahas: false,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Chart Meta Details
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A034D) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartMeta('Ayanamsha', _selectedAyanamsa, isDark),
              _buildChartMeta('House System', _selectedHouseSystem, isDark),
              _buildChartMeta('Year', '$_targetYear - ${_targetYear + 1}', isDark),
            ],
          ),
        ),
        SizedBox(height: 22.h),

        // Planetary Positions Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.public_rounded, color: const Color(0xFF4338CA), size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              'Annual Planetary Positions (Solar Return)',
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Annual Planets Table
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            headingRowHeight: 44.h,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            dividerThickness: 0.8,
            horizontalMargin: 16.w,
            columnSpacing: 22.w,
            dataTextStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            columns: const [
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('Sign')),
              DataColumn(label: Text('Degree DMS')),
              DataColumn(label: Text('House')),
              DataColumn(label: Text('Nakshatra & Pada')),
              DataColumn(label: Text('Dignity')),
              DataColumn(label: Text('Status')),
            ],
            rows: annualPlanets.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final isRetro = p['is_retrograde'] == true;
              final isCombust = p['is_combust'] == true;
              final status = isRetro ? 'Retrograde' : (isCombust ? 'Combust' : 'Direct');

              return DataRow(
                color: _tableRowColor(idx, isDark),
                cells: [
                  DataCell(_buildPlanetCell(
                    p['planet']?.toString() ?? '',
                    isRetro: isRetro,
                    isCombust: isCombust,
                    isDark: isDark,
                  )),
                  DataCell(Text(
                    p['sign_name']?.toString() ?? '',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12.sp),
                  )),
                  DataCell(Text(
                    p['degree_formatted']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5.sp,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )),
                  DataCell(_buildHousePill(p['house'], isDark)),
                  DataCell(Text('${p['nakshatra']} - ${p['pada']}')),
                  DataCell(_buildDignityPill(p['dignity']?.toString() ?? 'Neutral', isDark)),
                  DataCell(_buildStatusPill(status, isDark)),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 22.h),

        // Natal vs Annual Comparison Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.compare_arrows_rounded, color: const Color(0xFF10B981), size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              'Natal vs Annual Comparison',
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Natal vs Annual Comparison Table
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            headingRowHeight: 44.h,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            dividerThickness: 0.8,
            horizontalMargin: 16.w,
            columnSpacing: 22.w,
            dataTextStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            columns: const [
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('Natal Sign')),
              DataColumn(label: Text('Natal Deg')),
              DataColumn(label: Text('Annual Sign')),
              DataColumn(label: Text('Annual Deg')),
              DataColumn(label: Text('Annual House')),
            ],
            rows: annualPlanets.asMap().entries.map((entry) {
              final idx = entry.key;
              final ap = entry.value;
              final np = natalMap[ap['planet']] ?? {};
              return DataRow(
                color: _tableRowColor(idx, isDark),
                cells: [
                  DataCell(Text(
                    ap['planet']?.toString() ?? '',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5.sp),
                  )),
                  DataCell(Text(np['sign_name']?.toString() ?? '-')),
                  DataCell(Text(
                    np['degree_formatted']?.toString() ?? '-',
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  )),
                  DataCell(Text(
                    ap['sign_name']?.toString() ?? '-',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                  )),
                  DataCell(Text(
                    ap['degree_formatted']?.toString() ?? '-',
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  )),
                  DataCell(_buildHousePill(ap['house'], isDark)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChartMeta(String label, String val, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54),
        ),
        SizedBox(height: 2.h),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: VARSHESHA & MUNTHA
  // ---------------------------------------------------------------------------

  Widget _buildVarsheshaAndMunthaTab() {
    final isDark = widget.isDark;
    final varsheshaData = _varshaphalData?['panchadhikari_and_varshesha'] as Map<String, dynamic>? ?? {};
    final candidates = (varsheshaData['panchadhikari'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final muntha = _varshaphalData?['muntha'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // Varshesha Winner Banner
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Varshesha: ${varsheshaData['varshesha']}',
                        style: GoogleFonts.outfit(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Role: ${varsheshaData['varshesha_role']}',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                varsheshaData['selection_explanation']?.toString() ?? '',
                style: GoogleFonts.inter(fontSize: 12.5.sp, height: 1.4, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // Panchadhikari Candidates Table
        Text(
          'Panchadhikari (5 Office-Bearer Candidates)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            headingRowHeight: 44.h,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            dividerThickness: 0.8,
            horizontalMargin: 16.w,
            columnSpacing: 22.w,
            dataTextStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            columns: const [
              DataColumn(label: Text('Lordship Role')),
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('Vishwa Bala')),
              DataColumn(label: Text('Varsh House')),
              DataColumn(label: Text('Tajika Aspect')),
              DataColumn(label: Text('Eligibility')),
            ],
            rows: candidates.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              final isWinner = c['planet'] == varsheshaData['varshesha'];
              final aspects = c['aspects_lagna'] == true;

              return DataRow(
                selected: isWinner,
                color: _tableRowColor(idx, isDark, isSelected: isWinner),
                cells: [
                  DataCell(Text(
                    c['role']?.toString() ?? '',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.sp),
                  )),
                  DataCell(Text(
                    c['planet']?.toString() ?? '',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5.sp),
                  )),
                  DataCell(Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${c['strength']}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD97706),
                        fontSize: 11.5.sp,
                      ),
                    ),
                  )),
                  DataCell(_buildHousePill(c['house'], isDark)),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                      decoration: BoxDecoration(
                        color: (aspects ? Colors.green : Colors.red).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        aspects ? 'Aspects Lagna' : 'No Aspect',
                        style: TextStyle(
                          color: aspects ? Colors.green[700] : Colors.red[600],
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5.sp,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                            : (aspects ? const Color(0xFF4338CA).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isWinner
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        isWinner ? 'Selected Varshesha' : (aspects ? 'Eligible' : 'Ineligible'),
                        style: TextStyle(
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                          color: isWinner
                              ? const Color(0xFFD97706)
                              : (aspects ? const Color(0xFF4338CA) : Colors.grey[600]),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 24.h),

        // Muntha Analysis
        Text(
          'Muntha Analysis & Progression',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A034D) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMunthaStat('Muntha Sign', muntha['sign_name']?.toString() ?? '', isDark),
                  _buildMunthaStat('Muntha House', 'H${muntha['house']}', isDark),
                  _buildMunthaStat('Muntha Lord', muntha['muntha_lord']?.toString() ?? '', isDark),
                  _buildMunthaStat('Lord House', 'H${muntha['muntha_lord_house']}', isDark),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Classical Tajika Muntha Result:',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF4338CA),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                muntha['prediction']?.toString() ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMunthaStat(String title, String val, bool isDark) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54)),
        SizedBox(height: 3.h),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: PLANETARY STRENGTHS (PANCHAVARGEEYA & HARSHA BALA)
  // ---------------------------------------------------------------------------

  Widget _buildStrengthsTab() {
    final isDark = widget.isDark;
    final panchavargeeya = _varshaphalData?['panchavargeeya_bala'] as Map<String, dynamic>? ?? {};
    final harsha = _varshaphalData?['harsha_bala'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Panchavargeeya Bala (5-Fold Tajika Strength)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            horizontalMargin: 16.w,
            columnSpacing: 20.w,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            columns: const [
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('Graha Bala')),
              DataColumn(label: Text('Uchcha Bala')),
              DataColumn(label: Text('Hudda Bala')),
              DataColumn(label: Text('Drekkana Bala')),
              DataColumn(label: Text('Navamsha Bala')),
              DataColumn(label: Text('Total Vishwa Bala')),
            ],
            rows: panchavargeeya.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final b = e.value as Map<String, dynamic>;
              return DataRow(
                color: _tableRowColor(i, isDark),
                cells: [
                  DataCell(
                    Text(
                      e.key,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  DataCell(Text('${b['graha_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['uchcha_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['hudda_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['drekkana_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['navamsha_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '${b['total_vishwa_bala']}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5.sp,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 24.h),

        Text(
          'Harsha Bala (4 Joy Strengths)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            horizontalMargin: 16.w,
            columnSpacing: 18.w,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            columns: const [
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('1st Bala (Sthana)')),
              DataColumn(label: Text('2nd Bala (Swakshetra)')),
              DataColumn(label: Text('3rd Bala (Gender)')),
              DataColumn(label: Text('4th Bala (Dina/Ratri)')),
              DataColumn(label: Text('Total (0-20)')),
              DataColumn(label: Text('Rating')),
            ],
            rows: harsha.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final b = e.value as Map<String, dynamic>;
              final rating = b['rating']?.toString() ?? 'Medium';

              Color ratingColor = const Color(0xFFF59E0B);
              if (rating.toLowerCase().contains('strong')) {
                ratingColor = const Color(0xFF10B981);
              } else if (rating.toLowerCase().contains('weak')) {
                ratingColor = const Color(0xFFEF4444);
              }

              return DataRow(
                color: _tableRowColor(i, isDark),
                cells: [
                  DataCell(
                    Text(
                      e.key,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  DataCell(Text('${b['first_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['second_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['third_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(Text('${b['fourth_bala']}', style: GoogleFonts.outfit(fontSize: 12.5.sp))),
                  DataCell(
                    Text(
                      '${b['total']}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: ratingColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        rating,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: ratingColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 6: MUDDA VIMSHOTTARI DASHA
  // ---------------------------------------------------------------------------

  Widget _buildMuddaDashaTab() {
    final isDark = widget.isDark;
    final dasha = _varshaphalData?['mudda_dasha'] as Map<String, dynamic>? ?? {};
    final timeline = (dasha['timeline'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Annual Mudda Vimshottari Dasha Timeline',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        ...timeline.map((m) {
          final isCurrent = m['is_current'] == true;
          final antardashas = (m['antardashas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A034D) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              leading: Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: (isCurrent ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    m['lord']?.toString().substring(0, 2) ?? '',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    '${m['lord']} Mahadasha',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'H${m['house']}',
                      style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isCurrent) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'CURRENT',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),
                  Text(
                    '${m['start_date']} - ${m['end_date']} (${m['duration_days']} days)',
                    style: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    m['prediction']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      height: 1.35,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mudda Antardashas (Sub-Periods):',
                        style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        children: antardashas.map((sub) {
                          final isSubCurrent = sub['is_current'] == true;
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isSubCurrent
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : (isDark ? const Color(0xFF140770) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isSubCurrent ? const Color(0xFF10B981) : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              '${sub['sub_lord']}: ${sub['start_date']}-${sub['end_date']}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                fontWeight: isSubCurrent ? FontWeight.w700 : FontWeight.normal,
                                color: isSubCurrent ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 7: NAV TARA CHAKRA
  // ---------------------------------------------------------------------------

  Widget _buildNavTaraTab() {
    final isDark = widget.isDark;
    final navTara = _varshaphalData?['nav_tara_chakra'] as Map<String, dynamic>? ?? {};
    final taras = (navTara['taras'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A034D) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartMeta('Natal Reference Moon', navTara['reference_natal_moon_nakshatra']?.toString() ?? '', isDark),
              _buildChartMeta('Annual Chart Moon', navTara['annual_moon_nakshatra']?.toString() ?? '', isDark),
              _buildChartMeta('Annual Moon Tara', navTara['annual_moon_tara']?.toString() ?? '', isDark),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        Text(
          'Nav Taras (Counted from Natal Moon Nakshatra)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        ...taras.map((t) {
          final nakshatras = (t['nakshatras'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final isAuspicious = t['nature']?.toString().contains('Auspicious') == true;

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A034D) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.h,
                      decoration: BoxDecoration(
                        color: (isAuspicious ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${t['tara_number']}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: isAuspicious ? Colors.green : Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${t['tara_name']} (${t['sanskrit']})',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: (isAuspicious ? Colors.green : Colors.redAccent).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        t['nature']?.toString() ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isAuspicious ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  t['meaning']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  children: nakshatras.map((n) {
                    final isAnnual = n['is_annual_moon'] == true;
                    return Chip(
                      label: Text(
                        '${n['name']} (${n['lord']}) ${isAnnual ? '★ Annual Moon' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: isAnnual ? FontWeight.w800 : FontWeight.normal,
                          color: isAnnual ? Colors.amber[300] : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      backgroundColor: isAnnual
                          ? const Color(0xFFD97706).withValues(alpha: 0.3)
                          : (isDark ? const Color(0xFF140770) : const Color(0xFFF1F5F9)),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 8: GRAHA MAITRI (FRIENDSHIP MATRIX)
  // ---------------------------------------------------------------------------

  Widget _buildGrahaMaitriTab() {
    final isDark = widget.isDark;
    final maitriData = _varshaphalData?['graha_maitri']?['annual'] as Map<String, dynamic>? ?? {};
    final planets = (maitriData['planets'] as List<dynamic>? ?? []).cast<String>();
    final matrix = maitriData['matrix'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // Mode Switcher (Horizontal scroll to prevent RenderFlex overflow)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildMaitriFilterChip('compound', 'Compound (Panchadha)', isDark),
              SizedBox(width: 8.w),
              _buildMaitriFilterChip('temporary', 'Temporary (Tatkalika)', isDark),
              SizedBox(width: 8.w),
              _buildMaitriFilterChip('natural', 'Natural (Naisargika)', isDark),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        Text(
          'Planetary Friendship Matrix (Varshaphal)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),

        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            horizontalMargin: 16.w,
            columnSpacing: 18.w,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            columns: [
              const DataColumn(label: Text('Graha')),
              ...planets.map((p) => DataColumn(label: Text(p))),
            ],
            rows: planets.asMap().entries.map((entry) {
              final i = entry.key;
              final p1 = entry.value;
              final rowMap = matrix[p1] as Map<String, dynamic>? ?? {};
              return DataRow(
                color: _tableRowColor(i, isDark),
                cells: [
                  DataCell(
                    Text(
                      p1,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ...planets.map((p2) {
                    final cell = rowMap[p2] as Map<String, dynamic>? ?? {};
                    String val = cell[_maitriMode]?.toString() ?? '-';
                    Color color = Colors.grey;

                    if (val == 'Adhi Mitra') {
                      color = Colors.green[600]!;
                    } else if (val == 'Friend' || val == 'Mitra') {
                      color = Colors.teal[600]!;
                    } else if (val == 'Neutral' || val == 'Sama') {
                      color = Colors.blueGrey;
                    } else if (val == 'Enemy' || val == 'Shatru') {
                      color = Colors.orange[700]!;
                    } else if (val == 'Adhi Shatru') {
                      color = Colors.red[600]!;
                    } else if (val == 'Self') {
                      color = const Color(0xFF4338CA);
                    }

                    return DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          val,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMaitriFilterChip(String key, String label, bool isDark) {
    final isSelected = _maitriMode == key;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
      ),
      selected: isSelected,
      selectedColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF4338CA),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFF3730A3))
            : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      onSelected: (val) {
        if (val) setState(() => _maitriMode = key);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 9: TAJIKA SAHAMS (40 SENSITIVE POINTS)
  // ---------------------------------------------------------------------------

  Widget _buildSahamsTab() {
    final isDark = widget.isDark;
    final sahams = (_varshaphalData?['sahams'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          '40 Classical Tajika Sahams (Sensitive Points)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            horizontalMargin: 16.w,
            columnSpacing: 18.w,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            columns: const [
              DataColumn(label: Text('Saham')),
              DataColumn(label: Text('Significance')),
              DataColumn(label: Text('Sign')),
              DataColumn(label: Text('Degree DMS')),
              DataColumn(label: Text('House')),
              DataColumn(label: Text('Saham Lord')),
            ],
            rows: sahams.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return DataRow(
                color: _tableRowColor(i, isDark),
                cells: [
                  DataCell(
                    Text(
                      s['name']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      s['significance']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      s['sign_name']?.toString() ?? '',
                      style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      s['degree_formatted']?.toString() ?? '',
                      style: GoogleFonts.outfit(fontSize: 12.sp),
                    ),
                  ),
                  DataCell(_buildHousePill(s['house'], isDark)),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        s['saham_lord']?.toString() ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 10: TAJIKA YOGAS
  // ---------------------------------------------------------------------------

  Widget _buildTajikaYogasTab() {
    final isDark = widget.isDark;
    final yogas = (_varshaphalData?['tajika_yogas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    if (yogas.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'No major applying or separating Tajika yogas formed within orbs for this annual chart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Detected Classical Tajika Yogas',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        ...yogas.map((y) {
          final isBenefic = y['type']?.toString().contains('Benefic') == true ||
              y['type']?.toString().contains('Auspicious') == true;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A034D) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isBenefic
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isBenefic ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: isBenefic ? const Color(0xFF10B981) : Colors.amber,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      y['yoga_name']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: (isBenefic ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        y['status']?.toString() ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isBenefic ? Colors.green : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Planets: ${y['planets'] is List ? (y['planets'] as List).join(' & ') : (y['planets']?.toString() ?? '')}  •  Orb: ${y['orb_separation']}° (Max: ${y['max_orb']}°)',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
                SizedBox(height: 6.h),
                Text(
                  y['description']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 11: TRIPATAKI & MONTHLY CHARTS
  // ---------------------------------------------------------------------------

  Widget _buildTripatakiAndMonthlyTab() {
    final isDark = widget.isDark;
    final tripataki = _varshaphalData?['tripataki_chakra'] as Map<String, dynamic>? ?? {};
    final moonResults = (tripataki['results_on_moon'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final vedhasTable = tripataki['vedhas_table'] as Map<String, dynamic>? ?? {};
    final monthly = (_varshaphalData?['monthly_charts'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Tripataki Chakra & Vedhas on the Moon',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        ...moonResults.map((r) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A034D) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: const Color(0xFFEF4444), size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Vedha by ${r['planet']} on the Moon',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  r['result']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 20.h),

        Text(
          'Tripataki Vedhas Table',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        _buildTableCard(
          isDark: isDark,
          child: DataTable(
            horizontalMargin: 16.w,
            columnSpacing: 24.w,
            dataRowMinHeight: 46.h,
            dataRowMaxHeight: 52.h,
            headingRowColor: _tableHeaderColor(isDark),
            headingTextStyle: _tableHeaderStyle(isDark),
            columns: const [
              DataColumn(label: Text('Body / Graha')),
              DataColumn(label: Text('Vedhas Received From')),
            ],
            rows: vedhasTable.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final list = (e.value as List<dynamic>? ?? []).cast<String>();
              return DataRow(
                color: _tableRowColor(i, isDark),
                cells: [
                  DataCell(
                    Text(
                      e.key,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  DataCell(
                    list.isEmpty
                        ? Text(
                            'None',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: list.map((p) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  p,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 24.h),

        // 12 Monthly Charts (Masa Pravesha)
        Text(
          '12 Monthly Solar Returns (Masa Pravesha)',
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        ...monthly.map((m) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A034D) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isDark ? const Color(0xFF140770) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title']?.toString() ?? '',
                      style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      m['pravesha_date']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lagna: ${m['masa_lagna']}',
                      style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Lord: ${m['masa_lagna_lord']}',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR VIEW
  // ---------------------------------------------------------------------------

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            SizedBox(height: 12.h),
            Text(
              'Calculation Error',
              style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unknown error occurred while generating Varshaphal chart.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _loadVarshaphal,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Calculation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONFIGURATION & EDIT MODAL WITH LOCATION AUTOCOMPLETE
  // ---------------------------------------------------------------------------

  void _showEditConfigDialog() {
    final nameCtrl = TextEditingController(text: _personName);
    final dobCtrl = TextEditingController(text: _dob);
    final tobCtrl = TextEditingController(text: _tob);
    final pobCtrl = TextEditingController(text: _pob);
    final latCtrl = TextEditingController(text: _latitude.toString());
    final lonCtrl = TextEditingController(text: _longitude.toString());
    final tzCtrl = TextEditingController(text: _timezone.toString());
    final yearCtrl = TextEditingController(text: _targetYear.toString());

    bool useBirthplace = _useBirthplaceForReturn;
    final retPlaceCtrl = TextEditingController(text: _returnPlace);
    final retLatCtrl = TextEditingController(text: _returnLatitude.toString());
    final retLonCtrl = TextEditingController(text: _returnLongitude.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF0A034D) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: const Color(0xFF4338CA), size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Varshaphal Settings & Details',
                          style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildTextField('Full Name', nameCtrl),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeField(
                            label: 'Date of Birth (YYYY-MM-DD)',
                            ctrl: dobCtrl,
                            icon: Icons.calendar_today_rounded,
                            onTapIcon: () async {
                              final current = DateTime.tryParse(dobCtrl.text.trim()) ?? DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: current,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                dobCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildDateTimeField(
                            label: 'Time (HH:MM:SS)',
                            ctrl: tobCtrl,
                            icon: Icons.access_time_rounded,
                            onTapIcon: () async {
                              final parts = tobCtrl.text.split(':');
                              final initHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 12) : 12;
                              final initMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: initHour, minute: initMinute),
                              );
                              if (picked != null) {
                                tobCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Birthplace with Auto-Search & Auto-Fill Coordinates
                    _buildPlaceAutocompleteField(
                      label: 'Birthplace',
                      placeCtrl: pobCtrl,
                      latCtrl: latCtrl,
                      lonCtrl: lonCtrl,
                      tzCtrl: tzCtrl,
                      modalCtx: ctx,
                      onLocationUpdated: () => setModalState(() {}),
                    ),
                    SizedBox(height: 10.h),

                    // Coordinates & Timezone Auto-filled
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Latitude', latCtrl, isNumber: true)),
                        SizedBox(width: 10.w),
                        Expanded(child: _buildTextField('Longitude', lonCtrl, isNumber: true)),
                        SizedBox(width: 10.w),
                        Expanded(child: _buildTextField('Timezone', tzCtrl, isNumber: true)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField('Target Varshaphal Year', yearCtrl, isNumber: true),
                    SizedBox(height: 12.h),

                    // Return Location option
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Use Birthplace for Solar Return',
                          style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'When off, allows specifying return coordinates',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
                        ),
                        value: useBirthplace,
                        activeTrackColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          setModalState(() => useBirthplace = val);
                        },
                      ),
                    ),
                    if (!useBirthplace) ...[
                      SizedBox(height: 10.h),
                      _buildPlaceAutocompleteField(
                        label: 'Return Location Name',
                        placeCtrl: retPlaceCtrl,
                        latCtrl: retLatCtrl,
                        lonCtrl: retLonCtrl,
                        modalCtx: ctx,
                        onLocationUpdated: () => setModalState(() {}),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Return Latitude', retLatCtrl, isNumber: true)),
                          SizedBox(width: 10.w),
                          Expanded(child: _buildTextField('Return Longitude', retLonCtrl, isNumber: true)),
                        ],
                      ),
                    ],
                    SizedBox(height: 18.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        onPressed: () {
                          setState(() {
                            _personName = nameCtrl.text.trim();
                            _dob = AstroApiService.normalizeDate(dobCtrl.text.trim());
                            _tob = AstroApiService.normalizeTime(tobCtrl.text.trim());
                            _pob = pobCtrl.text.trim();
                            _latitude = double.tryParse(latCtrl.text.trim()) ?? _latitude;
                            _longitude = double.tryParse(lonCtrl.text.trim()) ?? _longitude;
                            _timezone = double.tryParse(tzCtrl.text.trim()) ?? _timezone;
                            _targetYear = int.tryParse(yearCtrl.text.trim()) ?? _targetYear;
                            _useBirthplaceForReturn = useBirthplace;
                            _returnPlace = retPlaceCtrl.text.trim();
                            _returnLatitude = double.tryParse(retLatCtrl.text.trim()) ?? _returnLatitude;
                            _returnLongitude = double.tryParse(retLonCtrl.text.trim()) ?? _returnLongitude;
                          });
                          Navigator.pop(ctx);
                          _loadVarshaphal();
                        },
                        child: Text(
                          'Save & Calculate Varshaphal',
                          style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
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

  Widget _buildPlaceAutocompleteField({
    required String label,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    TextEditingController? tzCtrl,
    required BuildContext modalCtx,
    required VoidCallback onLocationUpdated,
  }) {
    final isDark = widget.isDark;

    return Autocomplete<Map<String, String>>(
      initialValue: TextEditingValue(text: placeCtrl.text),
      displayStringForOption: (option) => option['city'] ?? '',
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Map<String, String>>.empty();
        try {
          return await AstroApiService.getPlaces(query: query);
        } catch (_) {
          return const Iterable<Map<String, String>>.empty();
        }
      },
      onSelected: (Map<String, String> selection) {
        placeCtrl.text = selection['city'] ?? '';
        latCtrl.text = selection['lat_val'] ?? latCtrl.text;
        lonCtrl.text = selection['lon_val'] ?? lonCtrl.text;
        if (tzCtrl != null && selection['tz_val'] != null) {
          tzCtrl.text = selection['tz_val']!;
        }
        onLocationUpdated();
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        if (controller.text.isEmpty && placeCtrl.text.isNotEmpty) {
          controller.text = placeCtrl.text;
        }
        controller.addListener(() {
          placeCtrl.text = controller.text;
        });

        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white60 : Colors.black54),
            hintText: 'Type city name to auto-fill coordinates...',
            hintStyle: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? Colors.white38 : Colors.black38),
            prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF4338CA), size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA)),
              tooltip: 'Browse / Search City',
              onPressed: () {
                showModalBottomSheet(
                  context: modalCtx,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (sheetCtx) => _VarshaphalLocationSelectorSheet(
                    isDark: widget.isDark,
                    onSelect: (city) {
                      controller.text = city['city'] ?? '';
                      placeCtrl.text = city['city'] ?? '';
                      latCtrl.text = city['lat_val'] ?? latCtrl.text;
                      lonCtrl.text = city['lon_val'] ?? lonCtrl.text;
                      if (tzCtrl != null && city['tz_val'] != null) {
                        tzCtrl.text = city['tz_val']!;
                      }
                      onLocationUpdated();
                    },
                  ),
                );
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: isDark ? const Color(0xFF140770) : const Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14.r),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 220.h, maxWidth: MediaQuery.of(context).size.width - 40.w),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF4338CA), size: 16),
                    ),
                    title: Text(
                      option['city'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      '${option['coords']} • ${option['tz']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required VoidCallback onTapIcon,
  }) {
    final isDark = widget.isDark;
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white60 : Colors.black54),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        suffixIcon: IconButton(
          icon: Icon(icon, size: 18.sp, color: const Color(0xFF4338CA)),
          onPressed: onTapIcon,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: isDark ? const Color(0xFF140770) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    final isDark = widget.isDark;
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white60 : Colors.black54),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: isDark ? const Color(0xFF140770) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOCATION SELECTOR BOTTOM SHEET (MATCHING HOROSCOPE SCREEN)
// ---------------------------------------------------------------------------

class _VarshaphalLocationSelectorSheet extends StatefulWidget {
  final bool isDark;
  final ValueChanged<Map<String, String>> onSelect;

  const _VarshaphalLocationSelectorSheet({
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_VarshaphalLocationSelectorSheet> createState() => _VarshaphalLocationSelectorSheetState();
}

class _VarshaphalLocationSelectorSheetState extends State<_VarshaphalLocationSelectorSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<Map<String, String>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchPlaces('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await AstroApiService.getPlaces(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaces(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Select Location',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search city (e.g. Kanyakumari, Chennai, Delhi)...',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _fetchPlaces('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
            onChanged: _onSearchChanged,
          ),
          SizedBox(height: 14.h),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA)))
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_rounded, size: 36.sp, color: Colors.grey),
                            SizedBox(height: 8.h),
                            Text(
                              'No matching locations found',
                              style: GoogleFonts.outfit(fontSize: 14.sp, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final city = _searchResults[index];
                          return ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFF4338CA), size: 18),
                            ),
                            title: Text(
                              city['city'] ?? 'Unknown',
                              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                            ),
                            subtitle: Text(
                              '${city['coords']} • ${city['tz']}',
                              style: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? Colors.white54 : Colors.black54),
                            ),
                            onTap: () {
                              widget.onSelect(city);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
