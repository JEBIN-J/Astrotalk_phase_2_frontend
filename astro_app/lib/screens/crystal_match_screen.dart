import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../services/crystal_match_service.dart';
import '../theme/numerology_theme.dart';

class CrystalMatchScreen extends StatefulWidget {
  final String? initialBirthName;
  final String? initialDob;
  final String? initialSystem;

  const CrystalMatchScreen({
    super.key,
    this.initialBirthName,
    this.initialDob,
    this.initialSystem,
  });

  @override
  State<CrystalMatchScreen> createState() => _CrystalMatchScreenState();
}

class _CrystalMatchScreenState extends State<CrystalMatchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  bool _isFiltering = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  final Map<String, Map<String, dynamic>> _reportCache = {};

  String _selectedSystem = 'pythagorean';
  String _selectedIntention = 'all';
  int _activeViewTab = 0; // 0: Recommendations, 1: Rule Trace, 2: Catalog, 3: Safety & Care

  List<Map<String, dynamic>> _intentions = [];
  List<Map<String, dynamic>> _catalog = [];
  bool _isLoadingCatalog = false;

  // Color Palette: Electric Indigo / Gemstone Lavender Theme (matching Crystal Match cosmic card)
  static const Color primaryViolet = Color(0xFF6366F1); // Indigo/Violet primary

  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get scaffoldBg => isDark ? NumerologyTheme.darkScaffoldBg : const Color(0xFFFBFBFE);
  Color get cardBg => isDark ? NumerologyTheme.darkCardBg : const Color(0xFFF5F3FF);
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : Colors.white;
  Color get cardBorder => isDark ? NumerologyTheme.darkBorder : const Color(0xFFEDE9FE);
  Color get darkText => isDark ? Colors.white : const Color(0xFF1E1B4B);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color get badgeBg => isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEDE9FE);
  Color get badgeText => isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.initialSystem ?? 'pythagorean';

    if (widget.initialBirthName != null && widget.initialBirthName!.trim().isNotEmpty) {
      _nameController.text = widget.initialBirthName!.trim();
    }
    if (widget.initialDob != null && widget.initialDob!.trim().isNotEmpty) {
      _dobController.text = widget.initialDob!.trim();
    }

    _loadIntentions();
    _loadCatalog();

    if (_dobController.text.isNotEmpty) {
      _fetchMatches();
    } else {
      _loadSavedProfile();
    }
  }

  Future<void> _loadIntentions() async {
    try {
      final ints = await AstroApiService.getCrystalIntentions();
      if (mounted && ints.isNotEmpty) {
        setState(() => _intentions = ints);
      }
    } catch (_) {}
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final cat = await AstroApiService.getCrystalCatalog();
      if (mounted) {
        setState(() {
          _catalog = cat;
          _isLoadingCatalog = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCatalog = false);
      }
    }
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('numerology_user_name') ?? '';
    final savedDob = prefs.getString('numerology_user_dob') ?? '1998-12-14';
    final savedSystem = prefs.getString('numerology_user_system') ?? 'pythagorean';

    if (mounted) {
      if (_nameController.text.isEmpty && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      if (_dobController.text.isEmpty && savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }
      _selectedSystem = savedSystem;
      _fetchMatches();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches({bool isFilterChange = false}) async {
    final dob = _dobController.text.trim();
    if (dob.isEmpty) {
      setState(() {
        _errorMessage = 'Date of birth is required to evaluate your personalized crystal match.';
      });
      return;
    }

    final cacheKey = '${_nameController.text.trim()}_${dob}_${_selectedSystem}_$_selectedIntention';
    if (_reportCache.containsKey(cacheKey)) {
      setState(() {
        _reportData = _reportCache[cacheKey];
        _isLoading = false;
        _isFiltering = false;
      });
      return;
    }

    if (isFilterChange) {
      setState(() {
        _isFiltering = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await AstroApiService.getCrystalMatchReport(
        dateOfBirth: dob,
        birthName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        system: _selectedSystem,
        intention: _selectedIntention,
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _reportCache[cacheKey] = res;
          _isLoading = false;
          _isFiltering = false;
        });

        final prefs = await SharedPreferences.getInstance();
        if (_nameController.text.trim().isNotEmpty) {
          await prefs.setString('numerology_user_name', _nameController.text.trim());
        }
        await prefs.setString('numerology_user_dob', dob);
        await prefs.setString('numerology_user_system', _selectedSystem);
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isLoading = false;
          _isFiltering = false;
          if (_reportData == null) {
            _errorMessage = err;
          }
        });

        if (_reportData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        }
      }
    }
  }

  void _showEditProfileDialog() {
    final nameEdit = TextEditingController(text: _nameController.text);
    final dobEdit = TextEditingController(text: _dobController.text);
    String tempSystem = _selectedSystem;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                child: Icon(Icons.diamond_rounded, color: primaryViolet, size: 20.sp),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your birth name and date of birth determine your Life Path, Birth Day, Expression, and Karmic harmonizing frequencies.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: nameEdit,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: darkText),
                  decoration: InputDecoration(
                    labelText: 'Full Birth Name',
                    hintText: 'e.g. JEBIN J',
                    labelStyle: GoogleFonts.inter(color: primaryViolet, fontSize: 13.sp),
                    hintStyle: GoogleFonts.inter(color: mutedText, fontSize: 13.sp),
                    prefixIcon: const Icon(Icons.person_rounded, color: primaryViolet),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF18233C) : cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryViolet, width: 1.5.w)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: dobEdit,
                  readOnly: true,
                  style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w600, color: darkText),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    hintText: '1998-12-14',
                    labelStyle: GoogleFonts.inter(color: primaryViolet, fontSize: 13.sp),
                    hintStyle: GoogleFonts.inter(color: mutedText, fontSize: 13.sp),
                    prefixIcon: const Icon(Icons.calendar_today_rounded, color: primaryViolet),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: primaryViolet),
                      onPressed: () async {
                        DateTime initial = DateTime.tryParse(dobEdit.text) ?? DateTime(1998, 12, 14);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dobEdit.text =
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF18233C) : cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryViolet, width: 1.5.w)),
                  ),
                ),
                SizedBox(height: 14.h),
                Text('Numerology System:', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkText)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Pythagorean', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                        selected: tempSystem == 'pythagorean',
                        selectedColor: primaryViolet.withValues(alpha: isDark ? 0.35 : 0.15),
                        backgroundColor: isDark ? const Color(0xFF18233C) : Colors.white,
                        onSelected: (val) {
                          if (val) setDialogState(() => tempSystem = 'pythagorean');
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Chaldean', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                        selected: tempSystem == 'chaldean',
                        selectedColor: primaryViolet.withValues(alpha: isDark ? 0.35 : 0.15),
                        backgroundColor: isDark ? const Color(0xFF18233C) : Colors.white,
                        onSelected: (val) {
                          if (val) setDialogState(() => tempSystem = 'chaldean');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: mutedText, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _reportCache.clear();
                setState(() {
                  _nameController.text = nameEdit.text.trim();
                  _dobController.text = dobEdit.text.trim();
                  _selectedSystem = tempSystem;
                });
                _fetchMatches();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('Recalculate', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
                        color: primaryViolet.withValues(alpha: isDark ? 0.2 : 0.08),
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
              'Crystal Match',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            Text(
              'Numerological Resonance & Mindful Synergy',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryViolet,
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
                    onTap: () {
                      _reportCache.clear();
                      _fetchMatches();
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: NumerologyTheme.circleBtnBg(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(color: NumerologyTheme.circleBtnBorder(isDark), width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: primaryViolet.withValues(alpha: isDark ? 0.2 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: primaryViolet, size: 19.sp),
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
    if (_isLoading && _reportData == null) {
      return _buildLoadingState();
    }
    if (_errorMessage != null && _reportData == null) {
      return _buildErrorState();
    }
    if (_reportData == null) {
      return _buildEmptyInputPrompt();
    }

    return Column(
      children: [
        _buildUserHeaderBar(),
        _buildIntentionSelector(),
        _buildViewTabBar(),
        if (_isFiltering)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: LinearProgressIndicator(
                minHeight: 2.5.h,
                backgroundColor: primaryViolet.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryViolet),
              ),
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildSelectedTabContent(),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // USER PROFILE HEADER & NUMEROLOGY NUMBERS BAR
  // =========================================================================

  Widget _buildUserHeaderBar() {
    final summary = _reportData!['profile_summary'] as Map<String, dynamic>? ?? {};
    final name = summary['birth_name'] ?? _nameController.text;
    final dob = summary['date_of_birth'] ?? _dobController.text;
    final lp = summary['life_path'] ?? '-';
    final bd = summary['birth_day'] ?? '-';
    final ex = summary['expression_number'] ?? '-';
    final missingList = (summary['missing_numbers'] as List<dynamic>?) ?? [];
    final py = summary['personal_year'] ?? '-';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryViolet.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryViolet.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.diamond_rounded, color: Colors.white, size: 22.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: badgeText, size: 10.sp),
                              SizedBox(width: 4.w),
                              Text(
                                'ANALYZED PROFILE',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: badgeText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E1065) : primaryViolet.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _selectedSystem.toUpperCase(),
                            style: GoogleFonts.firaCode(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFA5B4FC) : primaryViolet,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      name.toString().toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'DOB: $dob',
                      style: GoogleFonts.firaCode(
                        fontSize: 11.sp,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: Icon(Icons.edit_rounded, size: 13.sp, color: primaryViolet),
                label: Text('Change', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryViolet,
                  side: BorderSide(color: primaryViolet.withValues(alpha: 0.4)),
                  backgroundColor: isDark ? const Color(0xFF18233C) : Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18233C) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNumberMetricPill('Life Path', lp.toString(), Icons.route_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildNumberMetricPill('Birth Day', bd.toString(), Icons.cake_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildNumberMetricPill('Destiny', ex.toString(), Icons.stars_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildNumberMetricPill('Missing', missingList.isEmpty ? '0' : missingList.join(','), Icons.blur_on_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildNumberMetricPill('Pers. Yr', py.toString(), Icons.calendar_today_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberMetricPill(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10.sp, color: primaryViolet),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  color: mutedText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1.w,
      height: 20.h,
      color: isDark ? NumerologyTheme.darkBorder : cardBorder,
    );
  }

  // =========================================================================
  // INTENTION SELECTOR CHIPS
  // =========================================================================

  Widget _buildIntentionSelector() {
    final list = _intentions.isNotEmpty
        ? _intentions
        : CrystalMatchService.defaultIntentions;

    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final code = item['code']?.toString() ?? 'all';
          final title = item['title']?.toString() ?? code;
          final isSelected = _selectedIntention == code;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : darkText,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryViolet,
              backgroundColor: isDark ? const Color(0xFF18233C) : Colors.white,
              side: BorderSide(
                color: isSelected ? primaryViolet : cardBorder,
                width: 1.w,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              onSelected: (val) {
                if (val && _selectedIntention != code) {
                  setState(() => _selectedIntention = code);
                  _fetchMatches(isFilterChange: true);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // VIEW TABS (MATCHES, RULE TRACE, CATALOG, SAFETY)
  // =========================================================================

  Widget _buildViewTabBar() {
    final matchesCount = (_reportData?['recommendations'] as List<dynamic>?)?.length ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18233C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Matches ($matchesCount)', Icons.auto_awesome_rounded),
          _buildTabItem(1, 'Rule Trace', Icons.account_tree_rounded),
          _buildTabItem(2, 'Library', Icons.menu_book_rounded),
          _buildTabItem(3, 'Care & Safety', Icons.shield_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _activeViewTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: () => setState(() => _activeViewTab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? (isDark ? NumerologyTheme.darkCardBg : Colors.white) : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13.sp,
                  color: isSelected ? primaryViolet : mutedText,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5.sp,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? (isDark ? Colors.white : darkText) : mutedText,
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
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_activeViewTab) {
      case 0:
        return _buildMatchesList();
      case 1:
        return _buildRuleTraceTab();
      case 2:
        return _buildCatalogTab();
      case 3:
      default:
        return _buildCareAndSafetyTab();
    }
  }

  // =========================================================================
  // TAB 0: RECOMMENDED CRYSTALS LIST
  // =========================================================================

  Widget _buildMatchesList() {
    if (_isFiltering) {
      return _buildFilteringSkeleton();
    }

    final list = (_reportData?['recommendations'] as List<dynamic>?) ?? [];

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48.sp, color: mutedText),
              SizedBox(height: 12.h),
              Text(
                'No Documented Rule Match Found',
                style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
              ),
              SizedBox(height: 6.h),
              Text(
                'No published rules matched this specific combination under current filters. Try setting the intention filter to "All Intentions".',
                style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('matches_list_$_selectedIntention'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == list.length) {
          return _buildDisclaimerFooter();
        }
        final item = list[index] as Map<String, dynamic>;
        final crystal = item['crystal'] as Map<String, dynamic>;
        return _buildCrystalCard(item, crystal, index + 1);
      },
    );
  }

  Widget _buildFilteringSkeleton() {
    return ListView.builder(
      key: const ValueKey('filtering_skeleton'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: primaryViolet.withValues(alpha: isDark ? 0.1 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18233C) : cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 110.w,
                                height: 16.h,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF18233C) : cardBg,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 60.w,
                                height: 20.h,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF18233C) : cardBg,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 130.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF18233C) : cardBg,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233C) : cardBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: cardBorder),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Container(
                      width: 160.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18233C) : cardBg,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrystalCard(Map<String, dynamic> matchData, Map<String, dynamic> crystal, int rank) {
    final ruleCode = matchData['primary_rule_code'] ?? 'RULE-MATCH';
    final ruleTitle = matchData['primary_rule_title'] ?? 'Numerology Alignment';
    final explanation = matchData['match_explanation'] ?? '';
    final score = matchData['match_score'] ?? 0;
    final factors = (matchData['contributing_factors'] as List<dynamic>?) ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cardBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: primaryViolet.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => _showCrystalDetailModal(crystal, matchData),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18233C) : cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: primaryViolet,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  crystal['name'] ?? 'Crystal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF18233C) : cardBg,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  'Score: $score',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFA5B4FC) : primaryViolet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            crystal['mineral_family'] ?? 'Mineral Silicate',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: mutedText,
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
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233C) : cardBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rule_rounded, size: 13.sp, color: isDark ? const Color(0xFFA5B4FC) : primaryViolet),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              '$ruleCode: $ruleTitle',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFA5B4FC) : primaryViolet,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        explanation,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFFCBD5E1) : darkText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (factors.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: factors.map((factor) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          factor.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: mutedText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Traditional: ${crystal['traditional_associations'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontStyle: FontStyle.italic,
                          color: mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Full Details',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: primaryViolet,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16.sp, color: primaryViolet),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: CALCULATION & RULE TRACE
  // =========================================================================

  Widget _buildRuleTraceTab() {
    final rules = (_reportData?['evaluated_rules'] as List<dynamic>?) ?? [];
    final methodology = _reportData?['methodology'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: primaryViolet, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Deterministic Methodology',
                    style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'System: ${methodology['system_label'] ?? _selectedSystem}\n'
                'Engine Version: ${_reportData?['engine_version'] ?? '2.1.0'} | Content Version: ${_reportData?['content_version'] ?? '2026.1'}\n'
                'Policy: ${methodology['scientific_claim_policy'] ?? 'NCCIH compliant non-medical guidelines.'}',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Evaluated Matching Rules',
          style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
        ),
        SizedBox(height: 8.h),
        ...rules.map((rule) {
          final r = rule as Map<String, dynamic>;
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233C) : cardBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    r['rule_code'] ?? 'RULE',
                    style: GoogleFonts.firaCode(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFA5B4FC) : primaryViolet),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['title'] ?? '',
                        style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkText),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        r['description'] ?? '',
                        style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Input Used: ${r['input_value'] ?? r['input_values'] ?? 'Profile Data'}',
                        style: GoogleFonts.firaCode(fontSize: 10.sp, color: isDark ? const Color(0xFFA5B4FC) : primaryViolet),
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

  // =========================================================================
  // TAB 2: COMPLETE CURATED CATALOG
  // =========================================================================

  Widget _buildCatalogTab() {
    if (_isLoadingCatalog) {
      return const Center(child: CircularProgressIndicator(color: primaryViolet));
    }
    if (_catalog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond_outlined, size: 40.sp, color: mutedText),
            SizedBox(height: 8.h),
            Text('No crystals available', style: GoogleFonts.outfit(fontSize: 14.sp, color: mutedText)),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: _loadCatalog,
              style: ElevatedButton.styleFrom(backgroundColor: primaryViolet),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      itemCount: _catalog.length,
      itemBuilder: (context, index) {
        final c = _catalog[index];
        final name = c['name']?.toString() ?? '';
        final mineralFamily = c['mineral_family']?.toString() ?? 'Silicate';
        final mohsHardness = c['mohs_hardness']?.toString() ?? '7.0';
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cardBorder),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            leading: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF18233C) : cardBg,
              child: Icon(Icons.diamond_outlined, color: primaryViolet, size: 20.sp),
            ),
            title: Text(
              name,
              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
            ),
            subtitle: Text(
              '$mineralFamily • Mohs: $mohsHardness',
              style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: primaryViolet),
            onTap: () => _showCrystalDetailModal(c, null),
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 3: CARE, HANDLING & NCCIH SAFETY GUIDELINES
  // =========================================================================

  Widget _buildCareAndSafetyTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      children: [
        _buildCareCard(
          title: 'Physical Handling & Cleansing',
          icon: Icons.water_drop_outlined,
          color: const Color(0xFF0284C7),
          content:
              '• Water-Safe Crystals: Dense silicates like Quartz, Jasper, Agate, and Garnet can be safely rinsed with mild water.\n'
              '• Water-Sensitive Crystals: Selenite (Gypsum), Lepidolite, and Malachite should NEVER be soaked in water as they can dissolve, crack, or lose polish.\n'
              '• Sun Exposure: Intense direct UV sunlight can fade color centers in Amethyst, Rose Quartz, and Fluorite over time. Dry microfiber wiping is best.',
        ),
        SizedBox(height: 12.h),
        _buildCareCard(
          title: 'NCCIH & Complementary Practice Standards',
          icon: Icons.health_and_safety_outlined,
          color: primaryViolet,
          content:
              '• Non-Medical Nature: Crystal matching is a reflective, traditional mindfulness discipline rooted in symbolic numerology archetypes.\n'
              '• No Medical/Destiny Claims: Crystals do not diagnose, treat, or cure illness, nor do they guarantee financial or interpersonal outcomes.\n'
              '• External Use Only: Never ingest crystal powders or prepare direct-immersion crystal elixirs.',
        ),
        SizedBox(height: 12.h),
        _buildCareCard(
          title: 'Responsible Mindful Use',
          icon: Icons.self_improvement_rounded,
          color: const Color(0xFF059669),
          content:
              '• Focus Anchoring: Use stones as tangible sensory reminders of your conscious daily intentions (e.g. holding Smoky Quartz for focus, or Citrine for creative optimism).\n'
              '• Journaling Practice: Pair your crystal with 5 minutes of reflective writing about the corresponding numerological virtue.',
        ),
      ],
    );
  }

  Widget _buildCareCard({required String title, required IconData icon, required Color color, required String content}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: isDark ? const Color(0xFFCBD5E1) : darkText, height: 1.5),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODAL BOTTOM SHEET: FULL CRYSTAL DETAIL & SAFETY
  // =========================================================================

  void _showCrystalDetailModal(Map<String, dynamic> crystal, Map<String, dynamic>? matchData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(20.w),
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Icon(Icons.diamond_rounded, color: Colors.white, size: 28.sp),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crystal['name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: darkText,
                          ),
                        ),
                        Text(
                          crystal['mineral_family'] ?? '',
                          style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (matchData != null) ...[
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233C) : cardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rule_rounded, size: 14.sp, color: isDark ? const Color(0xFFA5B4FC) : primaryViolet),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'Why It Matched: ${matchData['primary_rule_title']}',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFA5B4FC) : primaryViolet,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        matchData['match_explanation'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: isDark ? const Color(0xFFCBD5E1) : darkText, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              _buildDetailSection('Geological & Physical Profile', [
                'Chemical Formula: ${crystal['chemical_formula'] ?? 'N/A'}',
                'Mohs Hardness: ${crystal['mohs_hardness'] ?? 'N/A'}',
                'Appearance: ${crystal['colour_description'] ?? 'N/A'}',
                'Geology: ${crystal['geological_description'] ?? 'N/A'}',
              ]),
              SizedBox(height: 14.h),
              _buildDetailSection('Traditional Associations', [
                crystal['traditional_associations'] ?? 'N/A',
              ]),
              SizedBox(height: 14.h),
              _buildDetailSection('Suggested Mindful Practice', [
                crystal['suggested_use'] ?? 'N/A',
              ]),
              SizedBox(height: 14.h),
              _buildDetailSection('Care & Handling Instructions', [
                crystal['care_instructions'] ?? 'N/A',
              ]),
              SizedBox(height: 14.h),
              _buildDetailSection('Safety Notes & Limitations', [
                'Safety: ${crystal['safety_notes'] ?? 'Safe to handle.'}',
                'Notice: ${crystal['limitations'] ?? 'Complementary symbolic practice.'}',
              ]),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryViolet,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 44.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Close Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
        SizedBox(height: 6.h),
        ...lines.map((line) => Padding(
              padding: EdgeInsets.only(bottom: 3.h),
              child: Text(
                line,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFFCBD5E1) : darkText,
                  height: 1.4,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDisclaimerFooter() {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 20.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18233C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? NumerologyTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        _reportData?['disclaimer'] ??
            'Crystals and stones are complementary symbolic and mindfulness practices. They are not intended to diagnose, treat, cure, or prevent any medical or psychological condition.',
        style: GoogleFonts.inter(
          fontSize: 10.5.sp,
          color: mutedText,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryViolet, strokeWidth: 3.w),
          SizedBox(height: 16.h),
          Text(
            'Evaluating Resonance Rules...',
            style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 4.h),
          Text(
            'Matching crystals against your authoritative numerology numbers',
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Calculation Note',
              style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
            ),
            SizedBox(height: 6.h),
            Text(
              _errorMessage ?? 'Unable to complete evaluation.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchMatches,
              style: ElevatedButton.styleFrom(backgroundColor: primaryViolet, foregroundColor: Colors.white),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInputPrompt() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showEditProfileDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Enter Profile Details'),
        style: ElevatedButton.styleFrom(backgroundColor: primaryViolet, foregroundColor: Colors.white),
      ),
    );
  }
}
