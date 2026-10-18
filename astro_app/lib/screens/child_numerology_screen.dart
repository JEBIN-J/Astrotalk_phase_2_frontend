import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../theme/numerology_theme.dart';

class ChildNumerologyScreen extends StatefulWidget {
  final String? initialChildName;
  final String? initialDob;
  final String? initialSystem;
  final String? initialParentName;
  final String? initialParentDob;

  const ChildNumerologyScreen({
    super.key,
    this.initialChildName,
    this.initialDob,
    this.initialSystem,
    this.initialParentName,
    this.initialParentDob,
  });

  @override
  State<ChildNumerologyScreen> createState() => _ChildNumerologyScreenState();
}

class _ChildNumerologyScreenState extends State<ChildNumerologyScreen> {
  // Controllers
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentDobController = TextEditingController();

  // Candidate Names for Comparison Mode
  final List<TextEditingController> _candidateControllers = [
    TextEditingController(text: 'AARAV'),
    TextEditingController(text: 'REYAAN'),
    TextEditingController(text: 'ADITYA'),
  ];

  String _selectedSystem = 'pythagorean'; // 'pythagorean' or 'chaldean'
  int _primaryMode = 0; // 0: Child Profile, 1: Compare Baby Names
  int _activeProfileTab = 0; // 0: Overview & Energy, 1: Name & Letters, 2: Parent-Child, 3: Parenting & Learning

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _childReport;
  Map<String, dynamic>? _comparisonReport;

  // Theme Palette: Warm Honey Amber & Sun Gold (Responsive to dark mode)
  static const Color primaryAmber = Color(0xFFD97706); // Warm Honey Amber
  static const Color accentAmber = Color(0xFFF59E0B);  // Radiant Sun Gold
  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get cardBg => isDark ? NumerologyTheme.darkCardBg : const Color(0xFFFFFBEB);
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFFD97706).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
  Color get darkText => isDark ? Colors.white : const Color(0xFF78350F);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF92400E);
  Color get badgeBg => isDark ? NumerologyTheme.darkButtonBg : const Color(0xFFFEF3C7);
  Color get badgeText => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.initialSystem ?? 'pythagorean';

    if (widget.initialChildName != null && widget.initialChildName!.trim().isNotEmpty) {
      _childNameController.text = widget.initialChildName!.trim();
    }
    if (widget.initialDob != null && widget.initialDob!.trim().isNotEmpty) {
      _dobController.text = widget.initialDob!.trim();
    }
    if (widget.initialParentName != null && widget.initialParentName!.trim().isNotEmpty) {
      _parentNameController.text = widget.initialParentName!.trim();
    }
    if (widget.initialParentDob != null && widget.initialParentDob!.trim().isNotEmpty) {
      _parentDobController.text = widget.initialParentDob!.trim();
    }

    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChild = prefs.getString('child_numerology_name') ?? '';
    final savedDob = prefs.getString('child_numerology_dob') ?? '';
    final savedParentName = prefs.getString('numerology_user_name') ?? '';
    final savedParentDob = prefs.getString('numerology_user_dob') ?? '';

    if (mounted) {
      if (_parentNameController.text.isEmpty && savedParentName.isNotEmpty) {
        _parentNameController.text = savedParentName;
      }
      if (_parentDobController.text.isEmpty && savedParentDob.isNotEmpty) {
        _parentDobController.text = savedParentDob;
      }

      if (_childNameController.text.isEmpty && savedChild.isNotEmpty) {
        _childNameController.text = savedChild;
      }
      if (_dobController.text.isEmpty && savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }

      // Auto-analyze if valid child profile exists
      if (_childNameController.text.isNotEmpty && _dobController.text.isNotEmpty) {
        _analyzeChild();
      }
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _dobController.dispose();
    _parentNameController.dispose();
    _parentDobController.dispose();
    for (var c in _candidateControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // =========================================================================
  // API ACTIONS
  // =========================================================================

  Future<void> _analyzeChild() async {
    final name = _childNameController.text.trim();
    final dob = _dobController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = "Please enter the child's name.");
      return;
    }
    if (dob.isEmpty) {
      setState(() => _errorMessage = "Please select the child's date of birth.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.analyzeChildNumerology(
        childName: name,
        dob: dob,
        system: _selectedSystem,
        parentName: _parentNameController.text.trim().isNotEmpty ? _parentNameController.text.trim() : null,
        parentDob: _parentDobController.text.trim().isNotEmpty ? _parentDobController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _childReport = res;
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('child_numerology_name', name);
        await prefs.setString('child_numerology_dob', dob);
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

  Future<void> _compareCandidateNames() async {
    final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '2024-08-14';
    final candidateNames = _candidateControllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (candidateNames.isEmpty) {
      setState(() => _errorMessage = 'Please provide at least one candidate name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.compareChildCandidateNames(
        candidateNames: candidateNames,
        dob: dob,
        system: _selectedSystem,
      );

      if (mounted) {
        setState(() {
          _comparisonReport = res;
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

  // =========================================================================
  // EDIT PROFILE DIALOG
  // =========================================================================

  void _showEditInputsDialog() {
    final nameEdit = TextEditingController(text: _childNameController.text);
    final dobEdit = TextEditingController(text: _dobController.text);
    final parentNameEdit = TextEditingController(text: _parentNameController.text);
    final parentDobEdit = TextEditingController(text: _parentDobController.text);
    String tempSystem = _selectedSystem;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? NumerologyTheme.darkScaffoldBg : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(Icons.child_care_rounded, color: primaryAmber, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Child Profile Details',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
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
                  "Enter your child's legal or candidate name and date of birth for deterministic Mulank, Bhagyank, and Name Harmony calculations.",
                  style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: nameEdit,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
                  decoration: InputDecoration(
                    labelText: "Child's First & Full Name",
                    hintText: 'e.g. Aarav Sharma',
                    prefixIcon: const Icon(Icons.badge_rounded, color: primaryAmber),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryAmber, width: 1.5.w)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: dobEdit,
                  readOnly: true,
                  style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
                  decoration: InputDecoration(
                    labelText: "Child's Date of Birth",
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.cake_rounded, color: primaryAmber),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: primaryAmber),
                      onPressed: () async {
                        DateTime initial = DateTime.tryParse(dobEdit.text) ?? DateTime(2024, 8, 14);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(1950),
                          lastDate: DateTime(2035),
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
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryAmber, width: 1.5.w)),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Numerology System',
                  style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: darkText),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Pythagorean (1-9)', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
                        selected: tempSystem == 'pythagorean',
                        selectedColor: accentAmber,
                        backgroundColor: isDark ? NumerologyTheme.darkCardBg : Colors.white,
                        labelStyle: TextStyle(color: tempSystem == 'pythagorean' ? Colors.white : darkText),
                        onSelected: (val) {
                          if (val) setDialogState(() => tempSystem = 'pythagorean');
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Chaldean (1-8)', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
                        selected: tempSystem == 'chaldean',
                        selectedColor: primaryAmber,
                        backgroundColor: isDark ? NumerologyTheme.darkCardBg : Colors.white,
                        labelStyle: TextStyle(color: tempSystem == 'chaldean' ? Colors.white : darkText),
                        onSelected: (val) {
                          if (val) setDialogState(() => tempSystem = 'chaldean');
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Divider(color: cardBorder, height: 1.h),
                SizedBox(height: 10.h),
                Text(
                  'Parent Information (Optional for Compatibility)',
                  style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w700, color: darkText),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: parentNameEdit,
                  style: GoogleFonts.outfit(fontSize: 13.5.sp, color: darkText),
                  decoration: InputDecoration(
                    labelText: "Parent's Name",
                    hintText: 'e.g. Anandhan',
                    prefixIcon: const Icon(Icons.person_rounded, color: primaryAmber),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: parentDobEdit,
                  readOnly: true,
                  style: GoogleFonts.firaCode(fontSize: 13.sp, color: darkText),
                  decoration: InputDecoration(
                    labelText: "Parent's Date of Birth",
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.favorite_rounded, color: primaryAmber),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, color: primaryAmber),
                      onPressed: () async {
                        DateTime initial = DateTime.tryParse(parentDobEdit.text) ?? DateTime(1995, 5, 8);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(1930),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            parentDobEdit.text =
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                  ),
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
                setState(() {
                  _childNameController.text = nameEdit.text.trim();
                  _dobController.text = dobEdit.text.trim();
                  _parentNameController.text = parentNameEdit.text.trim();
                  _parentDobController.text = parentDobEdit.text.trim();
                  _selectedSystem = tempSystem;
                });
                if (_primaryMode == 0) {
                  _analyzeChild();
                } else {
                  _compareCandidateNames();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('Update & Calculate', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MAIN BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NumerologyTheme.scaffoldBg(isDark),
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
                    border: Border.all(color: cardBorder, width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.1),
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
              'Child Numerology',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            Text(
              'Developmental Vibrations & Name Harmony',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryAmber,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () {
                    if (_primaryMode == 0) {
                      _analyzeChild();
                    } else {
                      _compareCandidateNames();
                    }
                  },
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: NumerologyTheme.circleBtnBg(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder, width: 1.w),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAmber.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.refresh_rounded, color: primaryAmber, size: 19.sp),
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
    if (_errorMessage != null && _childReport == null && _comparisonReport == null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildPrimaryModeSwitcher(),
        Expanded(
          child: _primaryMode == 0
              ? (_childReport == null ? _buildInitialInputForm() : _buildChildProfileView())
              : _buildBabyNameCompareView(),
        ),
      ],
    );
  }

  // =========================================================================
  // PRIMARY MODE SWITCHER (PROFILE VS BABY NAME COMPARE)
  // =========================================================================

  Widget _buildPrimaryModeSwitcher() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? NumerologyTheme.darkButtonBg : const Color(0xFFFEF3C7).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTabItem(
              index: 0,
              label: 'Child Profile & Vibration',
              icon: Icons.child_care_rounded,
            ),
          ),
          Expanded(
            child: _buildModeTabItem(
              index: 1,
              label: 'Baby Name Compare',
              icon: Icons.compare_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabItem({required int index, required String label, required IconData icon}) {
    final isSelected = _primaryMode == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          setState(() => _primaryMode = index);
          if (index == 1 && _comparisonReport == null) {
            _compareCandidateNames();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? NumerologyTheme.darkCardBg : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15.sp, color: isSelected ? primaryAmber : (isDark ? Colors.white60 : mutedText)),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? darkText : (isDark ? Colors.white60 : mutedText),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 1: INITIAL INPUT FORM (If no report exists)
  // =========================================================================

  Widget _buildInitialInputForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.child_care_rounded, color: Colors.white, size: 28.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Child Numerology',
                        style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Calculates Mulank (Birth Number), Bhagyank (Destiny), Name Expression, and harmonious parenting guidance.',
                        style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "Child's Full Name",
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _childNameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
            decoration: InputDecoration(
              hintText: 'e.g. Aarav Sharma',
              prefixIcon: const Icon(Icons.face_rounded, color: primaryAmber),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: primaryAmber, width: 2.w)),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            "Child's Date of Birth",
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _dobController,
            readOnly: true,
            style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(Icons.cake_rounded, color: primaryAmber),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: primaryAmber),
                onPressed: () async {
                  DateTime initial = DateTime.tryParse(_dobController.text) ?? DateTime(2024, 8, 14);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _dobController.text =
                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: primaryAmber, width: 2.w)),
            ),
          ),
          SizedBox(height: 22.h),
          ElevatedButton(
            onPressed: _analyzeChild,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmber,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Calculate Child Numerology', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _childNameController.text = 'Aarav';
                _dobController.text = '2024-08-14';
                _parentNameController.text = 'Anandhan';
                _parentDobController.text = '1995-05-08';
                _analyzeChild();
              },
              icon: Icon(Icons.science_outlined, size: 16.sp, color: primaryAmber),
              label: Text(
                'Try Verified Fixture: Aarav (14 Aug 2024)',
                style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: primaryAmber),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: CHILD PROFILE VIEW (Overview, Name, Parent Harmony, Learning)
  // =========================================================================

  Widget _buildChildProfileView() {
    return Column(
      children: [
        _buildChildHeroHeader(),
        _buildChildProfileTabs(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildSelectedProfileTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildChildHeroHeader() {
    final childName = _childReport?['child_name'] ?? 'Child';
    final dob = _childReport?['dob'] ?? '';
    final birthCalc = _childReport?['birth_number'] as Map<String, dynamic>? ?? {};
    final destinyCalc = _childReport?['destiny_number'] as Map<String, dynamic>? ?? {};
    final nameCalc = _childReport?['name_number'] as Map<String, dynamic>? ?? {};
    final nameCompat = _childReport?['name_compatibility'] as Map<String, dynamic>? ?? {};

    final mulank = birthCalc['birth_number'] ?? 0;
    final bhagyank = destinyCalc['destiny_number'] ?? 0;
    final nameRoot = nameCalc['name_root'] ?? 0;
    final harmonyCat = nameCompat['overall_category'] ?? 'Harmonious';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryAmber.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.child_care_rounded, color: Colors.white, size: 28.sp),
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
                            childName,
                            style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w800, color: darkText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _selectedSystem == 'chaldean' ? 'Chaldean' : 'Pythagorean',
                            style: GoogleFonts.firaCode(fontSize: 9.sp, fontWeight: FontWeight.w800, color: badgeText),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.cake_rounded, size: 12.sp, color: primaryAmber),
                        SizedBox(width: 4.w),
                        Text(
                          'DOB: $dob',
                          style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showEditInputsDialog,
                icon: Icon(Icons.edit_rounded, size: 12.sp, color: primaryAmber),
                label: Text('Edit', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryAmber,
                  side: BorderSide(color: primaryAmber.withValues(alpha: 0.4)),
                  backgroundColor: surfaceBg,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 4 Core Metric Pills
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildMetricItem('Mulank', 'Root $mulank', Icons.cake_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Bhagyank', 'Root $bhagyank', Icons.route_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Name Root', 'Root $nameRoot', Icons.spellcheck_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Harmony', harmonyCat.split(' ').first, Icons.stars_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10.sp, color: primaryAmber),
            SizedBox(width: 3.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: mutedText),
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
            style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: darkText),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1.w, height: 18.h, color: cardBorder);
  }

  Widget _buildChildProfileTabs() {
    final tabs = [
      {'label': 'Overview & Energy', 'icon': Icons.auto_awesome_rounded},
      {'label': 'Name & Letters', 'icon': Icons.spellcheck_rounded},
      {'label': 'Parent Harmony', 'icon': Icons.family_restroom_rounded},
      {'label': 'Parenting & Learning', 'icon': Icons.menu_book_rounded},
    ];

    return Container(
      height: 44.h,
      margin: EdgeInsets.only(top: 4.h, bottom: 6.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = _activeProfileTab == index;
          final tab = tabs[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => setState(() => _activeProfileTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? primaryAmber : surfaceBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? primaryAmber : cardBorder,
                    width: 1.w,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryAmber.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 14.sp,
                      color: isSelected ? Colors.white : primaryAmber,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedProfileTabContent() {
    switch (_activeProfileTab) {
      case 0:
        return _buildProfileOverviewTab();
      case 1:
        return _buildProfileNameTraceTab();
      case 2:
        return _buildProfileParentHarmonyTab();
      case 3:
      default:
        return _buildProfileParentingTab();
    }
  }

  // =========================================================================
  // TAB 0: OVERVIEW & CORE ENERGY (MULANK & BHAGYANK)
  // =========================================================================

  Widget _buildProfileOverviewTab() {
    final interp = _childReport?['interpretations'] as Map<String, dynamic>? ?? {};
    final birthInterp = interp['birth_number'] as Map<String, dynamic>? ?? {};
    final destinyInterp = interp['destiny_number'] as Map<String, dynamic>? ?? {};
    final nameCompat = _childReport?['name_compatibility'] as Map<String, dynamic>? ?? {};
    final score = nameCompat['overall_score'] ?? 80;
    final vsMulank = nameCompat['vs_birth_number'] as Map<String, dynamic>? ?? {};

    final elements = (birthInterp['favourable_elements'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Auspicious Name Harmony Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: isDark ? 0.05 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder, width: 1.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAmber.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$score%',
                        style: GoogleFonts.outfit(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryAmber,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameCompat['overall_category'] ?? 'Harmonious Resonance',
                          style: GoogleFonts.outfit(fontSize: 15.5.sp, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Name Vibration vs Birth & Destiny Alignment',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                vsMulank['explanation'] ?? 'Name root vibrations align with the child Mulank.',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Core Mulank Archetype Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.stars_rounded, color: Colors.white, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Day-of-Birth Temperament (Mulank)',
                            style: GoogleFonts.outfit(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: badgeText),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          birthInterp['archetype'] ?? 'Child Archetype',
                          style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                birthInterp['detailed_explanation'] ?? 'Detailed explanation of child temperament.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.45),
              ),
              SizedBox(height: 12.h),
              // Planetary Elements Strip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildElementMini('Ruler', elements['ruler'] ?? 'Sun'),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      flex: 3,
                      child: _buildElementMini('Element', elements['element'] ?? 'Fire'),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      flex: 5,
                      child: _buildElementMini('Colors', elements['colors'] ?? 'Gold'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Destiny Number (Bhagyank) Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.route_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Destiny Life Path (Bhagyank)',
                      style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                destinyInterp['detailed_explanation'] ?? 'Destiny roadmap explanation.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildElementMini(String title, String val) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 9.sp, color: mutedText, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            val,
            style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, color: darkText),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: NAME & LETTERS BREAKDOWN TRACE
  // =========================================================================

  Widget _buildProfileNameTraceTab() {
    final nameCalc = _childReport?['name_number'] as Map<String, dynamic>? ?? {};
    final letters = (nameCalc['letter_breakdown'] as List<dynamic>?) ?? [];
    final compound = nameCalc['compound_total'] ?? 0;
    final root = nameCalc['name_root'] ?? 0;
    final soulUrge = nameCalc['soul_urge'] as Map<String, dynamic>? ?? {};
    final personality = nameCalc['personality'] as Map<String, dynamic>? ?? {};
    final interp = _childReport?['interpretations'] as Map<String, dynamic>? ?? {};
    final soulInterp = interp['soul_urge'] as Map<String, dynamic>? ?? {};
    final persInterp = interp['personality_number'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Visual Letter Value Chips
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
                blurRadius: 10,
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Icon(Icons.spellcheck_rounded, color: primaryAmber, size: 16.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Name Sound Trace (${_selectedSystem.toUpperCase()})',
                        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Letters Wrap
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 8.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...letters.map((l) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: l['is_vowel'] == true
                                ? (isDark ? const Color(0xFF2A1C08) : const Color(0xFFFEF3C7))
                                : surfaceBg,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: l['is_vowel'] == true ? primaryAmber : cardBorder,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l['letter'] ?? '',
                                style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: darkText),
                              ),
                              Text(
                                '${l['value']}',
                                style: GoogleFonts.firaCode(fontSize: 11.sp, fontWeight: FontWeight.w700, color: primaryAmber),
                              ),
                            ],
                          ),
                        )),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text('=', style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1C08) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: primaryAmber),
                      ),
                      child: Text(
                        'Total $compound',
                        style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 14.sp, color: primaryAmber),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: primaryAmber,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Root $root',
                        style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Letters in gold pills denote vowels (Soul Urge), while white pills denote consonants (Personality).',
                style: GoogleFonts.inter(fontSize: 10.5.sp, color: mutedText),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Soul Urge Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.favorite_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Soul Urge (Vowels) • Root ${soulUrge['root'] ?? 0}',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                soulInterp['short_description'] ?? 'Inner emotional motivations of the child.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Personality Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.face_retouching_natural_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Outer Demeanor (Consonants) • Root ${personality['root'] ?? 0}',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                persInterp['short_description'] ?? 'Social presence and peer impression.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  // =========================================================================
  // TAB 2: PARENT-CHILD HARMONY TAB
  // =========================================================================

  Widget _buildProfileParentHarmonyTab() {
    final parentComp = _childReport?['parent_compatibility'] as Map<String, dynamic>?;

    if (parentComp == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: Icon(Icons.family_restroom_rounded, size: 34.sp, color: primaryAmber),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Parent Information Optional',
                style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w800, color: darkText),
              ),
              SizedBox(height: 6.h),
              Text(
                'Add the parent or guardian date of birth to evaluate natural planetary resonance, mutual communication flow, and supportive parenting advice.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: _showEditInputsDialog,
                icon: Icon(Icons.add_rounded, size: 16.sp),
                label: Text('Add Parent DOB', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pName = parentComp['parent_name'] ?? 'Parent';
    final pMulank = parentComp['parent_birth_number'] ?? 0;
    final mulankMatch = parentComp['mulank_harmony'] as Map<String, dynamic>? ?? {};
    final score = parentComp['overall_score'] ?? 80;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Overall Parent-Child Bond Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: isDark ? 0.05 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder, width: 1.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAmber.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$score%',
                        style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: primaryAmber),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentComp['overall_category'] ?? 'Harmonious Bond',
                          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$pName (Root $pMulank) & Child Dynamic',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: (score / 100.0).clamp(0.0, 1.0),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  color: primaryAmber,
                  minHeight: 7.h,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Mutual Dynamics Explanation Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                  Icon(Icons.hub_rounded, color: primaryAmber, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Planetary Communication Flow', style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText)),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                mulankMatch['explanation'] ?? 'Mutual communication dynamic.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Supportive Parenting Advice
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                  Icon(Icons.tips_and_updates_rounded, color: primaryAmber, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Parenting Harmony Tip', style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText)),
                ],
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  mulankMatch['parenting_tip'] ?? 'Parenting guidance.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  // =========================================================================
  // TAB 3: PARENTING & PRACTICAL LEARNING GUIDANCE
  // =========================================================================

  Widget _buildProfileParentingTab() {
    final interp = _childReport?['interpretations'] as Map<String, dynamic>? ?? {};
    final birthInterp = interp['birth_number'] as Map<String, dynamic>? ?? {};
    final strengths = (birthInterp['strengths'] as List<dynamic>?) ?? [];
    final challenges = (birthInterp['potential_challenges'] as List<dynamic>?) ?? [];
    final parenting = (birthInterp['supportive_parenting_guidance'] as List<dynamic>?) ?? [];
    final learning = (birthInterp['practical_learning_suggestions'] as List<dynamic>?) ?? [];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Positive Potential Strengths
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.verified_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Positive Potential Strengths',
                    style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...strengths.map((s) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: primaryAmber, size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            s.toString(),
                            style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: darkText),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Mindful Challenges Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.35) : const Color(0xFFFED7AA), width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2012) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: isDark ? const Color(0xFFB45309) : const Color(0xFFFED7AA)),
                    ),
                    child: Icon(Icons.shield_outlined, color: const Color(0xFFD97706), size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Mindful Developmental Nuances',
                    style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...challenges.map((c) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A).withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, color: const Color(0xFFD97706), size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            c.toString(),
                            style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF78350F)),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Supportive Parenting Suggestions
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.volunteer_activism_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Supportive Parenting Practices',
                    style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...parenting.map((p) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: primaryAmber, size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            p.toString(),
                            style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Practical Learning Suggestions
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withValues(alpha: 0.05),
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.toys_rounded, color: primaryAmber, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Learning, Play & Developmental Tools',
                    style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...learning.map((l) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.palette_outlined, color: primaryAmber, size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            l.toString(),
                            style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  // =========================================================================
  // VIEW 3: BABY NAME COMPARISON VIEW (Candidate Side-by-Side Analysis)
  // =========================================================================

  Widget _buildBabyNameCompareView() {
    final candidates = (_comparisonReport?['candidates'] as List<dynamic>?) ?? [];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Comparison Intro Card
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: surfaceBg, shape: BoxShape.circle),
                child: Center(
                  child: Icon(Icons.compare_rounded, color: primaryAmber, size: 22.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Candidate Name Comparison',
                      style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Compare candidate baby names against birth date (${_dobController.text.isNotEmpty ? _dobController.text : "2024-08-14"}).',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Candidate Input Row with Add/Remove
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidate Names to Evaluate',
                    style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  if (_candidateControllers.length < 5)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _candidateControllers.add(TextEditingController(text: 'NAME ${_candidateControllers.length + 1}'));
                        });
                      },
                      icon: Icon(Icons.add_circle_outline_rounded, size: 14.sp, color: primaryAmber),
                      label: Text('Add Name', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w700, color: primaryAmber)),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              ...List.generate(_candidateControllers.length, (idx) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${idx + 1}', style: GoogleFonts.firaCode(fontSize: 11.sp, fontWeight: FontWeight.w800, color: primaryAmber)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _candidateControllers[idx],
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            filled: true,
                            fillColor: cardBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: cardBorder)),
                          ),
                        ),
                      ),
                      if (_candidateControllers.length > 2) ...[
                        SizedBox(width: 6.w),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18.sp),
                          onPressed: () {
                            setState(() {
                              _candidateControllers.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }),
              SizedBox(height: 6.h),
              ElevatedButton(
                onPressed: _compareCandidateNames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 42.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Text('Run Name Comparison & Ranking', style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Ranked Candidate Cards
        if (candidates.isNotEmpty) ...[
          Text(
            'Ranked Recommendations (Highest Planetary Harmony First)',
            style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: darkText),
          ),
          SizedBox(height: 8.h),
          ...List.generate(candidates.length, (idx) {
            final cand = candidates[idx] as Map<String, dynamic>;
            final name = cand['candidate_name'] ?? '';
            final score = cand['suitability_score'] ?? 75;
            final root = cand['name_root'] ?? 0;
            final compound = cand['compound_total'] ?? 0;
            final category = cand['harmony_category'] ?? '';
            final archetype = cand['archetype'] ?? '';
            final vsMulank = cand['mulank_harmony'] as Map<String, dynamic>? ?? {};

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: idx == 0 ? primaryAmber : cardBorder, width: idx == 0 ? 1.8.w : 1.2.w),
                boxShadow: [
                  BoxShadow(
                    color: primaryAmber.withValues(alpha: idx == 0 ? 0.12 : 0.04),
                    blurRadius: 10,
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: idx == 0 ? primaryAmber : badgeBg,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Rank #${idx + 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: idx == 0 ? Colors.white : badgeText,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w900, color: darkText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Text(
                          '$score% Harmony',
                          style: GoogleFonts.firaCode(fontSize: 12.sp, fontWeight: FontWeight.w800, color: primaryAmber),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(6.r)),
                        child: Text(
                          'Compound $compound -> Root $root',
                          style: GoogleFonts.firaCode(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: darkText),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          archetype,
                          style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryAmber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    category,
                    style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    vsMulank['explanation'] ?? '',
                    style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35),
                  ),
                ],
              ),
            );
          }),
        ],
        SizedBox(height: 16.h),
      ],
    );
  }

  // =========================================================================
  // STATES (LOADING, ERROR)
  // =========================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryAmber, strokeWidth: 3.w),
          SizedBox(height: 16.h),
          Text(
            'Analyzing Child Numerology...',
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 4.h),
          Text(
            'Calculating Mulank, Bhagyank, and database-verified parenting guidance',
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
            Text('Analysis Note', style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText)),
            SizedBox(height: 6.h),
            Text(
              _errorMessage ?? 'Unable to complete evaluation.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _analyzeChild,
              style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.white),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
