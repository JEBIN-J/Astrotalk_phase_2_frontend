import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import 'numerology_calculator_screen.dart';
import 'name_analysis_screen.dart';

class NumerologyDashboardScreen extends StatefulWidget {
  const NumerologyDashboardScreen({super.key});

  @override
  State<NumerologyDashboardScreen> createState() => _NumerologyDashboardScreenState();
}

class _NumerologyDashboardScreenState extends State<NumerologyDashboardScreen> {
  String _userName = '';
  String _userDob = '';
  String _userSystem = 'pythagorean';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('numerology_user_name') ?? '';
    final dob = prefs.getString('numerology_user_dob') ?? '';
    final system = prefs.getString('numerology_user_system') ?? 'pythagorean';

    setState(() {
      _userName = name;
      _userDob = dob;
      _userSystem = system;
    });

    // If first time entering and no details saved yet, prompt user immediately
    if (name.isEmpty || dob.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showProfileDialog(isFirstTime: true);
        }
      });
    }
  }

  Future<void> _saveUserProfile(String name, String dob, String system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numerology_user_name', name);
    await prefs.setString('numerology_user_dob', dob);
    await prefs.setString('numerology_user_system', system);

    setState(() {
      _userName = name;
      _userDob = dob;
      _userSystem = system;
    });
  }

  void _showProfileDialog({required bool isFirstTime}) {
    final nameController = TextEditingController(
      text: _userName.isNotEmpty ? _userName : (isFirstTime ? 'Steve Jobs' : ''),
    );
    final dobController = TextEditingController(
      text: _userDob.isNotEmpty ? _userDob : '1995-05-15',
    );
    String selectedSystem = _userSystem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
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
                    // Pull Indicator
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),

                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    isFirstTime ? Icons.auto_awesome_rounded : Icons.edit_rounded,
                                    color: const Color(0xFF2563EB),
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
                                      isFirstTime ? 'Enter Your Details' : 'Change Profile Details',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      'Personalize your numerological blueprint',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Always accessible Close Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.r),
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, size: 20.sp, color: const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Full Name Input
                    Text(
                      'FULL NAME',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded, color: const Color(0xFF2563EB), size: 20.sp),
                          hintText: 'e.g. Steve Jobs',
                          hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Date of Birth Input
                    Text(
                      'DATE OF BIRTH',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Material(
                      color: const Color(0xFFF8FAFD),
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
                            builder: (dateCtx, child) {
                              return Theme(
                                data: Theme.of(dateCtx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2563EB),
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF1E293B),
                                  ),
                                ),
                                child: child!,
                              );
                            },
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
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: const Color(0xFF2563EB), size: 20.sp),
                              SizedBox(width: 12.w),
                              Text(
                                dobController.text.isNotEmpty ? dobController.text : 'Select Date of Birth',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: dobController.text.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down_rounded, color: const Color(0xFF64748B), size: 24.sp),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Numerology System Selection
                    Text(
                      'NUMEROLOGY SYSTEM',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSystem,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF2563EB), size: 22.sp),
                          items: const [
                            DropdownMenuItem(
                              value: 'pythagorean',
                              child: Text('Pythagorean Numerology (Modern)'),
                            ),
                            DropdownMenuItem(
                              value: 'chaldean',
                              child: Text('Chaldean Numerology (Ancient Vedic)'),
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

                    // Save / Reveal Numbers Button with Material InkWell
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () {
                          // Always ensure valid values (never dead-end the user)
                          String name = nameController.text.trim();
                          if (name.isEmpty) {
                            name = 'Steve Jobs';
                          }
                          String dob = dobController.text.trim();
                          if (dob.isEmpty) {
                            dob = '1995-05-15';
                          }

                          _saveUserProfile(name, dob, selectedSystem);
                          Navigator.pop(sheetContext);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF2563EB),
                                duration: const Duration(seconds: 2),
                                content: Text(
                                  isFirstTime ? 'Welcome $name! Blueprint unlocked.' : 'Details updated successfully!',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
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
                                  isFirstTime ? 'Save & Reveal Numbers' : 'Update Details',
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

                    if (isFirstTime) ...[
                      SizedBox(height: 10.h),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(
                            'Skip for now',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 6.h),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Safe Top Bar with user details & 3-line menu button to edit
            _buildTopBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "TODAY FOR YOU" Card with Blooming Lotus Mandala
                      _buildTodayForYouCard(context),
                      SizedBox(height: 20.h),

                      // "EXPLORE" Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXPLORE',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text(
                                  'See All',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Icon(Icons.arrow_forward_ios_rounded, size: 11.sp, color: const Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // 2x2 Explore Grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.w,
                          mainAxisSpacing: 14.h,
                          childAspectRatio: 0.82,
                        ),
                        children: [
                          _buildExploreCard(
                            context: context,
                            title: 'Numerology\nCalculator',
                            subtitle: 'Calculate your numerology report instantly.',
                            icon: Icons.calculate_rounded,
                            cardBg: const Color(0xFFF0F7FF),
                            borderColor: const Color(0xFFDBEAFE),
                            iconBg: const Color(0xFF3B82F6),
                            arrowBg: const Color(0xFFDBEAFE),
                            arrowColor: const Color(0xFF2563EB),
                            watermarkType: _WatermarkType.numbers,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NumerologyCalculatorScreen(
                                    initialName: _userName,
                                    initialDob: _userDob,
                                    initialSystem: _userSystem,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Name\nAnalysis',
                            subtitle: 'Deep Pythagorean & Chaldean name vibrations.',
                            icon: Icons.format_color_text_rounded,
                            cardBg: const Color(0xFFFEFCE8),
                            borderColor: const Color(0xFFFEF3C7),
                            iconBg: const Color(0xFFF59E0B),
                            arrowBg: const Color(0xFFFEF3C7),
                            arrowColor: const Color(0xFFD97706),
                            watermarkType: _WatermarkType.letters,
                            isNew: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NameAnalysisScreen(
                                    initialBirthName: _userName,
                                    initialSystem: _userSystem,
                                    dateOfBirth: _userDob,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Mobile\nNumber',
                            subtitle: 'The most advanced mobile number analysis.',
                            icon: Icons.phone_rounded,
                            cardBg: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFDCFCE7),
                            iconBg: const Color(0xFF22C55E),
                            arrowBg: const Color(0xFFDCFCE7),
                            arrowColor: const Color(0xFF16A34A),
                            watermarkType: _WatermarkType.phone,
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Child\nNumerology',
                            subtitle: 'Find the best dates for your child\'s birth and future.',
                            icon: Icons.child_care_rounded,
                            cardBg: const Color(0xFFFFFBEB),
                            borderColor: const Color(0xFFFEF3C7),
                            iconBg: const Color(0xFFF59E0B),
                            arrowBg: const Color(0xFFFEF3C7),
                            arrowColor: const Color(0xFFD97706),
                            watermarkType: _WatermarkType.baby,
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Advanced\nCompatibility',
                            subtitle: 'Check compatibility using DOB & numbers.',
                            icon: Icons.favorite_rounded,
                            cardBg: const Color(0xFFFAF5FF),
                            borderColor: const Color(0xFFF3E8FF),
                            iconBg: const Color(0xFFA855F7),
                            arrowBg: const Color(0xFFF3E8FF),
                            arrowColor: const Color(0xFF9333EA),
                            watermarkType: _WatermarkType.heart,
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Learn\nNumerology',
                            subtitle: 'Unlock and read expert guides to master numbers.',
                            icon: Icons.auto_stories_rounded,
                            cardBg: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFFEDD5),
                            iconBg: const Color(0xFFF97316),
                            arrowBg: const Color(0xFFFFEDD5),
                            arrowColor: const Color(0xFFEA580C),
                            watermarkType: _WatermarkType.book,
                          ),
                          _buildExploreCard(
                            context: context,
                            title: 'Angel\nNumbers',
                            subtitle: 'Discover the meaning of angel numbers and signs.',
                            icon: Icons.auto_awesome_rounded,
                            cardBg: const Color(0xFFF5F3FF),
                            borderColor: const Color(0xFFEDE9FE),
                            iconBg: const Color(0xFF6366F1),
                            arrowBg: const Color(0xFFEDE9FE),
                            arrowColor: const Color(0xFF4F46E5),
                            watermarkType: _WatermarkType.angel,
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Fully Responsive Top Bar (Cannot Overflow) ---
  Widget _buildTopBar(BuildContext context) {
    final canPop = Navigator.canPop(context);

    final displayName = _userName.isNotEmpty ? _userName : 'Welcome Back!';
    final greetingTitle = _userName.isNotEmpty ? 'Hello, $_userName' : 'Good Evening';

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      child: Row(
        children: [
          // Back button if screen was pushed
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B), size: 18.sp),
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Avatar Circle (Clicking also opens details editor)
          GestureDetector(
            onTap: () => _showProfileDialog(isFirstTime: false),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.person, color: const Color(0xFF2563EB), size: 22.sp),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // User title / subtitle (Expanded to avoid ANY overflow)
          Expanded(
            child: GestureDetector(
              onTap: () => _showProfileDialog(isFirstTime: false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greetingTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _userDob.isNotEmpty ? 'DOB: $_userDob' : displayName,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),


          // 3-Line Hamburger Menu Button (Click to change details)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => _showProfileDialog(isFirstTime: false),
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.menu_rounded, color: const Color(0xFF334155), size: 20.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- "TODAY FOR YOU" Card with Sacred Lotus Mandala ---
  Widget _buildTodayForYouCard(BuildContext context) {
    // Dynamically calculate today's personal/universal day vibration
    final now = DateTime.now();
    int dayVal = now.day;
    int monthVal = now.month;
    int yearVal = now.year;

    // If user has a valid DOB, calculate their Personal Day for today:
    // Personal Day = reduce(Personal Year + Current Month + Current Day)
    int personalDayNumber = 1;
    if (_userDob.isNotEmpty) {
      try {
        final parts = _userDob.split('-');
        if (parts.length == 3) {
          final bMonth = int.tryParse(parts[1]) ?? 1;
          final bDay = int.tryParse(parts[2]) ?? 1;

          int reduceN(int n) {
            while (n > 9) {
              int s = 0;
              for (final c in n.toString().split('')) {
                s += int.parse(c);
              }
              n = s;
            }
            return n;
          }

          final mRed = reduceN(bMonth);
          final dRed = reduceN(bDay);
          final yRed = reduceN(yearVal);
          final personalYear = reduceN(mRed + dRed + yRed);
          personalDayNumber = reduceN(personalYear + reduceN(monthVal) + reduceN(dayVal));
        }
      } catch (_) {
        personalDayNumber = 1;
      }
    } else {
      // Universal Day = reduce(current year + current month + current day)
      int reduceN(int n) {
        while (n > 9) {
          int s = 0;
          for (final c in n.toString().split('')) {
            s += int.parse(c);
          }
          n = s;
        }
        return n;
      }
      personalDayNumber = reduceN(reduceN(yearVal) + reduceN(monthVal) + reduceN(dayVal));
    }

    final dayThemes = {
      1: {"title": "A day to begin...", "desc": "A pioneering energy to plant new seeds and take the first bold step."},
      2: {"title": "A day for cooperation...", "desc": "Cultivate harmonious partnerships, quiet patience, and thoughtful listening."},
      3: {"title": "A day for creative joy...", "desc": "Express your ideas with vitality, communicate openly, and share inspiration."},
      4: {"title": "A day for grounded focus...", "desc": "Structure your goals, attend to practical foundations, and organize details."},
      5: {"title": "A day for exploration...", "desc": "Welcome dynamic movement, embrace versatility, and pivot as opportunities arise."},
      6: {"title": "A day for home & care...", "desc": "Nurture loved ones, restore domestic harmony, and extend supportive warmth."},
      7: {"title": "A day for quiet insight...", "desc": "Step back for mindful contemplation, study, and restorative inner reflection."},
      8: {"title": "A day for executive drive...", "desc": "Take decisive charge of practical benchmarks and manifest tangible progress."},
      9: {"title": "A day for completion...", "desc": "Release what has run its course and extend compassionate understanding."}
    };

    final dayTheme = dayThemes[personalDayNumber] ?? dayThemes[1]!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF5FE),
            Color(0xFFF9FBFE),
            Color(0xFFEEF6FE),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFDCE8F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF93C5FD).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blooming Sacred Lotus Mandala Painter
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: CustomPaint(
                painter: _BloomingLotusMandalaPainter(),
              ),
            ),
          ),

          // Foreground Content
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 14.w, 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big 3D/Gradient Calculated Day Number
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5B50EC), Color(0xFF3B82F6)],
                  ).createShader(bounds),
                  child: Text(
                    '$personalDayNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 66.sp,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Texts and Streak Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _userDob.isNotEmpty ? 'PERSONAL DAY $personalDayNumber' : 'UNIVERSAL DAY $personalDayNumber',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: const Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        dayTheme['title']!,
                        style: GoogleFonts.outfit(
                          fontSize: 17.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.only(right: 64.w),
                        child: Text(
                          dayTheme['desc']!,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 11.sp)),
                            SizedBox(width: 4.w),
                            Text(
                              '1-DAY STREAK',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Explore Card Builder ---
  Widget _buildExploreCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color iconBg,
    required Color arrowBg,
    required Color arrowColor,
    required _WatermarkType watermarkType,
    bool isNew = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Stack(
            children: [
              // Background Watermarks
              Positioned(
                right: 8.w,
                top: 8.h,
                child: _buildWatermark(watermarkType),
              ),

              // Card Foreground Content
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Icon Badge
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconBg.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 22.sp),
                      ),
                    ),
                    const Spacer(),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    // Bottom Row: NEW badge (if present) & Arrow Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isNew)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.outfit(
                                fontSize: 9.sp,
                                color: const Color(0xFF9333EA),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: arrowBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 15.sp,
                            color: arrowColor,
                          ),
                        ),
                      ],
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

  // --- Watermark builder for cards ---
  Widget _buildWatermark(_WatermarkType type) {
    switch (type) {
      case _WatermarkType.numbers:
        return Opacity(
          opacity: 0.22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text('3', style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6))),
                  SizedBox(width: 12.w),
                  Text('4', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
                ],
              ),
              Row(
                children: [
                  Text('7', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
                  SizedBox(width: 14.w),
                  Text('4', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6))),
                ],
              ),
            ],
          ),
        );
      case _WatermarkType.letters:
        return Opacity(
          opacity: 0.22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text('B', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFFD946EF))),
                ],
              ),
              Row(
                children: [
                  Text('A', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD946EF))),
                  SizedBox(width: 10.w),
                  Text('C', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFFD946EF))),
                ],
              ),
            ],
          ),
        );
      case _WatermarkType.phone:
        return Opacity(
          opacity: 0.22,
          child: Container(
            width: 36.w,
            height: 60.h,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF16A34A), width: 2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 12.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
        );
      case _WatermarkType.baby:
        return Opacity(
          opacity: 0.24,
          child: Icon(Icons.face_rounded, size: 54.sp, color: const Color(0xFFF59E0B)),
        );
      case _WatermarkType.heart:
        return Opacity(
          opacity: 0.22,
          child: Icon(Icons.favorite_rounded, size: 48.sp, color: const Color(0xFFA855F7)),
        );
      case _WatermarkType.book:
        return Opacity(
          opacity: 0.22,
          child: Icon(Icons.auto_stories_rounded, size: 48.sp, color: const Color(0xFFF97316)),
        );
      case _WatermarkType.angel:
        return Opacity(
          opacity: 0.22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('111', style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF6366F1))),
              Text('777', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF6366F1))),
            ],
          ),
        );
    }
  }
}

enum _WatermarkType { numbers, letters, phone, baby, heart, book, angel }

// --- Genuine Blooming Lotus Mandala Painter ---
class _BloomingLotusMandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 46.w, size.height * 0.55);

    // 1. Concentric Sacred Geometry Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 44.r, ringPaint);
    canvas.drawCircle(center, 64.r, ringPaint);
    canvas.drawCircle(center, 82.r, ringPaint);

    // Radiating Sacred Dots
    final dotPaint = Paint()..color = const Color(0xFF818CF8).withValues(alpha: 0.35);
    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final dx = center.dx + 74.r * math.cos(angle);
      final dy = center.dy + 74.r * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.3, dotPaint);
    }

    // 2. Floating Numerology Numbers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawNum(String text, Offset pos, double fontSize, Color color) {
      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.32),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos);
    }

    drawNum('3', Offset(center.dx - 12.w, center.dy - 68.h), 18.sp, const Color(0xFF3B82F6));
    drawNum('7', Offset(center.dx + 26.w, center.dy - 66.h), 18.sp, const Color(0xFF3B82F6));
    drawNum('5', Offset(center.dx - 55.w, center.dy - 25.h), 16.sp, const Color(0xFF818CF8));
    drawNum('9', Offset(center.dx + 38.w, center.dy + 15.h), 16.sp, const Color(0xFF818CF8));
    drawNum('8', Offset(center.dx - 40.w, center.dy + 42.h), 15.sp, const Color(0xFF3B82F6));

    // 3. Blooming Lotus Flower
    // Base lotus origin
    final lotusBase = Offset(center.dx, center.dy + 12.h);

    // Layer 1: Outermost Broad Blue/Violet Petals (Left & Right Wings)
    _drawLotusPetal(canvas, lotusBase, length: 44.r, width: 22.r, angle: -math.pi / 2 - 0.72, 
      colors: const [Color(0xFF67E8F9), Color(0xFF818CF8)], opacity: 0.65);
    _drawLotusPetal(canvas, lotusBase, length: 44.r, width: 22.r, angle: -math.pi / 2 + 0.72, 
      colors: const [Color(0xFF67E8F9), Color(0xFF818CF8)], opacity: 0.65);

    // Layer 2: Intermediate Violet/Pink Petals
    _drawLotusPetal(canvas, lotusBase, length: 46.r, width: 20.r, angle: -math.pi / 2 - 0.44, 
      colors: const [Color(0xFFC084FC), Color(0xFFF472B6)], opacity: 0.75);
    _drawLotusPetal(canvas, lotusBase, length: 46.r, width: 20.r, angle: -math.pi / 2 + 0.44, 
      colors: const [Color(0xFFC084FC), Color(0xFFF472B6)], opacity: 0.75);

    // Layer 3: Inner Petals
    _drawLotusPetal(canvas, lotusBase, length: 48.r, width: 18.r, angle: -math.pi / 2 - 0.20, 
      colors: const [Color(0xFFF472B6), Color(0xFFF9A8D4)], opacity: 0.85);
    _drawLotusPetal(canvas, lotusBase, length: 48.r, width: 18.r, angle: -math.pi / 2 + 0.20, 
      colors: const [Color(0xFFF472B6), Color(0xFFF9A8D4)], opacity: 0.85);

    // Layer 4: Center Lotus Crown Petal (Pointing Straight Up)
    _drawLotusPetal(canvas, lotusBase, length: 50.r, width: 19.r, angle: -math.pi / 2, 
      colors: const [Color(0xFF60A5FA), Color(0xFFC084FC), Color(0xFFF472B6)], opacity: 0.95);

    // Glowing Golden Base Core of Lotus
    final glowCore = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFEF08A),
          const Color(0xFFF59E0B),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: lotusBase, radius: 14.r));
    canvas.drawCircle(lotusBase, 12.r, glowCore);

    final coreSolid = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(lotusBase, 6.r, coreSolid);
  }

  // Draw organic, almond-shaped lotus petal
  void _drawLotusPetal(
    Canvas canvas,
    Offset base, {
    required double length,
    required double width,
    required double angle,
    required List<Color> colors,
    required double opacity,
  }) {
    final tip = Offset(base.dx + length * math.cos(angle), base.dy + length * math.sin(angle));
    final perpAngle = angle + math.pi / 2;

    // Control points for petal bulge
    final midLeft = Offset(
      base.dx + (length * 0.5) * math.cos(angle) + (width * 0.5) * math.cos(perpAngle),
      base.dy + (length * 0.5) * math.sin(angle) + (width * 0.5) * math.sin(perpAngle),
    );
    final midRight = Offset(
      base.dx + (length * 0.5) * math.cos(angle) - (width * 0.5) * math.cos(perpAngle),
      base.dy + (length * 0.5) * math.sin(angle) - (width * 0.5) * math.sin(perpAngle),
    );

    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(midLeft.dx, midLeft.dy, tip.dx, tip.dy);
    path.quadraticBezierTo(midRight.dx, midRight.dy, base.dx, base.dy);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: colors.map((c) => c.withValues(alpha: opacity)).toList(),
      ).createShader(Rect.fromPoints(base, tip))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Subtle edge highlight
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



