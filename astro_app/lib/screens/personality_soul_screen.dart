import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class PersonalitySoulScreen extends StatefulWidget {
  final String? initialBirthName;
  final String initialYPolicy;
  final Map<String, dynamic>? initialReportData;
  final int initialTabIndex;

  const PersonalitySoulScreen({
    super.key,
    this.initialBirthName,
    this.initialYPolicy = 'always_consonant',
    this.initialReportData,
    this.initialTabIndex = 0,
  });

  @override
  State<PersonalitySoulScreen> createState() => _PersonalitySoulScreenState();
}

class _PersonalitySoulScreenState extends State<PersonalitySoulScreen> {
  late final TextEditingController _nameController;
  late String _yPolicy;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  late int _selectedTabIndex;

  final List<String> _tabs = [
    'Overview',
    'Personality',
    'Soul Urge',
    'Strengths',
    'Challenges',
    'Relationships',
    'Career & Life',
    'Calculation Trace',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _nameController = TextEditingController(text: widget.initialBirthName ?? '');
    _yPolicy = widget.initialYPolicy;

    if (widget.initialReportData != null) {
      _reportData = widget.initialReportData;
    } else {
      _initializeAndCalculate();
    }
  }

  Future<void> _initializeAndCalculate() async {
    if (_nameController.text.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('numerology_user_name') ?? '';
      if (savedName.isNotEmpty && mounted) {
        setState(() {
          _nameController.text = savedName;
        });
      }
    }

    if (_nameController.text.trim().isNotEmpty) {
      _fetchReport();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchReport() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Full birth name is required for Personality & Soul Urge calculation.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getPersonalitySoulReport(
        birthName: name,
        yPolicy: _yPolicy,
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });

        // Persist name for convenient future visits
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('numerology_user_name', name);
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

  void _showEditNameDialog() {
    final editController = TextEditingController(text: _nameController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.edit_rounded, color: const Color(0xFF7C3AED), size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Change Birth Name',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your full name as recorded on your birth certificate for authoritative calculations.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.4),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: editController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Birth Name',
                hintText: 'e.g., Elizabeth Anne Taylor',
                filled: true,
                fillColor: const Color(0xFFFAF5FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _nameController.text = newName;
                });
                Navigator.pop(ctx);
                _fetchReport();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('Recalculate', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showYPolicyInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.info_outline_rounded, color: const Color(0xFF7C3AED), size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Letter Y Classification',
                style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B)),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Always as Consonant (Standard Pythagorean):',
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
              ),
              SizedBox(height: 4.h),
              Text(
                'Y is classified strictly as a consonant (numerical value 7). It contributes to your Personality Number and is excluded from your Soul Urge Number. This is the established Western Pythagorean standard.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569), height: 1.4),
              ),
              SizedBox(height: 12.h),
              Text(
                'Always as Vowel (Vocalic Policy):',
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF9333EA)),
              ),
              SizedBox(height: 4.h),
              Text(
                'Y is classified strictly as a vowel (numerical value 7). It contributes to your Soul Urge Number and is excluded from your Personality Number.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Understood', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFE),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEDE9FE), width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1E1B4B), size: 16.sp),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Personality & Soul',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            Text(
              'Consonants & Vowels Archetypes',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_reportData != null)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: _fetchReport,
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: const Color(0xFF7C3AED), size: 19.sp),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_reportData == null) {
      return _buildNameInputCard();
    }

    return Column(
      children: [
        _buildUserHeaderBar(),
        _buildTabNavigation(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: _buildSelectedTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Calculating Personality & Soul Urge...',
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Analyzing consonants for outer demeanor and vowels for heart desire.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 36.sp),
            ),
            SizedBox(height: 14.h),
            Text(
              'Calculation Error',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'An error occurred while calculating numerology.',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _showEditNameDialog,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text('Edit Name & Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputCard() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFE9D5FF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF5FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.join_inner_rounded, color: const Color(0xFF7C3AED), size: 36.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                'Birth Name Required',
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Text(
                'Enter your full name as it appears on your birth certificate to compute your authoritative Personality & Soul Urge Numbers.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Birth Name',
                  hintText: 'e.g., Elizabeth Anne Taylor',
                  filled: true,
                  fillColor: const Color(0xFFFAF5FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              ElevatedButton(
                onPressed: _fetchReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                child: Text(
                  'Calculate Numbers',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeaderBar() {
    final birthName = _reportData?['birth_name'] ?? _nameController.text;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFAF5FF),
            Color(0xFFF3E8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFE9D5FF),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 9.5.sp,
                            color: const Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 3.5.w),
                          Text(
                            'ANALYZED NAME',
                            style: GoogleFonts.inter(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7C3AED),
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  birthName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: _showEditNameDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 13.sp,
                      color: const Color(0xFF7C3AED),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Change',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
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

  Widget _buildTabNavigation() {
    return Container(
      height: 48.h,
      color: const Color(0xFFFBFBFE),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(20.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE9D5FF),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF581C87),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPersonalityTab();
      case 2:
        return _buildSoulUrgeTab();
      case 3:
        return _buildStrengthsTab();
      case 4:
        return _buildChallengesTab();
      case 5:
        return _buildRelationshipsTab();
      case 6:
        return _buildCareerTab();
      case 7:
        return _buildTraceTab();
      default:
        return _buildOverviewTab();
    }
  }

  // =========================================================================
  // TAB 1: OVERVIEW
  // =========================================================================
  Widget _buildOverviewTab() {
    final pers = _reportData?['personality'] as Map<String, dynamic>?;
    final soul = _reportData?['soul_urge'] as Map<String, dynamic>?;
    final harmony = _reportData?['harmony_analysis'] as Map<String, dynamic>?;

    final persNum = pers?['number'] ?? 0;
    final isPersMaster = pers?['is_master_number'] == true;
    final persTitle = (pers?['interpretation']?['title'] as String?) ?? 'Personality Demeanor';

    final soulNum = soul?['number'] ?? 0;
    final isSoulMaster = soul?['is_master_number'] == true;
    final soulTitle = (soul?['interpretation']?['title'] as String?) ?? "Soul Urge / Heart's Desire";

    final persWords = pers?['words_breakdown'] as List?;
    String persFormula = '';
    if (persWords != null && persWords.isNotEmpty) {
      persFormula = persWords
          .map((w) => (w['formula'] as String?) ?? '')
          .where((f) => f.isNotEmpty)
          .join(' + ');
    }
    if (persFormula.isEmpty) {
      persFormula = pers?['formula_summary']?.toString() ?? '';
    }

    final soulWords = soul?['words_breakdown'] as List?;
    String soulFormula = '';
    if (soulWords != null && soulWords.isNotEmpty) {
      soulFormula = soulWords
          .map((w) => (w['formula'] as String?) ?? '')
          .where((f) => f.isNotEmpty)
          .join(' + ');
    }
    if (soulFormula.isEmpty) {
      soulFormula = soul?['formula_summary']?.toString() ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dual Hero Cards
        Row(
          children: [
            // Personality Number Card
            Expanded(
              child: _buildCoreNumberCard(
                title: 'PERSONALITY',
                subtitle: 'The Outward Mask',
                number: persNum,
                isMaster: isPersMaster,
                basis: 'Consonants Only',
                formula: persFormula,
                accentColor: const Color(0xFF8B5CF6),
                bgTint: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFEDE9FE),
                icon: Icons.join_inner_rounded,
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
            ),
            SizedBox(width: 12.w),
            // Soul Urge Number Card
            Expanded(
              child: _buildCoreNumberCard(
                title: 'SOUL URGE',
                subtitle: "Heart's True Desire",
                number: soulNum,
                isMaster: isSoulMaster,
                basis: 'Vowels Only',
                formula: soulFormula,
                accentColor: const Color(0xFF7C3AED),
                bgTint: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFDDD6FE),
                icon: Icons.favorite_rounded,
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Cosmic Harmony Card
        if (harmony != null)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  blurRadius: 14,
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
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 15.sp),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                harmony['harmony_tag'] ?? 'Resonance Analysis',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'P$persNum + S$soulNum',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  'Inner Calling & Outer Persona Dynamics',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  harmony['harmony_summary'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 16.h),

        // Quick Highlights for both numbers
        _buildHighlightSummaryCard(
          title: 'Personality Aura ($persNum)',
          headline: persTitle,
          theme: pers?['interpretation']?['core_theme'] ?? '',
          color: const Color(0xFF8B5CF6),
          icon: Icons.shield_rounded,
          onExplore: () => setState(() => _selectedTabIndex = 1),
        ),

        SizedBox(height: 12.h),

        _buildHighlightSummaryCard(
          title: "Soul's Longing ($soulNum)",
          headline: soulTitle,
          theme: soul?['interpretation']?['core_theme'] ?? '',
          color: const Color(0xFF7C3AED),
          icon: Icons.wb_twilight_rounded,
          onExplore: () => setState(() => _selectedTabIndex = 2),
        ),

        SizedBox(height: 16.h),

        // Y Policy Quick Selector
        _buildYPolicySelectorCard(),
      ],
    );
  }

  Widget _buildCoreNumberCard({
    required String title,
    required String subtitle,
    required int number,
    required bool isMaster,
    required String basis,
    String? formula,
    required Color accentColor,
    required Color bgTint,
    required Color borderColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
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
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 15.sp),
                ),
                const Spacer(),
                if (isMaster)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'MASTER',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$number',
                  style: GoogleFonts.outfit(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      isMaster ? 'Master $number' : 'Root $number',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    basis,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                if (formula != null && formula.trim().isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                    ),
                    child: Text(
                      formula,
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightSummaryCard({
    required String title,
    required String headline,
    required String theme,
    required Color color,
    required IconData icon,
    required VoidCallback onExplore,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF3E8FF)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: onExplore,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deep Dive',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color, size: 16.sp),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            headline,
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          if (theme.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              theme,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYPolicySelectorCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: const Color(0xFF7C3AED), size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Letter Y Classification Policy',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.help_outline_rounded, size: 16.sp, color: const Color(0xFF7C3AED)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _showYPolicyInfoDialog,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Pythagorean numerology defaults Y to a consonant. You can switch to test vocalic Y if your tradition requires it.',
            style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B), height: 1.35),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildPolicyOption(
                  label: 'Y as Consonant',
                  sub: 'Default Pythagorean',
                  policyKey: 'always_consonant',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildPolicyOption(
                  label: 'Y as Vowel',
                  sub: 'Vocalic Policy',
                  policyKey: 'always_vowel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyOption({
    required String label,
    required String sub,
    required String policyKey,
  }) {
    final isSelected = _yPolicy == policyKey;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _yPolicy = policyKey;
          });
          _fetchReport();
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE9D5FF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
              size: 16.sp,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: const Color(0xFF94A3B8),
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

  // =========================================================================
  // TAB 2: PERSONALITY
  // =========================================================================
  Widget _buildPersonalityTab() {
    final pers = _reportData?['personality'] as Map<String, dynamic>?;
    if (pers == null) return const SizedBox();

    final num = pers['number'] ?? 0;
    final isMaster = pers['is_master_number'] == true;
    final interp = pers['interpretation'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroDetailBadge(
          title: 'PERSONALITY NUMBER',
          number: num,
          isMaster: isMaster,
          subtitle: 'The Outward Demeanor & First Impressions',
          color: const Color(0xFF8B5CF6),
          basisTag: 'Derived Strictly from Consonants',
        ),
        SizedBox(height: 16.h),
        _buildContentSection(
          title: 'Number Meaning & Core Demeanor',
          heading: interp?['title'] ?? 'The Archetype',
          coreTheme: interp?['core_theme'],
          body: interp?['overview'] ?? '',
          accentColor: const Color(0xFF8B5CF6),
        ),
        SizedBox(height: 14.h),
        _buildInfoBox(
          title: 'How Others Perceive You',
          body: 'Your Personality Number describes your initial energetic handshake with the world. It is the outer garment of your aura that people notice upon first meeting you.',
          accentColor: const Color(0xFF8B5CF6),
          icon: Icons.visibility_rounded,
        ),
        SizedBox(height: 14.h),
        _buildFormulaStrip(
          formula: pers['formula_summary'] ?? '',
          label: 'Consonants Sum',
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: SOUL URGE
  // =========================================================================
  Widget _buildSoulUrgeTab() {
    final soul = _reportData?['soul_urge'] as Map<String, dynamic>?;
    if (soul == null) return const SizedBox();

    final num = soul['number'] ?? 0;
    final isMaster = soul['is_master_number'] == true;
    final interp = soul['interpretation'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroDetailBadge(
          title: "SOUL URGE / HEART'S DESIRE",
          number: num,
          isMaster: isMaster,
          subtitle: 'Your Core Spiritual Motivations & True Desires',
          color: const Color(0xFF7C3AED),
          basisTag: 'Derived Strictly from Vowels',
        ),
        SizedBox(height: 16.h),
        _buildContentSection(
          title: "Soul Essence & Deepest Calling",
          heading: interp?['title'] ?? 'The Inner Flame',
          coreTheme: interp?['core_theme'],
          body: interp?['overview'] ?? '',
          accentColor: const Color(0xFF7C3AED),
        ),
        SizedBox(height: 14.h),
        _buildInfoBox(
          title: 'The Silent Longing of Your Spirit',
          body: "Unlike your outer personality, your Soul Urge is what drives you when you are completely alone with your thoughts. It reveals what truly brings peace and emotional fulfillment to your heart.",
          accentColor: const Color(0xFF7C3AED),
          icon: Icons.favorite_border_rounded,
        ),
        SizedBox(height: 14.h),
        _buildFormulaStrip(
          formula: soul['formula_summary'] ?? '',
          label: 'Vowels Sum',
          accentColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 4: STRENGTHS
  // =========================================================================
  Widget _buildStrengthsTab() {
    final persInterp = _reportData?['personality']?['interpretation'] as Map<String, dynamic>?;
    final soulInterp = _reportData?['soul_urge']?['interpretation'] as Map<String, dynamic>?;

    final persStrengths = (persInterp?['strengths'] as List?)?.cast<String>() ?? [];
    final soulStrengths = (soulInterp?['strengths'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildListCard(
          title: 'Personality Outward Strengths',
          subtitle: 'Gifts & talents the world notices immediately',
          items: persStrengths,
          icon: Icons.star_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
        SizedBox(height: 16.h),
        _buildListCard(
          title: 'Soul Urge Inner Spiritual Gifts',
          subtitle: 'Core internal values that fuel your resilience',
          items: soulStrengths,
          icon: Icons.diamond_rounded,
          accentColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 5: CHALLENGES
  // =========================================================================
  Widget _buildChallengesTab() {
    final persInterp = _reportData?['personality']?['interpretation'] as Map<String, dynamic>?;
    final soulInterp = _reportData?['soul_urge']?['interpretation'] as Map<String, dynamic>?;

    final persChallenges = (persInterp?['challenges'] as List?)?.cast<String>() ?? [];
    final soulChallenges = (soulInterp?['challenges'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildListCard(
          title: 'Personality Outer Blind Spots',
          subtitle: 'Impression habits that may misrepresent your true self',
          items: persChallenges,
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        SizedBox(height: 16.h),
        _buildListCard(
          title: 'Soul Urge Internal Vulnerabilities',
          subtitle: 'Emotional tension areas and private frustrations',
          items: soulChallenges,
          icon: Icons.psychology_rounded,
          accentColor: const Color(0xFFE11D48),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 6: RELATIONSHIPS
  // =========================================================================
  Widget _buildRelationshipsTab() {
    final persInterp = _reportData?['personality']?['interpretation'] as Map<String, dynamic>?;
    final soulInterp = _reportData?['soul_urge']?['interpretation'] as Map<String, dynamic>?;

    final persRel = persInterp?['relationships'] as String? ?? '';
    final soulRel = soulInterp?['relationships'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildParagraphCard(
          title: 'Outward Social Magnetism',
          subtitle: 'How you attract and engage with companions',
          body: persRel,
          icon: Icons.people_outline_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
        SizedBox(height: 16.h),
        _buildParagraphCard(
          title: 'Soul-Level Intimacy & Needs',
          subtitle: 'What your heart genuinely craves in lasting love',
          body: soulRel,
          icon: Icons.volunteer_activism_rounded,
          accentColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 7: CAREER & LIFE
  // =========================================================================
  Widget _buildCareerTab() {
    final persInterp = _reportData?['personality']?['interpretation'] as Map<String, dynamic>?;
    final soulInterp = _reportData?['soul_urge']?['interpretation'] as Map<String, dynamic>?;

    final persCareer = persInterp?['career'] as String? ?? '';
    final soulCareer = soulInterp?['career'] as String? ?? '';
    final persGuidance = persInterp?['guidance'] as String? ?? '';
    final soulGuidance = soulInterp?['guidance'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildParagraphCard(
          title: 'Outward Professional Style',
          subtitle: 'Leadership demeanor and collaborative aura in the workplace',
          body: persCareer,
          icon: Icons.work_outline_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
        SizedBox(height: 16.h),
        _buildParagraphCard(
          title: 'True Vocational Calling',
          subtitle: 'Work that brings profound emotional and spiritual meaning',
          body: soulCareer,
          icon: Icons.lightbulb_outline_rounded,
          accentColor: const Color(0xFF7C3AED),
        ),
        SizedBox(height: 16.h),
        _buildParagraphCard(
          title: 'Personality Balance Guidance',
          subtitle: 'How to harmonize your outward presentation',
          body: persGuidance,
          icon: Icons.self_improvement_rounded,
          accentColor: const Color(0xFF059669),
        ),
        SizedBox(height: 16.h),
        _buildParagraphCard(
          title: 'Soul Growth Advice',
          subtitle: 'Nourishing your inner spirit daily',
          body: soulGuidance,
          icon: Icons.spa_rounded,
          accentColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 8: CALCULATION TRACE
  // =========================================================================
  Widget _buildTraceTab() {
    final trace = _reportData?['audit_trace'] as Map<String, dynamic>?;
    final pers = _reportData?['personality'] as Map<String, dynamic>?;
    final soul = _reportData?['soul_urge'] as Map<String, dynamic>?;

    if (trace == null) return const SizedBox();

    final words = (trace['words'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final persSteps = (pers?['reduction_steps'] as List?)?.cast<String>() ?? [];
    final soulSteps = (soul?['reduction_steps'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Algorithm & Policy Metadata
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculation Engine & Standards',
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              SizedBox(height: 10.h),
              _buildTraceMetaRow('System Code', 'Pythagorean (Western 1-9)'),
              _buildTraceMetaRow('Algorithm Version', trace['algorithm_version'] ?? '1.0.0'),
              _buildTraceMetaRow('Letter Y Policy', trace['letter_classification_policy'] ?? ''),
              _buildTraceMetaRow('Master Numbers', '11, 22, 33 Preserved'),
              _buildTraceMetaRow('Total Evaluated Letters', '${trace['total_letters_evaluated'] ?? 0}'),
              _buildTraceMetaRow('Vowels Count', '${trace['vowels_count'] ?? 0} (Soul Urge)'),
              _buildTraceMetaRow('Consonants Count', '${trace['consonants_count'] ?? 0} (Personality)'),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Word-by-Word Breakdown
        Text(
          'Word-by-Word Letter Breakdown',
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        SizedBox(height: 10.h),

        ...words.map((w) {
          final word = w['word'] as String? ?? '';
          final letters = (w['letters'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      word,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${letters.length} letters',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: letters.map((l) {
                    final ch = l['letter'] ?? '';
                    final val = l['value'] ?? 0;
                    final isVowel = l['type'] == 'vowel';

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isVowel ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isVowel ? const Color(0xFFC084FC) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$ch',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isVowel ? const Color(0xFF7C3AED) : const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '$val',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isVowel ? const Color(0xFF9333EA) : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            isVowel ? 'V' : 'C',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: isVowel ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),

        SizedBox(height: 12.h),

        // Personality Calculation Math Card
        _buildMathStepCard(
          title: 'Personality Reduction Math (Consonants)',
          formula: pers?['formula_summary'] ?? '',
          steps: persSteps,
          finalNumber: pers?['number'] ?? 0,
          color: const Color(0xFF8B5CF6),
        ),

        SizedBox(height: 14.h),

        // Soul Urge Calculation Math Card
        _buildMathStepCard(
          title: "Soul Urge Reduction Math (Vowels)",
          formula: soul?['formula_summary'] ?? '',
          steps: soulSteps,
          finalNumber: soul?['number'] ?? 0,
          color: const Color(0xFF7C3AED),
        ),

        SizedBox(height: 16.h),

        // Disclaimer
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: const Color(0xFF94A3B8), size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _reportData?['disclaimer'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraceMetaRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150.w,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1B4B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathStepCard({
    required String title,
    required String formula,
    required List<String> steps,
    required int finalNumber,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.calculate_rounded, color: color, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Subtotals: $formula',
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 6.h),
          ...steps.map((st) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded, color: color, size: 16.sp),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        st,
                        style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              )),
          Divider(color: const Color(0xFFF1F5F9), height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Final Deterministic Result:',
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)),
                child: Text(
                  '$finalNumber',
                  style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER REUSABLE WIDGETS
  // =========================================================================
  Widget _buildHeroDetailBadge({
    required String title,
    required int number,
    required bool isMaster,
    required String subtitle,
    required Color color,
    required String basisTag,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.outfit(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (isMaster)
            Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'MASTER NUMBER $number',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1B4B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Text(
              basisTag,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required String heading,
    String? coreTheme,
    required String body,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                height: 16.h,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            heading,
            style: GoogleFonts.outfit(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          if (coreTheme != null && coreTheme.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFF3E8FF)),
              ),
              child: Text(
                coreTheme,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B21A8),
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String body,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 16.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaStrip({
    required String formula,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Row(
        children: [
          Icon(Icons.functions_rounded, color: accentColor, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              formula,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required String subtitle,
    required List<String> items,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (items.isEmpty)
            Text(
              'No specific items registered.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
            )
          else
            ...items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 5.h),
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          it,
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildParagraphCard({
    required String title,
    required String subtitle,
    required String body,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            body.isNotEmpty ? body : 'Detailed interpretation content is being updated.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
