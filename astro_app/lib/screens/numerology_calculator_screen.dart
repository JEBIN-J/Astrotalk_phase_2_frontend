import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/astro_api_service.dart';

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
          'reduced': dayReduced,
          'calculation': 'Day of birth reduced to $dayReduced',
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

  Widget _buildProfileHeader() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Seeker';
    final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1998-12-13';
    final String systemTitle = _system == 'vedic'
        ? 'Vedic Numerology'
        : (_system == 'chaldean' ? 'Chaldean Numerology' : 'Pythagorean Numerology');

    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'N',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 2.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cake_outlined, size: 11.5.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 3.w),
                        Text(
                          dob,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        systemTitle,
                        style: GoogleFonts.inter(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: _showEditProfileSheet,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_rounded, size: 14.sp, color: const Color(0xFF475569)),
              ),
            ),
          ),
        ],
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
            // Instant Profile Header based on selected user values
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
