import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/astro_api_service.dart';

class NumerologyCalculatorScreen extends StatefulWidget {
  const NumerologyCalculatorScreen({super.key});

  @override
  State<NumerologyCalculatorScreen> createState() => _NumerologyCalculatorScreenState();
}

class _NumerologyCalculatorScreenState extends State<NumerologyCalculatorScreen> with SingleTickerProviderStateMixin {
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

  Widget _buildResultCard(String title, String value, String subtitle, List<Color> gradient, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
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

  Widget _buildGridCard(String title, String subtitle, IconData icon, {VoidCallback? onTap, bool isNew = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24), // Dark sleek
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFF333344)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: const Color(0xFF818CF8), size: 24.sp),
                ),
                if (isNew)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: const Color(0xFF312E81), borderRadius: BorderRadius.circular(12.r)),
                    child: Text('NEW', style: GoogleFonts.outfit(fontSize: 10.sp, color: const Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Spacer(),
            Text(title, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 4.h),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildWideReportCard() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Full Report... (Coming Soon)')));
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            colors: [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(color: const Color(0xFF818CF8).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12.r)),
                  child: Text('COMPLETE REPORT', style: GoogleFonts.outfit(fontSize: 12.sp, color: const Color(0xFFC7D2FE), fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                Spacer(),
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                SizedBox(width: 4.w),
                Text('4.6', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              ],
            ),
            SizedBox(height: 12.h),
            Text('Your Complete Numerology Blueprint', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 6.h),
            Text('Name fixes, remedies, a 5-year forecast & more — all in one report.', style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8))),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(color: const Color(0xFF818CF8), borderRadius: BorderRadius.circular(12.r)),
              child: Center(
                child: Text('Get My Numerology Blueprint', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B))),
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
    
    // Core Existing Mappings
    if (isVedic) {
      gridItems.add(_buildGridCard('Mulank (Driver)', 'Your core nature', Icons.person, onTap: () => _showExplanationSheet('Mulank', _profileData!['mulank'], false)));
      gridItems.add(_buildGridCard('Bhagyank (Destiny)', 'Your life path', Icons.route, onTap: () => _showExplanationSheet('Bhagyank', _profileData!['bhagyank'], false)));
      gridItems.add(_buildGridCard('Grid Analysis', 'Lo Shu grid breakdown', Icons.grid_3x3, onTap: () => _showExplanationSheet('Lo Shu Grid', _profileData!['lo_shu_grid'], false)));
    } else {
      gridItems.add(_buildGridCard('Life Path', 'The single number that shapes you', Icons.timeline, onTap: () => _showExplanationSheet('Life Path', _profileData!['life_path'], false)));
      gridItems.add(_buildGridCard('Birth Day', 'Hidden influence of your day', Icons.wb_sunny, onTap: () => _showExplanationSheet('Birthday', _profileData!['birthday'], false)));
      gridItems.add(_buildGridCard('Personal Year', 'What this year is asking of you', Icons.calendar_month, onTap: () => _showExplanationSheet('Personal Year', _profileData!['personal_year'], false)));
    }

    gridItems.add(_buildGridCard('Name Analysis', 'What your name reveals', Icons.format_color_text, onTap: () => _showExplanationSheet('Name', _profileData!['namank'] ?? _profileData!['expression'], true)));

    // New Modules (Placeholders for Phase 2 calculation implementation)
    gridItems.add(_buildGridCard('Personality & Soul', 'The self you show', Icons.join_inner, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personality backend linking pending')))));
    gridItems.add(_buildGridCard('Missing Numbers', 'Numbers your chart is missing', Icons.border_clear, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing numbers backend linking pending')))));
    gridItems.add(_buildGridCard('Remedies', 'Simple fixes for what is missing', Icons.healing, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remedies backend linking pending')))));
    gridItems.add(_buildGridCard('Crystal Match', 'Stones chosen for your numbers', Icons.diamond, isNew: true, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crystal match backend linking pending')))));
    gridItems.add(_buildGridCard('Planes', 'Physical, mental, spiritual', Icons.layers, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Planes backend linking pending')))));
    gridItems.add(_buildGridCard('Phone Analysis', 'Vibration of your phone number', Icons.phone_android, isNew: true, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone analysis backend linking pending')))));

    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F14), // Dark background for the new grid layout
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Cosmic Profile', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 24.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.85,
                ),
                itemCount: 2, // Only show first two initially before the wide card
                itemBuilder: (context, index) => gridItems[index],
              ),
              _buildWideReportCard(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.85,
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
            
            _buildResultsView(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
