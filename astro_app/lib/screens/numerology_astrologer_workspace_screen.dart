import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import 'numerology_chart_workspace_screen.dart';

class NumerologyAstrologerWorkspaceScreen extends StatefulWidget {
  final String name;
  final String dob;
  final String system;

  const NumerologyAstrologerWorkspaceScreen({
    super.key,
    required this.name,
    required this.dob,
    this.system = 'pythagorean',
  });

  @override
  State<NumerologyAstrologerWorkspaceScreen> createState() =>
      _NumerologyAstrologerWorkspaceScreenState();
}

class _NumerologyAstrologerWorkspaceScreenState
    extends State<NumerologyAstrologerWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _workspaceData;

  late String _currentName;
  late String _currentDob;
  late String _currentSystem;

  // Selected filters for user interactivity
  int? _selectedParentDasha; // For Antardasha tab filtering
  int? _selectedAntardashaYear; // For Paryantardasha tab
  List<Map<String, dynamic>>? _customParyantardashas;
  bool _isLoadingParyantardasha = false;

  DateTime _selectedDate = DateTime.now();
  int _dailyDaysSpan = 14;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentName = widget.name.trim().isNotEmpty ? widget.name.trim() : 'Seeker';
    _currentDob = widget.dob.trim();
    _currentSystem = widget.system;
    _fetchWorkspaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkspaceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getAstrologerWorkspace(
        name: _currentName,
        dateOfBirth: _currentDob,
        system: _currentSystem,
        referenceDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      if (mounted) {
        setState(() {
          _workspaceData = res;
          _isLoading = false;
          // Set default selected Antardasha year from active summary
          final activeAd = res['active_summary']?['antardasha'];
          if (activeAd != null && activeAd['cycle_year'] != null) {
            _selectedAntardashaYear = activeAd['cycle_year'];
          }
          _customParyantardashas = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadParyantardashasForYear(int year) async {
    setState(() {
      _selectedAntardashaYear = year;
      _isLoadingParyantardasha = true;
    });

    try {
      final pds = await AstroApiService.getParyantardashasForYear(
        dateOfBirth: _currentDob,
        year: year,
        referenceDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      if (mounted) {
        setState(() {
          _customParyantardashas = pds;
          _isLoadingParyantardasha = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingParyantardasha = false);
      }
    }
  }

  // --- Interactive Profile Selection Modal ---
  void _showEditProfileModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _currentName);
    final dobController = TextEditingController(text: _currentDob);
    String selectedSystem = _currentSystem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change Profile Details',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Recalculates all Dasha & timelines instantly',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.r),
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded,
                                  size: 18.sp,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Full Name
                    Text(
                      'FULL NAME',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                              size: 20.sp),
                          hintText: 'e.g. Steve Jobs',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Date of Birth
                    Text(
                      'DATE OF BIRTH',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Material(
                      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () async {
                          DateTime initialDate = DateTime(1995, 5, 15);
                          try {
                            if (dobController.text.isNotEmpty) {
                              initialDate = DateFormat('yyyy-MM-dd').parse(dobController.text);
                            }
                          } catch (_) {}

                          final picked = await showDatePicker(
                            context: sheetContext,
                            useRootNavigator: true,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (picked != null) {
                            setModalState(() {
                              dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                                color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  size: 20.sp),
                              SizedBox(width: 12.w),
                              Text(
                                dobController.text.isNotEmpty
                                    ? dobController.text
                                    : 'Select Date of Birth',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: dobController.text.isNotEmpty
                                      ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down_rounded,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  size: 24.sp),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Numerology System
                    Text(
                      'NUMEROLOGY SYSTEM',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark ? const Color(0xFF131D36) : Colors.white,
                          value: selectedSystem,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                              size: 22.sp),
                          items: [
                            DropdownMenuItem(
                              value: 'pythagorean',
                              child: Text('Pythagorean Numerology (Modern)',
                                  style: GoogleFonts.inter(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B))),
                            ),
                            DropdownMenuItem(
                              value: 'chaldean',
                              child: Text('Chaldean Numerology (Ancient Vedic)',
                                  style: GoogleFonts.inter(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B))),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedSystem = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // Update & Recalculate Button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () async {
                          final name = nameController.text.trim().isNotEmpty
                              ? nameController.text.trim()
                              : 'Seeker';
                          final dob = dobController.text.trim().isNotEmpty
                              ? dobController.text.trim()
                              : '1995-05-15';

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('numerology_user_name', name);
                          await prefs.setString('numerology_user_dob', dob);
                          await prefs.setString('numerology_user_system', selectedSystem);

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          if (mounted) {
                            setState(() {
                              _currentName = name;
                              _currentDob = dob;
                              _currentSystem = selectedSystem;
                            });
                            _fetchWorkspaceData();
                          }
                        },
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
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Update & Recalculate',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5.sp,
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFD);

    return Scaffold(
      backgroundColor: bgCol,
      bottomNavigationBar: null, // Isolated workspace: no bottom nav
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(116.h),
        child: _buildHeader(isDark),
      ),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : _buildTabViews(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h,
        left: 16.w,
        right: 16.w,
        bottom: 8.h,
      ),
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
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
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
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Astrologer',
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            'PRO',
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
                    SizedBox(height: 2.h),
                    // Tappable profile details selector in header
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6.r),
                        onTap: _showEditProfileModal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '$_currentName • $_currentDob • ${_currentSystem == 'chaldean' ? 'Chaldean' : 'Pythagorean'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.edit_rounded,
                              size: 12.sp,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Compact Header Action Buttons (Cannot Overflow)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NumerologyChartWorkspaceScreen(
                              name: _currentName,
                              dob: _currentDob,
                              system: _currentSystem,
                              initialDurationYears: 10,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 17.sp,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
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
                          size: 17.sp,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  PopupMenuButton<String>(
                    tooltip: 'More Options',
                    padding: EdgeInsets.zero,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    icon: Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18.sp,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                      ),
                    ),
                    onSelected: (val) async {
                      if (val == 'date') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          _fetchWorkspaceData();
                        }
                      } else if (val == 'refresh') {
                        _fetchWorkspaceData();
                      } else if (val == 'profile') {
                        _showEditProfileModal();
                      } else if (val == 'chart') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NumerologyChartWorkspaceScreen(
                              name: _currentName,
                              dob: _currentDob,
                              system: _currentSystem,
                              initialDurationYears: 10,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'chart',
                        child: Row(
                          children: [
                            Icon(Icons.grid_view_rounded, size: 16.sp, color: const Color(0xFF10B981)),
                            SizedBox(width: 10.w),
                            Text('Open Numerology Chart',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded, size: 16.sp, color: const Color(0xFF2563EB)),
                            SizedBox(width: 10.w),
                            Text('Change Profile Details',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                size: 16.sp, color: const Color(0xFF10B981)),
                            SizedBox(width: 10.w),
                            Text('Inspect As-Of Date',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 16.sp, color: const Color(0xFF64748B)),
                            SizedBox(width: 10.w),
                            Text('Refresh Calculations',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Scrollable Tab Bar
          SizedBox(
            height: 38.h,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.symmetric(horizontal: 6.w),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTabPill('Basic Info', 0, isDark),
                _buildTabPill('Dasha', 1, isDark),
                _buildTabPill('Antardasha', 2, isDark),
                _buildTabPill('Paryantardasha', 3, isDark),
                _buildTabPill('Daily Dasha', 4, isDark),
              ],
            ),
          ),
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
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          ),
          SizedBox(height: 16.h),
          Text(
            'Computing Numerology Dasha Matrix...',
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Evaluating multi-tier cycles deterministically from DOB',
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40.sp),
              SizedBox(height: 12.h),
              Text(
                'Calculation Error',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _errorMessage ?? 'Unable to compute dasha data.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _fetchWorkspaceData,
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

  Widget _buildTabViews(bool isDark) {
    final basicInfo = _workspaceData?['basic_info'] as Map<String, dynamic>? ?? {};
    final mahadashas = (_workspaceData?['mahadashas'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final antardashas = (_workspaceData?['antardashas'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final paryantardashas = _customParyantardashas ??
        ((_workspaceData?['paryantardashas'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            []);
    final dailyDashas = (_workspaceData?['daily_dashas'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBasicInfoTab(basicInfo, isDark),
        _buildDashaTab(mahadashas, isDark),
        _buildAntardashaTab(antardashas, mahadashas, isDark),
        _buildParyantardashaTab(paryantardashas, antardashas, isDark),
        _buildDailyDashaTab(dailyDashas, isDark),
      ],
    );
  }

  // ==========================================
  // TAB 1: BASIC INFO
  // ==========================================
  Widget _buildBasicInfoTab(Map<String, dynamic> basicInfo, bool isDark) {
    final basic = basicInfo['basic_number'] as Map<String, dynamic>? ?? {};
    final supportive = basicInfo['supportive_number'] as Map<String, dynamic>? ?? {};
    final destiny = basicInfo['destiny_number'] as Map<String, dynamic>? ?? {};
    final lucky = basicInfo['lucky_attributes'] as Map<String, dynamic>? ?? {};
    final transparency = basicInfo['transparency'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Three Core Number Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildCoreNumberCard(
                  title: 'Basic Number',
                  subtitle: 'Mulank',
                  number: basic['number']?.toString() ?? '-',
                  lord: basic['planet']?.toString() ?? '',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildCoreNumberCard(
                  title: 'Supportive',
                  subtitle: 'Companion',
                  number: supportive['number']?.toString() ?? '-',
                  lord: supportive['planet']?.toString() ?? '',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildCoreNumberCard(
                  title: 'Destiny',
                  subtitle: 'Bhagyank',
                  number: destiny['number']?.toString() ?? '-',
                  lord: destiny['planet']?.toString() ?? '',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Profile & Planetary Attributes Card (Interactive values!)
          _buildCardContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildCardHeader(
                        icon: Icons.person_pin_rounded,
                        title: 'Profile & Numerical Blueprint',
                        subtitle: basicInfo['system_label'] ?? 'Vedic & Pythagorean Standards',
                        isDark: isDark,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showEditProfileModal,
                      icon: Icon(Icons.edit_rounded, size: 14.sp, color: const Color(0xFF2563EB)),
                      label: Text(
                        'Change',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        backgroundColor:
                            isDark ? const Color(0xFF1E2E56) : const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _buildInteractiveInfoRow(
                  label: 'Full Name',
                  value: basicInfo['name']?.toString() ?? _currentName,
                  isDark: isDark,
                  onTap: _showEditProfileModal,
                ),
                _buildInteractiveInfoRow(
                  label: 'Date of Birth',
                  value: basicInfo['dob']?.toString() ?? _currentDob,
                  isDark: isDark,
                  onTap: _showEditProfileModal,
                ),
                _buildInteractiveInfoRow(
                  label: 'Numerology Method',
                  value: basicInfo['system_label']?.toString() ?? _currentSystem,
                  isDark: isDark,
                  onTap: _showEditProfileModal,
                ),
                _buildInfoRow('Basic Number (Mulank)', '${basic['number']} (${basic['planet']})', isDark),
                _buildInfoRow('Supportive Number', '${supportive['number']} (${supportive['planet']})', isDark),
                _buildInfoRow('Destiny Number (Bhagyank)', '${destiny['number']} (${destiny['planet']})', isDark),
                _buildInfoRow(
                  'Harmonic Friendly Numbers',
                  (lucky['lucky_numbers'] as List<dynamic>?)?.join(', ') ?? '-',
                  isDark,
                ),
                _buildInfoRow('Lucky Colour', lucky['lucky_color']?.toString() ?? '-', isDark),
                _buildInfoRow('Lucky Direction', lucky['lucky_direction']?.toString() ?? '-', isDark),
                _buildInfoRow('Lucky Gemstone', lucky['lucky_gemstone']?.toString() ?? '-', isDark),
                _buildInfoRow(
                  'Favorable Days',
                  (lucky['favorable_days'] as List<dynamic>?)?.join(', ') ?? '-',
                  isDark,
                  isLast: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Calculation Transparency Expander
          _buildCardContainer(
            isDark: isDark,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(top: 8.h),
                leading: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.calculate_rounded, size: 18.sp, color: const Color(0xFF2563EB)),
                ),
                title: Text(
                  'Calculation Transparency & Steps',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Auditable formulas and intermediate reductions',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                children: [
                  _buildFormulaStepBox(
                    title: 'Basic Number (Day Reduction)',
                    formula: transparency['basic_number_formula']?.toString() ?? '-',
                    isDark: isDark,
                  ),
                  SizedBox(height: 8.h),
                  _buildFormulaStepBox(
                    title: 'Supportive Number (Month Reduction)',
                    formula: transparency['supportive_number_formula']?.toString() ?? '-',
                    isDark: isDark,
                  ),
                  SizedBox(height: 8.h),
                  _buildFormulaStepBox(
                    title: 'Destiny Number (Full Date Reduction)',
                    formula: transparency['destiny_number_formula']?.toString() ?? '-',
                    isDark: isDark,
                  ),
                  SizedBox(height: 8.h),
                  _buildFormulaStepBox(
                    title: 'Name Vibration (Namank)',
                    formula: transparency['name_number_formula']?.toString() ?? '-',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildCoreNumberCard({
    required String title,
    required String subtitle,
    required String number,
    required String lord,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            lord,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9.5.sp,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: DASHA (MAHADASHA TIMELINE)
  // ==========================================
  Widget _buildDashaTab(List<Map<String, dynamic>> mahadashas, bool isDark) {
    if (mahadashas.isEmpty) {
      return _buildEmptyMessage('No Mahadasha periods generated.', isDark);
    }

    return Column(
      children: [
        _buildSectionHeaderBar(
          title: 'Mahadasha Lifetime Progression',
          description: 'Tap any period to inspect its Antardasha subdivisions',
          isDark: isDark,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  dataRowMinHeight: 46.h,
                  dataRowMaxHeight: 52.h,
                  horizontalMargin: 12.w,
                  columnSpacing: 18.w,
                  border: TableBorder.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  columns: [
                    DataColumn(label: _buildColumnHeader('From Date', isDark)),
                    DataColumn(label: _buildColumnHeader('To Date', isDark)),
                    DataColumn(label: _buildColumnHeader('Dasha / Lord', isDark)),
                    DataColumn(label: _buildColumnHeader('Span (Age)', isDark)),
                    DataColumn(label: _buildColumnHeader('Status', isDark)),
                  ],
                  rows: mahadashas.map((m) {
                    final isActive = m['is_active'] == true;
                    final rowBg = isActive
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                            : const Color(0xFFEFF6FF))
                        : null;

                    return DataRow(
                      color: WidgetStateProperty.all(rowBg),
                      onSelectChanged: (_) {
                        // User can tap row to select this parent dasha and inspect its subdivisions
                        setState(() {
                          _selectedParentDasha = m['dasha_number'];
                        });
                        _tabController.animateTo(2); // Jump to Antardasha tab
                      },
                      cells: [
                        DataCell(
                          Text(
                            m['start_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            m['end_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberBadge(m['dasha_number'] ?? 0, isDark),
                              SizedBox(width: 8.w),
                              Text(
                                '${m['lord']} (${m['vedic_name'] ?? ''})',
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
                            '${m['duration_years']} Yrs (${m['age_start']}-${m['age_end']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(_buildStatusBadge(m['status']?.toString() ?? 'Upcoming', isDark)),
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
  // TAB 3: ANTARDASHA (ANNUAL SUB-PERIOD)
  // ==========================================
  Widget _buildAntardashaTab(
    List<Map<String, dynamic>> antardashas,
    List<Map<String, dynamic>> mahadashas,
    bool isDark,
  ) {
    if (antardashas.isEmpty) {
      return _buildEmptyMessage('No Antardasha data available.', isDark);
    }

    // Filter by selected parent Dasha if user tapped one
    final filteredAds = _selectedParentDasha == null
        ? antardashas
        : antardashas.where((ad) => ad['parent_dasha'] == _selectedParentDasha).toList();

    return Column(
      children: [
        _buildSectionHeaderBar(
          title: 'Annual Antardasha Schedule',
          description: 'Filter by Parent Dasha or tap row to inspect 9 Paryantardasha micro-periods',
          isDark: isDark,
        ),
        // Interactive Parent Dasha Filter Selector
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Row(
            children: [
              Text(
                'Parent Dasha:',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(
                  height: 32.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        label: 'All Periods',
                        isSelected: _selectedParentDasha == null,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedParentDasha = null),
                      ),
                      ...mahadashas.map((m) {
                        final dNum = m['dasha_number'];
                        final isSel = _selectedParentDasha == dNum;
                        return _buildFilterChip(
                          label: 'MD $dNum (${m['lord']})',
                          isSelected: isSel,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedParentDasha = dNum),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  dataRowMinHeight: 48.h,
                  dataRowMaxHeight: 54.h,
                  horizontalMargin: 12.w,
                  columnSpacing: 16.w,
                  border: TableBorder.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  columns: [
                    DataColumn(label: _buildColumnHeader('From Date', isDark)),
                    DataColumn(label: _buildColumnHeader('To Date', isDark)),
                    DataColumn(label: _buildColumnHeader('Parent Dasha', isDark)),
                    DataColumn(label: _buildColumnHeader('Antardasha / Lord', isDark)),
                    DataColumn(label: _buildColumnHeader('Formula Breakdown', isDark)),
                    DataColumn(label: _buildColumnHeader('Status', isDark)),
                  ],
                  rows: filteredAds.map((ad) {
                    final isActive = ad['is_active'] == true;
                    final rowBg = isActive
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                            : const Color(0xFFEFF6FF))
                        : null;

                    return DataRow(
                      color: WidgetStateProperty.all(rowBg),
                      onSelectChanged: (_) {
                        // Tapping selects this Antardasha and switches to Paryantardasha tab
                        final yr = ad['cycle_year'] as int?;
                        if (yr != null) {
                          _loadParyantardashasForYear(yr);
                        }
                        _tabController.animateTo(3); // Jump to Paryantardasha tab
                      },
                      cells: [
                        DataCell(
                          Text(
                            ad['start_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            ad['end_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'MD ${ad['parent_dasha']} (${ad['parent_lord']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberBadge(ad['antardasha_number'] ?? 0, isDark),
                              SizedBox(width: 8.w),
                              Text(
                                '${ad['lord']} (${ad['vedic_name'] ?? ''})',
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
                            ad['calculation_steps'] ?? '-',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 10.5.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(_buildStatusBadge(ad['status']?.toString() ?? 'Upcoming', isDark)),
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
  // TAB 4: PARYANTARDASHA (PRATANTARDASHA)
  // ==========================================
  Widget _buildParyantardashaTab(
    List<Map<String, dynamic>> paryantardashas,
    List<Map<String, dynamic>> antardashas,
    bool isDark,
  ) {
    if (paryantardashas.isEmpty) {
      return _buildEmptyMessage('No Paryantardasha subdivisions available.', isDark);
    }

    return Column(
      children: [
        _buildSectionHeaderBar(
          title: 'Paryantardasha Subdivisions',
          description: '9 micro-phases dividing selected annual Antardasha into standard 365 days',
          isDark: isDark,
        ),
        // Interactive Antardasha Cycle Selector
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Row(
            children: [
              Text(
                'Antardasha Cycle:',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(
                  height: 32.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: antardashas.map((ad) {
                      final yr = ad['cycle_year'] as int;
                      final isSel = _selectedAntardashaYear == yr;
                      final isActive = ad['is_active'] == true;
                      return _buildFilterChip(
                        label: '$yr (AD ${ad['antardasha_number']} ${ad['lord']})${isActive ? ' • Active' : ''}',
                        isSelected: isSel,
                        isDark: isDark,
                        onTap: () => _loadParyantardashasForYear(yr),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingParyantardasha)
          LinearProgressIndicator(
            color: const Color(0xFF2563EB),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  dataRowMinHeight: 48.h,
                  dataRowMaxHeight: 54.h,
                  horizontalMargin: 12.w,
                  columnSpacing: 16.w,
                  border: TableBorder.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  columns: [
                    DataColumn(label: _buildColumnHeader('From Date', isDark)),
                    DataColumn(label: _buildColumnHeader('To Date', isDark)),
                    DataColumn(label: _buildColumnHeader('Parent Dasha', isDark)),
                    DataColumn(label: _buildColumnHeader('Antardasha', isDark)),
                    DataColumn(label: _buildColumnHeader('Paryantardasha / Lord', isDark)),
                    DataColumn(label: _buildColumnHeader('Days', isDark)),
                    DataColumn(label: _buildColumnHeader('Status', isDark)),
                  ],
                  rows: paryantardashas.map((pd) {
                    final isActive = pd['is_active'] == true;
                    final rowBg = isActive
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                            : const Color(0xFFEFF6FF))
                        : null;

                    return DataRow(
                      color: WidgetStateProperty.all(rowBg),
                      cells: [
                        DataCell(
                          Text(
                            pd['start_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            pd['end_date'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'MD ${pd['parent_dasha']} (${pd['parent_lord']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'AD ${pd['antardasha']} (${pd['antardasha_lord']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberBadge(pd['paryantardasha_number'] ?? 0, isDark),
                              SizedBox(width: 8.w),
                              Text(
                                '${pd['lord']} (${pd['vedic_name'] ?? ''})',
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
                            '${pd['duration_days']} d',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(_buildStatusBadge(pd['status']?.toString() ?? 'Upcoming', isDark)),
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
  // TAB 5: DAILY DASHA
  // ==========================================
  Widget _buildDailyDashaTab(List<Map<String, dynamic>> dailyDashas, bool isDark) {
    if (dailyDashas.isEmpty) {
      return _buildEmptyMessage('No Daily Dasha schedule computed.', isDark);
    }

    return Column(
      children: [
        _buildSectionHeaderBar(
          title: 'Daily Dasha Schedule',
          description: 'Formula: (Active Pratantardasha + Weekday Value) mod 9',
          isDark: isDark,
        ),
        // Interactive Span Selector (7, 14, 30 days) & Target Date Picker
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Window:',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                SizedBox(width: 8.w),
                _buildFilterChip(
                  label: '7 Days',
                  isSelected: _dailyDaysSpan == 7,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _dailyDaysSpan = 7);
                    _fetchWorkspaceData();
                  },
                ),
                _buildFilterChip(
                  label: '14 Days',
                  isSelected: _dailyDaysSpan == 14,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _dailyDaysSpan = 14);
                    _fetchWorkspaceData();
                  },
                ),
                _buildFilterChip(
                  label: '30 Days',
                  isSelected: _dailyDaysSpan == 30,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _dailyDaysSpan = 30);
                    _fetchWorkspaceData();
                  },
                ),
                SizedBox(width: 6.w),
                // Date picker chip
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _fetchWorkspaceData();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 14.sp, color: const Color(0xFF2563EB)),
                          SizedBox(width: 4.w),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  dataRowMinHeight: 52.h,
                  dataRowMaxHeight: 62.h,
                  horizontalMargin: 12.w,
                  columnSpacing: 16.w,
                  border: TableBorder.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  columns: [
                    DataColumn(label: _buildColumnHeader('Date / Day', isDark)),
                    DataColumn(label: _buildColumnHeader('Weekday Ruler', isDark)),
                    DataColumn(label: _buildColumnHeader('Active PD', isDark)),
                    DataColumn(label: _buildColumnHeader('Daily Dasha / Lord', isDark)),
                    DataColumn(label: _buildColumnHeader('Formula', isDark)),
                    DataColumn(label: _buildColumnHeader('Energy & Key Themes', isDark)),
                  ],
                  rows: dailyDashas.map((dd) {
                    final isToday = dd['is_today'] == true;
                    final isSel = dd['is_selected'] == true;
                    final rowBg = isToday
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                            : const Color(0xFFEFF6FF))
                        : (isSel
                            ? (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9))
                            : null);

                    return DataRow(
                      color: WidgetStateProperty.all(rowBg),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dd['formatted_date'] ?? dd['date'] ?? '-',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    dd['weekday'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5.sp,
                                      color: isToday
                                          ? const Color(0xFF3B82F6)
                                          : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (isToday) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${dd['weekday_lord']} (${dd['weekday_value']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'PD ${dd['active_paryantardasha']} (${dd['active_paryantardasha_lord']})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberBadge(dd['daily_dasha_number'] ?? 0, isDark),
                              SizedBox(width: 8.w),
                              Text(
                                '${dd['lord']} (${dd['vedic_name'] ?? ''})',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            dd['calculation_formula'] ?? '-',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 10.5.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 280.w,
                            child: Text(
                              dd['explanation'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
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
  // SHARED UI HELPERS
  // ==========================================
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderBar({
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildNumberBadge(int num, bool isDark) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          '$num',
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
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

    final Color badgeColor = isActive
        ? const Color(0xFF10B981)
        : isCompleted
            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
            : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w800,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child, required bool isDark}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveInfoRow({
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.edit_rounded, size: 12.sp, color: const Color(0xFF2563EB)),
                ],
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaStepBox({
    required String title,
    required String formula,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            formula,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_view_month_rounded,
                size: 40.sp,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
