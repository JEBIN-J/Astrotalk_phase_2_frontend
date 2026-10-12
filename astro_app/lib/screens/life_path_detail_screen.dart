import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class LifePathDetailScreen extends StatefulWidget {
  final String dateOfBirth;
  final String userName;
  final String system;

  const LifePathDetailScreen({
    super.key,
    required this.dateOfBirth,
    this.userName = 'Seeker',
    this.system = 'pythagorean',
  });

  @override
  State<LifePathDetailScreen> createState() => _LifePathDetailScreenState();
}

class _LifePathDetailScreenState extends State<LifePathDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  int _selectedTabIndex = 0;

  late String _currentDob;
  late String _currentName;
  late String _currentSystem;

  final List<String> _tabTitles = [
    'Overview',
    'Personality',
    'Relationships',
    'Career & Work',
    'Strengths & Growth',
    'Daily Practices'
  ];

  @override
  void initState() {
    super.initState();
    _currentDob = widget.dateOfBirth.trim();
    _currentName = widget.userName.trim().isNotEmpty ? widget.userName.trim() : 'Seeker';
    _currentSystem = widget.system.isNotEmpty ? widget.system : 'pythagorean';

    _loadLifePathData();
  }

  Future<void> _loadLifePathData() async {
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
      final res = await AstroApiService.getLifePathReport(
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
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
      _loadLifePathData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18.sp, color: const Color(0xFF1E293B)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Life Path Number',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              '$_currentName • ${_currentDob.isNotEmpty ? _currentDob : 'No DOB'}',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20.sp, color: const Color(0xFF2563EB)),
            tooltip: 'Recalculate',
            onPressed: _loadLifePathData,
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
                  color: Color(0xFF2563EB),
                  strokeWidth: 3.2,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Calculating Life Path...',
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Deterministic Pythagorean reduction & DB interpretation',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_month_rounded, size: 48.sp, color: const Color(0xFF2563EB)),
              ),
              SizedBox(height: 20.h),
              Text(
                'Date of Birth Required',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'To calculate your authoritative Life Path number, we need your verified birth date.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
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
                  backgroundColor: const Color(0xFF2563EB),
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
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage ?? 'Unable to retrieve Life Path report.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: _loadLifePathData,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lpNum = _reportData!['life_path_number']?.toString() ?? '1';
    final title = _reportData!['number_title'] ?? 'The Pioneer';
    final coreTheme = _reportData!['core_theme'] ?? '';
    final isMaster = _reportData!['is_master_number'] == true;
    final trace = _reportData!['calculation_trace'] as Map<String, dynamic>? ?? {};
    final interp = _reportData!['interpretation'] as Map<String, dynamic>? ?? {};
    final sections = (interp['sections'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Card
          _buildHeroCard(lpNum, title, coreTheme, isMaster),
          SizedBox(height: 14.h),

          // 2. Calculation Trace Card
          _buildTraceCard(trace),
          SizedBox(height: 18.h),

          // 3. Tab Navigation Chips
          _buildTabChips(),
          SizedBox(height: 14.h),

          // 4. Tab Content
          _buildActiveTabContent(interp, sections),
          SizedBox(height: 16.h),

          // 5. Ethical Disclaimer
          _buildEthicalDisclaimer(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String lpNum, String title, String coreTheme, bool isMaster) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
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
                width: 62.w,
                height: 62.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  lpNum,
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
                    if (isMaster)
                      Container(
                        margin: EdgeInsets.only(bottom: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '⭐ MASTER NUMBER',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Pythagorean System • Verified',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Text('✨', style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    coreTheme,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
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

  Widget _buildTraceCard(Map<String, dynamic> trace) {
    final monthTrace = trace['month'] as Map<String, dynamic>? ?? {};
    final dayTrace = trace['day'] as Map<String, dynamic>? ?? {};
    final yearTrace = trace['year'] as Map<String, dynamic>? ?? {};
    final reductionSteps = (trace['reduction_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Icon(Icons.account_tree_outlined, size: 15.sp, color: const Color(0xFF2563EB)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'CALCULATION TRACE',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'DOB: $_currentDob',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.sp,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _buildTracePill('Month', '${monthTrace['original'] ?? ''}', 'Reduced: ${monthTrace['reduced'] ?? ''}')),
              SizedBox(width: 8.w),
              Expanded(child: _buildTracePill('Day', '${dayTrace['original'] ?? ''}', 'Reduced: ${dayTrace['reduced'] ?? ''}')),
              SizedBox(width: 8.w),
              Expanded(child: _buildTracePill('Year', '${yearTrace['original'] ?? ''}', 'Reduced: ${yearTrace['reduced'] ?? ''}')),
            ],
          ),
          if (reductionSteps.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 13.sp, color: const Color(0xFF16A34A)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      reductionSteps.join(' ➔ '),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTracePill(String title, String raw, String reduced) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            raw,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            reduced,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w600,
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
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent(Map<String, dynamic> interp, List<dynamic> sections) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewContent(interp, sections);
      case 1:
        return _buildPersonalityContent(interp);
      case 2:
        return _buildRelationshipsContent(interp);
      case 3:
        return _buildCareerContent(interp);
      case 4:
        return _buildStrengthsContent(interp);
      case 5:
        return _buildPracticesContent(interp);
      default:
        return _buildOverviewContent(interp, sections);
    }
  }

  Widget _buildOverviewContent(Map<String, dynamic> interp, List<dynamic> sections) {
    final overviewText = interp['overview'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Life Path Overview',
          icon: Icons.auto_awesome_rounded,
          content: overviewText,
        ),
        SizedBox(height: 12.h),
        for (final sec in sections)
          if (sec['section_type'] == 'overview' || sec['section_type'] == 'traditional')
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildSectionCard(
                title: sec['heading'] ?? '',
                icon: Icons.lightbulb_outline_rounded,
                content: sec['content'] ?? '',
              ),
            ),
      ],
    );
  }

  Widget _buildPersonalityContent(Map<String, dynamic> interp) {
    final strengths = (interp['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final challenges = (interp['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      children: [
        _buildListCard(
          title: 'Core Personality Strengths',
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF16A34A),
          items: strengths,
        ),
        SizedBox(height: 14.h),
        _buildListCard(
          title: 'Potential Growth Challenges',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD97706),
          items: challenges,
        ),
      ],
    );
  }

  Widget _buildRelationshipsContent(Map<String, dynamic> interp) {
    final relText = interp['relationships'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Relationships & Relational Harmony',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE11D48),
          content: relText,
        ),
        SizedBox(height: 14.h),
        _buildHighlightCard(
          title: 'Constructive Relational Guidance',
          body: 'Numerology provides archetypal reflections of communication preferences and emotional temperaments. Real-world relationship harmony thrives on mutual respect, candid dialogue, and authentic empathy rather than guaranteed astronomical predictions.',
        ),
      ],
    );
  }

  Widget _buildCareerContent(Map<String, dynamic> interp) {
    final careerText = interp['career'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Career & Vocational Expression',
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF0284C7),
          content: careerText,
        ),
        SizedBox(height: 14.h),
        _buildHighlightCard(
          title: 'Work Environment Alignment',
          body: 'Discover workplaces that honor your natural rhythm—whether that means high-autonomy leadership, collaborative diplomacy, or focused analytical investigation.',
        ),
      ],
    );
  }

  Widget _buildStrengthsContent(Map<String, dynamic> interp) {
    final growthText = interp['personal_growth'] ?? '';
    final challenges = (interp['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      children: [
        _buildSectionCard(
          title: 'Actionable Reflection Guidance',
          icon: Icons.psychology_rounded,
          iconColor: const Color(0xFF7C3AED),
          content: growthText,
        ),
        SizedBox(height: 14.h),
        _buildListCard(
          title: 'Areas for Mindful Improvement',
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF2563EB),
          items: challenges,
        ),
      ],
    );
  }

  Widget _buildPracticesContent(Map<String, dynamic> interp) {
    final growthText = interp['personal_growth'] ?? '';

    return Column(
      children: [
        _buildSectionCard(
          title: 'Daily Reflection & Habit Building',
          icon: Icons.self_improvement_rounded,
          iconColor: const Color(0xFF059669),
          content: growthText,
        ),
        SizedBox(height: 14.h),
        _buildHighlightCard(
          title: 'Daily Grounding Affirmation',
          body: '“I honor my authentic path, embrace continuous learning, and direct my energy toward meaningful service and balanced personal well-being.”',
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF2563EB),
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                    color: const Color(0xFF0F172A),
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
              color: const Color(0xFF334155),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFF0F172A),
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
                        color: const Color(0xFF334155),
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

  Widget _buildHighlightCard({required String title, required String body}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF166534),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF15803D),
              height: 1.4,
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
