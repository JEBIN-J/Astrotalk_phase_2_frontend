import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import '../theme/numerology_theme.dart';
import 'angel_number_detail_screen.dart';

class AngelNumbersDashboardScreen extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserDob;

  const AngelNumbersDashboardScreen({
    super.key,
    this.initialUserName,
    this.initialUserDob,
  });

  @override
  State<AngelNumbersDashboardScreen> createState() => _AngelNumbersDashboardScreenState();
}

class _AngelNumbersDashboardScreenState extends State<AngelNumbersDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _sequenceController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Exact Theme Palette from the Angel Numbers Card (Responsive to dark mode)
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color darkIndigo = Color(0xFF4F46E5);
  bool get isDark => mounted ? (Theme.of(context).brightness == Brightness.dark) : false;
  Color get softCardBg => isDark ? NumerologyTheme.darkCardBg : const Color(0xFFF5F3FF);
  Color get surfaceBg => isDark ? const Color(0xFF18233C) : Colors.white;
  Color get cardBorder => isDark ? primaryIndigo.withValues(alpha: 0.35) : const Color(0xFFEDE9FE);
  Color get darkText => isDark ? Colors.white : const Color(0xFF1E1B4B);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get badgeBg => isDark ? NumerologyTheme.darkButtonBg : const Color(0xFFEDE9FE);
  Color get badgeText => isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);

  bool _isDecoding = false;
  bool _isLoadingContent = true;

  // Data
  Map<String, dynamic>? _dailyReflection;
  List<Map<String, dynamic>> _popularNumbers = [];
  List<Map<String, dynamic>> _mirrorHours = [];
  List<Map<String, dynamic>> _patterns = [];
  
  // Personal Angel Number
  String _personalMethod = 'dob'; // 'dob' or 'name'
  bool _isCalculatingPersonal = false;
  Map<String, dynamic>? _personalResult;

  // Journal
  bool _isLoadingJournal = false;
  List<Map<String, dynamic>> _journalSightings = [];
  int _totalSightings = 0;
  String? _mostFrequentSequence;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _dobController.text = widget.initialUserDob ?? '';
    _nameController.text = widget.initialUserName ?? '';
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sequenceController.dispose();
    _dobController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingContent = true);
    
    // Check saved user prefs if not provided in widget
    if (_dobController.text.isEmpty || _nameController.text.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (_dobController.text.isEmpty) {
        _dobController.text = prefs.getString('numerology_user_dob') ?? '1995-05-15';
      }
      if (_nameController.text.isEmpty) {
        _nameController.text = prefs.getString('numerology_user_name') ?? 'Seeker';
      }
    }

    try {
      final daily = await AstroApiService.getDailyAngelReflection();
      final popular = await AstroApiService.getPopularAngelNumbers();
      final mirrors = await AstroApiService.getMirrorHours();
      final pats = await AstroApiService.getAngelNumberPatterns();

      setState(() {
        _dailyReflection = daily;
        _popularNumbers = popular;
        _mirrorHours = mirrors;
        _patterns = pats;
        _isLoadingContent = false;
      });
    } catch (_) {
      setState(() => _isLoadingContent = false);
    }

    _loadJournal();
  }

  Future<void> _loadJournal() async {
    setState(() => _isLoadingJournal = true);
    try {
      final journalData = await AstroApiService.getAngelSightings();
      final list = (journalData['sightings'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      setState(() {
        _journalSightings = list;
        _totalSightings = journalData['total_sightings'] ?? list.length;
        _mostFrequentSequence = journalData['most_frequent_sequence']?.toString();
        _isLoadingJournal = false;
      });
    } catch (_) {
      setState(() => _isLoadingJournal = false);
    }
  }

  Future<void> _decodeSequence(String rawSeq) async {
    final seq = rawSeq.trim();
    if (seq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number sequence (e.g. 111, 1234, 11:11)')),
      );
      return;
    }

    setState(() => _isDecoding = true);
    try {
      final res = await AstroApiService.lookupAngelNumber(seq);
      setState(() => _isDecoding = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AngelNumberDetailScreen(lookupData: res, initialSequence: seq),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDecoding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _calculatePersonalNumber() async {
    setState(() => _isCalculatingPersonal = true);
    try {
      final res = await AstroApiService.calculatePersonalAngelNumber(
        method: _personalMethod,
        dob: _personalMethod == 'dob' ? _dobController.text.trim() : null,
        name: _personalMethod == 'name' ? _nameController.text.trim() : null,
      );
      setState(() {
        _personalResult = res;
        _isCalculatingPersonal = false;
      });
    } catch (e) {
      setState(() => _isCalculatingPersonal = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showAddSightingSheet() {
    final seqController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Clock / Watch';
    String selectedMood = 'Inspired';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24.h,
          ),
          decoration: BoxDecoration(
            color: isDark ? NumerologyTheme.darkScaffoldBg : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  'Record a Number Sighting',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 16.h),
                Text('Observed Sequence (e.g. 111, 444, 11:11)',
                    style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: darkText)),
                SizedBox(height: 6.h),
                TextField(
                  controller: seqController,
                  decoration: InputDecoration(
                    hintText: 'Enter digits or HH:MM',
                    filled: true,
                    fillColor: softCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                  ),
                ),
                SizedBox(height: 14.h),
                Text('Where did you notice it?',
                    style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: darkText)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: ['Clock / Watch', 'Receipt / Bill', 'License Plate', 'Screen / Phone', 'Other'].map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: GoogleFonts.outfit(fontSize: 12.sp, color: isSel ? Colors.white : darkText)),
                      selected: isSel,
                      selectedColor: primaryIndigo,
                      backgroundColor: softCardBg,
                      side: BorderSide(color: isSel ? primaryIndigo : cardBorder),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 14.h),
                Text('Personal Note / Context (Optional)',
                    style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: darkText)),
                SizedBox(height: 6.h),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Your thoughts, feelings or setting...',
                    filled: true,
                    fillColor: softCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      final s = seqController.text.trim();
                      if (s.isEmpty) return;
                      Navigator.pop(sheetCtx);
                      try {
                        await AstroApiService.addAngelSighting(
                          observedSequence: s,
                          contextCategory: selectedCategory,
                          personalNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                          mood: selectedMood,
                        );
                        _loadJournal();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save sighting: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text('Save Sighting', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(116.h),
      child: Container(
        decoration: BoxDecoration(
          color: NumerologyTheme.appBarBg(isDark),
          border: Border(
            bottom: BorderSide(color: cardBorder, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryIndigo.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Top Bar Navigation & Title ---
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h),
                child: Row(
                  children: [
                    // Back Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: NumerologyTheme.circleBtnBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: NumerologyTheme.circleBtnIcon(isDark),
                            size: 15.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: const BoxDecoration(
                                  color: primaryIndigo,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 11.sp,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  'Angel Numbers',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Sacred Synchronicities & Pattern Guidance',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryIndigo,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Right Sighting Quick Action
                    InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: _showAddSightingSheet,
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: softCardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bookmark_add_outlined,
                            color: primaryIndigo,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Segmented Capsule Tab Bar ---
              Container(
                margin: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 8.h),
                height: 40.h,
                decoration: BoxDecoration(
                  color: softCardBg,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: cardBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                  labelPadding: EdgeInsets.symmetric(horizontal: 3.w),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: primaryIndigo,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryIndigo.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: darkText,
                  labelStyle: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.explore_rounded, size: 14.sp),
                            SizedBox(width: 5.w),
                            const Text('Decode & Explore'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin_rounded, size: 14.sp),
                            SizedBox(width: 5.w),
                            const Text('Personal Number'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 14.sp),
                            SizedBox(width: 5.w),
                            const Text('Mirror Hours'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_edu_rounded, size: 14.sp),
                            SizedBox(width: 5.w),
                            const Text('Sightings Journal'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NumerologyTheme.scaffoldBg(isDark),
      appBar: _buildCustomAppBar(context),
      body: _isLoadingContent
          ? const Center(child: CircularProgressIndicator(color: primaryIndigo))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDecodeTab(),
                _buildPersonalNumberTab(),
                _buildMirrorHoursTab(),
                _buildJournalTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton.extended(
              onPressed: _showAddSightingSheet,
              backgroundColor: primaryIndigo,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Record Sighting', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
    );
  }

  // ==========================================
  // TAB 1: DECODE & EXPLORE
  // ==========================================
  Widget _buildDecodeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decode Input Card
          _buildDecodeInputCard(),
          SizedBox(height: 18.h),

          // Daily Reflection Card
          if (_dailyReflection != null) ...[
            _buildDailyReflectionCard(),
            SizedBox(height: 20.h),
          ],

          // Popular Sequences Grid
          Text(
            'POPULAR NUMBER PATTERNS',
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: mutedText,
            ),
          ),
          SizedBox(height: 10.h),
          _buildPopularSequencesGrid(),
          SizedBox(height: 22.h),

          // Pattern Classifications Library
          Text(
            'MATHEMATICAL PATTERN LIBRARY',
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: mutedText,
            ),
          ),
          SizedBox(height: 10.h),
          _buildPatternsList(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildDecodeInputCard() {
    final quickSequences = ['111', '222', '333', '444', '555', '777', '888', '1111', '1212', '1234', '11:11', '12:21'];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryIndigo.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                decoration: BoxDecoration(
                  color: softCardBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_rounded, color: primaryIndigo, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decode a Number Sequence',
                      style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
                    ),
                    Text(
                      'Enter repeating digits, sequences, or clock hours',
                      style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sequenceController,
                  style: GoogleFonts.spaceMono(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
                  decoration: InputDecoration(
                    hintText: 'e.g. 111, 1234, 11:11',
                    hintStyle: GoogleFonts.outfit(fontSize: 14.sp, color: mutedText),
                    filled: true,
                    fillColor: softCardBg,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: primaryIndigo),
                    ),
                  ),
                  onSubmitted: _decodeSequence,
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isDecoding ? null : () => _decodeSequence(_sequenceController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                  child: _isDecoding
                      ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Decode', style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('Quick Sequence Lookups:', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: mutedText)),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickSequences.map((seq) {
                return Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: ActionChip(
                    label: Text(seq, style: GoogleFonts.spaceMono(fontSize: 12.sp, fontWeight: FontWeight.w600, color: darkIndigo)),
                    backgroundColor: softCardBg,
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    onPressed: () {
                      _sequenceController.text = seq;
                      _decodeSequence(seq);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReflectionCard() {
    final daily = _dailyReflection!;
    final seq = daily['sequence'] ?? '111';
    final title = daily['title'] ?? 'Daily Angel Guidance';
    final reflection = daily['reflection'] ?? '';
    final dateStr = daily['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: softCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: primaryIndigo, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'DAILY REFLECTION • $dateStr',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: darkIndigo,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  seq,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            reflection,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: mutedText,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () => _decodeSequence(seq),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore $seq Deep Breakdown',
                  style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.arrow_forward_rounded, size: 14.sp, color: primaryIndigo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSequencesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _popularNumbers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (ctx, idx) {
        final item = _popularNumbers[idx];
        final seq = item['canonical_sequence']?.toString() ?? '';
        final title = item['title']?.toString() ?? '';
        final rootNum = item['root_number'] ?? '';

        return InkWell(
          onTap: () => _decodeSequence(seq),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: softCardBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        seq,
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: darkIndigo,
                        ),
                      ),
                    ),
                    if (rootNum.toString().isNotEmpty)
                      CircleAvatar(
                        radius: 12.r,
                        backgroundColor: badgeBg,
                        child: Text(
                          '$rootNum',
                          style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, color: badgeText),
                        ),
                      ),
                  ],
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                    height: 1.25,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 16.sp, color: primaryIndigo),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatternsList() {
    return Column(
      children: _patterns.map((pat) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: softCardBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pattern_rounded, color: primaryIndigo, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pat['pattern_name']?.toString() ?? '',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      pat['pattern_description']?.toString() ?? '',
                      style: GoogleFonts.outfit(fontSize: 12.5.sp, color: mutedText, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // TAB 2: PERSONAL ANGEL NUMBER
  // ==========================================
  Widget _buildPersonalNumberTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: cardBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(color: softCardBg, shape: BoxShape.circle),
                      child: Icon(Icons.person_pin_rounded, color: primaryIndigo, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Angel Number',
                            style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w700, color: darkText),
                          ),
                          Text(
                            'Deterministic life vibrational angel frequency',
                            style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Method Switcher
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Method A: Birth Date (DOB)', style: GoogleFonts.outfit(fontSize: 12.sp))),
                        selected: _personalMethod == 'dob',
                        selectedColor: primaryIndigo,
                        labelStyle: TextStyle(color: _personalMethod == 'dob' ? Colors.white : darkText),
                        backgroundColor: softCardBg,
                        onSelected: (val) => setState(() => _personalMethod = 'dob'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Method B: Name Vibrations', style: GoogleFonts.outfit(fontSize: 12.sp))),
                        selected: _personalMethod == 'name',
                        selectedColor: primaryIndigo,
                        labelStyle: TextStyle(color: _personalMethod == 'name' ? Colors.white : darkText),
                        backgroundColor: softCardBg,
                        onSelected: (val) => setState(() => _personalMethod = 'name'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                if (_personalMethod == 'dob') ...[
                  Text('Date of Birth (YYYY-MM-DD)', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: darkText)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      hintText: '1995-05-15',
                      filled: true,
                      fillColor: softCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    ),
                  ),
                ] else ...[
                  Text('Full Name (Pythagorean)', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: darkText)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Your Birth Name',
                      filled: true,
                      fillColor: softCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    ),
                  ),
                ],
                SizedBox(height: 16.h),

                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isCalculatingPersonal ? null : _calculatePersonalNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: _isCalculatingPersonal
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Calculate Personal Angel Number', style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // Result Card if available
          if (_personalResult != null) _buildPersonalResultCard(),
        ],
      ),
    );
  }

  Widget _buildPersonalResultCard() {
    final calc = _personalResult!['calculation'] as Map<String, dynamic>? ?? {};
    final rootNum = calc['root_number'] ?? '';
    final personalSeq = calc['personal_angel_number']?.toString() ?? '$rootNum$rootNum$rootNum';
    final steps = (calc['calculation_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final explanation = calc['explanation']?.toString() ?? '';
    final seqInterp = _personalResult!['sequence_interpretation'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: softCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR PERSONAL ANGEL NUMBER',
                style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: darkIndigo),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  personalSeq,
                  style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(explanation, style: GoogleFonts.outfit(fontSize: 13.5.sp, color: darkText, height: 1.4)),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reduction Equation:', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: mutedText)),
                SizedBox(height: 4.h),
                for (final st in steps)
                  Text(st, style: GoogleFonts.spaceMono(fontSize: 12.5.sp, color: darkIndigo, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          if (seqInterp != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AngelNumberDetailScreen(lookupData: seqInterp, initialSequence: personalSeq),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded, color: primaryIndigo),
                label: Text('Read Full Interpretation for $personalSeq', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: primaryIndigo)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryIndigo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: MIRROR HOURS
  // ==========================================
  Widget _buildMirrorHoursTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: softCardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled_rounded, color: primaryIndigo, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mirror & Reversed Clock Hours',
                        style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
                      ),
                      Text(
                        'Clock synchronicity patterns such as 11:11, 12:21, 22:22',
                        style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mirrorHours.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (ctx, idx) {
              final mh = _mirrorHours[idx];
              final timeStr = mh['time']?.toString() ?? '';
              final title = mh['title']?.toString() ?? '';
              final short = mh['short_meaning']?.toString() ?? '';

              return InkWell(
                onTap: () => _decodeSequence(timeStr),
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: softCardBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Text(
                          timeStr,
                          style: GoogleFonts.spaceMono(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: darkIndigo,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText)),
                            SizedBox(height: 4.h),
                            Text(short, style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText, height: 1.3)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: primaryIndigo),
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

  // ==========================================
  // TAB 4: SIGHTINGS JOURNAL
  // ==========================================
  Widget _buildJournalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Highlights
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: softCardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Sightings', style: GoogleFonts.outfit(fontSize: 11.5.sp, color: mutedText)),
                      Text('$_totalSightings', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w800, color: darkIndigo)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Sighting', style: GoogleFonts.outfit(fontSize: 11.5.sp, color: mutedText)),
                      Text(
                        _mostFrequentSequence ?? 'None',
                        style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR RECORDED SIGHTINGS',
                style: GoogleFonts.outfit(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: mutedText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: primaryIndigo),
                onPressed: _loadJournal,
              ),
            ],
          ),
          SizedBox(height: 8.h),

          if (_isLoadingJournal)
            const Center(child: CircularProgressIndicator(color: primaryIndigo))
          else if (_journalSightings.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.history_edu_rounded, size: 40.sp, color: mutedText),
                  SizedBox(height: 10.h),
                  Text(
                    'No Sightings Recorded Yet',
                    style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap "Record Sighting" whenever you notice a number sequence in daily life to track its occurrences.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 12.5.sp, color: mutedText),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _journalSightings.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (ctx, idx) {
                final s = _journalSightings[idx];
                final id = s['id'] as int? ?? 0;
                final seq = s['observed_sequence']?.toString() ?? '';
                final cat = s['context_category']?.toString() ?? 'Sighting';
                final note = s['personal_note']?.toString() ?? '';
                final date = s['observed_at']?.toString() ?? '';

                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: softCardBg,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Text(
                          seq,
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: darkIndigo,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkText)),
                                Text(
                                  date.length >= 10 ? date.substring(0, 10) : date,
                                  style: GoogleFonts.outfit(fontSize: 11.sp, color: mutedText),
                                ),
                              ],
                            ),
                            if (note.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(note, style: GoogleFonts.outfit(fontSize: 12.5.sp, color: darkText)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () async {
                          final ok = await AstroApiService.deleteAngelSighting(id);
                          if (ok) _loadJournal();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: 70.h),
        ],
      ),
    );
  }
}
