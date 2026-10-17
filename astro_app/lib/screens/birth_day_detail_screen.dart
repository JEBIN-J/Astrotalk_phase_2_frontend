import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../theme/numerology_theme.dart';

class BirthDayDetailScreen extends StatefulWidget {
  final String dateOfBirth;
  final String userName;
  final String system;

  const BirthDayDetailScreen({
    super.key,
    required this.dateOfBirth,
    this.userName = 'Seeker',
    this.system = 'pythagorean',
  });

  @override
  State<BirthDayDetailScreen> createState() => _BirthDayDetailScreenState();
}

class _BirthDayDetailScreenState extends State<BirthDayDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  int _selectedTabIndex = 0;

  late String _currentDob;
  late String _currentName;
  late String _currentSystem;

  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get scaffoldBg => isDark ? NumerologyTheme.darkScaffoldBg : const Color(0xFFFDF4F8);
  Color get cardBg => isDark ? NumerologyTheme.darkCardBg : Colors.white;
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC);
  Color get cardBorder => isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0);
  Color get heroBg => isDark ? const Color(0xFF1F1226) : const Color(0xFFFDF2F8);
  Color get heroBorder => isDark ? const Color(0xFFEC4899).withValues(alpha: 0.3) : const Color(0xFFFCE7F3);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get subCardBg => isDark ? const Color(0xFF18233C) : const Color(0xFFFDF2F8);
  Color get subCardBorder => isDark ? const Color(0xFFEC4899).withValues(alpha: 0.25) : const Color(0xFFFCE7F3);

  final List<String> _tabTitles = [
    'Overview',
    'Personality',
    'Strengths',
    'Challenges',
    'Relationships',
    'Career & Work',
    'Personal Growth',
    'Quick Summary',
  ];

  @override
  void initState() {
    super.initState();
    _currentDob = widget.dateOfBirth.trim();
    _currentName = widget.userName.trim().isNotEmpty ? widget.userName.trim() : 'Seeker';
    _currentSystem = widget.system.isNotEmpty ? widget.system : 'pythagorean';

    _loadBirthDayData();
  }

  Future<void> _loadBirthDayData() async {
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
      final res = await AstroApiService.getBirthDayReport(
        dateOfBirth: _currentDob,
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
              primary: const Color(0xFFEC4899),
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
      _loadBirthDayData();
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
              'Birth Day Number',
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
            icon: Icon(Icons.refresh_rounded, size: 20.sp, color: const Color(0xFFEC4899)),
            tooltip: 'Recalculate',
            onPressed: _loadBirthDayData,
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
                  color: Color(0xFFEC4899),
                  strokeWidth: 3.2,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Calculating Birth Day Number...',
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Extracting calendar day & querying database interpretations',
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
                child: Icon(Icons.calendar_month_rounded, size: 48.sp, color: const Color(0xFFEC4899)),
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
                'To calculate your authoritative Birth Day number, we need your verified birth date.',
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
                  backgroundColor: const Color(0xFFEC4899),
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
                _errorMessage ?? 'Unable to retrieve Birth Day report.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: textSecondary),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: _loadBirthDayData,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dayNum = _reportData!['birth_day_number']?.toString() ?? '1';
    final reducedRoot = _reportData!['reduced_root']?.toString() ?? dayNum;
    final title = _reportData!['number_title'] ?? 'The Trailblazer';
    final coreTheme = _reportData!['core_theme'] ?? '';
    final isMasterDay = _reportData!['is_master_day'] == true;
    final trace = _reportData!['calculation_trace'] as Map<String, dynamic>? ?? {};
    final interp = _reportData!['interpretation'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Card
          _buildHeroCard(dayNum, reducedRoot, title, coreTheme, isMasterDay),
          SizedBox(height: 14.h),

          // 2. Calculation Trace Card
          _buildTraceCard(trace, dayNum, reducedRoot),
          SizedBox(height: 18.h),

          // 3. Tab Navigation Chips
          _buildTabChips(),
          SizedBox(height: 14.h),

          // 4. Tab Content
          _buildActiveTabContent(interp),
          SizedBox(height: 16.h),

          // 5. Ethical Disclaimer
          _buildEthicalDisclaimer(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String dayNum, String reducedRoot, String title, String coreTheme, bool isMasterDay) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: heroBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.15 : 0.08),
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
                    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  dayNum,
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
                    Row(
                      children: [
                        if (isMasterDay)
                          Container(
                            margin: EdgeInsets.only(right: 6.w),
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF332008) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '⭐ MASTER DAY',
                              style: GoogleFonts.outfit(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF831843).withValues(alpha: 0.4) : const Color(0xFFFCE7F3),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'ROOT: $reducedRoot',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
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
                      'Day of Month (1–31) • Distinct from Life Path',
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
                Text('☀️', style: TextStyle(fontSize: 13.sp)),
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

  Widget _buildTraceCard(Map<String, dynamic> trace, String dayNum, String reducedRoot) {
    final primaryRule = trace['primary_rule']?.toString() ??
        'Calendar day extracted as authoritative primary Birth Day Number: $dayNum';
    final reductionSteps = (trace['root_reduction_steps'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .join(' • ') ??
        'Day $dayNum -> Root $reducedRoot';

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
              Icon(Icons.calendar_today_rounded, size: 15.sp, color: const Color(0xFFEC4899)),
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
                  color: isDark ? const Color(0xFF831843).withValues(alpha: 0.3) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'DOB: $_currentDob',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.sp,
                    color: isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D),
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
                  'Primary Day',
                  dayNum,
                  'Calendar Day 1–31',
                  const Color(0xFFBE185D),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildTracePill(
                  'Reduced Root',
                  reducedRoot,
                  reductionSteps,
                  const Color(0xFF2563EB),
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
                Icon(Icons.check_circle_outline_rounded, size: 14.sp, color: const Color(0xFFDB2777)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    primaryRule,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFFBCFE8) : const Color(0xFF831843),
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
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
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
              fontSize: 9.sp,
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
              fontSize: 9.sp,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
                  color: isSelected ? const Color(0xFFEC4899) : cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFEC4899) : cardBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.25),
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
        return _buildPersonalityContent(interp);
      case 2:
        return _buildStrengthsContent(interp);
      case 3:
        return _buildChallengesContent(interp);
      case 4:
        return _buildRelationshipsContent(interp);
      case 5:
        return _buildCareerContent(interp);
      case 6:
        return _buildGrowthContent(interp);
      case 7:
        return _buildQuickSummaryContent(interp);
      default:
        return _buildOverviewContent(interp);
    }
  }

  Widget _buildOverviewContent(Map<String, dynamic> interp) {
    final overviewText = interp['overview'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Birth Day Overview',
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFEC4899),
          content: overviewText,
        ),
      ],
    );
  }

  Widget _buildPersonalityContent(Map<String, dynamic> interp) {
    final personalityText = interp['personality'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Personality & Behaviour',
          icon: Icons.psychology_rounded,
          iconColor: const Color(0xFF8B5CF6),
          content: personalityText,
        ),
      ],
    );
  }

  Widget _buildStrengthsContent(Map<String, dynamic> interp) {
    final strengths = (interp['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      children: [
        _buildListCard(
          title: 'Innate Talents & Strengths',
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF16A34A),
          items: strengths,
        ),
      ],
    );
  }

  Widget _buildChallengesContent(Map<String, dynamic> interp) {
    final challenges = (interp['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      children: [
        _buildListCard(
          title: 'Potential Challenges & Balance',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD97706),
          items: challenges,
        ),
      ],
    );
  }

  Widget _buildRelationshipsContent(Map<String, dynamic> interp) {
    final relText = interp['relationships'] ?? '';
    final sections = (interp['sections'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? relSection;
    for (final s in sections) {
      if (s is Map && s['section_type'] == 'relationships') {
        relSection = Map<String, dynamic>.from(s);
        break;
      }
    }

    return Column(
      children: [
        _buildSectionCard(
          title: relSection?['heading'] ?? 'Relationships & Relational Harmony',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE11D48),
          content: relText,
        ),
      ],
    );
  }

  Widget _buildCareerContent(Map<String, dynamic> interp) {
    final careerText = interp['career'] ?? '';
    final sections = (interp['sections'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? careerSection;
    for (final s in sections) {
      if (s is Map && s['section_type'] == 'career') {
        careerSection = Map<String, dynamic>.from(s);
        break;
      }
    }

    return Column(
      children: [
        _buildSectionCard(
          title: careerSection?['heading'] ?? 'Career & Work Style',
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF0284C7),
          content: careerText,
        ),
      ],
    );
  }

  Widget _buildGrowthContent(Map<String, dynamic> interp) {
    final growthText = interp['personal_growth'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Personal Growth & Positive Habits',
          icon: Icons.self_improvement_rounded,
          iconColor: const Color(0xFF059669),
          content: growthText,
        ),
      ],
    );
  }

  Widget _buildQuickSummaryContent(Map<String, dynamic> interp) {
    final summary = interp['quick_summary'] as Map<String, dynamic>? ?? {};
    final traits = (summary['key_traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final challenge = summary['potential_challenge']?.toString() ?? 'Maintaining balanced energy';
    final suggestion = summary['growth_suggestion']?.toString() ?? 'Daily grounding and intention setting';

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
              Icon(Icons.dashboard_customize_rounded, size: 18.sp, color: const Color(0xFFEC4899)),
              SizedBox(width: 8.w),
              Text(
                'Quick Summary Card',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'KEY TRAITS',
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: traits.map((t) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF831843).withValues(alpha: 0.3) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: subCardBorder),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 14.h),
          _buildSummaryItem('POTENTIAL CHALLENGE', challenge, const Color(0xFFD97706)),
          SizedBox(height: 10.h),
          _buildSummaryItem('GROWTH PRACTICE', suggestion, const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String text, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFFEC4899),
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
              'Numerology is a traditional philosophical and archetypal practice intended for personal reflection and self-discovery. It does not provide deterministic scientific predictions of future events, health, financial earnings, or legal outcomes.',
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
