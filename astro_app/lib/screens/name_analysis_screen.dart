import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class NameAnalysisScreen extends StatefulWidget {
  final String? initialBirthName;
  final String? initialCurrentName;
  final String initialSystem;
  final String? dateOfBirth;
  final Map<String, dynamic>? initialReportData;

  const NameAnalysisScreen({
    super.key,
    this.initialBirthName,
    this.initialCurrentName,
    this.initialSystem = 'pythagorean',
    this.dateOfBirth,
    this.initialReportData,
  });

  @override
  State<NameAnalysisScreen> createState() => _NameAnalysisScreenState();
}

class _NameAnalysisScreenState extends State<NameAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _birthNameController;
  late final TextEditingController _currentNameController;
  late final TextEditingController _dobController;
  late String _selectedSystem;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  bool _isFormExpanded = true;
  int _selectedCoreTab = 0; // 0: Expression, 1: Soul Urge, 2: Personality
  int _selectedTabIndex = 0; // 0: Overview, 1: Personality, 2: Strengths, 3: Challenges, 4: Relationships, 5: Career & Work, 6: Pillars & Harmony, 7: Calculation

  final List<String> _tabTitles = [
    'Overview',
    'Personality',
    'Strengths',
    'Challenges',
    'Relationships',
    'Career & Work',
    'Pillars & Harmony',
    'Calculation',
  ];

  @override
  void initState() {
    super.initState();
    _birthNameController = TextEditingController(text: widget.initialBirthName ?? '');
    _currentNameController = TextEditingController(text: widget.initialCurrentName ?? '');
    _dobController = TextEditingController(text: widget.dateOfBirth ?? '');
    _selectedSystem = widget.initialSystem.isNotEmpty ? widget.initialSystem : 'pythagorean';

    if (widget.initialReportData != null) {
      _reportData = widget.initialReportData;
      _isFormExpanded = false;
    } else {
      _initializeUserContext();
    }
  }

  Future<void> _initializeUserContext() async {
    if (_birthNameController.text.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('numerology_user_name') ?? '';
      final savedDob = prefs.getString('numerology_user_dob') ?? '';
      final savedSystem = prefs.getString('numerology_user_system') ?? 'pythagorean';

      if (mounted) {
        setState(() {
          if (savedName.isNotEmpty) _birthNameController.text = savedName;
          if (_dobController.text.isEmpty && savedDob.isNotEmpty) _dobController.text = savedDob;
          if (widget.initialSystem.isEmpty && savedSystem.isNotEmpty) _selectedSystem = savedSystem;
        });

        if (_birthNameController.text.trim().isNotEmpty) {
          _performCalculation();
        }
      }
    } else {
      _performCalculation();
    }
  }

  @override
  void dispose() {
    _birthNameController.dispose();
    _currentNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _performCalculation() async {
    final birthName = _birthNameController.text.trim();
    if (birthName.isEmpty) {
      setState(() {
        _errorMessage = 'Full birth name is required for Name Analysis.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getNameAnalysisReport(
        birthName: birthName,
        currentName: _currentNameController.text.trim().isNotEmpty ? _currentNameController.text.trim() : null,
        system: _selectedSystem,
        dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
          _isFormExpanded = false; // Auto-collapse to focus on results
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

  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.auto_stories_rounded, color: const Color(0xFF2563EB), size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Numerology Systems',
                style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
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
                'Pythagorean System (Modern Western):',
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
              ),
              SizedBox(height: 4.h),
              Text(
                'Assigns letters A through Z sequentially to numbers 1 to 9. Analyzes the full name for Expression/Destiny, vowels for Soul Urge, consonants for Personality, and identifies foundational Cornerstone and Capstone letters.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569), height: 1.4),
              ),
              SizedBox(height: 14.h),
              Text(
                'Chaldean System (Ancient Vibrational):',
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
              ),
              SizedBox(height: 4.h),
              Text(
                'Rooted in ancient Babylonian astrology. Letters are assigned numbers 1 to 8 based on planetary sound vibrations (9 is considered sacred and omitted from letter mapping). Preserves a compound total whose mystical archetype reveals deep karmic patterns.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Understood',
              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54.w,
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
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B), size: 19.sp),
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
              'Name Analysis',
              style: GoogleFonts.outfit(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'Pythagorean & Chaldean Vibrations',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_reportData != null) ...[
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => setState(() => _isFormExpanded = !_isFormExpanded),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFormExpanded ? Icons.close_rounded : Icons.edit_outlined,
                      color: const Color(0xFFD97706),
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: _showSystemInfoDialog,
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.info_outline_rounded, color: const Color(0xFFD97706), size: 19.sp),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isFormExpanded || _reportData == null) ...[
                _buildInputFormCard(),
                SizedBox(height: 14.h),
              ],
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_reportData != null)
                _buildResultsView(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. INPUT FORM CARD (Pastel Soft Luxury Style)
  // =========================================================================
  Widget _buildInputFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (_reportData != null) {
                setState(() => _isFormExpanded = !_isFormExpanded);
              }
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22.r),
              bottom: _isFormExpanded ? Radius.zero : Radius.circular(22.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Icon(Icons.badge_rounded, color: const Color(0xFFD97706), size: 19.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name Configuration',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _reportData != null && !_isFormExpanded
                              ? '${_birthNameController.text} (${_selectedSystem.toUpperCase()})'
                              : 'Enter your birth name and select calculation system',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_reportData != null)
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFormExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF64748B),
                        size: 20.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isFormExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Selector
                    Text(
                      'Calculation System',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSystemOptionPill(
                            id: 'pythagorean',
                            title: 'Pythagorean',
                            subtitle: 'Modern (1-9)',
                            icon: Icons.calculate_rounded,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildSystemOptionPill(
                            id: 'chaldean',
                            title: 'Chaldean',
                            subtitle: 'Ancient (1-8)',
                            icon: Icons.stars_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Full Birth Name Field
                    Text(
                      'Full Name at Birth *',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _birthNameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'e.g. John Ronald Reuel Tolkien',
                        hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 19.sp, color: const Color(0xFFF59E0B)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full birth name is required.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Traditionally used for core life destiny and spiritual purpose analysis.',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
                    ),
                    SizedBox(height: 14.h),

                    // Current Name Field (Optional)
                    Text(
                      'Current / Commonly Used Name (Optional)',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _currentNameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'e.g. J.R.R. Tolkien or Johnny',
                        hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.edit_note_rounded, size: 19.sp, color: const Color(0xFF94A3B8)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Analyzed separately to evaluate vibrational harmony with your birth name.',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
                    ),
                    SizedBox(height: 14.h),

                    // Optional Date of Birth
                    Text(
                      'Date of Birth (Optional)',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD (e.g. 1995-05-15)',
                        hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18.sp, color: const Color(0xFF94A3B8)),
                        suffixIcon: _dobController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 16.sp, color: const Color(0xFF94A3B8)),
                                onPressed: () => setState(() => _dobController.clear()),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Not required for name analysis, but reveals harmony with your Life Path.',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
                    ),
                    SizedBox(height: 14.h),

                    // Alphabet Transliteration Note (Soft Mint Box)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.translate_rounded, size: 18.sp, color: const Color(0xFF10B981)),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Supported Alphabet: Standard Latin (A-Z) & common accented characters. For non-Latin scripts (e.g., Devanagari, Arabic, Cyrillic), please enter an English/Latin transliteration.',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF065F46),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Warm Golden Orange Gradient Calculate Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: _isLoading ? null : _performCalculation,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            child: _isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 22.w,
                                      height: 22.w,
                                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 18.sp, color: Colors.white),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Calculate Name Analysis',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemOptionPill({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedSystem == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSystem = id;
        });
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      color: isSelected ? const Color(0xFFD97706) : const Color(0xFF64748B),
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    DateTime initial = DateTime(1995, 5, 15);
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF59E0B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  // =========================================================================
  // 2. LOADING & ERROR STATES
  // =========================================================================
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 42.w,
            height: 42.w,
            child: const CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 3.2),
          ),
          SizedBox(height: 16.h),
          Text(
            'Calculating Numerology Blueprint...',
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          SizedBox(height: 6.h),
          Text(
            'Analyzing letter vibrational frequencies and reduction sequences',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: const Color(0xFFDC2626), size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculation Error',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _errorMessage ?? 'An error occurred during calculation.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFB91C1C)),
                ),
                SizedBox(height: 10.h),
                InkWell(
                  onTap: _performCalculation,
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
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

  // =========================================================================
  // 3. RESULTS VIEW
  // =========================================================================
  Widget _buildResultsView() {
    final analysis = _reportData!['analysis'] as Map<String, dynamic>;
    final isPythagorean = _reportData!['system'] == 'pythagorean';
    final comparison = _reportData!['name_comparison'] as Map<String, dynamic>?;
    final dobHarmony = _reportData!['dob_harmony'] as Map<String, dynamic>?;
    final name = analysis['original_name'] ?? _birthNameController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: YOUR NAME BLUEPRINT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NAME BLUEPRINT',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5.sp,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (name.toString().isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      name.toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                isPythagorean ? 'Pythagorean' : 'Chaldean',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // 3 Side-by-Side Cards (Expression, Soul Urge, Personality - Matching Screenshot 2)
        if (isPythagorean)
          _buildPythagoreanCosmicCards(analysis)
        else
          _buildChaldeanCosmicCards(analysis),
        SizedBox(height: 16.h),

        // Horizontal Tab Bar (matching Image 2)
        _buildTabChips(),
        SizedBox(height: 14.h),

        // Active Tab Content View (Switches content cleanly with zero endless scrolling)
        _buildActiveTabContent(analysis, isPythagorean, comparison, dobHarmony),
        SizedBox(height: 16.h),

        // Metaphysical Disclaimer
        _buildDisclaimerCard(),
        SizedBox(height: 24.h),
      ],
    );
  }

  // =========================================================================
  // 5. 3 SIDE-BY-SIDE CORE CARDS (Matching Screenshot 2 Format)
  // =========================================================================
  Widget _buildPythagoreanCosmicCards(Map<String, dynamic> analysis) {
    final core = analysis['core_numbers'] as Map<String, dynamic>;
    final expr = core['expression'] as Map<String, dynamic>;
    final soul = core['soul_urge'] as Map<String, dynamic>;
    final pers = core['personality'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _buildCoreCardItem(
            index: 0,
            number: expr['final_number'].toString(),
            title: 'Expression',
            subtitle: 'Life Mission',
            color: const Color(0xFF8B5CF6),
            isMaster: expr['is_master_number'] == true,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildCoreCardItem(
            index: 1,
            number: soul['final_number'].toString(),
            title: 'Soul Urge',
            subtitle: 'Inner Desire',
            color: const Color(0xFFF59E0B),
            isMaster: soul['is_master_number'] == true,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildCoreCardItem(
            index: 2,
            number: pers['final_number'].toString(),
            title: 'Personality',
            subtitle: 'Outer Persona',
            color: const Color(0xFF10B981),
            isMaster: pers['is_master_number'] == true,
          ),
        ),
      ],
    );
  }

  Widget _buildChaldeanCosmicCards(Map<String, dynamic> analysis) {
    final compound = analysis['chaldean_compound_number']?.toString() ?? '';
    final root = analysis['chaldean_root_number']?.toString() ?? '';

    return Row(
      children: [
        Expanded(
          child: _buildCoreCardItem(
            index: 0,
            number: compound,
            title: 'Compound',
            subtitle: 'Ancient Vibration',
            color: const Color(0xFFF59E0B),
            isMaster: false,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildCoreCardItem(
            index: 1,
            number: root,
            title: 'Planetary Root',
            subtitle: 'Core Frequency',
            color: const Color(0xFF3B82F6),
            isMaster: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCoreCardItem({
    required int index,
    required String number,
    required String title,
    required String subtitle,
    required Color color,
    required bool isMaster,
  }) {
    final isSelected = _selectedCoreTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => setState(() => _selectedCoreTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.45),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMaster)
                Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'MASTER',
                    style: GoogleFonts.outfit(
                      fontSize: 7.5.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 6. COMPARISON & DOB HARMONY CARDS (Pastel Soft Luxury Style)
  // =========================================================================
  Widget _buildNameComparisonCard(Map<String, dynamic> comparison, bool isPythagorean) {
    final isHarmonized = comparison['is_harmonized'] == true;
    final summary = comparison['summary'] ?? '';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isHarmonized ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isHarmonized ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: isHarmonized ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHarmonized ? Icons.handshake_rounded : Icons.sync_alt_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birth Name vs. Current Name',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      isHarmonized ? 'Harmonized Resonance' : 'Alternate Vibration Active',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isHarmonized ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobHarmonyCard(Map<String, dynamic> dobHarmony, bool isPythagorean) {
    final isAligned = dobHarmony['is_aligned'] == true;
    final summary = dobHarmony['summary'] ?? '';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cake_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth Harmony',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isAligned ? 'Direct Harmonic Reflection' : 'Complementary Synergy',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. FOUNDATIONAL PILLARS (Pythagorean)
  // =========================================================================
  Widget _buildFoundationalPillarsCard(Map<String, dynamic> analysis) {
    final cornerstone = analysis['cornerstone'] as Map<String, dynamic>?;
    final capstone = analysis['capstone'] as Map<String, dynamic>?;
    final firstVowel = analysis['first_vowel'] as Map<String, dynamic>?;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_tree_rounded, color: const Color(0xFFD97706), size: 17.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Foundational Pillars of the Name',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'The structural keystones of your first name determine how you approach beginnings, endings, and instinctive impulses.',
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF64748B)),
          ),
          SizedBox(height: 14.h),

          if (cornerstone != null)
            _buildPillarItem(
              badge: 'CORNERSTONE',
              letter: cornerstone['letter'] ?? '',
              value: cornerstone['value']?.toString() ?? '',
              title: cornerstone['title'] ?? 'First Letter Approach',
              meaning: cornerstone['meaning'] ?? '',
              icon: Icons.start_rounded,
              cardBg: const Color(0xFFFAF5FF),
              borderColor: const Color(0xFFF3E8FF),
              color: const Color(0xFF8B5CF6),
            ),
          SizedBox(height: 10.h),

          if (capstone != null)
            _buildPillarItem(
              badge: 'CAPSTONE',
              letter: capstone['letter'] ?? '',
              value: capstone['value']?.toString() ?? '',
              title: capstone['title'] ?? 'Last Letter Tenacity',
              meaning: capstone['meaning'] ?? '',
              icon: Icons.flag_rounded,
              cardBg: const Color(0xFFFEFCE8),
              borderColor: const Color(0xFFFEF3C7),
              color: const Color(0xFFF59E0B),
            ),
          SizedBox(height: 10.h),

          if (firstVowel != null)
            _buildPillarItem(
              badge: 'FIRST VOWEL',
              letter: firstVowel['letter'] ?? '',
              value: firstVowel['value']?.toString() ?? '',
              title: firstVowel['title'] ?? 'Visceral Soul Reflex',
              meaning: firstVowel['meaning'] ?? '',
              icon: Icons.favorite_border_rounded,
              cardBg: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFDCFCE7),
              color: const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required String badge,
    required String letter,
    required String value,
    required String title,
    required String meaning,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$badge (Value $value)',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            meaning,
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 8. HORIZONTAL PILL TAB BAR & DYNAMIC ACTIVE SECTION CONTENT
  // =========================================================================
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
                  color: isSelected ? const Color(0xFFD97706) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.25),
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

  Widget _buildActiveTabContent(
    Map<String, dynamic> analysis,
    bool isPythagorean,
    Map<String, dynamic>? comparison,
    Map<String, dynamic>? dobHarmony,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTabContent(analysis, isPythagorean);
      case 1:
        return _buildPersonalityTabContent(analysis, isPythagorean);
      case 2:
        return _buildStrengthsTabContent(analysis, isPythagorean);
      case 3:
        return _buildChallengesTabContent(analysis, isPythagorean);
      case 4:
        return _buildRelationshipsTabContent(analysis, isPythagorean);
      case 5:
        return _buildCareerTabContent(analysis, isPythagorean);
      case 6:
        return _buildPillarsAndHarmonyTabContent(analysis, isPythagorean, comparison, dobHarmony);
      case 7:
        return _buildCalculationTabContent(analysis, isPythagorean);
      default:
        return _buildOverviewTabContent(analysis, isPythagorean);
    }
  }

  Map<String, dynamic> _getActiveInterp(Map<String, dynamic> analysis, bool isPythagorean) {
    final interpretations = _reportData!['interpretations'] as Map<String, dynamic>? ?? {};
    if (isPythagorean) {
      final keys = ['expression', 'soul_urge', 'personality'];
      final selectedKey = keys[_selectedCoreTab.clamp(0, 2)];
      return interpretations[selectedKey] as Map<String, dynamic>? ?? {};
    } else {
      final keys = ['chaldean_compound', 'chaldean_root'];
      final selectedKey = keys[_selectedCoreTab.clamp(0, 1)];
      return interpretations[selectedKey] as Map<String, dynamic>? ?? {};
    }
  }

  Map<String, dynamic> _getActiveCoreNumberData(Map<String, dynamic> analysis, bool isPythagorean) {
    if (isPythagorean) {
      final coreNumbers = analysis['core_numbers'] as Map<String, dynamic>? ?? {};
      final keys = ['expression', 'soul_urge', 'personality'];
      final selectedKey = keys[_selectedCoreTab.clamp(0, 2)];
      return coreNumbers[selectedKey] as Map<String, dynamic>? ?? {};
    } else {
      if (_selectedCoreTab == 0) {
        return {
          'final_number': analysis['chaldean_compound_number'],
          'label': 'Chaldean Compound Number',
          'description': 'Ancient Babylonian karmic compound vibrational sum.',
        };
      } else {
        return {
          'final_number': analysis['chaldean_root_number'],
          'label': 'Chaldean Planetary Root Number',
          'description': 'Primary cosmic vibrational frequency governing personal expression.',
        };
      }
    }
  }

  Widget _buildCoreNumberSwitcher(bool isPythagorean) {
    if (!isPythagorean) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildMiniCoreTab('Compound Number', 0),
            _buildMiniCoreTab('Planetary Root', 1),
          ],
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildMiniCoreTab('Expression', 0),
          _buildMiniCoreTab('Soul Urge', 1),
          _buildMiniCoreTab('Personality', 2),
        ],
      ),
    );
  }

  Widget _buildMiniCoreTab(String label, int index) {
    final isSelected = _selectedCoreTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCoreTab = index),
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final activeData = _getActiveCoreNumberData(analysis, isPythagorean);
    final numberVal = activeData['final_number']?.toString() ?? '';
    final label = activeData['label']?.toString() ?? 'Core Vibration';
    final title = interp['title']?.toString() ?? '';
    final theme = interp['core_theme']?.toString() ?? '';
    final overview = interp['overview']?.toString() ?? '';
    final guidance = interp['guidance']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildSectionCard(
          title: title.isNotEmpty ? title : '$label (Number $numberVal)',
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFFD97706),
          theme: theme,
          content: overview.isNotEmpty
              ? overview
              : 'Complete vibrational profile calculated from your name.',
        ),
        if (guidance.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.lightbulb_outline_rounded,
            'Practical Life Guidance',
            guidance,
            isHighlight: true,
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalityTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final activeData = _getActiveCoreNumberData(analysis, isPythagorean);
    final desc = activeData['description']?.toString() ?? '';
    final overview = interp['overview']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildSectionCard(
          title: 'Personality & Vibrational Demeanor',
          icon: Icons.psychology_rounded,
          iconColor: const Color(0xFF8B5CF6),
          content: desc.isNotEmpty ? '$desc\n\n$overview' : overview,
        ),
      ],
    );
  }

  Widget _buildStrengthsTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final strengths = (interp['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildListCard(
          title: 'Innate Talents & Core Strengths',
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF16A34A),
          items: strengths,
          emptyMessage: 'Innate talents and vibrational strengths are harmonious.',
        ),
      ],
    );
  }

  Widget _buildChallengesTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final challenges = (interp['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildListCard(
          title: 'Growth Lessons & Potential Challenges',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFDC2626),
          items: challenges,
          emptyMessage: 'No primary karmic obstacles identified for this vibrational frequency.',
          isNegative: true,
        ),
      ],
    );
  }

  Widget _buildRelationshipsTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final relText = interp['relationships']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildSectionCard(
          title: 'Relationships & Relational Harmony',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE11D48),
          content: relText.isNotEmpty
              ? relText
              : 'Relational resonance prioritizes empathetic dialogue and balanced understanding.',
        ),
      ],
    );
  }

  Widget _buildCareerTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    final interp = _getActiveInterp(analysis, isPythagorean);
    final careerText = interp['career']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoreNumberSwitcher(isPythagorean),
        _buildSectionCard(
          title: 'Career, Vocation & Work Style',
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF0284C7),
          content: careerText.isNotEmpty
              ? careerText
              : 'Career direction is energized by authentic self-expression and purposeful execution.',
        ),
      ],
    );
  }

  Widget _buildPillarsAndHarmonyTabContent(
    Map<String, dynamic> analysis,
    bool isPythagorean,
    Map<String, dynamic>? comparison,
    Map<String, dynamic>? dobHarmony,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comparison != null) ...[
          _buildNameComparisonCard(comparison, isPythagorean),
          SizedBox(height: 14.h),
        ],
        if (dobHarmony != null) ...[
          _buildDobHarmonyCard(dobHarmony, isPythagorean),
          SizedBox(height: 14.h),
        ],
        if (isPythagorean) ...[
          _buildFoundationalPillarsCard(analysis),
        ] else if (comparison == null && dobHarmony == null) ...[
          _buildChaldeanFoundationNote(),
        ],
      ],
    );
  }

  Widget _buildCalculationTabContent(Map<String, dynamic> analysis, bool isPythagorean) {
    return _buildCalculationTransparencyCard(analysis, isPythagorean);
  }

  Widget _buildChaldeanFoundationNote() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline_rounded, size: 17.sp, color: const Color(0xFFD97706)),
              ),
              SizedBox(width: 10.w),
              Text(
                'Chaldean Vibrational Keystones',
                style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'In the Chaldean metaphysical tradition, energetic harmonics are governed by sacred compound sums (10 to 52) and planetary root archetypes (1 to 8). First/last letter cornerstone keystones are specific to Pythagorean numerology.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? theme,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17.sp, color: iconColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          if (theme != null && theme.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                theme,
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD97706),
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF334155),
              height: 1.5,
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
    required String emptyMessage,
    bool isNegative = false,
  }) {
    final chipBg = isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final chipBorder = isNegative ? const Color(0xFFFECACA) : const Color(0xFFDCFCE7);
    final chipText = isNegative ? const Color(0xFFB91C1C) : const Color(0xFF059669);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17.sp, color: iconColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (items.isNotEmpty) ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: items.map((item) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: chipBorder),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: chipText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String text, {bool isHighlight = false}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: isHighlight ? const Color(0xFFD97706) : const Color(0xFF64748B)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 9. CALCULATION TRANSPARENCY CARD (Letter-by-Letter breakdown)
  // =========================================================================
  Widget _buildCalculationTransparencyCard(Map<String, dynamic> analysis, bool isPythagorean) {
    final words = analysis['words'] as List<dynamic>? ?? [];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.visibility_rounded, color: const Color(0xFFD97706), size: 17.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Calculation Transparency',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Every calculation step is verifiable. Letter values are mapped directly from the authoritative table.',
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF64748B)),
          ),
          SizedBox(height: 14.h),

          ...words.map((w) {
            final wordMap = w as Map<String, dynamic>;
            final wordName = wordMap['word'] ?? '';
            final letters = wordMap['letters'] as List<dynamic>? ?? [];

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          wordName,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          isPythagorean
                              ? 'Subtotal: ${wordMap['expression_subtotal']} (Reduced: ${wordMap['expression_reduced']})'
                              : 'Subtotal: ${wordMap['subtotal']} (Root: ${wordMap['reduced']})',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: letters.map((l) {
                      final lMap = l as Map<String, dynamic>;
                      final char = lMap['letter'] ?? '';
                      final val = lMap['value']?.toString() ?? '';
                      final isVowel = lMap['type'] == 'vowel';

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isVowel ? const Color(0xFFFEFCE8) : Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isVowel ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              char,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '=$val',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isVowel ? const Color(0xFFD97706) : const Color(0xFF64748B),
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

          SizedBox(height: 6.h),
          // Reduction Sequence Display
          if (isPythagorean) ...[
            _buildReductionStepBox('Expression Reduction', analysis['core_numbers']?['expression']?['reduction_steps']),
            SizedBox(height: 6.h),
            _buildReductionStepBox('Soul Urge (Vowels) Reduction', analysis['core_numbers']?['soul_urge']?['reduction_steps']),
            SizedBox(height: 6.h),
            _buildReductionStepBox('Personality (Consonants) Reduction', analysis['core_numbers']?['personality']?['reduction_steps']),
          ] else ...[
            _buildReductionStepBox('Chaldean Compound & Root Reduction', analysis['reduction_steps']),
          ],
        ],
      ),
    );
  }

  Widget _buildReductionStepBox(String label, dynamic stepsRaw) {
    final steps = stepsRaw as List<dynamic>? ?? [];
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8)),
          ),
          SizedBox(height: 2.h),
          ...steps.map(
            (s) => Text(
              '• $s',
              style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 10. METAPHYSICAL DISCLAIMER
  // =========================================================================
  Widget _buildDisclaimerCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 16.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _reportData?['disclaimer'] ??
                  'Name Analysis calculations are rooted in traditional Pythagorean and Chaldean numerology traditions. Interpretations are intended for self-reflection and personal inquiry, not deterministic scientific predictions.',
              style: GoogleFonts.inter(fontSize: 10.5.sp, color: const Color(0xFF64748B), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
