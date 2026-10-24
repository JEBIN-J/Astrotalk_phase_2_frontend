import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../theme/numerology_theme.dart';

class PersonalYearDetailScreen extends StatefulWidget {
  final String dateOfBirth;
  final String userName;
  final String system;
  final int? initialYear;

  const PersonalYearDetailScreen({
    super.key,
    required this.dateOfBirth,
    this.userName = 'Seeker',
    this.system = 'pythagorean',
    this.initialYear,
  });

  @override
  State<PersonalYearDetailScreen> createState() => _PersonalYearDetailScreenState();
}

class _PersonalYearDetailScreenState extends State<PersonalYearDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  int _selectedTabIndex = 0;

  late String _currentDob;
  late String _currentName;
  late String _currentSystem;
  late int _selectedYear;
  final ScrollController _yearScrollController = ScrollController();

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get scaffoldBg => isDark ? NumerologyTheme.darkScaffoldBg : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? NumerologyTheme.darkCardBg : Colors.white;
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC);
  Color get cardBorder => isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0);
  Color get heroBg => isDark ? const Color(0xFF0F241C) : const Color(0xFFECFDF5);
  Color get heroBorder => isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFD1FAE5);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get subCardBg => isDark ? const Color(0xFF18233C) : const Color(0xFFF0FDF4);
  Color get subCardBorder => isDark ? const Color(0xFF10B981).withValues(alpha: 0.25) : const Color(0xFFDCFCE7);

  final List<String> _tabTitles = [
    'Annual Overview',
    'Opportunities',
    'Challenges',
    'Career & Work',
    'Relationships',
    'Personal Growth',
    'Practical Guidance',
    'Reflection Questions',
  ];

  @override
  void initState() {
    super.initState();
    _currentDob = widget.dateOfBirth.trim();
    _currentName = widget.userName.trim().isNotEmpty ? widget.userName.trim() : 'Seeker';
    _currentSystem = widget.system.isNotEmpty ? widget.system : 'pythagorean';
    _selectedYear = widget.initialYear ?? DateTime.now().year;

    _loadPersonalYearData();
  }

  Future<void> _loadPersonalYearData() async {
    if (_currentDob.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedDob = prefs.getString('numerology_user_dob') ?? '';
      final savedName = prefs.getString('numerology_user_name') ?? '';
      if (savedDob.isNotEmpty) {
        _currentDob = savedDob;
        if (savedName.isNotEmpty) _currentName = savedName;
      }
    }

    if (_currentDob.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'MISSING_DOB';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getPersonalYearReport(
        dateOfBirth: _currentDob,
        year: _selectedYear,
        name: _currentName,
        system: _currentSystem,
      );
      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectAndSaveDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1998, 12, 16),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: textPrimary,
              surface: cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('numerology_user_dob', formatted);
      setState(() {
        _currentDob = formatted;
      });
      _loadPersonalYearData();
    }
  }

  void _onYearChanged(int newYear) {
    if (newYear != _selectedYear) {
      setState(() {
        _selectedYear = newYear;
      });
      _loadPersonalYearData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: NumerologyTheme.appBarBg(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: NumerologyTheme.circleBtnBg(isDark),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18.sp, color: NumerologyTheme.circleBtnIcon(isDark)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Year Number',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              '$_currentName • ${_currentDob.isNotEmpty ? _currentDob : 'No DOB'}',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20.sp, color: const Color(0xFF10B981)),
            tooltip: 'Recalculate',
            onPressed: _loadPersonalYearData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44.w,
                height: 44.w,
                child: const CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 3.2,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Calculating Personal Year $_selectedYear...',
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Summing birth month, birth day & target calendar year',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage == 'MISSING_DOB') {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: heroBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_month_rounded, size: 48.sp, color: const Color(0xFF10B981)),
              ),
              SizedBox(height: 20.h),
              Text(
                'Date of Birth Required',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'To calculate your authoritative Personal Year number, we need your verified birth date.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _selectAndSaveDob,
                icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Select Date of Birth',
                  style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _reportData == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48.sp, color: const Color(0xFFEF4444)),
              SizedBox(height: 16.h),
              Text(
                'Calculation Failed',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage ?? 'Unable to retrieve Personal Year report.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: textSecondary),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: _loadPersonalYearData,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final yearNum = _reportData!['personal_year_number']?.toString() ?? '1';
    final targetYear = _reportData!['target_year'] ?? _selectedYear;
    final title = _reportData!['number_title'] ?? 'The Year of New Beginnings';
    final coreTheme = _reportData!['core_theme'] ?? '';
    final trace = _reportData!['calculation_trace'] as Map<String, dynamic>? ?? {};
    final interp = _reportData!['interpretation'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Year Selector Bar
          _buildYearSelector(),
          SizedBox(height: 14.h),

          // 2. Hero Card
          _buildHeroCard(yearNum, targetYear, title, coreTheme),
          SizedBox(height: 14.h),

          // 3. Calculation Trace Card
          _buildTraceCard(trace, yearNum, targetYear),
          SizedBox(height: 18.h),

          // 4. Tab Navigation Chips
          _buildTabChips(),
          SizedBox(height: 14.h),

          // 5. Tab Content
          _buildActiveTabContent(interp),
          SizedBox(height: 16.h),

          // 6. Ethical Disclaimer
          _buildEthicalDisclaimer(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    int birthYear = DateTime.now().year;
    if (_currentDob.isNotEmpty) {
      final parts = _currentDob.split('-');
      if (parts.isNotEmpty) {
        birthYear = int.tryParse(parts[0]) ?? birthYear;
      }
    }
    final currentServerYear = DateTime.now().year;
    final startYear = birthYear <= currentServerYear ? birthYear : currentServerYear;
    final endYear = currentServerYear + 10;
    final years = [
      for (int y = startYear; y <= endYear; y++) y,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_yearScrollController.hasClients) {
        final index = years.indexOf(_selectedYear);
        if (index > 0) {
          final targetOffset = (index * 68.w) - 100.w;
          _yearScrollController.animateTo(
            targetOffset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 14.sp, color: const Color(0xFF10B981)),
              SizedBox(width: 6.w),
              Text(
                'SELECT CALENDAR YEAR',
                style: GoogleFonts.outfit(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (_selectedYear != startYear)
                Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.r),
                    onTap: () => _onYearChanged(startYear),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        'BIRTH ($startYear)',
                        style: GoogleFonts.outfit(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_selectedYear == currentServerYear)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'CURRENT YEAR',
                    style: GoogleFonts.outfit(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    ),
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(4.r),
                  onTap: () => _onYearChanged(currentServerYear),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'NOW ($currentServerYear)',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            controller: _yearScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: years.map((y) {
                final isSelected = y == _selectedYear;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => _onYearChanged(y),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : surfaceBg,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$y',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String yearNum, dynamic targetYear, String title, String coreTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: heroBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.10),
            blurRadius: 16,
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
              // Large Number Badge
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  yearNum,
                  style: GoogleFonts.outfit(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'YEAR $targetYear CYCLE',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Nine-Year Vibrational Cycle • Jan 1 - Dec 31',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: heroBorder),
            ),
            child: Row(
              children: [
                Text('🌱', style: TextStyle(fontSize: 13.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    coreTheme,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceCard(Map<String, dynamic> trace, String yearNum, dynamic targetYear) {
    final formula = trace['sum_formula']?.toString() ?? 'Month + Day + Year = Total';
    final monthStep = trace['month_reduction_step']?.toString() ?? 'Birth Month';
    final dayStep = trace['day_reduction_step']?.toString() ?? 'Birth Day';
    final yearStep = trace['year_reduction_step']?.toString() ?? 'Target Year';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, size: 15.sp, color: const Color(0xFF10B981)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'CALCULATION TRACE',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'DOB: $_currentDob',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.sp,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTracePill(
                  'Month',
                  trace['month_reduced']?.toString() ?? '',
                  monthStep,
                  const Color(0xFF059669),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildTracePill(
                  'Day',
                  trace['day_reduced']?.toString() ?? '',
                  dayStep,
                  const Color(0xFF0284C7),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildTracePill(
                  'Year',
                  trace['year_reduced']?.toString() ?? '',
                  yearStep,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: subCardBg,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: subCardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14.sp, color: const Color(0xFF059669)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Formula: $formula -> Personal Year $yearNum',
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracePill(String title, String val, String subtitle, Color valColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: valColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabTitles.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () {
                setState(() => _selectedTabIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : cardBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  _tabTitles[index],
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent(Map<String, dynamic> interp) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewContent(interp);
      case 1:
        return _buildOpportunitiesContent(interp);
      case 2:
        return _buildChallengesContent(interp);
      case 3:
        return _buildCareerContent(interp);
      case 4:
        return _buildRelationshipsContent(interp);
      case 5:
        return _buildGrowthContent(interp);
      case 6:
        return _buildPracticalContent(interp);
      case 7:
        return _buildQuestionsContent(interp);
      default:
        return _buildOverviewContent(interp);
    }
  }

  Widget _buildOverviewContent(Map<String, dynamic> interp) {
    final overviewText = interp['overview'] ?? '';
    return Column(
      children: [
        _buildSectionCard(
          title: 'Annual Overview & Cycle Context',
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFF10B981),
          content: overviewText,
        ),
      ],
    );
  }

  Widget _buildOpportunitiesContent(Map<String, dynamic> interp) {
    final opps = (interp['opportunities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return Column(
      children: [
        _buildListCard(
          title: 'Key Annual Opportunities',
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF059669),
          items: opps,
        ),
      ],
    );
  }

  Widget _buildChallengesContent(Map<String, dynamic> interp) {
    final challenges = (interp['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return Column(
      children: [
        _buildListCard(
          title: 'Navigating Challenges with Balance',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD97706),
          items: challenges,
        ),
      ],
    );
  }

  Widget _buildCareerContent(Map<String, dynamic> interp) {
    final careerText = interp['career_and_work'] ?? '';
    return Column(
      children: [
        _buildSectionCard(
          title: 'Career & Work Planning',
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF0284C7),
          content: careerText,
        ),
      ],
    );
  }

  Widget _buildRelationshipsContent(Map<String, dynamic> interp) {
    final relText = interp['relationships'] ?? '';
    return Column(
      children: [
        _buildSectionCard(
          title: 'Relationships & Interpersonal Harmony',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE11D48),
          content: relText,
        ),
      ],
    );
  }

  Widget _buildGrowthContent(Map<String, dynamic> interp) {
    final growthText = interp['personal_growth'] ?? '';
    return Column(
      children: [
        _buildSectionCard(
          title: 'Personal Growth & Habits',
          icon: Icons.self_improvement_rounded,
          iconColor: const Color(0xFF8B5CF6),
          content: growthText,
        ),
      ],
    );
  }

  Widget _buildPracticalContent(Map<String, dynamic> interp) {
    final practicalText = interp['practical_guidance'] ?? '';
    return Column(
      children: [
        _buildSectionCard(
          title: 'Practical Planning & Annual Action',
          icon: Icons.task_alt_rounded,
          iconColor: const Color(0xFF10B981),
          content: practicalText,
        ),
      ],
    );
  }

  Widget _buildQuestionsContent(Map<String, dynamic> interp) {
    final questions = (interp['reflection_questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return Column(
      children: [
        _buildListCard(
          title: 'Annual Reflection Prompts',
          icon: Icons.lightbulb_outline_rounded,
          iconColor: const Color(0xFFD97706),
          items: questions,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF10B981),
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: iconColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: iconColor),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEthicalDisclaimer() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Personal Year Numerology is a traditional philosophical and archetypal practice intended for personal reflection, seasonal goal-setting, and self-discovery. It does not provide deterministic scientific predictions of future events, health, financial outcomes, or legal matters.',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
