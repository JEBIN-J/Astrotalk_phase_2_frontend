import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../screens/numerology_astrologer_workspace_screen.dart';
import '../screens/numerology_chart_workspace_screen.dart';

class NumerologyProfileInputSheet extends StatefulWidget {
  final String initialName;
  final String initialDob;
  final String initialSystem;
  final String initialGender;
  final bool isFirstTime;
  final Function(String name, String dob, String system, String gender)? onProfileUpdated;

  const NumerologyProfileInputSheet({
    super.key,
    required this.initialName,
    required this.initialDob,
    required this.initialSystem,
    this.initialGender = 'other',
    this.isFirstTime = false,
    this.onProfileUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentName,
    required String currentDob,
    required String currentSystem,
    String currentGender = 'other',
    bool isFirstTime = false,
    Function(String name, String dob, String system, String gender)? onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return NumerologyProfileInputSheet(
          initialName: currentName,
          initialDob: currentDob,
          initialSystem: currentSystem,
          initialGender: currentGender,
          isFirstTime: isFirstTime,
          onProfileUpdated: onUpdated,
        );
      },
    );
  }

  @override
  State<NumerologyProfileInputSheet> createState() => _NumerologyProfileInputSheetState();
}

class _NumerologyProfileInputSheetState extends State<NumerologyProfileInputSheet> {
  late final TextEditingController _nameController;
  late String _selectedSystem;
  late String _selectedGender;

  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  Timer? _debounceTimer;
  bool _isLoadingPreview = false;
  bool _isSubmitting = false;
  String? _submitError;

  // Authoritative & Live calculated states
  int? _compoundTotal;
  int? _reducedNumber;
  List<String> _reductionSteps = [];
  List<Map<String, dynamic>> _letterValues = [];
  Set<String> _activeLetters = {};
  int? _birthDayNumber;
  int? _lifePathNumber;
  bool _isDateValid = false;
  String? _dateError;

  // Conventional alphabet maps
  static const Map<String, int> chaldeanMap = {
    'A': 1, 'I': 1, 'J': 1, 'Q': 1, 'Y': 1,
    'B': 2, 'K': 2, 'R': 2,
    'C': 3, 'G': 3, 'L': 3, 'S': 3,
    'D': 4, 'M': 4, 'T': 4,
    'E': 5, 'H': 5, 'N': 5, 'X': 5,
    'U': 6, 'V': 6, 'W': 6,
    'O': 7, 'Z': 7,
    'F': 8, 'P': 8,
  };

  static const Map<String, int> pythagoreanMap = {
    'A': 1, 'J': 1, 'S': 1,
    'B': 2, 'K': 2, 'T': 2,
    'C': 3, 'L': 3, 'U': 3,
    'D': 4, 'M': 4, 'V': 4,
    'E': 5, 'N': 5, 'W': 5,
    'F': 6, 'O': 6, 'X': 6,
    'G': 7, 'P': 7, 'Y': 7,
    'H': 8, 'Q': 8, 'Z': 8,
    'I': 9, 'R': 9,
  };

  static const Map<int, List<String>> chaldeanChart = {
    1: ['A', 'I', 'J', 'Q', 'Y'],
    2: ['B', 'K', 'R'],
    3: ['C', 'G', 'L', 'S'],
    4: ['D', 'M', 'T'],
    5: ['E', 'H', 'N', 'X'],
    6: ['U', 'V', 'W'],
    7: ['O', 'Z'],
    8: ['F', 'P'],
  };

  static const Map<int, List<String>> pythagoreanChart = {
    1: ['A', 'J', 'S'],
    2: ['B', 'K', 'T'],
    3: ['C', 'L', 'U'],
    4: ['D', 'M', 'V'],
    5: ['E', 'N', 'W'],
    6: ['F', 'O', 'X'],
    7: ['G', 'P', 'Y'],
    8: ['H', 'Q', 'Z'],
    9: ['I', 'R'],
  };

  static const List<String> monthNames = [
    'Jan (01)', 'Feb (02)', 'Mar (03)', 'Apr (04)',
    'May (05)', 'Jun (06)', 'Jul (07)', 'Aug (08)',
    'Sep (09)', 'Oct (10)', 'Nov (11)', 'Dec (12)'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedSystem = widget.initialSystem.isNotEmpty ? widget.initialSystem : 'chaldean';
    _selectedGender = widget.initialGender.isNotEmpty ? widget.initialGender : 'male';

    _parseInitialDob(widget.initialDob);

    // Initial calculation
    _calculateLocally();
    _fetchBackendPreview();
  }

  void _parseInitialDob(String dob) {
    if (dob.isEmpty) return;
    try {
      final parts = dob.split('-');
      if (parts.length == 3) {
        _selectedYear = int.tryParse(parts[0]);
        _selectedMonth = int.tryParse(parts[1]);
        _selectedDay = int.tryParse(parts[2]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // Pure calendar date validation (leap year aware)
  bool _isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) {
      return 30;
    }
    return 31;
  }

  void _validateAndCalculateDate() {
    if (_selectedDay == null || _selectedMonth == null || _selectedYear == null) {
      _isDateValid = false;
      _dateError = 'Please select complete Day, Month, and Year.';
      _birthDayNumber = null;
      _lifePathNumber = null;
      return;
    }

    final maxDays = _daysInMonth(_selectedYear!, _selectedMonth!);
    if (_selectedDay! < 1 || _selectedDay! > maxDays) {
      _isDateValid = false;
      if (_selectedMonth == 2) {
        final isLeap = _isLeapYear(_selectedYear!);
        _dateError = isLeap
            ? 'February ${_selectedYear!} has 29 days in a leap year.'
            : 'February ${_selectedYear!} has only 28 days (not a leap year).';
      } else {
        _dateError = 'Selected month only has $maxDays days.';
      }
      _birthDayNumber = null;
      _lifePathNumber = null;
      return;
    }

    _isDateValid = true;
    _dateError = null;

    final isChaldean = _selectedSystem.toLowerCase() == 'chaldean';
    final dayVal = _selectedDay!;
    final monthVal = _selectedMonth!;
    final yearVal = _selectedYear!;

    if (isChaldean) {
      // Chaldean psychic / birth day: reduce day to single digit 1-9
      _birthDayNumber = _reduceNumber(dayVal, keepMaster: false);

      // Chaldean destiny / bhagyank: sum of all digits in date reduced to 1-9
      final dateStr = '${yearVal.toString().padLeft(4, '0')}${monthVal.toString().padLeft(2, '0')}${dayVal.toString().padLeft(2, '0')}';
      int sumAll = 0;
      for (final char in dateStr.split('')) {
        sumAll += int.tryParse(char) ?? 0;
      }
      _lifePathNumber = _reduceNumber(sumAll, keepMaster: false);
    } else {
      // Pythagorean birthday: calendar day preserved or reduced
      _birthDayNumber = _reduceNumber(dayVal, keepMaster: true);

      // Pythagorean life path: month reduced + day reduced + year digits reduced
      final mRed = _reduceNumber(monthVal, keepMaster: true);
      final dRed = _reduceNumber(dayVal, keepMaster: true);
      int ySum = 0;
      for (final char in yearVal.toString().split('')) {
        ySum += int.tryParse(char) ?? 0;
      }
      final yRed = _reduceNumber(ySum, keepMaster: true);
      _lifePathNumber = _reduceNumber(mRed + dRed + yRed, keepMaster: true);
    }
  }

  int _reduceNumber(int n, {required bool keepMaster}) {
    if (keepMaster && (n == 11 || n == 22 || n == 33)) return n;
    while (n > 9) {
      int sum = 0;
      for (final char in n.toString().split('')) {
        sum += int.parse(char);
      }
      n = sum;
      if (keepMaster && (n == 11 || n == 22 || n == 33)) return n;
    }
    return n;
  }

  void _calculateLocally() {
    final rawName = _nameController.text.trim();
    final isChaldean = _selectedSystem.toLowerCase() == 'chaldean';
    final map = isChaldean ? chaldeanMap : pythagoreanMap;

    _validateAndCalculateDate();

    if (rawName.isEmpty) {
      setState(() {
        _compoundTotal = null;
        _reducedNumber = null;
        _reductionSteps = [];
        _letterValues = [];
        _activeLetters = {};
      });
      return;
    }

    int sum = 0;
    final List<Map<String, dynamic>> letters = [];
    final Set<String> activeSet = {};

    // Remove diacritics and filter unsupported characters
    final upper = rawName.toUpperCase();
    for (int i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (map.containsKey(ch)) {
        final val = map[ch]!;
        sum += val;
        letters.add({'char': ch, 'value': val});
        activeSet.add(ch);
      }
    }

    if (letters.isEmpty) {
      setState(() {
        _compoundTotal = null;
        _reducedNumber = null;
        _reductionSteps = [];
        _letterValues = [];
        _activeLetters = {};
      });
      return;
    }

    final red = _reduceNumber(sum, keepMaster: !isChaldean);
    final List<String> steps = [];
    if (sum > 9) {
      final digits = sum.toString().split('').join(' + ');
      steps.add('$sum -> $digits = ${_reduceNumber(sum, keepMaster: false)}');
    }

    setState(() {
      _compoundTotal = sum;
      _reducedNumber = red;
      _reductionSteps = steps;
      _letterValues = letters;
      _activeLetters = activeSet;
    });
  }

  void _onNameChanged(String val) {
    _calculateLocally();
    _triggerDebouncedBackendPreview();
  }

  void _triggerDebouncedBackendPreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      _fetchBackendPreview();
    });
  }

  Future<void> _fetchBackendPreview() async {
    final name = _nameController.text.trim();
    String? dobFormatted;
    if (_isDateValid && _selectedDay != null && _selectedMonth != null && _selectedYear != null) {
      dobFormatted = '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}';
    }

    setState(() => _isLoadingPreview = true);

    try {
      final res = await AstroApiService.getNumerologyPreview(
        name: name,
        dob: dobFormatted,
        day: _selectedDay,
        month: _selectedMonth,
        year: _selectedYear,
        system: _selectedSystem,
        gender: _selectedGender,
      );

      if (res['data'] != null && mounted) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          if (data['is_name_empty'] == true) {
            _compoundTotal = null;
            _reducedNumber = null;
            _reductionSteps = [];
            _letterValues = [];
            _activeLetters = {};
          } else {
            _compoundTotal = data['compound_total'] as int?;
            _reducedNumber = data['reduced_number'] as int?;
            _reductionSteps = (data['reduction_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            _activeLetters = (data['active_letters'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {};
            if (data['letter_values'] != null) {
              _letterValues = (data['letter_values'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
            }
          }

          if (data['is_date_valid'] == true) {
            _isDateValid = true;
            _dateError = null;
            _birthDayNumber = data['birth_day_number'] as int?;
            _lifePathNumber = data['life_path_number'] as int?;
          } else if (data['date_error'] != null) {
            _dateError = data['date_error'].toString();
          }
        });
      }
    } catch (_) {
      // Gracefully maintain client calculation if backend is unreachable
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _submitError = 'Please enter your full name.');
      return;
    }

    _validateAndCalculateDate();
    if (!_isDateValid) {
      setState(() => _submitError = _dateError ?? 'Please provide a valid calendar date.');
      return;
    }

    final dobFormatted = '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}';

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // 1. Authoritative Backend profile persistence and calculation
      await AstroApiService.saveNumerologyProfile(
        name: name,
        dob: dobFormatted,
        system: _selectedSystem,
        gender: _selectedGender,
      );
    } catch (e) {
      debugPrint('Note: Backend save returned: $e. Proceeding with local state synchronization.');
    }

    // 2. Persist locally to SharedPreferences for offline consistency across all screens
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numerology_user_name', name);
    await prefs.setString('numerology_user_dob', dobFormatted);
    await prefs.setString('numerology_user_system', _selectedSystem);
    await prefs.setString('numerology_user_gender', _selectedGender);

    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(name, dobFormatted, _selectedSystem, _selectedGender);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2563EB),
          duration: const Duration(seconds: 2),
          content: Text(
            widget.isFirstTime ? 'Welcome $name! Blueprint unlocked.' : 'Profile details updated successfully!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isChaldean = _selectedSystem.toLowerCase() == 'chaldean';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D36) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.5.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          widget.isFirstTime ? Icons.auto_awesome_rounded : Icons.edit_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstTime ? 'Enter Your Details' : 'Change Profile Details',
                            style: GoogleFonts.outfit(
                              fontSize: 16.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Personalize your numerological blueprint',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20.sp,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. NUMEROLOGY SYSTEM SELECTOR
                  _buildSectionLabel('NUMEROLOGY SYSTEM', isDark),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: isDark ? const Color(0xFF131D36) : Colors.white,
                        value: _selectedSystem,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          size: 22.sp,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'chaldean',
                            child: Row(
                              children: [
                                Icon(Icons.auto_stories_rounded, size: 16.sp, color: const Color(0xFFF59E0B)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text('Chaldean Numerology (Ancient Vedic)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'pythagorean',
                            child: Row(
                              children: [
                                Icon(Icons.calculate_rounded, size: 16.sp, color: const Color(0xFF3B82F6)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text('Pythagorean Numerology (Modern)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null && val != _selectedSystem) {
                            setState(() {
                              _selectedSystem = val;
                            });
                            _calculateLocally();
                            _fetchBackendPreview();
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 2. FULL NAME INPUT & LIVE CALCULATION PREVIEW
                  _buildSectionLabel('FULL NAME', isDark),
                  SizedBox(height: 6.h),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _submitError != null && _nameController.text.trim().isEmpty
                            ? const Color(0xFFEF4444)
                            : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      onChanged: _onNameChanged,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.inter(
                        fontSize: 14.5.sp,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          size: 20.sp,
                        ),
                        hintText: 'e.g. Steve Jobs',
                        hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        suffixIcon: _isLoadingPreview
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: Center(
                                  child: SizedBox(
                                    width: 14.w,
                                    height: 14.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Live Name Calculation Card
                  _buildLiveNameCalculationCard(isDark, isChaldean),
                  SizedBox(height: 16.h),

                  // 3. DATE OF BIRTH SEPARATE FIELDS (DAY, MONTH, YEAR)
                  _buildSectionLabel('DATE OF BIRTH', isDark),
                  SizedBox(height: 6.h),
                  _buildDateFields(isDark),
                  SizedBox(height: 8.h),

                  // Date Validation / Derived Numbers Banner
                  _buildDateDerivedBanner(isDark, isChaldean),
                  SizedBox(height: 16.h),

                  // 5. GENDER SELECTION
                  _buildSectionLabel('GENDER', isDark),
                  SizedBox(height: 6.h),
                  _buildGenderSelector(isDark),
                  SizedBox(height: 16.h),

                  // 6. ASTROLOGER MODE TILE (PRESERVED)
                  _buildSectionLabel('ASTROLOGER', isDark),
                  SizedBox(height: 6.h),
                  _buildAstrologerTile(isDark),
                  SizedBox(height: 8.h),

                  // 7. NUMEROLOGY CHART TILE (PRESERVED)
                  _buildNumerologyChartTile(isDark),
                  SizedBox(height: 20.h),

                  // Error message banner if any
                  if (_submitError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 16.sp, color: const Color(0xFFEF4444)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // 8. UPDATE DETAILS SUBMIT BUTTON
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: _isSubmitting ? null : _handleSave,
                      child: Ink(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSubmitting) ...[
                              SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Saving & Calculating...',
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ] else ...[
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                widget.isFirstTime ? 'Unlock Numerology Blueprint' : 'Update Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildLiveNameCalculationCard(bool isDark, bool isChaldean) {
    if (_compoundTotal == null || _reducedNumber == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 18.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Type your full name above to see live compound and reduced numerical vibrations.',
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B3E) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.5) : const Color(0xFF93C5FD),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  // Compound Total Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL: ',
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$_compoundTotal',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reduced Root Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'REDUCED ROOT: ',
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$_reducedNumber',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                isChaldean ? 'Chaldean' : 'Pythagorean',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          if (_reductionSteps.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Reduction: ${_reductionSteps.join(' -> ')}',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
              ),
            ),
          ],
          if (_letterValues.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: _letterValues.map((item) {
                final ch = item['char'].toString();
                final val = item['value'].toString();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    '$ch: $val',
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildAlphabetChart({
    required Map<int, List<String>> chart,
    required Set<String> activeLetters,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chart.entries.map((entry) {
          final number = entry.key;
          final letters = entry.value;

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2.5.h),
            child: Row(
              children: [
                // Number column
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Letters list with dynamic highlight
                Expanded(
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: letters.map((letter) {
                      final isUsed = activeLetters.contains(letter);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: isUsed
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          boxShadow: isUsed
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          letter,
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontWeight: isUsed ? FontWeight.w800 : FontWeight.w600,
                            color: isUsed
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFields(bool isDark) {
    final currentYear = DateTime.now().year;
    final yearsList = List.generate(currentYear - 1900 + 1, (i) => currentYear - i);
    final daysList = List.generate(31, (i) => i + 1);

    return Row(
      children: [
        // Day Dropdown
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _dateError != null && _selectedDay != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: isDark ? const Color(0xFF131D36) : Colors.white,
                value: _selectedDay,
                hint: Text('Day', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8))),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, size: 20.sp, color: const Color(0xFF94A3B8)),
                items: daysList.map((day) {
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      day.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedDay = val);
                  _calculateLocally();
                  _fetchBackendPreview();
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),

        // Month Dropdown
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _dateError != null && _selectedMonth != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: isDark ? const Color(0xFF131D36) : Colors.white,
                value: _selectedMonth,
                hint: Text('Month', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8))),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, size: 20.sp, color: const Color(0xFF94A3B8)),
                items: List.generate(12, (i) => i + 1).map((month) {
                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(
                      monthNames[month - 1],
                      style: GoogleFonts.inter(fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedMonth = val);
                  _calculateLocally();
                  _fetchBackendPreview();
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),

        // Year Dropdown
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _dateError != null && _selectedYear != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                dropdownColor: isDark ? const Color(0xFF131D36) : Colors.white,
                value: _selectedYear,
                hint: Text('Year', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8))),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, size: 20.sp, color: const Color(0xFF94A3B8)),
                items: yearsList.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      '$year',
                      style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedYear = val);
                  _calculateLocally();
                  _fetchBackendPreview();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateDerivedBanner(bool isDark, bool isChaldean) {
    if (_dateError != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16.sp, color: const Color(0xFFEF4444)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _dateError!,
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isDateValid || _birthDayNumber == null || _lifePathNumber == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF6EE7B7),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_rounded, size: 18.sp, color: const Color(0xFF059669)),
          SizedBox(width: 10.w),
          Expanded(
            child: Wrap(
              spacing: 12.w,
              children: [
                Text(
                  'Birth Day: $_birthDayNumber',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Life Path: $_lifePathNumber',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'VALID DATE',
              style: GoogleFonts.outfit(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    final options = [
      {'key': 'male', 'label': 'Male', 'icon': Icons.male_rounded},
      {'key': 'female', 'label': 'Female', 'icon': Icons.female_rounded},
      {'key': 'other', 'label': 'Other', 'icon': Icons.transgender_rounded},
    ];

    return Row(
      children: options.map((opt) {
        final key = opt['key'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedGender == key;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                setState(() => _selectedGender = key);
                _fetchBackendPreview();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                      : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD)),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                        : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16.sp,
                      color: isSelected
                          ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAstrologerTile(bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          final name = _nameController.text.trim();
          final dob = (_selectedYear != null && _selectedMonth != null && _selectedDay != null)
              ? '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}'
              : '';

          if (name.isEmpty || dob.isEmpty || !_isDateValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFDC2626),
                content: Text(
                  'Please enter a valid Name and Date of Birth to launch Astrologer mode.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
            return;
          }

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NumerologyAstrologerWorkspaceScreen(
                name: name,
                dob: dob,
                system: _selectedSystem,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              width: 1.2,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFEFF6FF), Colors.white],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_chart_rounded,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                  size: 19.sp,
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
                      children: [
                        Text(
                          'Astrologer Workspace',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.outfit(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Table-based Numerology Dasha & Timelines',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumerologyChartTile(bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          final name = _nameController.text.trim();
          final dob = (_selectedYear != null && _selectedMonth != null && _selectedDay != null)
              ? '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}'
              : '';

          if (name.isEmpty || dob.isEmpty || !_isDateValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFDC2626),
                content: Text(
                  'Please enter a valid Name and Date of Birth to view your Chart.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
            return;
          }

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NumerologyChartWorkspaceScreen(
                name: name,
                dob: dob,
                system: _selectedSystem,
                initialDurationYears: 10,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              width: 1.2,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF064E3B).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                  : [const Color(0xFFECFDF5), Colors.white],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                  size: 19.sp,
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
                      children: [
                        Text(
                          'Numerology Chart',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'LO SHU & 10-YR',
                            style: GoogleFonts.outfit(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Lo Shu 3x3 Grid, 10-Yr Dasha & Pratyantar',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
