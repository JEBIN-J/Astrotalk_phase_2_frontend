import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/astro_api_service.dart';

class NumerologyDashboardScreen extends StatefulWidget {
  const NumerologyDashboardScreen({super.key});

  @override
  State<NumerologyDashboardScreen> createState() => _NumerologyDashboardScreenState();
}

class _NumerologyDashboardScreenState extends State<NumerologyDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  late AnimationController _animController;

  final TextEditingController _nameController = TextEditingController(text: "Steve Jobs");
  final TextEditingController _dobController = TextEditingController(text: "1955-02-24");
  String _system = 'pythagorean';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fetchNumerology(); // fetch on init for wow effect
  }

  @override
  void dispose() {
    _animController.dispose();
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
      setState(() {
        _profileData = res['data'];
      });
      _animController.forward();
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildResultCard(String title, String value, String subtitle, List<Color> gradient) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: gradient[0].withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  width: 65.w,
                  height: 65.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: gradient[0], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_profileData == null) return const SizedBox();
    
    final sys = _profileData!['system'] as String?;
    
    List<Widget> cards = [];
    if (sys == 'vedic') {
      final mulank = _profileData!['mulank'];
      if(mulank != null) cards.add(_buildResultCard('Mulank (Driver)', '${mulank['reduced']}', 'Planet Ruler: ${mulank['planet'] ?? 'Unknown'}', [const Color(0xFFF59E0B), const Color(0xFFD97706)]));
      
      final bhagyank = _profileData!['bhagyank'];
      if(bhagyank != null) cards.add(_buildResultCard('Bhagyank (Destiny)', '${bhagyank['reduced']}', 'Planet Ruler: ${bhagyank['planet'] ?? 'Unknown'}', [const Color(0xFF6366F1), const Color(0xFF4338CA)]));
      
      final namank = _profileData!['namank'];
      if(namank != null) cards.add(_buildResultCard('Namank (Name No.)', '${namank['reduced']}', 'Compound Value: ${namank['compound_total']}', [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]));
      
      final rel = _profileData!['relationship'];
      if(rel != null) cards.add(_buildResultCard('Driver-Destiny Sync', 'Sync', rel['value'], [const Color(0xFFEC4899), const Color(0xFFDB2777)]));

      final loshu = _profileData!['lo_shu_grid'];
      if(loshu != null) {
          int missingCount = (loshu['missing'] as List).length;
          cards.add(_buildResultCard('Lo Shu Grid', 'Grid', '$missingCount Missing Digits Detected', [const Color(0xFF14B8A6), const Color(0xFF0F766E)]));
      }

    } else {
      final lp = _profileData!['life_path'];
      if(lp != null) cards.add(_buildResultCard('Life Path', '${lp['reduced']}', 'Calculation: ${lp['calculation'] ?? ''}', [const Color(0xFF10B981), const Color(0xFF059669)]));
      
      final exp = _profileData!['expression'];
      if(exp != null) cards.add(_buildResultCard('Expression', '${exp['reduced']}', 'Compound Total: ${exp['compound_total']}', [const Color(0xFF3B82F6), const Color(0xFF2563EB)]));
      
      final su = _profileData!['soul_urge'];
      if(su != null) cards.add(_buildResultCard('Soul Urge', '${su['reduced']}', 'Vowel Summation: ${su['compound_total']}', [const Color(0xFFEC4899), const Color(0xFFDB2777)]));
      
      final pers = _profileData!['personality'];
      if(pers != null) cards.add(_buildResultCard('Personality', '${pers['reduced']}', 'Consonant Sum: ${pers['compound_total']}', [const Color(0xFF0EA5E9), const Color(0xFF0284C7)]));

      final py = _profileData!['personal_year'];
      if(py != null) cards.add(_buildResultCard('Personal Year', '${py['reduced']}', 'Year: ${py['year']}', [const Color(0xFFF59E0B), const Color(0xFFD97706)]));
    }

    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(color: const Color(0xFF4338CA).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF4338CA), size: 20),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Your Cosmic Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            ...cards,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Numerology', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32.r), bottomRight: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF94A3B8).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ]
              ),
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover Your Numbers', style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  SizedBox(height: 6.h),
                  Text('Enter your details to reveal your numerological blueprint.', style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF64748B))),
                  SizedBox(height: 24.h),
                  
                  // Inputs
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Full Name at Birth',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _dobController,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Date of Birth (YYYY-MM-DD)',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        prefixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _system,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        items: const [
                          DropdownMenuItem(value: 'pythagorean', child: Text('Pythagorean Numerology')),
                          DropdownMenuItem(value: 'vedic', child: Text('Vedic Numerology')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() {
                            _system = val;
                            _fetchNumerology();
                          });
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchNumerology,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 4,
                        shadowColor: const Color(0xFF4338CA).withValues(alpha: 0.4),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flare_rounded, size: 20),
                                SizedBox(width: 8.w),
                                Text('Reveal Numbers', style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
              child: _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }
}
