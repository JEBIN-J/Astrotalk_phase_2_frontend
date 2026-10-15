import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';

class AdvancedCompatibilityScreen extends StatefulWidget {
  final String? initialPersonAName;
  final String? initialPersonADob;
  final String? initialSystem;
  final String? appBarTitle;
  final String? initialRelationshipType;

  const AdvancedCompatibilityScreen({
    super.key,
    this.initialPersonAName,
    this.initialPersonADob,
    this.initialSystem,
    this.appBarTitle,
    this.initialRelationshipType,
  });

  @override
  State<AdvancedCompatibilityScreen> createState() => _AdvancedCompatibilityScreenState();
}

class _AdvancedCompatibilityScreenState extends State<AdvancedCompatibilityScreen> with SingleTickerProviderStateMixin {
  // Theme Color Palette - Lilac & Royal Purple (Matching Dashboard Explore Card)
  static const Color primaryPurple = Color(0xFFA855F7);
  static const Color deepPurple = Color(0xFF9333EA);
  static const Color darkPurple = Color(0xFF7E22CE);
  static const Color screenBg = Color(0xFFFAF5FF);
  static const Color cardBg = Color(0xFFFAF5FF);
  static const Color cardBorder = Color(0xFFF3E8FF);
  static const Color badgeBg = Color(0xFFF3E8FF);
  static const Color badgeText = Color(0xFF7E22CE);
  static const Color darkText = Color(0xFF1E293B);
  static const Color mutedText = Color(0xFF64748B);

  // Controllers
  final TextEditingController _nameAController = TextEditingController();
  final TextEditingController _dobAController = TextEditingController();
  final TextEditingController _nameBController = TextEditingController();
  final TextEditingController _dobBController = TextEditingController();

  // State
  String _selectedRelationshipType = 'romantic';
  String _selectedSystem = 'pythagorean'; // 'pythagorean' or 'chaldean'
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _compatibilityReport;
  bool _isSaved = false;

  late TabController _tabController;

  final List<Map<String, dynamic>> _relationshipTypes = [
    {'type': 'romantic', 'label': 'Romantic', 'icon': Icons.favorite_rounded},
    {'type': 'marriage', 'label': 'Marriage', 'icon': Icons.celebration_rounded},
    {'type': 'friendship', 'label': 'Friendship', 'icon': Icons.people_alt_rounded},
    {'type': 'business', 'label': 'Business', 'icon': Icons.business_center_rounded},
    {'type': 'family', 'label': 'Family', 'icon': Icons.family_restroom_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialPersonAName != null && widget.initialPersonAName!.isNotEmpty) {
      _nameAController.text = widget.initialPersonAName!;
    }
    if (widget.initialPersonADob != null && widget.initialPersonADob!.isNotEmpty) {
      _dobAController.text = widget.initialPersonADob!;
    }
    if (widget.initialSystem != null && widget.initialSystem!.isNotEmpty) {
      _selectedSystem = widget.initialSystem!.toLowerCase();
    }
    if (widget.initialRelationshipType != null && widget.initialRelationshipType!.isNotEmpty) {
      _selectedRelationshipType = widget.initialRelationshipType!.toLowerCase();
    }

    // Auto-calculate if initial inputs exist for both
    if (_nameAController.text.isNotEmpty && _nameBController.text.isNotEmpty) {
      _calculateCompatibility();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameAController.dispose();
    _dobAController.dispose();
    _nameBController.dispose();
    _dobBController.dispose();
    super.dispose();
  }

  // =========================================================================
  // API ACTIONS
  // =========================================================================

  Future<void> _calculateCompatibility() async {
    final nameA = _nameAController.text.trim();
    final nameB = _nameBController.text.trim();
    final dobA = _dobAController.text.trim();
    final dobB = _dobBController.text.trim();

    if (nameA.isEmpty) {
      setState(() => _errorMessage = "Please enter Person A's name.");
      return;
    }
    if (nameB.isEmpty) {
      setState(() => _errorMessage = "Please enter Person B's name.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSaved = false;
    });

    try {
      final res = await AstroApiService.calculateAdvancedCompatibility(
        personAName: nameA,
        personBName: nameB,
        personADob: dobA.isNotEmpty ? dobA : null,
        personBDob: dobB.isNotEmpty ? dobB : null,
        relationshipType: _selectedRelationshipType,
        system: _selectedSystem,
      );

      setState(() {
        _compatibilityReport = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _swapProfiles() {
    final tempName = _nameAController.text;
    final tempDob = _dobAController.text;
    _nameAController.text = _nameBController.text;
    _dobAController.text = _dobBController.text;
    _nameBController.text = tempName;
    _dobBController.text = tempDob;
    _calculateCompatibility();
  }

  Future<void> _saveCurrentReport() async {
    if (_compatibilityReport == null) return;
    try {
      final res = await AstroApiService.saveCompatibilityReport(
        relationshipType: _selectedRelationshipType,
        system: _selectedSystem,
        personALabel: _nameAController.text.trim(),
        personBLabel: _nameBController.text.trim(),
        calculatedData: _compatibilityReport!,
      );
      if (res['status'] == 'success') {
        setState(() => _isSaved = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compatibility report saved successfully!', style: GoogleFonts.inter(fontSize: 13.sp)),
              backgroundColor: deepPurple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: $e', style: GoogleFonts.inter(fontSize: 13.sp)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (_compatibilityReport == null) return;
    final overall = _compatibilityReport!['overall_harmony'] as Map<String, dynamic>? ?? {};
    final score = overall['score_index'] ?? 0;
    final cat = overall['category'] ?? 'Harmony';
    final nameA = _nameAController.text.trim();
    final nameB = _nameBController.text.trim();

    final text = '✨ Advanced Numerology Compatibility ✨\n'
        '• $nameA & $nameB\n'
        '• Relationship Type: ${_selectedRelationshipType.toUpperCase()}\n'
        '• Harmony Index: $score/100 ($cat)\n'
        '• Calculation System: ${_selectedSystem.toUpperCase()}\n\n'
        'Calculated using authentic Pythagorean & Chaldean vibrational principles.';

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compatibility summary copied to clipboard!', style: GoogleFonts.inter(fontSize: 13.sp)),
          backgroundColor: deepPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  Future<void> _pickDate(BuildContext ctx, TextEditingController controller) async {
    DateTime initial = DateTime(1995, 6, 15);
    try {
      if (controller.text.isNotEmpty) {
        initial = DateFormat('yyyy-MM-dd').parse(controller.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: deepPurple,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // =========================================================================
  // BUILD METHOD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(color: deepPurple, backgroundColor: badgeBg),
            Expanded(
              child: _compatibilityReport == null
                  ? _buildInputFormView()
                  : _buildReportResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: darkText, size: 22.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: deepPurple, size: 16.sp),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              widget.appBarTitle ?? 'Advanced Compatibility',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (_compatibilityReport != null) ...[
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? deepPurple : mutedText,
              size: 20.sp,
            ),
            onPressed: _saveCurrentReport,
            tooltip: 'Save Report',
          ),
          IconButton(
            icon: Icon(Icons.share_rounded, color: mutedText, size: 20.sp),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
        ],
        SizedBox(width: 6.w),
      ],
    );
  }

  // =========================================================================
  // VIEW 1: INPUT FORM VIEW
  // =========================================================================

  Widget _buildInputFormView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: cardBorder, width: 1.2.w),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.favorite_rounded, color: Colors.white, size: 24.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authentic Multi-Factor Analysis',
                        style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Calculates Life Path, Birth Day, Name Sound, Soul Urge & Personality harmony using documented rules.',
                        style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 1. Relationship Type Selector
          Text(
            '1. RELATIONSHIP CONTEXT',
            style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: mutedText),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 38.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _relationshipTypes.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, i) {
                final rel = _relationshipTypes[i];
                final isSel = _selectedRelationshipType == rel['type'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rel['icon'] as IconData, size: 13.sp, color: isSel ? Colors.white : deepPurple),
                      SizedBox(width: 6.w),
                      Text(rel['label'] as String),
                    ],
                  ),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRelationshipType = rel['type'] as String);
                  },
                  selectedColor: deepPurple,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSel ? deepPurple : cardBorder),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white : darkText,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),

          // 2. Numerology System Toggle
          Text(
            '2. CALCULATION SYSTEM',
            style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: mutedText),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSystemChoiceButton('pythagorean', 'Pythagorean (Western 1-9)'),
                ),
                Expanded(
                  child: _buildSystemChoiceButton('chaldean', 'Chaldean (Ancient 1-8)'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 3. Person A Card
          _buildPersonCard(
            title: 'PERSON A (YOU / SEEKER)',
            nameController: _nameAController,
            dobController: _dobAController,
            avatarIcon: Icons.person_rounded,
            badgeColor: primaryPurple,
          ),
          SizedBox(height: 14.h),

          // Swap indicator
          Center(
            child: IconButton.filledTonal(
              onPressed: _swapProfiles,
              icon: Icon(Icons.swap_vert_rounded, color: deepPurple, size: 20.sp),
              style: IconButton.styleFrom(
                backgroundColor: badgeBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              tooltip: 'Swap Person A and Person B',
            ),
          ),
          SizedBox(height: 6.h),

          // 4. Person B Card
          _buildPersonCard(
            title: 'PERSON B (PARTNER / COMPANION)',
            nameController: _nameBController,
            dobController: _dobBController,
            avatarIcon: Icons.favorite_rounded,
            badgeColor: const Color(0xFFD946EF),
          ),
          SizedBox(height: 16.h),

          // Error Message Display
          if (_errorMessage != null)
            Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.red.shade700, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red.shade800, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _calculateCompatibility,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepPurple,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: deepPurple.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10.w),
                        Text('Calculating Resonance...', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text('Calculate Advanced Compatibility', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildSystemChoiceButton(String sys, String label) {
    final isSel = _selectedSystem == sys;
    return GestureDetector(
      onTap: () => setState(() => _selectedSystem = sys),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSel ? badgeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: isSel ? Border.all(color: deepPurple.withValues(alpha: 0.4)) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11.5.sp,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? deepPurple : mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard({
    required String title,
    required TextEditingController nameController,
    required TextEditingController dobController,
    required IconData avatarIcon,
    required Color badgeColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.04),
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
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(avatarIcon, color: badgeColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: darkText, letterSpacing: 0.8),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Name Input
          Text('FULL NAME', style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: mutedText)),
          SizedBox(height: 4.h),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBFE),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cardBorder),
            ),
            child: TextField(
              controller: nameController,
              style: GoogleFonts.inter(fontSize: 13.5.sp, color: darkText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.spellcheck_rounded, color: deepPurple, size: 18.sp),
                hintText: 'e.g. Eleanor or Alexander',
                hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // DOB Picker
          Text('DATE OF BIRTH (OPTIONAL BUT RECOMMENDED)', style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: mutedText)),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => _pickDate(context, dobController),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBFE),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_rounded, color: deepPurple, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      dobController.text.isNotEmpty ? dobController.text : 'Select Date of Birth (YYYY-MM-DD)',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: dobController.text.isNotEmpty ? darkText : const Color(0xFF94A3B8),
                        fontWeight: dobController.text.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, size: 15.sp, color: deepPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: REPORT RESULTS VIEW
  // =========================================================================

  Widget _buildReportResultsView() {
    return Column(
      children: [
        _buildHeroHeaderCard(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildFactorByFactorTab(),
              _buildProfilesTraceTab(),
              _buildRelationshipDynamicsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderCard() {
    final overall = _compatibilityReport?['overall_harmony'] as Map<String, dynamic>? ?? {};
    final score = overall['score_index'] ?? 0;
    final cat = overall['category'] ?? 'Natural Harmony';
    final nameA = _nameAController.text.trim();
    final nameB = _nameBController.text.trim();

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Score Radial Badge
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryPurple, darkPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                      ),
                      Text(
                        'INDEX',
                        style: GoogleFonts.outfit(fontSize: 8.sp, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
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
                        Flexible(
                          child: Text(
                            '$nameA & $nameB',
                            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: darkText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6.r)),
                          child: Text(
                            _selectedSystem == 'chaldean' ? 'Chaldean' : 'Pythagorean',
                            style: GoogleFonts.firaCode(fontSize: 9.sp, fontWeight: FontWeight.w800, color: badgeText),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, color: deepPurple),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showEditInputsDialog,
                icon: Icon(Icons.tune_rounded, color: deepPurple, size: 20.sp),
                tooltip: 'Modify Inputs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 42.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: deepPurple,
        indicatorWeight: 3.h,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: deepPurple,
        unselectedLabelColor: mutedText,
        labelStyle: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview & Harmony'),
          Tab(text: 'Factor Breakdown'),
          Tab(text: 'Profiles Trace'),
          Tab(text: 'Dynamics & Guidance'),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW & HARMONY
  // =========================================================================

  Widget _buildOverviewTab() {
    final overall = _compatibilityReport?['overall_harmony'] as Map<String, dynamic>? ?? {};
    final headline = overall['headline'] ?? 'Resonance Evaluation';
    final strengths = (_compatibilityReport?['strengths_summary'] as List<dynamic>?) ?? [];
    final growths = (_compatibilityReport?['growth_areas_summary'] as List<dynamic>?) ?? [];
    final transparency = _compatibilityReport?['scoring_transparency'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Headline Banner
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: deepPurple, size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.inter(fontSize: 12.5.sp, color: darkText, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Core Strengths
        if (strengths.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: cardBorder, width: 1.2.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 16.sp),
                    SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Natural Strengths & Harmony',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ],
                ),
                SizedBox(height: 10.h),
                ...strengths.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(color: deepPurple, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              s.toString().replaceAll('**', ''),
                              style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // Growth & Understanding Areas
        if (growths.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: cardBorder, width: 1.2.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: primaryPurple, size: 16.sp),
                    SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Areas Requiring Understanding & Adaptation',
                      style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ],
                ),
                SizedBox(height: 10.h),
                ...growths.map((g) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(color: Colors.amber.shade700, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              g.toString().replaceAll('**', ''),
                              style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // Transparent Scoring Disclosure Card
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8FE),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: deepPurple, size: 15.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Transparent Calculation Formula',
                    style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                transparency['formula_expression'] ?? 'Normalized Weighted Factor Index',
                style: GoogleFonts.firaCode(fontSize: 10.5.sp, color: deepPurple, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                transparency['normalization_note'] ?? 'All factors normalized deterministically.',
                style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // =========================================================================
  // TAB 2: FACTOR-BY-FACTOR COMPATIBILITY
  // =========================================================================

  Widget _buildFactorByFactorTab() {
    final factors = (_compatibilityReport?['factor_comparisons'] as List<dynamic>?) ?? [];

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      itemCount: factors.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, i) {
        final f = factors[i] as Map<String, dynamic>;
        final title = f['factor_title'] ?? 'Factor';
        final numA = f['person_a_number'];
        final numB = f['person_b_number'];
        final cat = f['compatibility_category'] ?? 'Category';
        final score = f['score_value'] ?? 0;
        final normWeight = f['normalized_weight_percent'] ?? 20;
        final ruleExpl = f['rule_explanation'] ?? '';
        final interp = f['interpretation'] as Map<String, dynamic>? ?? {};

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Weight: $normWeight% of overall harmony index',
                          style: GoogleFonts.inter(fontSize: 10.sp, color: mutedText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$score%',
                      style: GoogleFonts.firaCode(fontSize: 12.sp, fontWeight: FontWeight.w800, color: deepPurple),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Number pair strip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Person A', style: GoogleFonts.inter(fontSize: 9.sp, color: mutedText, fontWeight: FontWeight.w600)),
                          Text('Root $numA', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: darkText)),
                        ],
                      ),
                    ),
                    Container(width: 1.w, height: 26.h, color: cardBorder),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          '&',
                          style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: primaryPurple),
                        ),
                      ),
                    ),
                    Container(width: 1.w, height: 26.h, color: cardBorder),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Person B', style: GoogleFonts.inter(fontSize: 9.sp, color: mutedText, fontWeight: FontWeight.w600)),
                          Text('Root $numB', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: darkText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              // Category Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: deepPurple),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                ruleExpl,
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.4),
              ),

              if (interp.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Divider(color: cardBorder, height: 1.h),
                SizedBox(height: 10.h),
                Text(
                  'COMMUNICATION GUIDANCE',
                  style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: deepPurple),
                ),
                SizedBox(height: 3.h),
                Text(
                  interp['communication_guidance'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.35),
                ),
                SizedBox(height: 8.h),
                Text(
                  'PRACTICAL ACTION',
                  style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: deepPurple),
                ),
                SizedBox(height: 3.h),
                Text(
                  interp['practical_guidance'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.35),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 3: PROFILES TRACE & ARITHMETIC
  // =========================================================================

  Widget _buildProfilesTraceTab() {
    final pA = _compatibilityReport?['person_a'] as Map<String, dynamic>? ?? {};
    final pB = _compatibilityReport?['person_b'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        _buildProfileTraceCard('Person A', pA, primaryPurple),
        SizedBox(height: 14.h),
        _buildProfileTraceCard('Person B', pB, const Color(0xFFD946EF)),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildProfileTraceCard(String label, Map<String, dynamic> pData, Color accentColor) {
    final name = pData['name'] ?? 'Anonymous';
    final dob = pData['dob'] ?? 'Not provided';
    final numbers = pData['numbers'] as Map<String, dynamic>? ?? {};
    final steps = pData['calculation_steps'] as Map<String, dynamic>? ?? {};
    final nameSteps = steps['name'] as Map<String, dynamic>? ?? {};
    final letters = (nameSteps['letter_breakdown'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: accentColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label: $name',
                      style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    Text(
                      'DOB: $dob',
                      style: GoogleFonts.inter(fontSize: 10.5.sp, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 5 Core Numbers Pills
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(child: _buildProfilePill('Mulank', '${numbers['birth_number'] ?? '-' }')),
                _buildProfileDivider(),
                Expanded(child: _buildProfilePill('Life Path', '${numbers['life_path'] ?? '-' }')),
                _buildProfileDivider(),
                Expanded(child: _buildProfilePill('Name Root', '${numbers['name_number'] ?? '-' }')),
                _buildProfileDivider(),
                Expanded(child: _buildProfilePill('Soul Urge', '${numbers['soul_urge'] ?? '-' }')),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Letters Wrap trace
          if (letters.isNotEmpty) ...[
            Text('Letter Vibrations (${_selectedSystem.toUpperCase()}):', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w700, color: mutedText)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: letters.map((l) {
                final isVowel = l['is_vowel'] == true;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isVowel ? badgeBg : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: isVowel ? deepPurple : cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l['letter'] ?? '', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, color: darkText)),
                      SizedBox(width: 3.w),
                      Text('=${l['value']}', style: GoogleFonts.firaCode(fontSize: 10.sp, color: deepPurple, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePill(String title, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 8.5.sp, color: mutedText, fontWeight: FontWeight.w600)),
        SizedBox(height: 2.h),
        Text(val, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w900, color: darkText)),
      ],
    );
  }

  Widget _buildProfileDivider() {
    return Container(width: 1.w, height: 22.h, color: cardBorder);
  }

  // =========================================================================
  // TAB 4: RELATIONSHIP DYNAMICS & ETHICAL GUIDANCE
  // =========================================================================

  Widget _buildRelationshipDynamicsTab() {
    final relTypeCapitalized = _selectedRelationshipType[0].toUpperCase() + _selectedRelationshipType.substring(1);
    final limitations = _compatibilityReport?['limitations_statement'] ?? '';

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      children: [
        // Relationship Type Context Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.diversity_3_rounded, color: deepPurple, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '$relTypeCapitalized Dynamic Principles',
                      style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'In $relTypeCapitalized bonds, harmonious numbers indicate shared cadence and effortless rapport. '
                'However, real connection thrives on proactive boundaries, clear communication rituals, and genuine commitment.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 3 Pillars of Long-Term Harmony
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRACTICAL ALIGNMENT PRACTICES',
                style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: deepPurple),
              ),
              SizedBox(height: 10.h),
              _buildGuidanceItem(
                Icons.record_voice_over_rounded,
                'Empathetic Communication Check-ins',
                'Hold regular, non-defensive check-ins to express feelings, goals, and needs without assumptions.',
              ),
              SizedBox(height: 8.h),
              _buildGuidanceItem(
                Icons.health_and_safety_rounded,
                'Sacred Personal Boundaries',
                'Healthy relationships require individual room to breathe. Respect each other\'s solo hobbies, personal space, and friendships.',
              ),
              SizedBox(height: 8.h),
              _buildGuidanceItem(
                Icons.handshake_rounded,
                'Collaborative Agreements',
                'Establish explicit mutual agreements around finances, responsibilities, and decision-making instead of unstated expectations.',
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Ethical Limitations & Transparency
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.red.shade700, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Traditional Philosophy & Ethical Disclaimer',
                      style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.red.shade900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                limitations.isNotEmpty
                    ? limitations
                    : 'Numerology is a traditional symbolic tool for self-reflection and communication insight. '
                        'It is not a scientific test or guarantee of relationship outcomes.',
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red.shade800, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildGuidanceItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
          child: Icon(icon, size: 14.sp, color: deepPurple),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: darkText)),
              SizedBox(height: 2.h),
              Text(desc, style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // EDIT INPUTS MODAL
  // =========================================================================

  void _showEditInputsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, MediaQuery.of(ctx).viewInsets.bottom + 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Compatibility Inputs', style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w800, color: darkText)),
                    IconButton(icon: Icon(Icons.close_rounded, size: 20.sp, color: mutedText), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildPersonCard(title: 'Person A', nameController: _nameAController, dobController: _dobAController, avatarIcon: Icons.person_rounded, badgeColor: primaryPurple),
                SizedBox(height: 10.h),
                _buildPersonCard(title: 'Person B', nameController: _nameBController, dobController: _dobBController, avatarIcon: Icons.favorite_rounded, badgeColor: const Color(0xFFD946EF)),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _calculateCompatibility();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: Text('Re-calculate Compatibility', style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
