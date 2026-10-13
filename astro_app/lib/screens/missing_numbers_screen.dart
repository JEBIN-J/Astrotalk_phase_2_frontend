import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class MissingNumbersScreen extends StatefulWidget {
  final String? initialBirthName;
  final Map<String, dynamic>? initialReportData;
  final int initialTabIndex;

  const MissingNumbersScreen({
    super.key,
    this.initialBirthName,
    this.initialReportData,
    this.initialTabIndex = 0,
  });

  @override
  State<MissingNumbersScreen> createState() => _MissingNumbersScreenState();
}

class _MissingNumbersScreenState extends State<MissingNumbersScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  int _selectedTabIndex = 0;
  int? _selectedNumberDetail; // For focusing on a specific missing number

  final List<String> _tabs = [
    'Overview',
    'Frequency Grid',
    'Karmic Lessons',
    'Present Numbers',
    'Calculation Trace',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;

    if (widget.initialReportData != null) {
      _reportData = widget.initialReportData;
      final name = widget.initialReportData!['birth_name'] ?? widget.initialBirthName ?? '';
      _nameController.text = name;
    } else if (widget.initialBirthName != null && widget.initialBirthName!.trim().isNotEmpty) {
      _nameController.text = widget.initialBirthName!.trim();
      _fetchReport();
    } else {
      _loadSavedUserName();
    }
  }

  Future<void> _loadSavedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('numerology_user_name') ?? '';
    if (savedName.trim().isNotEmpty && mounted) {
      _nameController.text = savedName.trim();
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
        _errorMessage = 'Full birth name is required for Missing Numbers calculation.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getMissingNumbersReport(
        birthName: name,
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
          final missingList = (res['missing_numbers'] as List?)?.map((e) => e as int).toList() ?? [];
          if (missingList.isNotEmpty && _selectedNumberDetail == null) {
            _selectedNumberDetail = missingList.first;
          }
        });

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
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.edit_rounded, color: const Color(0xFFEA580C), size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Change Birth Name',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
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
              'Enter your full name as recorded on your birth certificate for authoritative Pythagorean frequency analysis.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.4),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: editController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'e.g. Mary Ann Jones',
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFFFFBFB),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFFED7AA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: const Color(0xFFEA580C), width: 1.5.w),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _nameController.text = newName;
                });
                _fetchReport();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
            ),
            child: Text(
              'Recalculate',
              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCFB),
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
                    border: Border.all(color: const Color(0xFFFED7AA), width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1E293B), size: 16.sp),
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
              'Missing Numbers',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'Karmic Lessons & Frequency Matrix',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEA580C).withValues(alpha: 0.9),
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
                        border: Border.all(color: const Color(0xFFFED7AA), width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: const Color(0xFFEA580C), size: 19.sp),
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Analyzing 1–9 Letter Frequencies...',
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Calculating zero-count Karmic Lessons from full birth name',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFFED7AA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.06),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 32.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                'Calculation Interrupted',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _errorMessage ?? 'Unable to compute Missing Numbers at this time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: _fetchReport,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
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

  Widget _buildNameInputCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.border_clear_rounded, color: Colors.white, size: 24.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birth Name Required',
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Authoritative Pythagorean Frequency Analysis',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: const Color(0xFFEA580C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Text(
                  'Missing Numbers (Karmic Lessons) reflect the vibrations absent from your full birth name. Enter your complete birth certificate name to calculate your exact 1–9 frequency table and zero-count numbers.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Birth Name',
                    hintText: 'e.g. Mary Ann Jones',
                    labelStyle: GoogleFonts.inter(color: const Color(0xFFEA580C)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFFED7AA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(color: const Color(0xFFEA580C), width: 2.w),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _fetchReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Calculate Missing Numbers',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
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
  // LUXURY USER HEADER BAR (Peach / Warm Amber Theme)
  // =========================================================================
  Widget _buildUserHeaderBar() {
    final birthName = _reportData?['birth_name'] ?? _nameController.text;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF7ED), // Soft Peach
            Color(0xFFFFEDD5), // Warm Amber Glow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFFED7AA),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.07),
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
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.border_clear_rounded,
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
                        border: Border.all(color: const Color(0xFFFED7AA), width: 0.8.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 9.5.sp,
                            color: const Color(0xFFEA580C),
                          ),
                          SizedBox(width: 3.5.w),
                          Text(
                            'ANALYZED NAME',
                            style: GoogleFonts.inter(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEA580C),
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
                    color: const Color(0xFF1E293B),
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
                  border: Border.all(color: const Color(0xFFFED7AA), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.08),
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
                      color: const Color(0xFFEA580C),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Change',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA580C),
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
  // TAB NAVIGATION (Warm Peach & Amber Palette)
  // =========================================================================
  Widget _buildTabNavigation() {
    return Container(
      height: 48.h,
      color: const Color(0xFFFDFCFB),
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
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFFED7AA),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF9A3412),
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
        return _buildFrequencyGridTab();
      case 2:
        return _buildKarmicLessonsTab();
      case 3:
        return _buildPresentNumbersTab();
      case 4:
        return _buildTraceTab();
      default:
        return _buildOverviewTab();
    }
  }

  // =========================================================================
  // TAB 1: OVERVIEW
  // =========================================================================
  Widget _buildOverviewTab() {
    final missingList = (_reportData?['missing_numbers'] as List?)?.map((e) => e as int).toList() ?? [];
    final presentList = (_reportData?['present_numbers'] as List?)?.map((e) => e as int).toList() ?? [];
    final freqMap = _getFrequencyMap();
    final hasNoMissing = _reportData?['has_no_missing_numbers'] == true || missingList.isEmpty;
    final hiddenPassion = _reportData?['hidden_passion'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Hero Card
        _buildSummaryHeroCard(missingList, presentList, hasNoMissing),

        SizedBox(height: 16.h),

        // Quick 3x3 Frequency Matrix Preview
        _buildMiniFrequencyGrid(freqMap, missingList),

        SizedBox(height: 16.h),

        // Hidden Passion Callout (if available)
        if (hiddenPassion != null && (hiddenPassion['numbers'] as List?)?.isNotEmpty == true)
          _buildHiddenPassionBanner(hiddenPassion),

        SizedBox(height: 16.h),

        // Missing Numbers Quick Cards or Celebratory Full Spectrum Card
        if (hasNoMissing)
          _buildFullHarmonicSpectrumCard()
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KARMIC LESSONS (${missingList.length})',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 2),
                child: Text(
                  'View All In-Depth >',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...missingList.map((n) => _buildMissingNumberPreviewCard(n)),
        ],
      ],
    );
  }

  Widget _buildSummaryHeroCard(List<int> missingList, List<int> presentList, bool hasNoMissing) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 14.sp),
                    SizedBox(width: 5.w),
                    Text(
                      hasNoMissing ? 'Full Spectrum' : 'Karmic Blueprint',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Pythagorean 1–9',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            hasNoMissing
                ? 'Complete Numeric Harmony'
                : '${missingList.length} Missing Number${missingList.length > 1 ? 's' : ''} Identified',
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            hasNoMissing
                ? 'Your birth name contains every vibration from 1 to 9. You possess broad versatility across all energetic frequencies.'
                : 'Numbers with exactly zero occurrences in your birth name represent Karmic Lessons—specific soul qualities meant for conscious cultivation.',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              if (!hasNoMissing)
                ...missingList.map((n) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_circle_outline_rounded, size: 12.sp, color: const Color(0xFFEA580C)),
                          SizedBox(width: 4.w),
                          Text(
                            'Missing $n',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    )),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${presentList.length} Present Vibrations',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFrequencyGrid(Map<int, int> freqMap, List<int> missingList) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
            blurRadius: 12,
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
              Text(
                '1–9 FREQUENCY MATRIX',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: Text(
                  'Full Matrix Grid >',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, idx) {
              final num = idx + 1;
              final count = freqMap[num] ?? 0;
              final isMissing = count == 0;

              return InkWell(
                onTap: () {
                  if (isMissing) {
                    setState(() {
                      _selectedNumberDetail = num;
                      _selectedTabIndex = 2; // Karmic Lessons tab
                    });
                  } else {
                    setState(() {
                      _selectedTabIndex = 3; // Present Numbers tab
                    });
                  }
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isMissing ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isMissing ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
                      width: isMissing ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$num',
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: isMissing ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '($count)',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isMissing ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isMissing ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isMissing ? 'MISSING' : '$count occurrence${count == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isMissing ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenPassionBanner(Map<String, dynamic> hiddenPassion) {
    final nums = (hiddenPassion['numbers'] as List?)?.join(', ') ?? '';
    final maxFreq = hiddenPassion['max_frequency'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.whatshot_rounded, color: Colors.white, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIDDEN PASSION: NUMBER $nums',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Most frequent vibration in your birth name with $maxFreq occurrence${maxFreq == 1 ? '' : 's'}.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullHarmonicSpectrumCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: const Color(0xFFEA580C), size: 36.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            'Complete Numeric Spectrum',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Congratulations! Your full birth name incorporates every single vibration from 1 through 9. Under classical Pythagorean numerology traditions, no major Karmic Lessons are marked as completely absent.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingNumberPreviewCard(int number) {
    final interp = _getInterpretation(number);
    final title = interp?['number_title'] ?? 'Karmic Lesson $number';
    final theme = interp?['core_theme'] ?? 'Conscious cultivation of vibration $number.';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
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
                width: 36.w,
                height: 36.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '0 Occurrences in Birth Name',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFFEA580C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNumberDetail = number;
                    _selectedTabIndex = 2; // Karmic Lessons tab
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFFEA580C), size: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            theme,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: FULL FREQUENCY MATRIX GRID
  // =========================================================================
  Widget _buildFrequencyGridTab() {
    final freqMap = _getFrequencyMap();
    final totalLetters = _reportData?['total_letters_evaluated'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: const Color(0xFFEA580C), size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Frequency Matrix counts how many times each Pythagorean number (1–9) appears in your full birth name ($totalLetters total letters evaluated).',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF7C2D12), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        ...List.generate(9, (idx) {
          final num = idx + 1;
          final count = freqMap[num] ?? 0;
          final isMissing = count == 0;
          final pct = totalLetters > 0 ? (count / totalLetters * 100).toStringAsFixed(1) : '0';

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isMissing ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
                width: isMissing ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isMissing ? const Color(0xFFEA580C).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: isMissing ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      '$num',
                      style: GoogleFonts.outfit(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: isMissing ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getNumberTitleQuick(num),
                              style: GoogleFonts.outfit(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isMissing ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isMissing ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              isMissing ? 'ZERO (MISSING)' : '$count occurrence${count == 1 ? '' : 's'} ($pct%)',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: isMissing ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getLettersForNumber(num),
                        style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
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
  // TAB 3: KARMIC LESSONS (IN-DEPTH INTERPRETATIONS)
  // =========================================================================
  Widget _buildKarmicLessonsTab() {
    final missingList = (_reportData?['missing_numbers'] as List?)?.map((e) => e as int).toList() ?? [];

    if (missingList.isEmpty) {
      return _buildFullHarmonicSpectrumCard();
    }

    final activeNum = _selectedNumberDetail != null && missingList.contains(_selectedNumberDetail)
        ? _selectedNumberDetail!
        : missingList.first;
    final interp = _getInterpretation(activeNum);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Number Selector Pills
        if (missingList.length > 1) ...[
          Container(
            height: 44.h,
            margin: EdgeInsets.only(bottom: 14.h),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: missingList.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, idx) {
                final n = missingList[idx];
                final isSelected = n == activeNum;

                return InkWell(
                  onTap: () => setState(() => _selectedNumberDetail = n),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEA580C) : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFFED7AA),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Missing Lesson $n',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        if (interp != null) ...[
          _buildDetailedInterpretationView(interp, activeNum),
        ] else ...[
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Text(
              'Interpretation for Missing Number $activeNum is being verified.',
              style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedInterpretationView(Map<String, dynamic> interp, int number) {
    final title = interp['number_title'] ?? 'Karmic Lesson $number';
    final theme = interp['core_theme'] ?? '';
    final overview = interp['overview'] ?? '';
    final challenges = (interp['potential_challenges'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final learnings = (interp['learning_themes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final guidance = interp['practical_guidance'] ?? '';
    final relationships = interp['relationships_communication'] ?? '';
    final work = interp['work_daily_life'] ?? '';
    final questions = (interp['reflection_questions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Header Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Karmic Lesson & Spiritual Curriculum',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                theme,
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Section A: Overview & Meaning
        _buildSectionCard(
          icon: Icons.lightbulb_outline_rounded,
          heading: 'Overview & Soul Meaning',
          content: overview,
          badgeColor: const Color(0xFFEA580C),
        ),

        SizedBox(height: 14.h),

        // Section B: Learning Themes
        if (learnings.isNotEmpty)
          _buildBulletListCard(
            icon: Icons.school_rounded,
            heading: 'Potential Learning Themes',
            items: learnings,
            badgeColor: const Color(0xFFD97706),
          ),

        SizedBox(height: 14.h),

        // Section C: Potential Challenges
        if (challenges.isNotEmpty)
          _buildBulletListCard(
            icon: Icons.warning_amber_rounded,
            heading: 'Common Obstacles & Pitfalls',
            items: challenges,
            badgeColor: const Color(0xFFDC2626),
          ),

        SizedBox(height: 14.h),

        // Section D: Personal Development & Practical Guidance
        if (guidance.isNotEmpty)
          _buildSectionCard(
            icon: Icons.fitness_center_rounded,
            heading: 'Personal Development & Practical Exercises',
            content: guidance,
            badgeColor: const Color(0xFF16A34A),
          ),

        SizedBox(height: 14.h),

        // Section E: Relationships & Communication
        if (relationships.isNotEmpty)
          _buildSectionCard(
            icon: Icons.favorite_border_rounded,
            heading: 'Relationships & Communication',
            content: relationships,
            badgeColor: const Color(0xFFE11D48),
          ),

        SizedBox(height: 14.h),

        // Section F: Work, Career & Daily Life
        if (work.isNotEmpty)
          _buildSectionCard(
            icon: Icons.work_outline_rounded,
            heading: 'Work, Career & Daily Habits',
            content: work,
            badgeColor: const Color(0xFF2563EB),
          ),

        SizedBox(height: 14.h),

        // Section G: Reflection Questions
        if (questions.isNotEmpty)
          _buildReflectionQuestionsCard(questions),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String heading,
    required String content,
    required Color badgeColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.04),
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
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: badgeColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  heading,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletListCard({
    required IconData icon,
    required String heading,
    required List<String> items,
    required Color badgeColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.04),
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
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: badgeColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  heading,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 5.h),
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF475569),
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

  Widget _buildReflectionQuestionsCard(List<String> questions) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_outline_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'Reflection & Self-Inquiry',
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final q = entry.value;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFFED7AA).withValues(alpha: 0.7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$idx.',
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      q,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 4: PRESENT NUMBERS
  // =========================================================================
  Widget _buildPresentNumbersTab() {
    final presentList = (_reportData?['present_numbers'] as List?)?.map((e) => e as int).toList() ?? [];
    final freqMap = _getFrequencyMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF16A34A), size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Present numbers represent the familiar strengths and inherent energetic resources naturally active in your birth name.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF14532D), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        ...presentList.map((n) {
          final count = freqMap[n] ?? 0;
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNumberTitleQuick(n),
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _getLettersForNumber(n),
                        style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    '$count occurrence${count == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
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
  // TAB 5: CALCULATION TRACE (AUDITABILITY)
  // =========================================================================
  Widget _buildTraceTab() {
    final trace = _reportData?['audit_trace'] as Map<String, dynamic>?;
    final words = (trace?['words_evaluated'] as List?) ?? [];
    final freqMap = _getFrequencyMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFFED7AA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculation Engine & Standards',
                style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
              ),
              SizedBox(height: 8.h),
              _buildTraceInfoRow('System', 'Pythagorean Name Numerology'),
              _buildTraceInfoRow('Policy', trace?['normalization_policy'] ?? 'NFKD Unicode Normalization'),
              _buildTraceInfoRow('Total Letters', '${_reportData?['total_letters_evaluated'] ?? 0} letters'),
              _buildTraceInfoRow('Algorithm Version', _reportData?['algorithm_version'] ?? '1.0.0'),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'WORD BREAKDOWN & LETTER TRACE',
          style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 1.0),
        ),
        SizedBox(height: 10.h),
        ...words.map((w) {
          final wordText = w['word']?.toString() ?? '';
          final letters = (w['letters'] as List?) ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wordText,
                  style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFFEA580C)),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: letters.map((l) {
                    final ch = l['letter']?.toString() ?? '';
                    final num = l['mapped_number']?.toString() ?? '';
                    final isZeroMissing = freqMap[int.tryParse(num) ?? 0] == 0;

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isZeroMissing ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isZeroMissing ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ch,
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            num,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isZeroMissing ? const Color(0xFFEA580C) : const Color(0xFF64748B),
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
      ],
    );
  }

  Widget _buildTraceInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  Map<int, int> _getFrequencyMap() {
    final raw = _reportData?['frequency_table'] as Map<String, dynamic>?;
    if (raw == null) return {};

    final result = <int, int>{};
    raw.forEach((key, val) {
      final k = int.tryParse(key);
      if (k != null) {
        result[k] = (val as num).toInt();
      }
    });
    return result;
  }

  Map<String, dynamic>? _getInterpretation(int number) {
    final interps = _reportData?['interpretations'] as Map<String, dynamic>?;
    if (interps == null) return null;
    return interps[number.toString()] as Map<String, dynamic>?;
  }

  String _getNumberTitleQuick(int number) {
    const titles = {
      1: 'Number 1: Leadership & Independence',
      2: 'Number 2: Diplomacy & Sensitivity',
      3: 'Number 3: Creative Expression & Joy',
      4: 'Number 4: Stability & Hard Work',
      5: 'Number 5: Freedom & Adaptability',
      6: 'Number 6: Responsibility & Care',
      7: 'Number 7: Wisdom & Spiritual Faith',
      8: 'Number 8: Power & Material Mastery',
      9: 'Number 9: Compassion & Universal Love',
    };
    return titles[number] ?? 'Number $number';
  }

  String _getLettersForNumber(int number) {
    const letters = {
      1: 'Mapped letters: A, J, S',
      2: 'Mapped letters: B, K, T',
      3: 'Mapped letters: C, L, U',
      4: 'Mapped letters: D, M, V',
      5: 'Mapped letters: E, N, W',
      6: 'Mapped letters: F, O, X',
      7: 'Mapped letters: G, P, Y',
      8: 'Mapped letters: H, Q, Z',
      9: 'Mapped letters: I, R',
    };
    return letters[number] ?? '';
  }
}
