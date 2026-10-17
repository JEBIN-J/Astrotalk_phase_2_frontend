import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../theme/numerology_theme.dart';

class NumerologyRemediesScreen extends StatefulWidget {
  final String? initialBirthName;
  final String? initialDob;
  final Map<String, dynamic>? initialReportData;

  const NumerologyRemediesScreen({
    super.key,
    this.initialBirthName,
    this.initialDob,
    this.initialReportData,
  });

  @override
  State<NumerologyRemediesScreen> createState() => _NumerologyRemediesScreenState();
}

class _NumerologyRemediesScreenState extends State<NumerologyRemediesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;

  String _selectedCategory = 'all';
  int _activeViewTab = 0; // 0: Remedies List, 1: Calculation & Rule Trace

  // Palette: Soft Mint, Aquamarine, Fresh Teal (matching Remedies & Fixes card)
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color deepTeal = Color(0xFF134E4A);

  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get scaffoldBg => isDark ? NumerologyTheme.darkScaffoldBg : const Color(0xFFF9FBFB);
  Color get cardBg => isDark ? NumerologyTheme.darkCardBg : const Color(0xFFF0FDFA);
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : Colors.white;
  Color get cardBorder => isDark ? NumerologyTheme.darkBorder : const Color(0xFFCCFBF1);
  Color get darkText => isDark ? Colors.white : const Color(0xFF1E293B);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();

    if (widget.initialReportData != null) {
      _reportData = widget.initialReportData;
      final summary = widget.initialReportData!['profile_summary'] as Map<String, dynamic>?;
      _nameController.text = summary?['birth_name'] ?? widget.initialBirthName ?? '';
      _dobController.text = summary?['date_of_birth'] ?? widget.initialDob ?? '1998-12-13';
    } else {
      if (widget.initialBirthName != null && widget.initialBirthName!.trim().isNotEmpty) {
        _nameController.text = widget.initialBirthName!.trim();
      }
      if (widget.initialDob != null && widget.initialDob!.trim().isNotEmpty) {
        _dobController.text = widget.initialDob!.trim();
      } else {
        _dobController.text = '1998-12-13';
      }

      if (_dobController.text.isNotEmpty) {
        _fetchRemedies();
      } else {
        _loadSavedProfile();
      }
    }
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('numerology_user_name') ?? '';
    final savedDob = prefs.getString('numerology_user_dob') ?? '1998-12-13';

    if (mounted) {
      if (_nameController.text.isEmpty && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      if (_dobController.text.isEmpty && savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }
      _fetchRemedies();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchRemedies() async {
    final dob = _dobController.text.trim();
    if (dob.isEmpty) {
      setState(() {
        _errorMessage = 'Date of birth is required to evaluate your personalized remedies.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getNumerologyRemedies(
        dateOfBirth: dob,
        birthName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        category: 'all', // Fetch all so user can switch filter chips locally
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        if (_nameController.text.trim().isNotEmpty) {
          await prefs.setString('numerology_user_name', _nameController.text.trim());
        }
        await prefs.setString('numerology_user_dob', dob);
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

  void _showEditProfileDialog() {
    final nameEdit = TextEditingController(text: _nameController.text);
    final dobEdit = TextEditingController(text: _dobController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18233C) : cardBg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: cardBorder),
              ),
              child: Icon(Icons.healing_rounded, color: primaryTeal, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Personalize Profile',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: darkText,
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
              'Enter your full birth name and date of birth to evaluate your Life Path, Karmic Lessons, and cycle remedies.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: nameEdit,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: darkText),
              decoration: InputDecoration(
                labelText: 'Full Birth Name (Optional for Karmic Lessons)',
                labelStyle: GoogleFonts.inter(fontSize: 13.sp, color: mutedText),
                hintText: 'e.g. JEBIN J',
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: mutedText),
                filled: true,
                fillColor: isDark ? const Color(0xFF18233C) : cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryTeal, width: 1.5.w)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: dobEdit,
              style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: darkText),
              decoration: InputDecoration(
                labelText: 'Date of Birth (YYYY-MM-DD)',
                labelStyle: GoogleFonts.inter(fontSize: 13.sp, color: mutedText),
                hintText: '1998-12-13',
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: mutedText),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_rounded, color: primaryTeal),
                  onPressed: () async {
                    DateTime initial = DateTime.tryParse(dobEdit.text) ?? DateTime(1998, 12, 13);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dobEdit.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF18233C) : cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryTeal, width: 1.5.w)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: mutedText, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _nameController.text = nameEdit.text.trim();
                _dobController.text = dobEdit.text.trim();
              });
              _fetchRemedies();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text('Recalculate', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: NumerologyTheme.appBarBg(isDark),
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
                    color: NumerologyTheme.circleBtnBg(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(color: NumerologyTheme.circleBtnBorder(isDark), width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withValues(alpha: isDark ? 0.2 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: NumerologyTheme.circleBtnIcon(isDark), size: 16.sp),
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
              'Remedies & Fixes',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            Text(
              'Traditional Balance & Behavioral Guidance',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryTeal,
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
                    onTap: _fetchRemedies,
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: NumerologyTheme.circleBtnBg(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(color: NumerologyTheme.circleBtnBorder(isDark), width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: isDark ? 0.2 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: primaryTeal, size: 19.sp),
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
      return _buildEmptyInputPrompt();
    }

    return Column(
      children: [
        _buildUserHeaderBar(),
        _buildProfileVibrationsStrip(),
        _buildViewSelectorTabs(),
        Expanded(
          child: _activeViewTab == 0 ? _buildRemediesListView() : _buildAuditTraceView(),
        ),
      ],
    );
  }

  // =========================================================================
  // LUXURY USER HEADER BAR (Matching Mint / Teal Palette)
  // =========================================================================
  Widget _buildUserHeaderBar() {
    final summary = _reportData?['profile_summary'] as Map<String, dynamic>?;
    final name = summary?['birth_name'] ?? _nameController.text;
    final dob = summary?['date_of_birth'] ?? _dobController.text;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF0D2524),
                  Color(0xFF131D36),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFF0FDFA), // Soft Mint
                  Color(0xFFE6FFFA), // Pale Aquamarine Glow
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? primaryTeal.withValues(alpha: 0.35) : cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teal circular badge with healing icon
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [accentTeal, primaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.healing_rounded, color: Colors.white, size: 22.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233C) : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: cardBorder, width: 0.8.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.spa_outlined, size: 10.sp, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal),
                      SizedBox(width: 3.5.w),
                      Flexible(
                        child: Text(
                          'ANALYZED PROFILE',
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF5EEAD4) : primaryTeal,
                            letterSpacing: 0.7,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  name.isNotEmpty ? name.toUpperCase() : 'SEEKER',
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'DOB: $dob',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: _showEditProfileDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233C) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: cardBorder, width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13.sp, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal),
                    SizedBox(width: 4.w),
                    Text(
                      'Change',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF5EEAD4) : primaryTeal,
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

  // =========================================================================
  // VIBRATIONS BADGE STRIP
  // =========================================================================
  Widget _buildProfileVibrationsStrip() {
    final summary = _reportData?['profile_summary'] as Map<String, dynamic>?;
    final lp = summary?['life_path_number']?.toString() ?? '-';
    final bd = summary?['birth_day_reduced']?.toString() ?? summary?['birth_day_number']?.toString() ?? '-';
    final missingList = (summary?['missing_numbers'] as List?)?.map((e) => e as int).toList() ?? [];
    final py = summary?['personal_year_number']?.toString() ?? '-';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVibrationBadge('Life Path', lp, Icons.alt_route_rounded),
          Container(width: 1.w, height: 28.h, color: cardBorder),
          _buildVibrationBadge('Birth Day', bd, Icons.cake_outlined),
          Container(width: 1.w, height: 28.h, color: cardBorder),
          _buildVibrationBadge('Missing', '${missingList.length}', Icons.remove_circle_outline_rounded),
          Container(width: 1.w, height: 28.h, color: cardBorder),
          _buildVibrationBadge('Personal Year', py, Icons.calendar_today_rounded),
        ],
      ),
    );
  }

  Widget _buildVibrationBadge(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10.sp, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal),
              SizedBox(width: 2.w),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: mutedText, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(value, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText)),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW SELECTOR (Remedies List vs Audit Trace)
  // =========================================================================
  Widget _buildViewSelectorTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18233C) : cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewTab = 0),
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _activeViewTab == 0 ? primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.healing_rounded, size: 14.sp, color: _activeViewTab == 0 ? Colors.white : (isDark ? const Color(0xFF5EEAD4) : primaryTeal)),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'Remedies (${_getAllRemedies().length})',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _activeViewTab == 0 ? Colors.white : (isDark ? const Color(0xFF94A3B8) : deepTeal),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewTab = 1),
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: _activeViewTab == 1 ? primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rule_folder_outlined, size: 14.sp, color: _activeViewTab == 1 ? Colors.white : (isDark ? const Color(0xFF5EEAD4) : primaryTeal)),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'Rule Trace',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _activeViewTab == 1 ? Colors.white : (isDark ? const Color(0xFF94A3B8) : deepTeal),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 1: REMEDIES LIST VIEW WITH CATEGORY PILLS
  // =========================================================================
  List<Map<String, dynamic>> _getAllRemedies() {
    final list = (_reportData?['remedies'] as List?) ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  List<Map<String, dynamic>> _getFilteredRemedies() {
    final all = _getAllRemedies();
    if (_selectedCategory == 'all') return all;
    return all.where((r) => r['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  Widget _buildRemediesListView() {
    final filtered = _getFilteredRemedies();
    final categories = [
      {'code': 'all', 'label': 'All Remedies'},
      {'code': 'daily_habits', 'label': 'Daily Habits'},
      {'code': 'reflection', 'label': 'Reflection & Mind'},
      {'code': 'symbolic', 'label': 'Symbolic Harmony'},
      {'code': 'service', 'label': 'Acts of Kindness'},
      {'code': 'karmic_balance', 'label': 'Karmic Balance'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Filter Chips
        SizedBox(
          height: 42.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              final code = cat['code']!;
              final isSelected = _selectedCategory == code;

              return InkWell(
                onTap: () => setState(() => _selectedCategory = code),
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryTeal : (isDark ? const Color(0xFF18233C) : cardBg),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? primaryTeal : cardBorder, width: 1.w),
                  ),
                  child: Center(
                    child: Text(
                      cat['label']!,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? const Color(0xFF5EEAD4) : deepTeal),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Remedies Cards
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyCategoryState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildRemedyCard(filtered[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildRemedyCard(Map<String, dynamic> rem) {
    final title = rem['title']?.toString() ?? 'Remedy';
    final category = rem['category']?.toString() ?? 'daily_habits';
    final primaryReason = rem['primary_reason']?.toString() ?? '';
    final traditional = rem['traditional_association']?.toString() ?? '';
    final explanation = rem['explanation']?.toString() ?? '';
    final instructions = (rem['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final precautions = rem['precautions']?.toString() ?? '';
    final affirmation = rem['affirmation']?.toString() ?? '';
    final color = rem['symbolic_color']?.toString() ?? '';
    final day = rem['symbolic_day']?.toString() ?? '';
    final cost = rem['estimated_cost_category']?.toString() ?? 'Zero Cost';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233C) : cardBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(category), size: 11.sp, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal),
                    SizedBox(width: 4.w),
                    Text(
                      _formatCategoryName(category),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF5EEAD4) : deepTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  cost,
                  style: GoogleFonts.inter(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.w800,
              color: darkText,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8.h),

          // Applicability Reason Pill
          if (primaryReason.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2524) : const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? primaryTeal.withValues(alpha: 0.4) : const Color(0xFF99F6E4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal, size: 14.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      primaryReason,
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        color: isDark ? const Color(0xFFCCFBF1) : deepTeal,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12.h),

          // Traditional Association
          if (traditional.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_rounded, size: 13.sp, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    traditional,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: mutedText,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          if (explanation.isNotEmpty) ...[
            Text(
              explanation,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            SizedBox(height: 10.h),
          ],

          // Practical Instructions Header
          if (instructions.isNotEmpty) ...[
            Text(
              'PRACTICAL STEPS:',
              style: GoogleFonts.outfit(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF5EEAD4) : deepTeal,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 6.h),
            ...instructions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18233C) : cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          '$idx',
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF5EEAD4) : primaryTeal,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 10.h),
          ],

          // Affirmation Quote Box
          if (affirmation.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18233C) : cardBg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      affirmation,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCCFBF1) : deepTeal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.h),

          // Sensory Alignment Tags (Color & Day)
          if (color.isNotEmpty || day.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if (color.isNotEmpty)
                  _buildTagPill(Icons.palette_outlined, 'Color: $color'),
                if (day.isNotEmpty)
                  _buildTagPill(Icons.wb_sunny_outlined, 'Timing: $day'),
              ],
            ),

          SizedBox(height: 12.h),

          // Precautions Box
          if (precautions.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1E0A) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: const Color(0xFFD97706), size: 14.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      precautions,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
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

  Widget _buildTagPill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: isDark ? const Color(0xFF94A3B8) : mutedText),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 10.5.sp, color: isDark ? const Color(0xFF94A3B8) : mutedText, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: RULE EVALUATION AUDIT TRACE
  // =========================================================================
  Widget _buildAuditTraceView() {
    final trace = (_reportData?['rule_evaluation_trace'] as List?) ?? [];
    final safety = _reportData?['safety_notice']?.toString() ?? '';

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
      children: [
        // Engine Notice Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2524) : cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: isDark ? primaryTeal.withValues(alpha: 0.35) : cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: isDark ? const Color(0xFF5EEAD4) : primaryTeal, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Deterministic Rule Engine 1.0.0',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF5EEAD4) : deepTeal),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'Zero random suggestions. Every remedy displayed is activated by an explicit backend rule evaluated against your authenticated numerology profile.',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? const Color(0xFFCCFBF1) : deepTeal, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        Text(
          'RULES EVALUATED (${trace.length})',
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: mutedText,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 8.h),

        ...trace.map((item) {
          final ruleCode = item['rule_code']?.toString() ?? '';
          final desc = item['description']?.toString() ?? '';
          final inputType = item['input_number_type']?.toString() ?? '';
          final condition = item['condition']?.toString() ?? '';
          final actual = item['actual_value']?.toString() ?? '';
          final isMatched = item['status'] == 'matched';

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isMatched
                    ? (isDark ? const Color(0xFF14B8A6) : const Color(0xFF99F6E4))
                    : (isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0)),
                width: isMatched ? 1.4.w : 1.w,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                        : (isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMatched ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isMatched ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)) : mutedText,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              desc,
                              style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkText),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isMatched
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                                  : (isDark ? const Color(0xFF18233C) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isMatched ? 'MATCHED' : 'NOT APPLICABLE',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: isMatched ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)) : mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Rule: $ruleCode | Input: $inputType ($condition)',
                        style: GoogleFonts.inter(fontSize: 10.5.sp, color: mutedText),
                      ),
                      Text(
                        'Your Profile Value: $actual',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isMatched ? (isDark ? const Color(0xFF5EEAD4) : primaryTeal) : darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        if (safety.isNotEmpty) ...[
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 14.sp, color: mutedText),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    safety,
                    style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // STATE HELPERS
  // =========================================================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18233C) : cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Evaluating Backend Remedy Rules...',
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 6.h),
          Text(
            'Matching Life Path, Missing Numbers & Cycle vibrations with verified database guidance',
            style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 32.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                'Evaluation Interrupted',
                style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: darkText),
              ),
              SizedBox(height: 6.h),
              Text(
                _errorMessage ?? 'Unable to evaluate remedies at this time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5.sp, color: mutedText, height: 1.4),
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: _fetchRemedies,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInputPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.healing_rounded, size: 48.sp, color: primaryTeal),
            SizedBox(height: 12.h),
            Text(
              'No Profile Loaded',
              style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: darkText),
            ),
            SizedBox(height: 6.h),
            Text(
              'Please enter your date of birth to evaluate personalized remedies.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: mutedText),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _showEditProfileDialog,
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
              child: const Text('Enter Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off_rounded, size: 40.sp, color: mutedText),
            SizedBox(height: 10.h),
            Text(
              'No Remedies in This Category',
              style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
            ),
            SizedBox(height: 6.h),
            Text(
              'Your specific profile numbers activated remedies in other categories. Select "All Remedies" to view all suggestions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
            ),
            SizedBox(height: 14.h),
            OutlinedButton(
              onPressed: () => setState(() => _selectedCategory = 'all'),
              style: OutlinedButton.styleFrom(foregroundColor: isDark ? const Color(0xFF5EEAD4) : primaryTeal, side: BorderSide(color: isDark ? const Color(0xFF5EEAD4) : primaryTeal)),
              child: const Text('View All Remedies'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'daily_habits':
        return Icons.checklist_rounded;
      case 'reflection':
        return Icons.self_improvement_rounded;
      case 'symbolic':
        return Icons.palette_outlined;
      case 'service':
        return Icons.volunteer_activism_rounded;
      case 'karmic_balance':
        return Icons.loop_rounded;
      default:
        return Icons.spa_outlined;
    }
  }

  String _formatCategoryName(String cat) {
    switch (cat.toLowerCase()) {
      case 'daily_habits':
        return 'DAILY HABIT';
      case 'reflection':
        return 'REFLECTION & MIND';
      case 'symbolic':
        return 'SYMBOLIC HARMONY';
      case 'service':
        return 'ACT OF KINDNESS';
      case 'karmic_balance':
        return 'KARMIC BALANCE';
      default:
        return cat.toUpperCase();
    }
  }
}
