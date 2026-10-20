import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class NumerologyChartWorkspaceScreen extends StatefulWidget {
  final String name;
  final String dob;
  final String system;
  final String? initialStartDate;
  final int initialDurationYears;

  const NumerologyChartWorkspaceScreen({
    super.key,
    required this.name,
    required this.dob,
    this.system = 'pythagorean',
    this.initialStartDate,
    this.initialDurationYears = 10,
  });

  @override
  State<NumerologyChartWorkspaceScreen> createState() =>
      _NumerologyChartWorkspaceScreenState();
}

class _NumerologyChartWorkspaceScreenState
    extends State<NumerologyChartWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active state
  late String _currentName;
  late String _currentDob;
  late String _currentSystem;
  String _gridType = 'vedic';
  late DateTime _startDate;
  DateTime? _customEndDate;
  int _durationYears = 10;
  int? _selectedParentDasha;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _chartData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentName = widget.name;
    _currentDob = widget.dob;
    _currentSystem = widget.system;

    if (widget.initialStartDate != null && widget.initialStartDate!.isNotEmpty) {
      try {
        _startDate = DateTime.parse(widget.initialStartDate!);
      } catch (_) {
        _startDate = DateTime.now();
      }
    } else {
      _startDate = DateTime.now();
    }
    _durationYears = widget.initialDurationYears;

    _fetchChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getChartWorkspace(
        name: _currentName,
        dateOfBirth: _currentDob,
        system: _currentSystem,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        durationYears: _durationYears,
        endDate: _customEndDate != null
            ? DateFormat('yyyy-MM-dd').format(_customEndDate!)
            : null,
        parentDashaFilter: _selectedParentDasha,
        gridType: _gridType,
      );

      if (mounted) {
        setState(() {
          _chartData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _currentName);
    final dobController = TextEditingController(text: _currentDob);
    String selectedSystem = _currentSystem;
    String selectedGridType = _gridType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            top: 20.h,
            left: 20.w,
            right: 20.w,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chart Calculation Profile',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Update details to recompute the 3x3 Charts, Dasha & Pratyantar timelines.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 16.h),
              // Full Name field
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 12.h),
              // Date of Birth field
              TextField(
                controller: dobController,
                readOnly: true,
                onTap: () async {
                  DateTime initDate = DateTime.tryParse(dobController.text) ?? DateTime(1995, 1, 1);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final formatted = DateFormat('yyyy-MM-dd').format(picked);
                    setModalState(() {
                      dobController.text = formatted;
                    });
                  }
                },
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.cake_rounded),
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 14.h),
              // Grid Model Type Selector (Vedic / Lo Shu)
              Text(
                'Grid Layout Model:',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Vedic Ank Kundli (3-1-9)', style: GoogleFonts.outfit(fontSize: 12.sp)),
                      selected: selectedGridType == 'vedic',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedGridType = 'vedic');
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Lo Shu Square (4-9-2)', style: GoogleFonts.outfit(fontSize: 12.sp)),
                      selected: selectedGridType == 'loshu',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedGridType = 'loshu');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Numerology System Selector
              Text(
                'Calculation Engine System:',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Pythagorean (1-9)', style: GoogleFonts.outfit(fontSize: 12.sp)),
                      selected: selectedSystem == 'pythagorean',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedSystem = 'pythagorean');
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Chaldean (1-8)', style: GoogleFonts.outfit(fontSize: 12.sp)),
                      selected: selectedSystem == 'chaldean',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedSystem = 'chaldean');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () {
                    final trimmedName = nameController.text.trim();
                    final trimmedDob = dobController.text.trim();
                    if (trimmedName.isEmpty || trimmedDob.isEmpty) return;

                    setState(() {
                      _currentName = trimmedName;
                      _currentDob = trimmedDob;
                      _currentSystem = selectedSystem;
                      _gridType = selectedGridType;
                    });
                    Navigator.of(ctx).pop();
                    _saveProfilePreferences(trimmedName, trimmedDob, selectedSystem);
                    _fetchChartData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'Update & Recalculate Charts',
                    style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfilePreferences(String name, String dob, String system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_dob', dob);
    await prefs.setString('user_system', system);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFD);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _errorMessage != null
                      ? _buildErrorState(isDark)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 0: The exact 3-section stacked layout from screenshot!
                            _buildAllChartsView(isDark),
                            // TAB 1: Dasha Timeline Table & details
                            _buildDashaTimelineTab(isDark),
                            // TAB 2: Pratyantar Subperiods Table & details
                            _buildPratyantarSubperiodsTab(isDark),
                            // TAB 3: 8 Planes Analysis
                            _buildPlanesAnalysisTab(isDark),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP APP BAR (STANDARD ASTROTALK WORKSPACE THEME)
  // ==========================================
  Widget _buildTopAppBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back Button, Title with Badge, Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16.sp,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Chart',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'NUMEROLOGY',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons: Edit Profile & Refresh
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.r),
                        onTap: _showEditProfileModal,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 16.sp,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.r),
                        onTap: _fetchChartData,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 16.sp,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Row 2: Profile Subtitle Strip
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: InkWell(
              onTap: _showEditProfileModal,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14.sp, color: const Color(0xFF2563EB)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        '$_currentName • $_currentDob • ${_currentSystem == 'chaldean' ? 'Chaldean' : 'Pythagorean'} • ${_gridType == 'vedic' ? 'Vedic' : 'Lo Shu'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 9.5.sp,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.edit_rounded,
                            size: 10.sp,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 7.h),

          // Row 3: Separated & Labeled Controls (Span vs Start Date)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group 1: Span / Duration
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          'Span:',
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      _buildDurationChip('1Y', _durationYears == 1 && _customEndDate == null, () {
                        setState(() {
                          _durationYears = 1;
                          _customEndDate = null;
                        });
                        _fetchChartData();
                      }),
                      _buildDurationChip('5Y', _durationYears == 5 && _customEndDate == null, () {
                        setState(() {
                          _durationYears = 5;
                          _customEndDate = null;
                        });
                        _fetchChartData();
                      }),
                      _buildDurationChip('10Y', _durationYears == 10 && _customEndDate == null, () {
                        setState(() {
                          _durationYears = 10;
                          _customEndDate = null;
                        });
                        _fetchChartData();
                      }),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Group 2: Start Date
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          'Start:',
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      _buildDateOriginChip(
                        'DOB',
                        _isSameDay(_startDate, _parseDateSafely(_currentDob)),
                        () {
                          final dobDate = _parseDateSafely(_currentDob);
                          if (dobDate != null) {
                            setState(() {
                              _startDate = dobDate;
                              _customEndDate = null;
                            });
                            _fetchChartData();
                          }
                        },
                      ),
                      _buildDateOriginChip(
                        'Today',
                        _isSameDay(_startDate, DateTime.now()),
                        () {
                          setState(() {
                            _startDate = DateTime.now();
                            _customEndDate = null;
                          });
                          _fetchChartData();
                        },
                      ),
                      // Custom Date Picker Chip
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                            _fetchChartData();
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 3.w),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: (!_isSameDay(_startDate, _parseDateSafely(_currentDob)) &&
                                    !_isSameDay(_startDate, DateTime.now()))
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: (!_isSameDay(_startDate, _parseDateSafely(_currentDob)) &&
                                      !_isSameDay(_startDate, DateTime.now()))
                                  ? const Color(0xFF3B82F6)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 12.sp,
                                color: (!_isSameDay(_startDate, _parseDateSafely(_currentDob)) &&
                                        !_isSameDay(_startDate, DateTime.now()))
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                DateFormat('dd-MMM-yyyy').format(_startDate),
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: (!_isSameDay(_startDate, _parseDateSafely(_currentDob)) &&
                                          !_isSameDay(_startDate, DateTime.now()))
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 7.h),

          // Row 4: Navigation Tabs
          SizedBox(
            height: 38.h,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTabPill('All Charts', 0, isDark),
                _buildTabPill('Dasha Timeline', 1, isDark),
                _buildTabPill('Pratyantar Dasha', 2, isDark),
                _buildTabPill('Planes Analysis', 3, isDark),
              ],
            ),
          ),
          SizedBox(height: 7.h),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, int index, bool isDark) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final isSelected = _tabController.index == index;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 0: ALL CHARTS (MATCHES SCREENSHOT 1:1)
  // ==========================================
  Widget _buildAllChartsView(bool isDark) {
    final basicChart = _chartData?['basic_chart'] as Map<String, dynamic>? ?? {};
    final basicGridMatrix = basicChart['grid_matrix'] as List<dynamic>? ?? [];

    final dashaChart = _chartData?['dasha_chart'] as Map<String, dynamic>? ?? {};
    final dashaCards = (dashaChart['charts'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    final pratyantarChart = _chartData?['pratyantar_chart'] as Map<String, dynamic>? ?? {};
    final pratyantarCards = (pratyantarChart['charts'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // SECTION 1: BASIC CHART
          // ----------------------------------------------------
          _buildSectionHeaderBanner(
            title: 'Basic Chart:',
            icon: Icons.auto_awesome_rounded,
            badgeText: basicChart['core_numbers']?['mulank']?['number'] != null
                ? 'Mulank ${basicChart['core_numbers']['mulank']['number']}'
                : null,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13.r),
              child: _buildGridMatrixTable(
                gridMatrix: basicGridMatrix,
                isDark: isDark,
                cellHeight: 52.h,
                fontSize: 19.sp,
                onCellTap: (cell) => _showCellDetailsModal(cell),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // ----------------------------------------------------
          // SECTION 2: DASHA AND ANTARDASHA CHART
          // ----------------------------------------------------
          _buildSectionHeaderBanner(
            title: 'Dasha and Antardasha Chart:',
            icon: Icons.timeline_rounded,
            badgeText: dashaCards.isNotEmpty
                ? '${dashaCards.length} Charts'
                : null,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          if (dashaCards.isEmpty)
            _buildEmptyInlineCard('No Dasha charts found for this time window.', isDark)
          else if (dashaCards.length == 1)
            _buildDashaCardModel(dashaCards.first, isDark, isFullWidth: true)
          else
            SizedBox(
              height: 226.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: dashaCards.length,
                itemBuilder: (context, index) {
                  final card = dashaCards[index];
                  return _buildDashaCardModel(card, isDark, width: 335.w);
                },
              ),
            ),
          SizedBox(height: 18.h),

          // ----------------------------------------------------
          // SECTION 3: PRATYANTAR DASHA CHART
          // ----------------------------------------------------
          _buildSectionHeaderBanner(
            title: 'Pratyantar Dasha Chart:',
            icon: Icons.hourglass_top_rounded,
            badgeText: pratyantarCards.isNotEmpty
                ? '${pratyantarCards.length} Charts'
                : null,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          if (pratyantarCards.isEmpty)
            _buildEmptyInlineCard('No Pratyantar charts found for this time window.', isDark)
          else if (pratyantarCards.length == 1)
            _buildPratyantarCardModel(pratyantarCards.first, isDark, isFullWidth: true)
          else
            SizedBox(
              height: 226.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: pratyantarCards.length,
                itemBuilder: (context, index) {
                  final card = pratyantarCards[index];
                  return _buildPratyantarCardModel(card, isDark, width: 335.w);
                },
              ),
            ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION HEADER BANNER (STANDARD ASTROTALK STYLE)
  // ==========================================
  Widget _buildSectionHeaderBanner({
    required String title,
    IconData? icon,
    String? badgeText,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.5) : const Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                    size: 15.sp,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (badgeText != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.5.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.5) : const Color(0xFFBFDBFE),
                  width: 0.8,
                ),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 3x3 GRID MATRIX TABLE WIDGET (STANDARD ASTROTALK STYLE)
  // ==========================================
  Widget _buildGridMatrixTable({
    required List<dynamic> gridMatrix,
    required bool isDark,
    required double cellHeight,
    required double fontSize,
    Function(Map<String, dynamic>)? onCellTap,
  }) {
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final numberColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final watermarkColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (r) {
        return Row(
          children: List.generate(3, (c) {
            final cell = (gridMatrix.length > r && (gridMatrix[r] as List).length > c)
                ? gridMatrix[r][c] as Map<String, dynamic>?
                : null;
            final displayText = cell?['display_text']?.toString() ?? '';
            final hasNumber = displayText.isNotEmpty && displayText != '-';
            final isAdded = cell?['is_added'] == true;
            final int expectedNumber = cell?['number'] ?? 0;

            return Expanded(
              child: InkWell(
                onTap: cell != null && onCellTap != null ? () => onCellTap(cell) : null,
                child: Container(
                  height: cellHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      right: c < 2 ? BorderSide(color: borderColor, width: 1.0) : BorderSide.none,
                      bottom: r < 2 ? BorderSide(color: borderColor, width: 1.0) : BorderSide.none,
                    ),
                    color: isAdded
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                            : const Color(0xFFEFF6FF))
                        : (isDark ? const Color(0xFF111827) : Colors.white),
                  ),
                  child: Stack(
                    children: [
                      // Faint watermark of expected house number when empty
                      if (!hasNumber && expectedNumber > 0)
                        Center(
                          child: Text(
                            '$expectedNumber',
                            style: GoogleFonts.outfit(
                              fontSize: (fontSize - 2).sp,
                              fontWeight: FontWeight.w500,
                              color: watermarkColor,
                            ),
                          ),
                        ),

                      // Number Text
                      if (hasNumber)
                        Center(
                          child: Text(
                            displayText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w800,
                              color: isAdded
                                  ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                  : numberColor,
                              letterSpacing: displayText.length > 2 ? 0.5 : 1.2,
                            ),
                          ),
                        ),

                      // Subtle dot indicator for added Dasha numbers
                      if (isAdded)
                        Positioned(
                          top: 4.h,
                          right: 5.w,
                          child: Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ==========================================
  // DASHA AND ANTARDASHA CARD MODEL (EXECUTIVE STANDARD THEME)
  // ==========================================
  Widget _buildDashaCardModel(
    Map<String, dynamic> card,
    bool isDark, {
    bool isFullWidth = false,
    double? width,
  }) {
    final fromDate = card['from_date'] ?? '-';
    final toDate = card['to_date'] ?? '-';
    final antardasha = card['antardasha']?.toString() ?? '-';
    final dasha = card['dasha']?.toString() ?? '-';
    final gridMatrix = card['grid_matrix'] as List<dynamic>? ?? [];

    return Container(
      width: isFullWidth ? double.infinity : (width ?? 335.w),
      margin: isFullWidth ? EdgeInsets.zero : EdgeInsets.only(right: 14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Executive Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Dates with calendar icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            fromDate,
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      Text(
                        toDate,
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // Row 2: AntarDasha & Dasha Stat Pills
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AntarDasha',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                antardasha,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dasha',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                dasha,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3x3 Grid Matrix Body
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: _buildGridMatrixTable(
                gridMatrix: gridMatrix,
                isDark: isDark,
                cellHeight: isFullWidth ? 52.h : 50.h,
                fontSize: isFullWidth ? 19.sp : 18.sp,
                onCellTap: (cell) => _showCellDetailsModal(cell),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRATYANTAR DASHA CARD MODEL (EXECUTIVE STANDARD THEME)
  // ==========================================
  Widget _buildPratyantarCardModel(
    Map<String, dynamic> card,
    bool isDark, {
    bool isFullWidth = false,
    double? width,
  }) {
    final fromDate = card['from_date'] ?? '-';
    final toDate = card['to_date'] ?? '-';
    final antardasha = card['antardasha']?.toString() ?? '-';
    final dasha = card['dasha']?.toString() ?? '-';
    final pratyantarDasha = card['pratyantar_dasha']?.toString() ?? '-';
    final gridMatrix = card['grid_matrix'] as List<dynamic>? ?? [];

    return Container(
      width: isFullWidth ? double.infinity : (width ?? 335.w),
      margin: isFullWidth ? EdgeInsets.zero : EdgeInsets.only(right: 14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Executive Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Dates
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            fromDate,
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      Text(
                        toDate,
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // Row 2: 3 Stat Badges (AD, Dasha, PD)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('AD', style: GoogleFonts.inter(fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(antardasha, style: GoogleFonts.outfit(fontSize: 12.5.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MD', style: GoogleFonts.inter(fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(dasha, style: GoogleFonts.outfit(fontSize: 12.5.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PD', style: GoogleFonts.inter(fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(pratyantarDasha, style: GoogleFonts.outfit(fontSize: 12.5.sp, color: const Color(0xFF0284C7), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3x3 Grid Matrix Body
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: _buildGridMatrixTable(
                gridMatrix: gridMatrix,
                isDark: isDark,
                cellHeight: isFullWidth ? 52.h : 50.h,
                fontSize: isFullWidth ? 19.sp : 18.sp,
                onCellTap: (cell) => _showCellDetailsModal(cell),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: DASHA TIMELINE TABLE
  // ==========================================
  Widget _buildDashaTimelineTab(bool isDark) {
    final dashaChart = _chartData?['dasha_chart'] as Map<String, dynamic>? ?? {};
    final timeline = dashaChart['timeline'] as Map<String, dynamic>? ?? {};
    final periods = (dashaChart['periods'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final activeDasha = timeline['active_dasha'] as Map<String, dynamic>?;
    final dashaCards = (dashaChart['charts'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Column(
      children: [
        // Top Timeline Summary Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: isDark ? const Color(0xFF111827) : const Color(0xFFEFF6FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dasha Timeline Window',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      timeline['duration_label'] ?? '$_durationYears Years',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                'Window: ${timeline['formatted_window'] ?? '-'}',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                ),
              ),
              if (activeDasha != null) ...[
                SizedBox(height: 3.h),
                Text(
                  'Active Period: MD ${activeDasha['dasha_number']} (${activeDasha['lord']}) • ${activeDasha['start_date']} to ${activeDasha['end_date']}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Quick peek horizontal cards
        if (dashaCards.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 14.w, top: 10.h, bottom: 4.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Period Chart Models:',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 226.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              physics: const BouncingScrollPhysics(),
              itemCount: dashaCards.length,
              itemBuilder: (context, index) => _buildDashaCardModel(
                dashaCards[index],
                isDark,
                width: dashaCards.length == 1 ? (1.sw - 28.w) : 335.w,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],

        // Intersecting Mahadashas Table
        Expanded(
          child: periods.isEmpty
              ? _buildEmptyMessage('No Dasha periods intersect this window.', isDark)
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        dataRowMinHeight: 46.h,
                        dataRowMaxHeight: 54.h,
                        horizontalMargin: 12.w,
                        columnSpacing: 14.w,
                        border: TableBorder.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        columns: [
                          DataColumn(label: _buildColumnHeader('Dasha / Lord', isDark)),
                          DataColumn(label: _buildColumnHeader('Actual Start', isDark)),
                          DataColumn(label: _buildColumnHeader('Actual End', isDark)),
                          DataColumn(label: _buildColumnHeader('Duration', isDark)),
                          DataColumn(label: _buildColumnHeader('Age Span', isDark)),
                          DataColumn(label: _buildColumnHeader('Status', isDark)),
                          DataColumn(label: _buildColumnHeader('Action', isDark)),
                        ],
                        rows: periods.map((p) {
                          final isActive = p['is_active'] == true;
                          final rowBg = isActive
                              ? (isDark
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                                  : const Color(0xFFEFF6FF))
                              : null;

                          return DataRow(
                            color: WidgetStateProperty.all(rowBg),
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildNumberBadge(p['dasha_number'] ?? 0, isDark),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${p['lord']} (${p['vedic_name'] ?? ''})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  p['start_date'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  p['end_date'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${p['duration_years']} Yrs',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'Age ${p['age_start']} - ${p['age_end']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(p['status'] ?? 'Upcoming', isDark)),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedParentDasha = p['dasha_number'];
                                    });
                                    _tabController.animateTo(2);
                                    _fetchChartData();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                                  ),
                                  child: Text('Inspect', style: GoogleFonts.outfit(fontSize: 10.sp)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: PRATYANTAR SUBPERIODS TABLE
  // ==========================================
  Widget _buildPratyantarSubperiodsTab(bool isDark) {
    final pratyantar = _chartData?['pratyantar_chart'] as Map<String, dynamic>? ?? {};
    final subperiods = (pratyantar['subperiods'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final pratyantarCards = (pratyantar['charts'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Column(
      children: [
        // Parent Filter Bar
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFD),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter Dasha:',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                SizedBox(width: 8.w),
                _buildTimelineFilterChip('All Dashas', _selectedParentDasha == null, isDark, () {
                  setState(() => _selectedParentDasha = null);
                  _fetchChartData();
                }),
                ...List.generate(9, (idx) {
                  final dNum = idx + 1;
                  return _buildTimelineFilterChip('MD $dNum', _selectedParentDasha == dNum, isDark, () {
                    setState(() => _selectedParentDasha = dNum);
                    _fetchChartData();
                  });
                }),
              ],
            ),
          ),
        ),

        // Quick peek horizontal cards
        if (pratyantarCards.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 14.w, top: 10.h, bottom: 4.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subperiod Chart Models (${pratyantarCards.length}):',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 226.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              physics: const BouncingScrollPhysics(),
              itemCount: pratyantarCards.length,
              itemBuilder: (context, index) => _buildPratyantarCardModel(
                pratyantarCards[index],
                isDark,
                width: pratyantarCards.length == 1 ? (1.sw - 28.w) : 335.w,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],

        // Subperiods Table
        Expanded(
          child: subperiods.isEmpty
              ? _buildEmptyMessage('No Pratyantar periods found for the selected filter.', isDark)
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        dataRowMinHeight: 46.h,
                        dataRowMaxHeight: 54.h,
                        horizontalMargin: 12.w,
                        columnSpacing: 14.w,
                        border: TableBorder.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        columns: [
                          DataColumn(label: _buildColumnHeader('Subperiod / Lord', isDark)),
                          DataColumn(label: _buildColumnHeader('Start Date', isDark)),
                          DataColumn(label: _buildColumnHeader('End Date', isDark)),
                          DataColumn(label: _buildColumnHeader('Duration', isDark)),
                          DataColumn(label: _buildColumnHeader('Parent Dasha', isDark)),
                          DataColumn(label: _buildColumnHeader('Status', isDark)),
                        ],
                        rows: subperiods.map((sp) {
                          final isActive = sp['is_active'] == true;
                          final rowBg = isActive
                              ? (isDark
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                                  : const Color(0xFFEFF6FF))
                              : null;

                          return DataRow(
                            color: WidgetStateProperty.all(rowBg),
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildNumberBadge(sp['pratyantar_dasha'] ?? 0, isDark),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${sp['lord'] ?? ''} (${sp['vedic_name'] ?? ''})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  sp['start_date'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  sp['end_date'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${sp['duration_days']} Days',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'MD ${sp['dasha_number']} (${sp['dasha_lord']})',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(sp['status'] ?? 'Upcoming', isDark)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: PLANES ANALYSIS
  // ==========================================
  Widget _buildPlanesAnalysisTab(bool isDark) {
    final basicChart = _chartData?['basic_chart'] as Map<String, dynamic>? ?? {};
    final coreNumbers = basicChart['core_numbers'] as Map<String, dynamic>? ?? {};
    final mulank = coreNumbers['mulank'] as Map<String, dynamic>? ?? {};
    final supportive = coreNumbers['supportive'] as Map<String, dynamic>? ?? {};
    final destiny = coreNumbers['destiny'] as Map<String, dynamic>? ?? {};
    final nameNum = coreNumbers['name_number'] as Map<String, dynamic>? ?? {};
    final planes = (basicChart['planes_analysis'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final presentNums = (basicChart['present_numbers'] as List<dynamic>?)?.cast<int>() ?? [];
    final missingNums = (basicChart['missing_numbers'] as List<dynamic>?)?.cast<int>() ?? [];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      children: [
        // Core Numbers 4-card grid
        Row(
          children: [
            Expanded(
              child: _buildCoreMetricCard(
                title: 'Mulank',
                subtitle: 'Driver',
                number: mulank['number']?.toString() ?? '-',
                lord: mulank['planet'] ?? '',
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCoreMetricCard(
                title: 'Supportive',
                subtitle: 'Month Root',
                number: supportive['number']?.toString() ?? '-',
                lord: supportive['planet'] ?? '',
                color: const Color(0xFF0D9488),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildCoreMetricCard(
                title: 'Bhagyank',
                subtitle: 'Destiny',
                number: destiny['number']?.toString() ?? '-',
                lord: destiny['planet'] ?? '',
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCoreMetricCard(
                title: 'Namank',
                subtitle: 'Expression',
                number: nameNum['number']?.toString() ?? '-',
                lord: nameNum['planet'] ?? '',
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Present & Missing Summary Chips
        _buildPresentMissingSummary(presentNums, missingNums, isDark),
        SizedBox(height: 16.h),

        Text(
          'The 8 Planes of Alignment (Arrows of Pythagoras / Lo Shu):',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 8.h),

        ...planes.map((plane) {
          final isComplete = plane['is_complete'] == true;
          final pct = plane['completion_percentage'] as num? ?? 0;
          final accentColor = isComplete
              ? const Color(0xFF10B981)
              : (pct > 0 ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8));

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plane['name'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        plane['status'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  'Type: ${plane['type']} • Target Numbers: ${(plane['target_numbers'] as List).join('-')}',
                  style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 5.h,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  plane['summary'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // SHARED UI HELPERS
  // ==========================================
  Widget _buildCoreMetricCard({
    required String title,
    required String subtitle,
    required String number,
    required String lord,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$subtitle • $lord',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentMissingSummary(List<int> present, List<int> missing, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 15.sp, color: const Color(0xFF10B981)),
              SizedBox(width: 6.w),
              Text(
                'Present Numbers in Chart:',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 5.w,
            children: present
                .map((n) => Chip(
                      label: Text('Number $n',
                          style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.cancel_rounded, size: 15.sp, color: const Color(0xFFEF4444)),
              SizedBox(width: 6.w),
              Text(
                'Missing Numbers (Karmic Lessons):',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 5.w,
            children: missing
                .map((n) => Chip(
                      label: Text('Number $n',
                          style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showCellDetailsModal(Map<String, dynamic> cell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.45) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${cell['number']}',
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
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
                        '${cell['planet']} (${cell['vedic_name'] ?? ''})',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Frequency: ${cell['count']} time(s) • ${cell['strength_label'] ?? 'Natal'}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              cell['attribute'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              cell['theme'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Element: ${cell['element']}', style: GoogleFonts.inter(fontSize: 11.5.sp)),
                  Text('Direction: ${cell['direction']}', style: GoogleFonts.inter(fontSize: 11.5.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDateSafely(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    final clean = str.trim();
    try {
      return DateTime.parse(clean);
    } catch (_) {}
    try {
      return DateFormat('yyyy-MM-dd').parse(clean);
    } catch (_) {}
    try {
      return DateFormat('dd-MMM-yyyy').parse(clean);
    } catch (_) {}
    try {
      return DateFormat('dd/MM/yyyy').parse(clean);
    } catch (_) {}
    return null;
  }

  bool _isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDurationChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOriginChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineFilterChip(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildNumberBadge(int num, bool isDark) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Center(
        child: Text(
          '$num',
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final isActive = status.toLowerCase() == 'active';
    final isCompleted = status.toLowerCase() == 'completed';
    final Color color = isActive
        ? const Color(0xFF10B981)
        : (isCompleted
            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
            : const Color(0xFF2563EB));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyInlineCard(String msg, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF2563EB),
          ),
          SizedBox(height: 16.h),
          Text(
            'Computing 3x3 Charts & Timelines...',
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36.sp),
              SizedBox(height: 10.h),
              Text(
                'Chart Calculation Error',
                style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6.h),
              Text(
                _errorMessage ?? 'Unable to generate Chart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              SizedBox(height: 14.h),
              ElevatedButton.icon(
                onPressed: _fetchChartData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Calculation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String msg, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Text(
          msg,
          style: GoogleFonts.inter(
            fontSize: 12.5.sp,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
