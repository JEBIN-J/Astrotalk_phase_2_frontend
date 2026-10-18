import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';

class KundliMatchMakingScreen extends StatefulWidget {
  final String? initialBoyName;
  final String? initialBoyDob;
  final String? initialGirlName;
  final String? initialGirlDob;

  const KundliMatchMakingScreen({
    super.key,
    this.initialBoyName,
    this.initialBoyDob,
    this.initialGirlName,
    this.initialGirlDob,
  });

  @override
  State<KundliMatchMakingScreen> createState() => _KundliMatchMakingScreenState();
}

// Theme Color Palette - Rich Wine & Deep Rose (Darker & Subdued)
const Color primaryRose = Color(0xFFBE123C); // Darker rich crimson (was bright neon 0xFFE11D48)
const Color deepRose = Color(0xFF881337);    // Deep wine red
const Color softRose = Color(0xFFFFF1F2);
const Color roseBorder = Color(0xFFFECDD3);
const Color darkText = Color(0xFF0F172A);
const Color mutedText = Color(0xFF64748B);
const Color goldAccent = Color(0xFFF59E0B);
const Color successGreen = Color(0xFF10B981);
const Color warningOrange = Color(0xFFF97316);

// Dark mode helpers
Color _cardBg(bool isDark) => isDark ? const Color(0xFF1E293B) : Colors.white;
Color _scaffoldBg(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF5F7);
Color _bodyText(bool isDark) => isDark ? Colors.white : darkText;
Color _borderCol(bool isDark) => isDark ? const Color(0xFF334155) : roseBorder;
Color _subCardBg(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
Color _disclaimerBg(bool isDark) => isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
Color _disclaimerBorder(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
Color _softRoseDark(bool isDark) => isDark ? const Color(0xFF1E1419) : softRose;
Color _primaryRed(bool isDark) => isDark ? const Color(0xFF881337) : primaryRose;
Color _deepRed(bool isDark) => isDark ? const Color(0xFF4C0519) : deepRose;
Color _accentRose(bool isDark) => isDark ? const Color(0xFFFB7185) : primaryRose;

class _KundliMatchMakingScreenState extends State<KundliMatchMakingScreen>
    with SingleTickerProviderStateMixin {

  // Controllers - Person A (Groom)
  final TextEditingController _boyNameController = TextEditingController();
  final TextEditingController _boyDobController = TextEditingController();
  final TextEditingController _boyTobController = TextEditingController();
  final TextEditingController _boyPlaceController = TextEditingController();
  bool _boyTimeUnknown = false;

  // Controllers - Person B (Bride)
  final TextEditingController _girlNameController = TextEditingController();
  final TextEditingController _girlDobController = TextEditingController();
  final TextEditingController _girlTobController = TextEditingController();
  final TextEditingController _girlPlaceController = TextEditingController();
  bool _girlTimeUnknown = false;

  // State
  String _selectedTradition = 'both'; // 'ashta_koota', 'porutham', 'both'
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _matchResult;
  bool _isSaved = false;

  late TabController _resultTabController;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  void _showLocationSelector(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationSelectorSheet(
        onSelect: (city) {
          setState(() {
            controller.text = city['city'] ?? '';
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _resultTabController = TabController(length: 4, vsync: this);

    if (widget.initialBoyName != null && widget.initialBoyName!.isNotEmpty) {
      _boyNameController.text = widget.initialBoyName!;
    }
    if (widget.initialBoyDob != null && widget.initialBoyDob!.isNotEmpty) {
      _boyDobController.text = widget.initialBoyDob!;
    }
    if (widget.initialGirlName != null && widget.initialGirlName!.isNotEmpty) {
      _girlNameController.text = widget.initialGirlName!;
    }
    if (widget.initialGirlDob != null && widget.initialGirlDob!.isNotEmpty) {
      _girlDobController.text = widget.initialGirlDob!;
    }
  }

  @override
  void dispose() {
    _resultTabController.dispose();
    _boyNameController.dispose();
    _boyDobController.dispose();
    _boyTobController.dispose();
    _boyPlaceController.dispose();
    _girlNameController.dispose();
    _girlDobController.dispose();
    _girlTobController.dispose();
    _girlPlaceController.dispose();
    super.dispose();
  }

  // =========================================================================
  // API ACTIONS
  // =========================================================================

  Future<void> _calculateMatch() async {
    final boyDob = _boyDobController.text.trim();
    final girlDob = _girlDobController.text.trim();
    final boyPlace = _boyPlaceController.text.trim();
    final girlPlace = _girlPlaceController.text.trim();

    if (boyDob.isEmpty) {
      setState(() => _errorMessage = "Please enter Groom's date of birth.");
      return;
    }
    if (!_boyTimeUnknown && _boyTobController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter Groom's time of birth or check 'unknown'.");
      return;
    }
    if (boyPlace.isEmpty) {
      setState(() => _errorMessage = "Please enter Groom's birth place (city).");
      return;
    }
    if (girlDob.isEmpty) {
      setState(() => _errorMessage = "Please enter Bride's date of birth.");
      return;
    }
    if (!_girlTimeUnknown && _girlTobController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter Bride's time of birth or check 'unknown'.");
      return;
    }
    if (girlPlace.isEmpty) {
      setState(() => _errorMessage = "Please enter Bride's birth place (city).");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSaved = false;
    });

    try {
      final boyPayload = {
        'name': _boyNameController.text.trim().isEmpty ? 'Groom' : _boyNameController.text.trim(),
        'date_of_birth': boyDob,
        'time_of_birth': _boyTimeUnknown ? null : _boyTobController.text.trim(),
        'place_of_birth': boyPlace,
        'is_birth_time_known': !_boyTimeUnknown,
      };

      final girlPayload = {
        'name': _girlNameController.text.trim().isEmpty ? 'Bride' : _girlNameController.text.trim(),
        'date_of_birth': girlDob,
        'time_of_birth': _girlTimeUnknown ? null : _girlTobController.text.trim(),
        'place_of_birth': girlPlace,
        'is_birth_time_known': !_girlTimeUnknown,
      };

      final result = await AstroApiService.calculateMatchMaking(
        boy: boyPayload,
        girl: girlPayload,
        tradition: _selectedTradition,
      );

      setState(() {
        _matchResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Calculation failed: ${e.toString().replaceAll('Exception: ', '')}";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReport() async {
    if (_matchResult == null || _isSaved) return;

    try {
      await AstroApiService.saveMatchMakingReport(
        reportData: _matchResult!,
        userId: 'current_user',
      );
      setState(() => _isSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kundli Milan report saved successfully!"),
            backgroundColor: primaryRose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save report: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================================
  // DATE & TIME PICKERS
  // =========================================================================

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime(1995, 1, 1);
    if (controller.text.isNotEmpty) {
      try {
        initial = DateFormat('yyyy-MM-dd').parse(controller.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final dark = isDark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: dark
                ? const ColorScheme.dark(
                    primary: primaryRose,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: primaryRose,
                    onPrimary: Colors.white,
                    onSurface: darkText,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay initial = const TimeOfDay(hour: 12, minute: 0);
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      if (parts.length >= 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 12,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final dark = isDark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: dark
                ? const ColorScheme.dark(
                    primary: primaryRose,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: primaryRose,
                    onPrimary: Colors.white,
                    onSurface: darkText,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        controller.text = '$h:$m';
      });
    }
  }

  // =========================================================================
  // BUILD METHOD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark;
    return Scaffold(
      backgroundColor: _scaffoldBg(dark),
      appBar: AppBar(
        title: Text(
          'Match Making / Kundli Milan',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: dark ? _scaffoldBg(dark) : primaryRose,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_matchResult != null)
            IconButton(
              icon: Icon(
                _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: Colors.white,
              ),
              onPressed: _saveReport,
              tooltip: 'Save Report',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBanner(),
              SizedBox(height: 16.h),
              if (_matchResult == null) ...[
                _buildTraditionSelector(),
                SizedBox(height: 16.h),
                _buildPersonCard(
                  title: "Groom's Birth Details (Person A)",
                  icon: Icons.male_rounded,
                  accentColor: const Color(0xFF2563EB),
                  nameController: _boyNameController,
                  dobController: _boyDobController,
                  tobController: _boyTobController,
                  placeController: _boyPlaceController,
                  timeUnknown: _boyTimeUnknown,
                  onTimeUnknownChanged: (val) => setState(() => _boyTimeUnknown = val),
                ),
                SizedBox(height: 16.h),
                _buildPersonCard(
                  title: "Bride's Birth Details (Person B)",
                  icon: Icons.female_rounded,
                  accentColor: _accentRose(dark),
                  nameController: _girlNameController,
                  dobController: _girlDobController,
                  tobController: _girlTobController,
                  placeController: _girlPlaceController,
                  timeUnknown: _girlTimeUnknown,
                  onTimeUnknownChanged: (val) => setState(() => _girlTimeUnknown = val),
                ),
                SizedBox(height: 24.h),
                if (_errorMessage != null) _buildErrorBanner(),
                _buildCalculateButton(),
              ] else ...[
                _buildScoreSummaryCard(),
                SizedBox(height: 16.h),
                _buildResultsTabBar(),
                SizedBox(height: 16.h),
                _buildActiveTabContent(),
                SizedBox(height: 20.h),
                _buildActionButtons(),
              ],
              SizedBox(height: 24.h),
              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET BUILDERS: INPUT SECTION
  // =========================================================================

  Widget _buildHeaderBanner() {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF4C0519), const Color(0xFF1E293B)]
              : [primaryRose, deepRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: dark ? const Color(0xFF881337).withValues(alpha: 0.5) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? const Color(0xFF4C0519) : primaryRose).withValues(alpha: dark ? 0.35 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF881337).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: dark ? const Color(0xFFFDA4AF) : Colors.white, size: 28.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vedic Vivah Horoscope Matching',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'High-precision ephemeris calculation of 36 Gunas, South Indian Poruthams, and Manglik Dosha.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionSelector() {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _borderCol(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matching Tradition',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: _bodyText(dark),
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildTraditionChip('both', 'Comprehensive (All Factors)', Icons.auto_awesome_rounded),
              _buildTraditionChip('ashta_koota', 'Ashta Koota (36 Gunas)', Icons.stars_rounded),
              _buildTraditionChip('porutham', 'South Indian (10 Poruthams)', Icons.temple_hindu_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionChip(String value, String label, IconData icon) {
    final bool dark = isDark;
    final isSelected = _selectedTradition == value;
    return InkWell(
      onTap: () => setState(() => _selectedTradition = value),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? _primaryRed(dark) : _softRoseDark(dark),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? (dark ? const Color(0xFFBE123C) : _deepRed(dark)) : _borderCol(dark),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : _accentRose(dark),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : _bodyText(dark),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required TextEditingController nameController,
    required TextEditingController dobController,
    required TextEditingController tobController,
    required TextEditingController placeController,
    required bool timeUnknown,
    required ValueChanged<bool> onTimeUnknownChanged,
  }) {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _borderCol(dark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: _bodyText(dark),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Name field
          TextField(
            controller: nameController,
            style: GoogleFonts.outfit(color: _bodyText(dark), fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'Name (Optional)',
              hintText: 'Enter name',
              hintStyle: GoogleFonts.outfit(color: mutedText.withValues(alpha: 0.6), fontSize: 13.sp),
              labelStyle: GoogleFonts.outfit(color: mutedText, fontSize: 13.sp),
              prefixIcon: Icon(Icons.person_outline_rounded, color: accentColor, size: 20.sp),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          // DOB field
          InkWell(
            onTap: () => _pickDate(dobController),
            child: IgnorePointer(
              child: TextField(
                controller: dobController,
                style: GoogleFonts.outfit(color: _bodyText(dark), fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)*',
                  hintText: 'Select date of birth',
                  hintStyle: GoogleFonts.outfit(color: mutedText.withValues(alpha: 0.6), fontSize: 13.sp),
                  labelStyle: GoogleFonts.outfit(color: mutedText, fontSize: 13.sp),
                  prefixIcon: Icon(Icons.calendar_month_outlined, color: accentColor, size: 20.sp),
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: mutedText),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // TOB field
          if (!timeUnknown)
            InkWell(
              onTap: () => _pickTime(tobController),
              child: IgnorePointer(
                child: TextField(
                  controller: tobController,
                  style: GoogleFonts.outfit(color: _bodyText(dark), fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Time of Birth (HH:MM)*',
                    hintText: 'Select time of birth',
                    hintStyle: GoogleFonts.outfit(color: mutedText.withValues(alpha: 0.6), fontSize: 13.sp),
                    labelStyle: GoogleFonts.outfit(color: mutedText, fontSize: 13.sp),
                    prefixIcon: Icon(Icons.access_time_rounded, color: accentColor, size: 20.sp),
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                ),
              ),
            ),
          // Birth Time Unknown Checkbox
          Row(
            children: [
              Checkbox(
                value: timeUnknown,
                activeColor: accentColor,
                onChanged: (val) => onTimeUnknownChanged(val ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTimeUnknownChanged(!timeUnknown),
                  child: Text(
                    'Exact birth time is unknown (Flags Lagna as unavailable)',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: _bodyText(dark),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Birth Place field with net-based location selector (like Horoscope section)
          TextField(
            controller: placeController,
            readOnly: false,
            style: GoogleFonts.outfit(color: _bodyText(dark), fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'Birth Place (City)*',
              hintText: 'e.g. Chennai, Mumbai, London',
              hintStyle: GoogleFonts.outfit(color: mutedText.withValues(alpha: 0.6), fontSize: 13.sp),
              labelStyle: GoogleFonts.outfit(color: mutedText, fontSize: 13.sp),
              prefixIcon: Icon(Icons.location_on_outlined, color: accentColor, size: 20.sp),
              suffixIcon: IconButton(
                icon: Icon(Icons.search_rounded, color: accentColor, size: 20.sp),
                tooltip: 'Search City Coordinates',
                onPressed: () => _showLocationSelector(placeController),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
            onTap: () => _showLocationSelector(placeController),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: const Color(0xFF991B1B), fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    final bool dark = isDark;
    return ElevatedButton(
      onPressed: _isLoading ? null : _calculateMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryRed(dark),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: 4,
        shadowColor: _primaryRed(dark).withValues(alpha: 0.4),
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Computing Real-Time Ephemeris...',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Calculate Kundli Match',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
    );
  }

  // =========================================================================
  // WIDGET BUILDERS: RESULTS SECTION
  // =========================================================================

  Widget _buildScoreSummaryCard() {
    final res = _matchResult!;
    final totalScore = res['total_score'] ?? 0.0;
    final maxScore = res['max_score'] ?? 36.0;
    final percentage = res['percentage'] ?? 0.0;
    final status = res['status'] ?? 'Calculated';
    final recommendation = res['recommendation'] ?? '';
    final boyName = res['boy_name'] ?? 'Groom';
    final girlName = res['girl_name'] ?? 'Bride';

    Color statusColor = successGreen;
    if (totalScore < 18.0) {
      statusColor = Colors.red;
    } else if (totalScore < 28.0) {
      statusColor = warningOrange;
    }

    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _borderCol(dark)),
        boxShadow: [
          BoxShadow(
            color: primaryRose.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$boyName & $girlName',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: _bodyText(dark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.split(' ')[0],
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Gauge / Radial Score
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF3B0A1A), const Color(0xFF1E293B)]
                    : [softRose, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _borderCol(dark)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$totalScore',
                      style: GoogleFonts.outfit(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w900,
                        color: primaryRose,
                      ),
                    ),
                    Text(
                      'Out of $maxScore Gunas',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 48.h, color: _borderCol(dark)),
                Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: GoogleFonts.outfit(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: _bodyText(dark),
                      ),
                    ),
                    Text(
                      'Compatibility Match',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            recommendation,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: _bodyText(dark).withValues(alpha: 0.85),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTabBar() {
    final bool dark = isDark;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _borderCol(dark)),
      ),
      child: TabBar(
        controller: _resultTabController,
        isScrollable: true,
        labelColor: _accentRose(dark),
        unselectedLabelColor: mutedText,
        indicatorColor: _accentRose(dark),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 13.sp),
        tabs: const [
          Tab(text: 'Ashta Koota (36)'),
          Tab(text: 'Porutham (10)'),
          Tab(text: 'Manglik Dosha'),
          Tab(text: 'Birth Profiles'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_resultTabController.index) {
      case 0:
        return _buildAshtaKootaView();
      case 1:
        return _buildPoruthamView();
      case 2:
        return _buildManglikView();
      case 3:
      default:
        return _buildProfilesView();
    }
  }

  // -------------------------------------------------------------
  // TAB 1: ASHTA KOOTA BREAKDOWN
  // -------------------------------------------------------------
  Widget _buildAshtaKootaView() {
    final kootas = (_matchResult!['kootas'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        ...kootas.map((k) {
          final name = k['koota_name'] ?? '';
          final maxP = (k['max_points'] as num?)?.toDouble() ?? 0.0;
          final obtP = (k['obtained_points'] as num?)?.toDouble() ?? 0.0;
          final boyAttr = k['boy_attribute'] ?? '';
          final girlAttr = k['girl_attribute'] ?? '';
          final isComp = k['is_compatible'] ?? false;
          final remarks = k['remarks'] ?? '';
          final desc = k['description'] ?? '';

          final ratio = maxP > 0 ? (obtP / maxP) : 0.0;
          final isParihara = remarks.toLowerCase().contains('cancelled') || remarks.toLowerCase().contains('parihara');

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: _cardBg(isDark),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isParihara ? goldAccent : (isComp ? const Color(0xFFBBF7D0) : _borderCol(isDark)),
                width: isParihara ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: _bodyText(isDark),
                            ),
                          ),
                          if (isParihara)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: goldAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Parihara (Cancelled)',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$obtP / $maxP Pts',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: obtP > 0 ? primaryRose : Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: mutedText,
                  ),
                ),
                SizedBox(height: 10.h),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: isDark ? const Color(0xFF334155) : softRose,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio == 1.0 ? successGreen : (ratio > 0 ? primaryRose : Colors.red),
                    ),
                    minHeight: 6.h,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: _subCardBg(isDark),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Groom Attribute',
                              style: GoogleFonts.outfit(fontSize: 10.sp, color: mutedText),
                            ),
                            Text(
                              boyAttr,
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: _bodyText(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: _subCardBg(isDark),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bride Attribute',
                              style: GoogleFonts.outfit(fontSize: 10.sp, color: mutedText),
                            ),
                            Text(
                              girlAttr,
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: _bodyText(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  remarks,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: _bodyText(isDark).withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: SOUTH INDIAN PORUTHAM (10 PORUTHAMS)
  // -------------------------------------------------------------
  Widget _buildPoruthamView() {
    final poruthamData = _matchResult!['south_indian_porutham'] as Map<String, dynamic>?;
    if (poruthamData == null) {
      return Center(
        child: Text(
          'Porutham matching was not calculated for this request.',
          style: GoogleFonts.outfit(color: mutedText),
        ),
      );
    }

    final satisfiedCount = poruthamData['satisfied_count'] ?? 0;
    final totalPoruthams = poruthamData['total_poruthams'] ?? 10;
    final list = (poruthamData['poruthams'] as List<dynamic>?) ?? [];
    final isRajjuGood = poruthamData['is_rajju_satisfied'] ?? true;
    final isVedhaGood = poruthamData['is_vedha_satisfied'] ?? true;

    return Column(
      children: [
        // Summary Header
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _cardBg(isDark),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _borderCol(isDark)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'South Indian Dasa Porutham',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: _bodyText(isDark),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$satisfiedCount / $totalPoruthams Satisfied',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: primaryRose,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildPoruthamStatusBadge(
                      'Rajju Porutham',
                      isRajjuGood ? 'Satisfied' : 'Rajju Dosha',
                      isRajjuGood,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildPoruthamStatusBadge(
                      'Vedha Porutham',
                      isVedhaGood ? 'Satisfied' : 'Vedha Dosha',
                      isVedhaGood,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // List of 10 Poruthams
        ...list.map((p) {
          final name = p['porutham_name'] ?? '';
          final isSat = p['is_satisfied'] ?? false;
          final status = p['status'] ?? '';
          final bVal = p['boy_value'] ?? '';
          final gVal = p['girl_value'] ?? '';
          final sig = p['significance'] ?? '';
          final exp = p['explanation'] ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: _cardBg(isDark),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isSat ? const Color(0xFFDCFCE7) : _borderCol(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: _bodyText(isDark),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isSat ? successGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isSat ? successGreen : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  sig,
                  style: GoogleFonts.outfit(fontSize: 11.sp, color: mutedText),
                ),
                SizedBox(height: 8.h),
                Text(
                  exp,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: _bodyText(isDark).withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Groom: $bVal  |  Bride: $gVal',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: _bodyText(isDark).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPoruthamStatusBadge(String title, String label, bool isGood) {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isGood
            ? (dark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4))
            : (dark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isGood ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 11.sp, color: mutedText)),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isGood ? successGreen : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: MANGLIK / KUJA DOSHA ANALYSIS
  // -------------------------------------------------------------
  Widget _buildManglikView() {
    final manglik = _matchResult!['manglik_analysis'] as Map<String, dynamic>?;
    if (manglik == null) {
      return Center(
        child: Text('Manglik analysis unavailable', style: GoogleFonts.outfit(color: mutedText)),
      );
    }

    final isMatch = manglik['is_manglik_match'] ?? false;
    final verdict = manglik['verdict'] ?? '';
    final boyStatus = manglik['boy_status'] ?? '';
    final boyDetails = manglik['boy_details'] ?? '';
    final girlStatus = manglik['girl_status'] ?? '';
    final girlDetails = manglik['girl_details'] ?? '';

    final remedies = (_matchResult!['remedies'] as List<dynamic>?) ?? [];

    final bool dark = isDark;
    return Column(
      children: [
        // Compatibility Verdict
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _cardBg(dark),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isMatch ? const Color(0xFFBBF7D0) : _borderCol(dark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isMatch ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: isMatch ? successGreen : warningOrange,
                    size: 24.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Manglik / Kuja Dosha Compatibility',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: _bodyText(dark),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                verdict,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  color: _bodyText(dark).withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Groom & Bride Status Cards
        _buildManglikPersonStatus("Groom's Manglik Status", boyStatus, boyDetails, const Color(0xFF2563EB)),
        SizedBox(height: 10.h),
        _buildManglikPersonStatus("Bride's Manglik Status", girlStatus, girlDetails, primaryRose),
        SizedBox(height: 16.h),
        // Remedies Card
        if (remedies.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D1B00) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFFB45309)),
                    SizedBox(width: 8.w),
                    Text(
                      'Recommended Shastric Remedies',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                ...remedies.map((rem) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: const Color(0xFFB45309), fontSize: 16.sp)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 12.sp, color: _bodyText(isDark)),
                              children: [
                                TextSpan(
                                  text: '${rem['type']}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: rem['recommendation']),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManglikPersonStatus(String title, String status, String details, Color accent) {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _borderCol(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: _bodyText(dark),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            details,
            style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText, height: 1.3),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: PLANETARY / BIRTH PROFILES
  // -------------------------------------------------------------
  Widget _buildProfilesView() {
    final profiles = _matchResult!['profiles'] as Map<String, dynamic>?;
    if (profiles == null) {
      return Center(
        child: Text('Profiles unavailable', style: GoogleFonts.outfit(color: mutedText)),
      );
    }

    final boy = profiles['boy'] as Map<String, dynamic>? ?? {};
    final girl = profiles['girl'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _buildProfileCard("Groom's Astrological Profile", boy, const Color(0xFF2563EB)),
        SizedBox(height: 14.h),
        _buildProfileCard("Bride's Astrological Profile", girl, primaryRose),
      ],
    );
  }

  Widget _buildProfileCard(String title, Map<String, dynamic> data, Color accent) {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(dark),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _borderCol(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_moon_outlined, color: accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: _bodyText(dark),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildProfileRow('Moon Sign (Rashi)', '${data['moon_sign']} (Lord: ${data['moon_lord']})'),
          _buildProfileRow('Birth Nakshatra', '${data['nakshatra']} (Pada ${data['nakshatra_pada']})'),
          _buildProfileRow('Ascendant (Lagna)', '${data['ascendant']}'),
          _buildProfileRow('Mars (Mangal) Sign', '${data['mars_sign']}'),
          _buildProfileRow('Varna & Vashya', '${data['varna']}  |  ${data['vashya']}'),
          _buildProfileRow('Gana & Yoni', '${data['gana']}  |  ${data['yoni']}'),
          _buildProfileRow('Nadi & Rajju', '${data['nadi']}  |  ${data['rajju']}'),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _bodyText(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ACTIONS & DISCLAIMER
  // =========================================================================

  Widget _buildActionButtons() {
    final bool dark = isDark;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _matchResult = null),
            icon: Icon(Icons.refresh_rounded, color: _accentRose(dark)),
            label: Text(
              'Recalculate / Modify',
              style: GoogleFonts.outfit(
                color: _accentRose(dark),
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: BorderSide(color: _primaryRed(dark)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveReport,
            icon: Icon(
              _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
              size: 18.sp,
            ),
            label: Text(
              _isSaved ? 'Saved' : 'Save Report',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed(dark),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    final bool dark = isDark;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _disclaimerBg(dark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _disclaimerBorder(dark)),
      ),
      child: Text(
        'Traditional Shastric Disclaimer: This matching analysis is calculated from classical Vedic scriptures (Brihat Parashara Hora Shastra, Muhurta Chintamani, and South Indian Dasa Porutham). It serves as an advisory astrological tool and should be considered alongside mutual understanding, emotional maturity, shared values, and reciprocal love.',
        style: GoogleFonts.outfit(
          fontSize: 11.sp,
          color: mutedText,
          height: 1.4,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}

// =============================================================================
// LOCATION SELECTOR SHEET (Direct network-based search from Horoscope section)
// =============================================================================

class _LocationSelectorSheet extends StatefulWidget {
  final Function(Map<String, String> city) onSelect;

  const _LocationSelectorSheet({required this.onSelect});

  @override
  State<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<_LocationSelectorSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<Map<String, String>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchPlaces('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await AstroApiService.getPlaces(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaces(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Select Location',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : darkText,
            ),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: GoogleFonts.outfit(color: dark ? Colors.white : darkText, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Search for a city (e.g. Chennai, Mumbai)...',
              hintStyle: GoogleFonts.outfit(color: mutedText, fontSize: 13.sp),
              prefixIcon: const Icon(Icons.search, color: primaryRose),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _fetchPlaces('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: dark ? const Color(0xFF3B0A1A) : const Color(0xFFFFF1F2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
            ),
            onChanged: _onSearchChanged,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: primaryRose))
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_rounded, size: 40.sp, color: Colors.grey),
                            SizedBox(height: 8.h),
                            Text(
                              'No matching locations found',
                              style: GoogleFonts.outfit(fontSize: 14.sp, color: (dark ? Colors.white : darkText).withValues(alpha: 0.7)),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'You can also type your city directly in the form.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 12.sp, color: mutedText),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final city = _searchResults[index];
                          final cityName = city['city'] ?? 'Unknown';
                          return ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: primaryRose.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.location_on, color: primaryRose, size: 18.sp),
                            ),
                            title: Text(
                              cityName,
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : darkText,
                              ),
                            ),
                            subtitle: Text(
                              '${city['coords']} • ${city['tz']}',
                              style: GoogleFonts.outfit(fontSize: 11.sp, color: mutedText),
                            ),
                            onTap: () {
                              widget.onSelect(city);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

