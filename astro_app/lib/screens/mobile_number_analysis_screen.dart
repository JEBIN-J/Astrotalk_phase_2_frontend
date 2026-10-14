import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

class MobileNumberAnalysisScreen extends StatefulWidget {
  final String? initialPhoneNumber;
  final String? initialDob;
  final String? initialSystem;
  final String? initialName;

  const MobileNumberAnalysisScreen({
    super.key,
    this.initialPhoneNumber,
    this.initialDob,
    this.initialSystem,
    this.initialName,
  });

  @override
  State<MobileNumberAnalysisScreen> createState() => _MobileNumberAnalysisScreenState();
}

class _MobileNumberAnalysisScreenState extends State<MobileNumberAnalysisScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _selectedCountryCode = 'IN';
  String _selectedSystem = 'pythagorean';
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;

  int _activeTab = 0; // 0: Overview, 1: Digit Matrix, 2: Compatibility, 3: Daily Life

  // Theme Palette: Emerald Mint & Fresh Leaf (Matching the Mobile Number card)
  static const Color primaryGreen = Color(0xFF16A34A); // Emerald Primary
  static const Color cardBg = Color(0xFFF0FDF4); // Soft mint background
  static const Color cardBorder = Color(0xFFDCFCE7); // Delicate mint border
  static const Color darkText = Color(0xFF064E3B); // Deep pine text
  static const Color mutedText = Color(0xFF4B5563); // Slate muted text
  static const Color badgeBg = Color(0xFFDCFCE7);
  static const Color badgeText = Color(0xFF15803D);

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.initialSystem ?? 'pythagorean';

    if (widget.initialPhoneNumber != null && widget.initialPhoneNumber!.trim().isNotEmpty) {
      _phoneController.text = widget.initialPhoneNumber!.trim();
    }
    if (widget.initialDob != null && widget.initialDob!.trim().isNotEmpty) {
      _dobController.text = widget.initialDob!.trim();
    }

    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDob = prefs.getString('numerology_user_dob') ?? '1995-05-15';
    final savedPhone = prefs.getString('numerology_user_phone') ?? '';

    if (mounted) {
      if (_dobController.text.isEmpty && savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }
      if (_phoneController.text.isEmpty && savedPhone.isNotEmpty) {
        _phoneController.text = savedPhone;
        _analyzeNumber();
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _analyzeNumber() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid mobile number to evaluate.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.analyzePhoneNumber(
        phoneNumber: rawNumber,
        countryCode: _selectedCountryCode,
        dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        system: _selectedSystem,
      );

      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('numerology_user_phone', rawNumber);
        if (_dobController.text.trim().isNotEmpty) {
          await prefs.setString('numerology_user_dob', _dobController.text.trim());
        }
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

  void _showEditInputsDialog() {
    final phoneEdit = TextEditingController(text: _phoneController.text);
    final dobEdit = TextEditingController(text: _dobController.text);
    String tempCountry = _selectedCountryCode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
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
                child: Icon(Icons.phone_android_rounded, color: primaryGreen, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Change Mobile Number',
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
                  'Enter the subscriber mobile number to calculate its compound total, root vibration, and personal compatibility.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: phoneEdit,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.firaCode(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'e.g. 9876543210',
                    prefixText: '+91 ',
                    prefixStyle: GoogleFonts.firaCode(fontWeight: FontWeight.w700, color: primaryGreen, fontSize: 15.sp),
                    prefixIcon: const Icon(Icons.phone_rounded, color: primaryGreen),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryGreen, width: 1.5.w)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: dobEdit,
                  readOnly: true,
                  style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w600, color: darkText),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (For Compatibility)',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.cake_rounded, color: primaryGreen),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: primaryGreen),
                      onPressed: () async {
                        DateTime initial = DateTime.tryParse(dobEdit.text) ?? DateTime(1995, 5, 15);
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
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: primaryGreen, width: 1.5.w)),
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
                  _phoneController.text = phoneEdit.text.trim();
                  _dobController.text = dobEdit.text.trim();
                  _selectedCountryCode = tempCountry;
                });
                _analyzeNumber();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('Analyze Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFDFB),
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
                    border: Border.all(color: cardBorder, width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: darkText, size: 16.sp),
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
              'Mobile Numerology',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            Text(
              'Subscriber Digit Energy & Planetary Resonance',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryGreen,
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
                    onTap: _analyzeNumber,
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: primaryGreen, size: 19.sp),
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
    if (_errorMessage != null && _reportData == null) {
      return _buildErrorState();
    }
    if (_reportData == null) {
      return _buildInitialInputForm();
    }

    return Column(
      children: [
        _buildPhoneHeaderBar(),
        _buildViewTabBar(),
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
  // INITIAL INPUT FORM
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
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
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
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.phone_android_rounded, color: Colors.white, size: 26.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Your Number Vibration',
                        style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Computes compound sum, single root (1-9), digit frequencies, and compatibility with your birth chart.',
                        style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Enter Mobile Number',
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.firaCode(fontSize: 16.sp, fontWeight: FontWeight.w700, color: darkText),
            decoration: InputDecoration(
              hintText: '9876543210',
              prefixText: '+91 ',
              prefixStyle: GoogleFonts.firaCode(fontWeight: FontWeight.w700, color: primaryGreen, fontSize: 16.sp),
              prefixIcon: const Icon(Icons.phone_rounded, color: primaryGreen),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: primaryGreen, width: 2.w)),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Date of Birth (Optional for Personal Compatibility)',
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _dobController,
            readOnly: true,
            style: GoogleFonts.firaCode(fontSize: 14.sp, fontWeight: FontWeight.w600, color: darkText),
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(Icons.calendar_today_rounded, color: primaryGreen),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: primaryGreen),
                onPressed: () async {
                  DateTime initial = DateTime.tryParse(_dobController.text) ?? DateTime(1995, 5, 15);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: primaryGreen, width: 2.w)),
            ),
          ),
          SizedBox(height: 22.h),
          ElevatedButton(
            onPressed: _analyzeNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
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
                Text('Analyze Mobile Number', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _phoneController.text = '9876543210';
                _dobController.text = '1995-05-15';
                _analyzeNumber();
              },
              icon: Icon(Icons.science_outlined, size: 16.sp, color: primaryGreen),
              label: Text('Try Test Fixture: 9876543210', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600, color: primaryGreen)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PHONE SUMMARY & HERO ROOT NUMBER HEADER
  // =========================================================================

  Widget _buildPhoneHeaderBar() {
    final root = _reportData?['root_number'] ?? 0;
    final compound = _reportData?['compound_total'] ?? 0;
    final masked = _reportData?['masked_number'] ?? '';
    final digitsCount = _reportData?['total_digits_count'] ?? 10;
    final ruler = _reportData?['planetary_ruler'] as Map<String, dynamic>? ?? {};
    final interp = _reportData?['interpretation'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Large Root Number Badge
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$root',
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'ROOT',
                        style: GoogleFonts.firaCode(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 14.w),
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
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_rounded, color: badgeText, size: 10.sp),
                              SizedBox(width: 4.w),
                              Text(
                                masked,
                                style: GoogleFonts.firaCode(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: badgeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            ruler['planet']?.toString() ?? 'Sun',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      interp['title'] ?? 'Mobile Vibration',
                      style: GoogleFonts.outfit(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ruler['energy'] ?? 'Planetary Alignment',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showEditInputsDialog,
                icon: Icon(Icons.edit_rounded, size: 12.sp, color: primaryGreen),
                label: Text('Edit', style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: BorderSide(color: primaryGreen.withValues(alpha: 0.4)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Formula & Metric Strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildMetricItem('Compound', '$compound', Icons.calculate_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Root Number', '$root', Icons.stars_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Digits', '$digitsCount Digits', Icons.pin_rounded)),
                _buildMetricDivider(),
                Expanded(child: _buildMetricItem('Country', 'India (+91)', Icons.flag_rounded)),
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
            Icon(icon, size: 11.sp, color: primaryGreen),
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
        SizedBox(height: 3.h),
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

  // =========================================================================
  // VIEW TABS (OVERVIEW, DIGIT MATRIX, COMPATIBILITY, CALLING/DAILY)
  // =========================================================================

  Widget _buildViewTabBar() {
    final tabs = [
      {'label': 'Overview', 'icon': Icons.auto_awesome_rounded},
      {'label': 'Digit Matrix', 'icon': Icons.grid_view_rounded},
      {'label': 'Compatibility', 'icon': Icons.favorite_rounded},
      {'label': 'Daily Calling', 'icon': Icons.call_rounded},
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
          final isSelected = _activeTab == index;
          final tab = tabs[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => setState(() => _activeTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? primaryGreen : cardBorder,
                    width: 1.w,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.28),
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
                      color: isSelected ? Colors.white : primaryGreen,
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

  Widget _buildSelectedTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildDigitMatrixTab();
      case 2:
        return _buildCompatibilityTab();
      case 3:
      default:
        return _buildDailyCallingTab();
    }
  }

  // =========================================================================
  // TAB 0: OVERVIEW & TRADITIONAL THEMES
  // =========================================================================

  Widget _buildOverviewTab() {
    final interp = _reportData?['interpretation'] as Map<String, dynamic>? ?? {};
    final strengths = (interp['traditional_strengths'] as List<dynamic>?) ?? [];
    final challenges = (interp['potential_challenges'] as List<dynamic>?) ?? [];
    final reduction = (_reportData?['reduction_trace'] as List<dynamic>?) ?? [];
    final digitsStr = _reportData?['subscriber_digits_str'] ?? '';
    final root = _reportData?['root_number'] ?? 0;
    final compound = _reportData?['compound_total'] ?? 0;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Step-by-Step Reduction Formula Card with interactive math chips
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.calculate_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step-by-Step Reduction Trace',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: darkText,
                          ),
                        ),
                        Text(
                          'Subscriber digits summed to single root vibration',
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
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
              // Visual Digit Calculation Wrap
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.w,
                  runSpacing: 7.h,
                  children: [
                    ...digitsStr.split('').expand((d) => [
                          _buildDigitPill(d),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.w),
                            child: Text(
                              '+',
                              style: GoogleFonts.firaCode(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ]).toList()
                      ..removeLast(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: Text(
                        '=',
                        style: GoogleFonts.firaCode(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: darkText,
                        ),
                      ),
                    ),
                    _buildResultPill('$compound', isCompound: true),
                    if (reduction.length > 1) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Icon(Icons.arrow_forward_rounded, size: 13.sp, color: primaryGreen),
                      ),
                      _buildResultPill('$root', isCompound: false),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 13.sp, color: primaryGreen),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'All 10 subscriber digits are summed (${digitsStr.split('').join(' + ')} = $compound), then reduced by integer sum to final root $root. Regional dial routing (+91) is preserved.',
                      style: GoogleFonts.inter(fontSize: 10.5.sp, color: mutedText, height: 1.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Core Theme & Overview Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16.sp),
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
                            'Root $root Core Archetype',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              color: badgeText,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          interp['core_theme'] ?? 'Core Vibration',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: darkText,
                            height: 1.3,
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
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.8)),
                ),
                child: Text(
                  interp['overview'] ?? 'Detailed overview of this phone number root vibration.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: darkText,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Traditional Strengths Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.verified_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Traditional Strengths',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                    ),
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
                        Icon(Icons.check_circle_rounded, color: primaryGreen, size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            s.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Mindful Precautions Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFFED7AA), width: 1.2.w),
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
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: const Color(0xFFD97706), size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Mindful Precautions',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...challenges.map((c) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: const Color(0xFFD97706), size: 15.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            c.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF78350F),
                              height: 1.35,
                            ),
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

  Widget _buildDigitPill(String digit) {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: cardBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          digit,
          style: GoogleFonts.firaCode(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildResultPill(String val, {required bool isCompound}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isCompound ? const Color(0xFFDCFCE7) : primaryGreen,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isCompound ? primaryGreen : Colors.transparent),
        boxShadow: isCompound
            ? null
            : [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        val,
        style: GoogleFonts.outfit(
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          color: isCompound ? darkText : Colors.white,
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: DIGIT MATRIX & FREQUENCY BREAKDOWN
  // =========================================================================

  Widget _buildDigitMatrixTab() {
    final patterns = _reportData?['digit_patterns'] as Map<String, dynamic>? ?? {};
    final freq = (patterns['frequency_table'] as Map<String, dynamic>?) ?? {};
    final repeated = (patterns['repeated_digits'] as List<dynamic>?) ?? [];
    final missing = (patterns['missing_digits'] as List<dynamic>?) ?? [];
    final first = patterns['first_digit'] ?? 0;
    final last = patterns['last_digit'] ?? 0;
    final lastTwo = patterns['last_two_digits'] ?? '';

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Positional Gates Triple Banner
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.compare_arrows_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Positional Number Gates',
                    style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildGateCard(
                      label: 'Opening Gate',
                      sublabel: 'Initial Caller Impression',
                      value: '$first',
                      icon: Icons.login_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildGateCard(
                      label: 'Closing Gate',
                      sublabel: 'Ending Energy Impression',
                      value: '$last',
                      icon: Icons.logout_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildGateCard(
                      label: 'Tail Compound',
                      sublabel: 'Final Digit Compound',
                      value: '$lastTwo',
                      icon: Icons.tag_rounded,
                      isMonospace: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Frequency Grid 0-9
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                        child: Icon(Icons.dialpad_rounded, color: primaryGreen, size: 16.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Digit Matrix (0 to 9)',
                        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 4.w),
                      Text('Repeated', style: GoogleFonts.inter(fontSize: 10.sp, color: mutedText, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8.w),
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle),
                      ),
                      SizedBox(width: 4.w),
                      Text('Missing', style: GoogleFonts.inter(fontSize: 10.sp, color: mutedText, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                  childAspectRatio: 1.05,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final count = int.tryParse(freq['$index']?.toString() ?? '0') ?? 0;
                  final isRepeated = count > 1;
                  final isMissing = count == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isRepeated
                          ? const Color(0xFFDCFCE7)
                          : (isMissing ? const Color(0xFFF8FAFC) : cardBg),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isRepeated
                            ? primaryGreen
                            : (isMissing ? const Color(0xFFE2E8F0) : cardBorder),
                        width: isRepeated ? 1.5.w : 1.w,
                      ),
                      boxShadow: isRepeated
                          ? [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$index',
                          style: GoogleFonts.outfit(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: isMissing
                                ? const Color(0xFF94A3B8)
                                : (isRepeated ? const Color(0xFF064E3B) : darkText),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: isRepeated
                                ? primaryGreen
                                : (isMissing ? const Color(0xFFE2E8F0) : Colors.white),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            count == 0 ? '0' : '${count}x',
                            style: GoogleFonts.firaCode(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: isRepeated
                                  ? Colors.white
                                  : (isMissing ? const Color(0xFF64748B) : primaryGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Repeated Digits Analysis
        if (repeated.isNotEmpty) ...[
          Text(
            'Repeated Vibrations (Amplified Energies)',
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
          ),
          SizedBox(height: 8.h),
          ...repeated.map((r) {
            final digit = r['digit'];
            final count = r['count'];
            final intensity = r['intensity'];
            final insight = r['insight'] ?? 'Amplified frequency of number $digit.';
            final rec = r['recommendation'] ?? '';

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cardBorder, width: 1.2.w),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Digit $digit • Appears $count Times',
                          style: GoogleFonts.firaCode(fontSize: 11.sp, fontWeight: FontWeight.w800, color: badgeText),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '$intensity',
                          style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w700, color: primaryGreen),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(insight, style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.4)),
                  if (rec.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_rounded, color: primaryGreen, size: 14.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                                color: darkText,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ] else ...[
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: primaryGreen, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'No repeated digits detected. Energies are distributed evenly across the subscriber sequence.',
                    style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 12.h),

        // Missing Digits Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.blur_on_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Missing Digits (Frequencies To Cultivate)',
                    style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (missing.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: missing.map((d) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.remove_circle_outline_rounded, size: 12.sp, color: const Color(0xFF94A3B8)),
                            SizedBox(width: 5.w),
                            Text(
                              'Digit $d Absent',
                              style: GoogleFonts.firaCode(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
                SizedBox(height: 10.h),
              ],
              Text(
                missing.isEmpty
                    ? 'All digits 0–9 are present across your subscriber sequence.'
                    : 'Missing digits highlight qualities you are not relying upon automatically through this telephone number, offering conscious opportunities for mindful personal balance.',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildGateCard({
    required String label,
    required String sublabel,
    required String value,
    required IconData icon,
    bool isMonospace = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16.sp, color: primaryGreen),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9.5.sp, color: mutedText, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: isMonospace
                ? GoogleFonts.firaCode(fontSize: 16.sp, fontWeight: FontWeight.w900, color: darkText)
                : GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PERSONAL COMPATIBILITY
  // =========================================================================

  Widget _buildCompatibilityTab() {
    final compat = _reportData?['personal_compatibility'] as Map<String, dynamic>?;

    if (compat == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: Icon(Icons.cake_rounded, size: 36.sp, color: primaryGreen),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Date of Birth Required',
                style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w800, color: darkText),
              ),
              SizedBox(height: 6.h),
              Text(
                'Personal compatibility evaluates planetary harmony between your Mobile Root and your Life Path / Birth Day numbers.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: mutedText, height: 1.4),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: _showEditInputsDialog,
                icon: Icon(Icons.add_rounded, size: 16.sp),
                label: Text('Add Date of Birth', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
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

    final lpNum = compat['life_path_number'] ?? 0;
    final bdNum = compat['birth_day_number'] ?? 0;
    final overall = compat['overall_category'] ?? 'Balanced & Neutral';
    final scoreIndex = (compat['rule_based_resonance_index'] as num?)?.toInt() ?? 75;
    final explanation = compat['astrological_explanation'] ?? '';
    final lpCompat = compat['life_path_compatibility'] as Map<String, dynamic>? ?? {};
    final bdCompat = compat['birth_day_compatibility'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // Overall Resonance Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.12),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder, width: 1.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$scoreIndex',
                            style: GoogleFonts.outfit(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: primaryGreen,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '/100',
                            style: GoogleFonts.firaCode(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overall,
                          style: GoogleFonts.outfit(fontSize: 16.5.sp, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Personal Planetary Resonance Index',
                          style: GoogleFonts.inter(fontSize: 10.5.sp, color: mutedText, fontWeight: FontWeight.w500),
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
                  value: (scoreIndex / 100.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.white,
                  color: primaryGreen,
                  minHeight: 7.h,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Life Path Alignment Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.route_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Life Path $lpNum Harmony',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6.r)),
                    child: Text(
                      lpCompat['status_label'] ?? 'Balanced',
                      style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, color: badgeText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Assesses how your mobile frequency aligns with your core life purpose and foundational karmic destiny ($lpNum).',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Birth Day Talent Alignment Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.cake_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Birth Day $bdNum Harmony',
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6.r)),
                    child: Text(
                      bdCompat['status_label'] ?? 'Balanced',
                      style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w800, color: badgeText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Measures resonance with your natural daily temperament, applied communication gifts, and personal talents ($bdNum).',
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: mutedText, height: 1.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Planetary Astrological Explanation Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.05),
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
                    child: Icon(Icons.menu_book_rounded, color: primaryGreen, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text('Documented Planetary Principle', style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: darkText)),
                ],
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                ),
                child: Text(
                  explanation,
                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: darkText, height: 1.45),
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
  // TAB 3: DAILY CALLING & PRACTICAL GUIDANCE
  // =========================================================================

  Widget _buildDailyCallingTab() {
    final interp = _reportData?['interpretation'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        _buildCallingCard(
          title: 'Communication Aura',
          icon: Icons.chat_bubble_outline_rounded,
          content: interp['communication_themes'] ?? 'How calls and texts through this number are experienced by contacts.',
        ),
        SizedBox(height: 12.h),
        _buildCallingCard(
          title: 'Work & Professional Resonance',
          icon: Icons.business_center_outlined,
          content: interp['work_and_daily_life'] ?? 'Professional contexts and enterprise fields that thrive under this root.',
        ),
        SizedBox(height: 12.h),
        _buildCallingCard(
          title: 'Practical Calling Guidance',
          icon: Icons.tips_and_updates_outlined,
          content: interp['practical_guidance'] ?? 'Mindful practices to optimize clarity and prevent misunderstanding.',
        ),
        SizedBox(height: 12.h),
        _buildCallingCard(
          title: 'Mindful Reflection Question',
          icon: Icons.psychology_outlined,
          content: interp['reflection_questions'] ?? 'A conscious inquiry to align your telephone use with your higher intent.',
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildCallingCard({required String title, required IconData icon, required String content}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.05),
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
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(icon, color: primaryGreen, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: darkText),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(fontSize: 12.sp, color: darkText, height: 1.45),
            ),
          ),
        ],
      ),
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
          CircularProgressIndicator(color: primaryGreen, strokeWidth: 3.w),
          SizedBox(height: 16.h),
          Text(
            'Analyzing Mobile Vibration...',
            style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: darkText),
          ),
          SizedBox(height: 4.h),
          Text(
            'Summing subscriber digits and evaluating reviewed database records',
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
              onPressed: _analyzeNumber,
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
