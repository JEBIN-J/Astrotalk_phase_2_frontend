import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';
import 'life_path_detail_screen.dart';
import 'birth_day_detail_screen.dart';
import 'personal_year_detail_screen.dart';
import 'name_analysis_screen.dart';
import 'personality_soul_screen.dart';
import 'missing_numbers_screen.dart';

class NumerologyCalculatorScreen extends StatefulWidget {
  final String? initialName;
  final String? initialDob;
  final String? initialSystem;

  const NumerologyCalculatorScreen({
    super.key,
    this.initialName,
    this.initialDob,
    this.initialSystem,
  });

  @override
  State<NumerologyCalculatorScreen> createState() => _NumerologyCalculatorScreenState();
}

enum _WatermarkType { numbers, letters, soul, gem, remedies, phone }

class _NumerologyCalculatorScreenState extends State<NumerologyCalculatorScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  late AnimationController _animController;

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late String _system;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.initialName != null && widget.initialName!.isNotEmpty)
          ? widget.initialName!
          : "",
    );
    _dobController = TextEditingController(
      text: (widget.initialDob != null && widget.initialDob!.isNotEmpty)
          ? widget.initialDob!
          : "",
    );
    _system = (widget.initialSystem != null && widget.initialSystem!.isNotEmpty)
        ? widget.initialSystem!
        : 'pythagorean';
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _initUserDataAndFetch();
  }

  Future<void> _initUserDataAndFetch() async {
    if (_nameController.text.isEmpty || _dobController.text.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('numerology_user_name');
      final savedDob = prefs.getString('numerology_user_dob');
      final savedSystem = prefs.getString('numerology_user_system');

      if (_nameController.text.isEmpty && savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      if (_dobController.text.isEmpty && savedDob != null && savedDob.isNotEmpty) {
        _dobController.text = savedDob;
      }
      if (savedSystem != null && savedSystem.isNotEmpty) {
        _system = savedSystem;
      }
    }

    if (_nameController.text.isEmpty) _nameController.text = "Seeker";
    if (_dobController.text.isEmpty) _dobController.text = "1998-12-13";

    if (mounted) {
      setState(() {});
      _fetchNumerology();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchNumerology() async {
    setState(() => _isLoading = true);
    _animController.reset();
    try {
      final res = await AstroApiService.getNumerologyProfile(
        name: _nameController.text,
        dateOfBirth: _dobController.text,
        system: _system,
      );
      if (res['data'] != null) {
        setState(() {
          _profileData = res['data'];
        });
      } else {
        _setFallbackProfile();
      }
      _animController.forward();
    } catch (_) {
      // In case of offline/network issues, gracefully generate valid profile calculations
      _setFallbackProfile();
      _animController.forward();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setFallbackProfile() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Seeker';
    final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1998-12-13';

    int birthDay = 13;
    int birthMonth = 12;
    int birthYear = 1998;
    try {
      final parts = dob.split('-');
      if (parts.length == 3) {
        birthYear = int.tryParse(parts[0]) ?? 1998;
        birthMonth = int.tryParse(parts[1]) ?? 12;
        birthDay = int.tryParse(parts[2]) ?? 13;
      }
    } catch (_) {}

    int reduceNumber(int n) {
      while (n > 9 && n != 11 && n != 22 && n != 33) {
        int sum = 0;
        for (final char in n.toString().split('')) {
          sum += int.parse(char);
        }
        n = sum;
      }
      return n;
    }

    final dayReduced = reduceNumber(birthDay);
    final monthReduced = reduceNumber(birthMonth);
    final yearReduced = reduceNumber(birthYear);
    final lifePath = reduceNumber(dayReduced + monthReduced + yearReduced);
    final currentYear = DateTime.now().year;
    final personalYear = reduceNumber(reduceNumber(currentYear) + monthReduced + dayReduced);

    const pythagoreanMap = {
      'a': 1, 'j': 1, 's': 1,
      'b': 2, 'k': 2, 't': 2,
      'c': 3, 'l': 3, 'u': 3,
      'd': 4, 'm': 4, 'v': 4,
      'e': 5, 'n': 5, 'w': 5,
      'f': 6, 'o': 6, 'x': 6,
      'g': 7, 'p': 7, 'y': 7,
      'h': 8, 'q': 8, 'z': 8,
      'i': 9, 'r': 9,
    };
    int nameSum = 0;
    for (final rune in name.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      if (pythagoreanMap.containsKey(char)) {
        nameSum += pythagoreanMap[char]!;
      }
    }
    final nameReduced = reduceNumber(nameSum > 0 ? nameSum : 7);

    setState(() {
      _profileData = {
        'system': _system,
        'life_path': {
          'reduced': lifePath,
          'calculation': '$birthDay + $birthMonth + $birthYear = $lifePath',
        },
        'birthday': {
          'original': birthDay,
          'reduced': dayReduced,
          'calculation': 'Day of birth $birthDay (Root $dayReduced)',
        },
        'personal_year': {
          'reduced': personalYear,
          'calculation': 'Year $currentYear cycle reduced to $personalYear',
        },
        'expression': {
          'reduced': nameReduced,
          'compound_total': nameSum,
          'breakdown': [],
        },
        'mulank': {
          'reduced': dayReduced,
          'calculation': 'Day of birth reduced to $dayReduced',
        },
        'bhagyank': {
          'reduced': lifePath,
          'calculation': 'Destiny path reduced to $lifePath',
        },
        'lo_shu_grid': {
          'reduced': lifePath,
          'grid': 'Complete cosmic Lo Shu mapping',
        },
      };
    });
  }

  void _showExplanationSheet(String title, Map<String, dynamic> data, bool isName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title Details', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              SizedBox(height: 16.h),
              if (isName && data['breakdown'] != null) ...[
                Text('Letter Breakdown:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12.r)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (data['breakdown'] as List).map<Widget>((wordData) {
                      final letters = (wordData['letters'] as List).map((l) => '${l['char']}(${l['value']})').join(' + ');
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text('${wordData['word'].toUpperCase()}: $letters = ${wordData['subtotal']}', style: GoogleFonts.inter(fontSize: 14.sp)),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12.h),
                Text('Compound Total: ${data['compound_total']}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ] else if (data['calculation'] != null) ...[
                Text('Formula Breakdown:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12.r)),
                  child: Text('${data['calculation']}', style: GoogleFonts.inter(fontSize: 16.sp)),
                ),
              ] else ...[
                Text('Raw Backend Data:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12.r)),
                  child: Text(data.toString(), style: GoogleFonts.inter(fontSize: 14.sp)),
                ),
              ],
              SizedBox(height: 16.h),
              Text('Final Reduced Number: ${data['reduced'] ?? 'N/A'}', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
              SizedBox(height: 30.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCosmicCard({
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
    String? valueBadge,
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
              Positioned(
                right: 8.w,
                top: 8.h,
                child: _buildWatermark(watermarkType),
              ),
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
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
                            child: Icon(icon, color: Colors.white, size: 20.sp),
                          ),
                        ),
                        if (valueBadge != null && valueBadge.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: iconBg.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              valueBadge,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: iconBg,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
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

  Widget _buildWatermark(_WatermarkType type) {
    switch (type) {
      case _WatermarkType.numbers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text('3', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF93C5FD).withValues(alpha: 0.28))),
                SizedBox(width: 8.w),
                Text('4', style: GoogleFonts.outfit(fontSize: 26.sp, fontWeight: FontWeight.w900, color: const Color(0xFF60A5FA).withValues(alpha: 0.32))),
              ],
            ),
            Row(
              children: [
                Text('7', style: GoogleFonts.outfit(fontSize: 26.sp, fontWeight: FontWeight.w900, color: const Color(0xFF93C5FD).withValues(alpha: 0.25))),
                SizedBox(width: 6.w),
                Text('4', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6).withValues(alpha: 0.22))),
              ],
            ),
          ],
        );
      case _WatermarkType.letters:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('B', style: GoogleFonts.outfit(fontSize: 28.sp, fontWeight: FontWeight.w900, color: const Color(0xFFF472B6).withValues(alpha: 0.28))),
            Row(
              children: [
                Text('A', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFFF472B6).withValues(alpha: 0.25))),
                SizedBox(width: 4.w),
                Text('C', style: GoogleFonts.outfit(fontSize: 26.sp, fontWeight: FontWeight.w900, color: const Color(0xFFEC4899).withValues(alpha: 0.3))),
              ],
            ),
          ],
        );
      case _WatermarkType.soul:
        return Icon(Icons.auto_awesome, size: 48.sp, color: const Color(0xFFC084FC).withValues(alpha: 0.22));
      case _WatermarkType.gem:
        return Icon(Icons.diamond_outlined, size: 48.sp, color: const Color(0xFF818CF8).withValues(alpha: 0.24));
      case _WatermarkType.remedies:
        return Icon(Icons.spa_outlined, size: 48.sp, color: const Color(0xFF34D399).withValues(alpha: 0.24));
      case _WatermarkType.phone:
        return Icon(Icons.phone_android_rounded, size: 48.sp, color: const Color(0xFF10B981).withValues(alpha: 0.2));
    }
  }

  Widget _buildWideReportCard() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Full Report... (Coming Soon)')));
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 16.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF93C5FD).withValues(alpha: 0.25),
              blurRadius: 12,
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
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'COMPLETE REPORT',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 4.w),
                Text(
                  '4.6',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Your Complete Numerology Blueprint',
              style: GoogleFonts.outfit(
                fontSize: 17.5.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Name fixes, remedies, a 5-year forecast & more — all in one report.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF475569),
                height: 1.3,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 13.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Get My Numerology Blueprint',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_profileData == null) return const SizedBox();

    final sys = _profileData!['system'] as String?;
    final bool isVedic = sys == 'vedic';

    List<Widget> gridItems = [];

    // Core Calculated Mappings with Exact Image 1 Color Palette
    if (isVedic) {
      final mulankVal = _profileData!['mulank']?['reduced']?.toString();
      final bhagyankVal = _profileData!['bhagyank']?['reduced']?.toString();
      final loShuVal = _profileData!['lo_shu_grid']?['reduced']?.toString();

      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Mulank\n(Driver)',
        subtitle: 'Your core nature.',
        icon: Icons.person_rounded,
        cardBg: const Color(0xFFF0F7FF),
        borderColor: const Color(0xFFDBEAFE),
        iconBg: const Color(0xFF3B82F6),
        arrowBg: const Color(0xFFDBEAFE),
        arrowColor: const Color(0xFF2563EB),
        watermarkType: _WatermarkType.numbers,
        valueBadge: mulankVal != null ? 'No. $mulankVal' : null,
        onTap: () => _showExplanationSheet('Mulank', _profileData!['mulank'], false),
      ));
      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Bhagyank\n(Destiny)',
        subtitle: 'Your destiny path.',
        icon: Icons.alt_route_rounded,
        cardBg: const Color(0xFFFDF2F8),
        borderColor: const Color(0xFFFCE7F3),
        iconBg: const Color(0xFFEC4899),
        arrowBg: const Color(0xFFFCE7F3),
        arrowColor: const Color(0xFFDB2777),
        watermarkType: _WatermarkType.letters,
        valueBadge: bhagyankVal != null ? 'No. $bhagyankVal' : null,
        onTap: () => _showExplanationSheet('Bhagyank', _profileData!['bhagyank'], false),
      ));
      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Lo Shu\nGrid',
        subtitle: 'Lo Shu breakdown.',
        icon: Icons.grid_3x3_rounded,
        cardBg: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFDCFCE7),
        iconBg: const Color(0xFF10B981),
        arrowBg: const Color(0xFFDCFCE7),
        arrowColor: const Color(0xFF059669),
        watermarkType: _WatermarkType.remedies,
        valueBadge: loShuVal != null ? 'Grid $loShuVal' : null,
        onTap: () => _showExplanationSheet('Lo Shu Grid', _profileData!['lo_shu_grid'], false),
      ));
    } else {
      final lpVal = _profileData!['life_path']?['reduced']?.toString();
      final bdVal = _profileData!['birthday']?['original']?.toString() ?? 
                    _profileData!['birthday']?['reduced']?.toString();
      final pyVal = _profileData!['personal_year']?['reduced']?.toString();

      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Life Path\nNumber',
        subtitle: 'The single number that shapes you.',
        icon: Icons.timeline_rounded,
        cardBg: const Color(0xFFF0F7FF),
        borderColor: const Color(0xFFDBEAFE),
        iconBg: const Color(0xFF3B82F6),
        arrowBg: const Color(0xFFDBEAFE),
        arrowColor: const Color(0xFF2563EB),
        watermarkType: _WatermarkType.numbers,
        valueBadge: lpVal != null ? 'No. $lpVal' : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LifePathDetailScreen(
                dateOfBirth: _dobController.text,
                userName: _nameController.text,
                system: _system,
              ),
            ),
          );
        },
      ));
      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Birth Day\nNumber',
        subtitle: 'Hidden influence of your day.',
        icon: Icons.wb_sunny_rounded,
        cardBg: const Color(0xFFFDF2F8),
        borderColor: const Color(0xFFFCE7F3),
        iconBg: const Color(0xFFEC4899),
        arrowBg: const Color(0xFFFCE7F3),
        arrowColor: const Color(0xFFDB2777),
        watermarkType: _WatermarkType.letters,
        valueBadge: bdVal != null ? 'No. $bdVal' : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BirthDayDetailScreen(
                dateOfBirth: _dobController.text,
                userName: _nameController.text,
                system: _system,
              ),
            ),
          );
        },
      ));
      gridItems.add(_buildCosmicCard(
        context: context,
        title: 'Personal\nYear',
        subtitle: 'What this year is asking of you.',
        icon: Icons.calendar_month_rounded,
        cardBg: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFDCFCE7),
        iconBg: const Color(0xFF10B981),
        arrowBg: const Color(0xFFDCFCE7),
        arrowColor: const Color(0xFF059669),
        watermarkType: _WatermarkType.remedies,
        valueBadge: pyVal != null ? 'Year $pyVal' : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalYearDetailScreen(
                dateOfBirth: _dobController.text,
                userName: _nameController.text,
                system: _system,
              ),
            ),
          );
        },
      ));
    }

    final nameVal = (_profileData!['namank']?['reduced'] ?? _profileData!['expression']?['reduced'])?.toString();
    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Name\nAnalysis',
      subtitle: 'What your name reveals.',
      icon: Icons.format_color_text_rounded,
      cardBg: const Color(0xFFFEFCE8),
      borderColor: const Color(0xFFFEF3C7),
      iconBg: const Color(0xFFF59E0B),
      arrowBg: const Color(0xFFFEF3C7),
      arrowColor: const Color(0xFFD97706),
      watermarkType: _WatermarkType.letters,
      valueBadge: nameVal != null ? 'No. $nameVal' : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NameAnalysisScreen(
              initialBirthName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
              initialSystem: _system,
              dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
            ),
          ),
        );
      },
    ));

    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Personality\n& Soul',
      subtitle: 'The self you project.',
      icon: Icons.join_inner_rounded,
      cardBg: const Color(0xFFFAF5FF),
      borderColor: const Color(0xFFF3E8FF),
      iconBg: const Color(0xFF8B5CF6),
      arrowBg: const Color(0xFFF3E8FF),
      arrowColor: const Color(0xFF7C3AED),
      watermarkType: _WatermarkType.soul,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalitySoulScreen(
              initialBirthName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
            ),
          ),
        );
      },
    ));

    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Missing\nNumbers',
      subtitle: 'Numbers your chart lacks.',
      icon: Icons.border_clear_rounded,
      cardBg: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFFEDD5),
      iconBg: const Color(0xFFF97316),
      arrowBg: const Color(0xFFFFEDD5),
      arrowColor: const Color(0xFFEA580C),
      watermarkType: _WatermarkType.numbers,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissingNumbersScreen(
              initialBirthName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
            ),
          ),
        );
      },
    ));

    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Remedies\n& Fixes',
      subtitle: 'Simple fixes for balance.',
      icon: Icons.healing_rounded,
      cardBg: const Color(0xFFF0FDFA),
      borderColor: const Color(0xFFCCFBF1),
      iconBg: const Color(0xFF14B8A6),
      arrowBg: const Color(0xFFCCFBF1),
      arrowColor: const Color(0xFF0D9488),
      watermarkType: _WatermarkType.remedies,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remedies module'))),
    ));

    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Crystal\nMatch',
      subtitle: 'Stones chosen for numbers.',
      icon: Icons.diamond_rounded,
      cardBg: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFEDE9FE),
      iconBg: const Color(0xFF6366F1),
      arrowBg: const Color(0xFFEDE9FE),
      arrowColor: const Color(0xFF4F46E5),
      watermarkType: _WatermarkType.gem,
      isNew: true,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crystal match module'))),
    ));

    gridItems.add(_buildCosmicCard(
      context: context,
      title: 'Phone\nAnalysis',
      subtitle: 'Vibration of your phone.',
      icon: Icons.phone_android_rounded,
      cardBg: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      iconBg: const Color(0xFF059669),
      arrowBg: const Color(0xFFA7F3D0),
      arrowColor: const Color(0xFF047857),
      watermarkType: _WatermarkType.phone,
      isNew: true,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone vibration module'))),
    ));

    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Explore Section from Image 1
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR COSMIC PROFILE',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Row(
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
                ],
              ),
              SizedBox(height: 14.h),

              // 2x2 Grid of First Two Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 0.82,
                ),
                itemCount: 2,
                itemBuilder: (context, index) => gridItems[index],
              ),

              // Light Luxury Complete Report Card
              _buildWideReportCard(),

              // Remaining Cards in 2x2 Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 0.82,
                ),
                itemCount: gridItems.length - 2,
                itemBuilder: (context, index) => gridItems[index + 2],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Seeker';
    final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1998-12-13';
    final String systemTitle = _system == 'vedic'
        ? 'Vedic'
        : (_system == 'chaldean' ? 'Chaldean' : 'Pythagorean');

    final String lpNumber = (_profileData?['life_path']?['reduced'] ?? 
                             _profileData?['mulank']?['reduced'] ?? 
                             '7').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LifePathDetailScreen(
              dateOfBirth: _dobController.text,
              userName: _nameController.text,
              system: _system,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 14.h),
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
              color: const Color(0xFF93C5FD).withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            children: [
              // Celestial orbit background watermark
              Positioned(
                right: -10.w,
                top: -10.h,
                child: Opacity(
                  opacity: 0.35,
                  child: SizedBox(
                    width: 140.w,
                    height: 140.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110.w,
                          height: 110.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                          ),
                        ),
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC084FC), width: 1),
                          ),
                        ),
                        Positioned(
                          top: 15.h,
                          right: 35.w,
                          child: Text('3', style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
                        ),
                        Positioned(
                          bottom: 25.h,
                          left: 20.w,
                          child: Text('5', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6))),
                        ),
                        Positioned(
                          bottom: 12.h,
                          right: 25.w,
                          child: Text('8', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big 3D Gradient Number (like the "1" in Image 1)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF5B50EC), Color(0xFF3B82F6)],
                      ).createShader(bounds),
                      child: Text(
                        lpNumber,
                        style: GoogleFonts.outfit(
                          fontSize: 52.sp,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Middle details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'COSMIC BLUEPRINT',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5.sp,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'DOB: $dob • $systemTitle',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
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
                                Text('✨', style: TextStyle(fontSize: 10.sp)),
                                SizedBox(width: 4.w),
                                Text(
                                  'LIFE PATH $lpNumber ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right action arrow/edit button
                    Container(
                      width: 30.w,
                      height: 30.w,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final editNameCtrl = TextEditingController(text: _nameController.text);
    final editDobCtrl = TextEditingController(text: _dobController.text);
    String editSystem = _system;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    TextField(
                      controller: editNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    GestureDetector(
                      onTap: () async {
                        DateTime initialDate = DateTime(1998, 12, 13);
                        try {
                          initialDate = DateFormat('yyyy-MM-dd').parse(editDobCtrl.text);
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
                            editDobCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B)),
                            SizedBox(width: 12.w),
                            Text(
                              editDobCtrl.text.isNotEmpty ? editDobCtrl.text : 'Select Date of Birth',
                              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    DropdownButtonFormField<String>(
                      initialValue: editSystem,
                      decoration: InputDecoration(
                        labelText: 'Numerology System',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pythagorean', child: Text('Pythagorean Numerology')),
                        DropdownMenuItem(value: 'vedic', child: Text('Vedic Numerology')),
                        DropdownMenuItem(value: 'chaldean', child: Text('Chaldean Numerology')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => editSystem = val);
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        onPressed: () async {
                          final newName = editNameCtrl.text.trim();
                          final newDob = editDobCtrl.text.trim();
                          if (newName.isNotEmpty) _nameController.text = newName;
                          if (newDob.isNotEmpty) _dobController.text = newDob;
                          _system = editSystem;

                          Navigator.pop(sheetContext);

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('numerology_user_name', _nameController.text);
                          await prefs.setString('numerology_user_dob', _dobController.text);
                          await prefs.setString('numerology_user_system', _system);

                          if (mounted) {
                            setState(() {});
                            _fetchNumerology();
                          }
                        },
                        child: Text(
                          'Update & Recalculate',
                          style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B), size: 19.sp),
                    ),
                  ),
                ),
                Text(
                  'Numerology',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: _showEditProfileSheet,
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.tune_rounded, color: const Color(0xFF334155), size: 18.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Profile Card
            _buildProfileHeader(),

            // Loading Indicator or Results
            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF4338CA)),
                      SizedBox(height: 16.h),
                      Text(
                        'Calculating your cosmic blueprint...',
                        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildResultsView(),
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
