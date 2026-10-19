import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';
import '../services/astrologer_location_service.dart';
import '../theme/numerology_theme.dart';

class HoraryScreen extends StatefulWidget {
  const HoraryScreen({super.key});

  @override
  State<HoraryScreen> createState() => _HoraryScreenState();
}

class _HoraryScreenState extends State<HoraryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _horaryData;
  String _errorMsg = '';
  List<dynamic> _questions = [];
  int _resultTabIndex = 0; // 0: Planets, 1: House Cusps
  bool _isCurrentLocation = true;

  // Form Fields matching Horary specifications
  final TextEditingController _nameCtrl = TextEditingController();
  String _selectedGender = 'Male'; // 'Male' or 'Female'
  String _horaryMode = 'range_249'; // 'range_249', 'range_2193', 'current_time'

  final TextEditingController _questionCtrl = TextEditingController();
  final TextEditingController _kpNumberCtrl = TextEditingController();
  late final TextEditingController _dateCtrl;
  late final TextEditingController _timeCtrl;
  final TextEditingController _latCtrl = TextEditingController(text: '28.6139');
  final TextEditingController _lonCtrl = TextEditingController(text: '77.2090');
  final TextEditingController _tzCtrl = TextEditingController(text: '5.5');
  String _locationName = 'New Delhi, India';
  String _selectedAyanamsa = 'KP_NEW';

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Theming
  Color get scaffoldBg => isDark ? const Color(0xFF080D1A) : const Color(0xFFF8FAFD);
  Color get cardBg => isDark ? const Color(0xFF131D36) : Colors.white;
  Color get surfaceCard => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  Color get cardBorder => isDark ? const Color(0xFF2E3D60) : const Color(0xFFE2E8F0);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textMuted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryBlue = Color(0xFF3B82F6);


  static const Map<String, String> _ayanamsaLabels = {
    'KP_NEW': 'KP New (Krishnamurti)',
    'KP_OLD': 'KP Old (Krishnamurti)',
    'KP_STRAIGHT_LINE': 'KP Straight Line',
    'LAHIRI': 'Lahiri (Chitrapaksha)',
    'BV_RAMAN': 'B.V. Raman',
    'KHULLAR': 'Khullar (Cuspal Interlinks)',
    'CHANDRA_HARI': 'Chandra Hari',
    'SRI_YUKTESWAR': 'Sri Yukteswar',
    'FAGAN_BRADLEY': 'Fagan Bradley (Western Sidereal)',
    'DE_LUCE': 'De Luce',
    'USHA_SHASHI': 'Usha Shashi',
    'DJWHAL_KHOOL': 'Djwhal Khool',
    'JN_BHASIN': 'J.N. Bhasin',
  };

  @visibleForTesting
  void setMockHoraryData(Map<String, dynamic> data) {
    _horaryData = data;
  }

  @visibleForTesting
  void setResultTabForTesting(int tab) {
    _resultTabIndex = tab;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(now));
    _timeCtrl = TextEditingController(text: DateFormat('HH:mm:ss').format(now));
    _fetchQuestions();
    _loadAstrologerLocation();
    AstrologerLocationService.locationNotifier.addListener(_onGlobalLocationChanged);
  }

  Future<void> _loadAstrologerLocation() async {
    final loc = await AstrologerLocationService.getLocation();
    if (mounted) {
      setState(() {
        _locationName = loc.city;
        _latCtrl.text = loc.latitude.toString();
        _lonCtrl.text = loc.longitude.toString();
        _tzCtrl.text = loc.timezone.toString();
      });
    }
  }

  void _onGlobalLocationChanged() {
    final loc = AstrologerLocationService.locationNotifier.value;
    if (loc != null && mounted) {
      setState(() {
        _locationName = loc.city;
        _latCtrl.text = loc.latitude.toString();
        _lonCtrl.text = loc.longitude.toString();
        _tzCtrl.text = loc.timezone.toString();
      });
    }
  }

  @override
  void dispose() {
    AstrologerLocationService.locationNotifier.removeListener(_onGlobalLocationChanged);
    _nameCtrl.dispose();
    _questionCtrl.dispose();
    _kpNumberCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      final q = await AstroApiService.getHoraryQuestions();
      if (mounted) {
        setState(() {
          _questions = q;
        });
      }
    } catch (e) {
      debugPrint("Failed to load horary questions: $e");
    }
  }

  String _formatDMS(double val, bool isLat) {
    final dir = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    final abs = val.abs();
    final deg = abs.floor();
    final minFloat = (abs - deg) * 60;
    final min = minFloat.floor();
    final sec = ((minFloat - min) * 60).round();
    return "$deg° $min' $sec\" $dir";
  }

  void _generateRandomNumber() {
    final rand = Random();
    int numVal;
    if (_horaryMode == 'range_2193') {
      numVal = rand.nextInt(2193) + 1;
    } else {
      numVal = rand.nextInt(249) + 1;
    }
    setState(() {
      _kpNumberCtrl.text = numVal.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Random seed $numVal selected!'),
        backgroundColor: const Color(0xFF4F46E5),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _fetchHorary() async {
    final q = _questionCtrl.text.trim();
    final questionText = q.isNotEmpty
        ? q
        : (_nameCtrl.text.trim().isNotEmpty ? 'Horary Reading for ${_nameCtrl.text.trim()}' : 'Horary Chart Query');

    int? horaryNum;
    if (_horaryMode != 'current_time') {
      final parsed = int.tryParse(_kpNumberCtrl.text.trim());
      if (parsed == null || parsed < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _horaryMode == 'range_2193'
                  ? 'Please enter or pick a number between 1 and 2193.'
                  : 'Please enter or pick a number between 1 and 249.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
      horaryNum = parsed;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final data = await AstroApiService.getHoraryChart(
        question: questionText,
        questionDate: _dateCtrl.text.trim(),
        questionTime: _timeCtrl.text.trim(),
        latitude: double.tryParse(_latCtrl.text) ?? 28.6139,
        longitude: double.tryParse(_lonCtrl.text) ?? 77.2090,
        timezone: double.tryParse(_tzCtrl.text) ?? 5.5,
        ayanamsa: _selectedAyanamsa,
        horaryNumber: horaryNum,
        horaryMode: _horaryMode,
      );
      if (mounted) {
        setState(() {
          _horaryData = data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLocationPicker() async {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> places = await AstroApiService.getPlaces();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131D36) : Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        margin: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: primaryIndigo, size: 22.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Select Horary Location',
                            style: GoogleFonts.outfit(fontSize: 16.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        controller: searchCtrl,
                        style: GoogleFonts.outfit(color: textPrimary, fontSize: 13.5.sp),
                        decoration: InputDecoration(
                          hintText: 'Search city (e.g. Mumbai, Delhi, London)...',
                          hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 13.sp),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryIndigo, size: 18.sp),
                          filled: true,
                          fillColor: surfaceCard,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                        ),
                        onChanged: (val) async {
                          final results = await AstroApiService.getPlaces(query: val);
                          setModalState(() {
                            places = results;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Current Location Default Action
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: _isCurrentLocation
                            ? primaryIndigo.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _isCurrentLocation ? primaryIndigo : cardBorder,
                          width: _isCurrentLocation ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: EdgeInsets.all(7.w),
                          decoration: BoxDecoration(
                            color: primaryIndigo.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.my_location_rounded, color: primaryIndigo, size: 18.sp),
                        ),
                        title: Text(
                          'Default Astrologer Location',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '$_locationName • ${_latCtrl.text}° N, ${_lonCtrl.text}° E (TZ: ${_tzCtrl.text})',
                          style: GoogleFonts.inter(fontSize: 11.5.sp, color: textMuted),
                        ),
                        trailing: _isCurrentLocation
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: primaryIndigo,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _isCurrentLocation = true;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Divider(height: 1),
                    Expanded(
                      child: places.isEmpty
                          ? Center(
                              child: Text('No matching locations found', style: GoogleFonts.outfit(color: textMuted)),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              padding: EdgeInsets.all(16.w),
                              itemCount: places.length,
                              itemBuilder: (c, idx) {
                                final p = places[idx];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.place_outlined, color: primaryIndigo, size: 20.sp),
                                  title: Text(
                                    p['city'] ?? '',
                                    style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  subtitle: Text(
                                    '${p['coords']} • ${p['tz']}',
                                    style: GoogleFonts.inter(fontSize: 11.5.sp, color: textMuted),
                                  ),
                                  onTap: () {
                                    final city = p['city'] ?? 'Custom Location';
                                    final lat = double.tryParse(p['lat_val'] ?? '') ?? 28.6139;
                                    final lon = double.tryParse(p['lon_val'] ?? '') ?? 77.2090;
                                    final tz = double.tryParse(p['tz_val'] ?? '') ?? 5.5;

                                    setState(() {
                                      _isCurrentLocation = false;
                                      _locationName = city;
                                      _latCtrl.text = lat.toString();
                                      _lonCtrl.text = lon.toString();
                                      _tzCtrl.text = tz.toString();
                                    });

                                    AstrologerLocationService.setLocation(
                                      AstrologerLocation(
                                        city: city,
                                        latitude: lat,
                                        longitude: lon,
                                        timezone: tz,
                                      ),
                                    );

                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Astrologer location updated to $city'),
                                        backgroundColor: const Color(0xFF4F46E5),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showKpNumberPicker() {
    final searchCtrl = TextEditingController();
    final maxNum = _horaryMode == 'range_2193' ? 2193 : 249;
    int? selectedRangeIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131D36) : Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.trim();
            final allNumbers = List.generate(maxNum, (i) => i + 1);

            List<int> filtered = allNumbers.where((n) {
              if (selectedRangeIndex != null) {
                final step = maxNum == 2193 ? 500 : 50;
                final start = selectedRangeIndex! * step + 1;
                final end = (selectedRangeIndex! == 4) ? maxNum : (selectedRangeIndex! + 1) * step;
                if (n < start || n > end) return false;
              }
              if (query.isNotEmpty) {
                return n.toString().contains(query);
              }
              return true;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        margin: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: primaryIndigo.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.format_list_numbered_rounded, color: primaryIndigo, size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select KP Horary Seed (1–$maxNum)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Choose an intuitive number seed',
                                  style: GoogleFonts.inter(fontSize: 12.sp, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        controller: searchCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: textPrimary, fontSize: 13.5.sp),
                        decoration: InputDecoration(
                          hintText: 'Search number (e.g. 7, 108)...',
                          hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 13.sp),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryIndigo, size: 18.sp),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, size: 16.sp, color: textMuted),
                                  onPressed: () => setModalState(() => searchCtrl.clear()),
                                )
                              : null,
                          filled: true,
                          fillColor: surfaceCard,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('All (1–$maxNum)', style: GoogleFonts.outfit(fontSize: 11.5.sp)),
                            selected: selectedRangeIndex == null,
                            selectedColor: primaryIndigo,
                            labelStyle: TextStyle(color: selectedRangeIndex == null ? Colors.white : textMuted),
                            backgroundColor: surfaceCard,
                            onSelected: (_) => setModalState(() => selectedRangeIndex = null),
                          ),
                          SizedBox(width: 6.w),
                          if (maxNum == 249)
                            ...List.generate(5, (idx) {
                              final label = idx == 4 ? '201–249' : '${idx * 50 + 1}–${(idx + 1) * 50}';
                              final isSel = selectedRangeIndex == idx;
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: ChoiceChip(
                                  label: Text(label, style: GoogleFonts.outfit(fontSize: 11.5.sp)),
                                  selected: isSel,
                                  selectedColor: primaryIndigo,
                                  labelStyle: TextStyle(color: isSel ? Colors.white : textMuted),
                                  backgroundColor: surfaceCard,
                                  onSelected: (_) => setModalState(() => selectedRangeIndex = idx),
                                ),
                              );
                            })
                          else
                            ...List.generate(5, (idx) {
                              final label = idx == 4 ? '2001–2193' : '${idx * 500 + 1}–${(idx + 1) * 500}';
                              final isSel = selectedRangeIndex == idx;
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: ChoiceChip(
                                  label: Text(label, style: GoogleFonts.outfit(fontSize: 11.5.sp)),
                                  selected: isSel,
                                  selectedColor: primaryIndigo,
                                  labelStyle: TextStyle(color: isSel ? Colors.white : textMuted),
                                  backgroundColor: surfaceCard,
                                  onSelected: (_) => setModalState(() => selectedRangeIndex = idx),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('No matching numbers found', style: GoogleFonts.outfit(color: textMuted)),
                            )
                          : GridView.builder(
                              controller: scrollCtrl,
                              padding: EdgeInsets.all(16.w),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 10.w,
                                mainAxisSpacing: 10.h,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final numVal = filtered[i];
                                final isChosen = _kpNumberCtrl.text.trim() == numVal.toString();
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _kpNumberCtrl.text = numVal.toString();
                                    });
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? primaryIndigo
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: isChosen ? primaryIndigo : cardBorder,
                                        width: isChosen ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$numVal',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15.sp,
                                          fontWeight: isChosen ? FontWeight.w800 : FontWeight.w600,
                                          color: isChosen ? Colors.white : textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd').parse(_dateCtrl.text);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: primaryIndigo, surface: Color(0xFF1E293B)),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: primaryIndigo),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initial = TimeOfDay.now();
    try {
      final dt = DateFormat('HH:mm:ss').parse(_timeCtrl.text);
      initial = TimeOfDay.fromDateTime(dt);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: primaryIndigo, surface: Color(0xFF1E293B)),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: primaryIndigo),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute, now.second);
      setState(() {
        _timeCtrl.text = DateFormat('HH:mm:ss').format(dt);
      });
    }
  }

  void _showQuestionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131D36) : Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline_rounded, color: primaryIndigo, size: 20.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Horary Questions',
                              style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            Text(
                              'Select a classic query categorized by life theme',
                              style: GoogleFonts.inter(fontSize: 12.sp, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _questions.isEmpty
                      ? Center(
                          child: Text('No predefined questions loaded.', style: GoogleFonts.outfit(color: textMuted)),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: EdgeInsets.all(16.w),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final cat = _questions[index];
                            final catName = cat['category']?.toString() ?? 'General';
                            final qs = (cat['questions'] as List<dynamic>?) ?? [];
                            return Container(
                              margin: EdgeInsets.only(bottom: 14.h),
                              decoration: BoxDecoration(
                                color: surfaceCard,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: index == 0,
                                  leading: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: primaryIndigo.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(Icons.folder_open_rounded, color: primaryIndigo, size: 16.sp),
                                  ),
                                  title: Text(
                                    catName,
                                    style: GoogleFonts.outfit(color: textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700),
                                  ),
                                  children: qs.map((q) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                                      dense: true,
                                      leading: Icon(Icons.subdirectory_arrow_right_rounded, size: 16.sp, color: primaryIndigo),
                                      title: Text(
                                        q.toString(),
                                        style: GoogleFonts.inter(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                                      ),
                                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: textMuted),
                                      onTap: () {
                                        _questionCtrl.text = q.toString();
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: Center(
          child: InkWell(
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
                child: Icon(Icons.arrow_back_ios_new_rounded, color: NumerologyTheme.circleBtnIcon(isDark), size: 15.sp),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13.sp),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                'Horary Astrology (KP)',
                style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MAIN HORARY FORM CARD ---
            _buildHoraryFormCard(),
            SizedBox(height: 20.h),

            // --- ACTION BUTTONS (CREATE / CANCEL) ---
            _buildActionButtons(),
            SizedBox(height: 16.h),

            if (_errorMsg.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _errorMsg,
                        style: GoogleFonts.inter(fontSize: 13.sp, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),

            // --- RESULTS SECTION ---
            if (_horaryData != null) ...[
              SizedBox(height: 8.h),
              _buildResultsDashboard(),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HORARY SPECIFICATION FORM CARD
  // =========================================================================

  Widget _buildHoraryFormCard() {
    final latVal = double.tryParse(_latCtrl.text) ?? 28.6139;
    final lonVal = double.tryParse(_lonCtrl.text) ?? 77.2090;
    final tzVal = double.tryParse(_tzCtrl.text) ?? 5.5;
    final tzStr = tzVal >= 0
        ? 'GMT+${tzVal.toStringAsFixed(2).replaceAll('.50', ':30').replaceAll('.00', ':00')}'
        : 'GMT${tzVal.toStringAsFixed(2)}';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ROW
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horary Chart Setup',
                      style: GoogleFonts.outfit(fontSize: 16.5.sp, fontWeight: FontWeight.w800, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'KP Prashna Astrology Parameters',
                      style: GoogleFonts.inter(fontSize: 11.5.sp, color: textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 2. NAME & GENDER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Input
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                    SizedBox(height: 6.h),
                    SizedBox(
                      height: 48.h,
                      child: TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.outfit(color: textPrimary, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Querent Name',
                          hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 12.5.sp),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: primaryIndigo, size: 19.sp),
                          filled: true,
                          fillColor: surfaceCard,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: primaryIndigo, width: 1.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),

              // Gender Selector Pills
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gender', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                    SizedBox(height: 6.h),
                    Container(
                      height: 48.h,
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedGender = 'Male'),
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Male' ? primaryIndigo : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    'Male',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedGender == 'Male' ? Colors.white : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedGender = 'Female'),
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Female' ? primaryIndigo : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: Text(
                                    'Female',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedGender == 'Female' ? Colors.white : textMuted,
                                    ),
                                  ),
                                ),
                              ),
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
          SizedBox(height: 18.h),

          // 3. HORARY MODE SEGMENTED CONTROL
          Text('Select Horary Mode', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                _buildSegmentedTab(
                  mode: 'range_249',
                  title: 'KP 1–249',
                  subtitle: 'Classical',
                ),
                _buildSegmentedTab(
                  mode: 'range_2193',
                  title: 'KP 1–2193',
                  subtitle: 'Sub-Sub',
                ),
                _buildSegmentedTab(
                  mode: 'current_time',
                  title: 'Current Time',
                  subtitle: 'Direct Asc',
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // 4. NUMBER SEED SECTION (When not Current Time)
          if (_horaryMode != 'current_time') ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Horary Seed Number',
                        style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: primaryIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _horaryMode == 'range_2193' ? 'Valid: 1 to 2193' : 'Valid: 1 to 249',
                        style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Full-width seed input field with generous space
                SizedBox(
                  height: 48.h,
                  child: TextField(
                    controller: _kpNumberCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _horaryMode == 'range_2193' ? 'Enter seed number (1 to 2193)' : 'Enter seed number (1 to 249)',
                      hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 13.sp),
                      prefixIcon: Icon(Icons.tag_rounded, color: primaryIndigo, size: 20.sp),
                      filled: true,
                      fillColor: surfaceCard,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: primaryIndigo, width: 1.5)),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                // Quick Action Buttons (Random & Browse) neatly arranged side-by-side
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _generateRandomNumber,
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          height: 38.h,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: primaryIndigo.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.casino_rounded, color: primaryIndigo, size: 15.sp),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  'Random Seed',
                                  style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkWell(
                        onTap: _showKpNumberPicker,
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          height: 38.h,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: primaryIndigo.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.format_list_numbered_rounded, color: primaryIndigo, size: 15.sp),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  'Browse Seeds',
                                  style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: const Color(0xFFF59E0B), size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Direct Mode: Chart Ascendant is derived from exact query timestamp.',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 18.h),

          // 5. DATE & TIME (SIDE-BY-SIDE EQUAL COLUMNS)
          Row(
            children: [
              // Date Card
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Query Date', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                    SizedBox(height: 6.h),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        height: 48.h,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: primaryIndigo, size: 19.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _dateCtrl.text,
                                style: GoogleFonts.firaCode(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),

              // Time Card
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Query Time', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                    SizedBox(height: 6.h),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        height: 48.h,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: primaryIndigo, size: 19.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _timeCtrl.text,
                                style: GoogleFonts.firaCode(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 6. LOCATION CARD (CURRENT LOCATION DEFAULT + CHANGE)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Location', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: (_isCurrentLocation ? const Color(0xFF10B981) : primaryIndigo).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCurrentLocation ? Icons.my_location_rounded : Icons.place_rounded,
                          size: 11.sp,
                          color: _isCurrentLocation ? const Color(0xFF10B981) : primaryIndigo,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _isCurrentLocation ? 'Current Location' : 'Custom Location',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: _isCurrentLocation ? const Color(0xFF10B981) : primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.w),
                          decoration: BoxDecoration(
                            color: primaryIndigo.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isCurrentLocation ? Icons.my_location_rounded : Icons.location_on_rounded,
                            color: primaryIndigo,
                            size: 17.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _locationName,
                            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: _showLocationPicker,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_location_alt_rounded, color: primaryIndigo, size: 14.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  'Change',
                                  style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Clearly arranged coordinate badges with no truncation
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lat: ', style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: textMuted)),
                              Text(_formatDMS(latVal, true), style: GoogleFonts.firaCode(fontSize: 10.sp, fontWeight: FontWeight.w600, color: textPrimary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lon: ', style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: textMuted)),
                              Text(_formatDMS(lonVal, false), style: GoogleFonts.firaCode(fontSize: 10.sp, fontWeight: FontWeight.w600, color: textPrimary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                          ),
                          child: Text(tzStr, style: GoogleFonts.firaCode(fontSize: 10.sp, fontWeight: FontWeight.w600, color: primaryIndigo)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 7. SPECIFIC QUESTION (WITH BROWSE & QUICK PILLS)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Question (Optional / Specific Query)',
                      style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _showQuestionPicker,
                    borderRadius: BorderRadius.circular(6.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt_rounded, color: primaryIndigo, size: 14.sp),
                          SizedBox(width: 3.w),
                          Text(
                            'Browse',
                            style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryIndigo),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              // Full-width question input field so hint and user queries never get cramped
              SizedBox(
                height: 48.h,
                child: TextField(
                  controller: _questionCtrl,
                  style: GoogleFonts.outfit(color: textPrimary, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. Will I get the job I applied for?',
                    hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 12.5.sp),
                    prefixIcon: Icon(Icons.help_outline_rounded, color: primaryIndigo, size: 19.sp),
                    filled: true,
                    fillColor: surfaceCard,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: primaryIndigo, width: 1.5)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 8. AYANAMSA SYSTEM
          Text('Ayanamsa System', style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
          SizedBox(height: 6.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedAyanamsa,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: GoogleFonts.outfit(color: textPrimary, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.auto_fix_high_rounded, color: primaryIndigo, size: 19.sp),
              filled: true,
              fillColor: surfaceCard,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: primaryIndigo, width: 1.5)),
            ),
            items: _ayanamsaLabels.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedAyanamsa = val);
            },
          ),

        ],
      ),
    );
  }

  Widget _buildSegmentedTab({
    required String mode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _horaryMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _horaryMode = mode;
            if (mode == 'range_249') {
              final parsed = int.tryParse(_kpNumberCtrl.text);
              if (parsed != null && parsed > 249) _kpNumberCtrl.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected ? primaryIndigo : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white.withValues(alpha: 0.9) : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ACTION BUTTONS (CREATE / CANCEL)
  // =========================================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        // CREATE / CALCULATE
        Expanded(
          flex: 3,
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchHorary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Create',
                          style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // CANCEL / RESET
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52.h,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _nameCtrl.clear();
                  _questionCtrl.clear();
                  _kpNumberCtrl.clear();
                  _horaryMode = 'range_249';
                  _horaryData = null;
                  _errorMsg = '';
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cardBorder, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                backgroundColor: surfaceCard,
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // RESULTS DASHBOARD
  // =========================================================================

  Widget _buildResultsDashboard() {
    final asc = (_horaryData!['ascendant'] as num?)?.toDouble() ?? 0.0;
    final ayanamsaVal = (_horaryData!['ayanamsa_value'] as num?)?.toDouble() ?? 0.0;
    final ascDetails = _horaryData!['ascendant_details'] as Map<String, dynamic>?;
    final planets = (_horaryData!['planets'] as List<dynamic>?) ?? [];
    final cusps = (_horaryData!['cusps'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: primaryIndigo, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horary Engine Analysis',
                      style: GoogleFonts.outfit(fontSize: 17.sp, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    Text(
                      'Krishnamurti Paddhati Astrological Matrix',
                      style: GoogleFonts.inter(fontSize: 11.5.sp, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // TWO KEY METRIC CARDS
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASCENDANT', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.1)),
                      SizedBox(height: 4.h),
                      Text(
                        '${asc.toStringAsFixed(2)}°',
                        style: GoogleFonts.outfit(fontSize: 19.sp, fontWeight: FontWeight.w900, color: primaryIndigo),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AYANAMSA', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.1)),
                      SizedBox(height: 4.h),
                      Text(
                        '${ayanamsaVal.toStringAsFixed(4)}°',
                        style: GoogleFonts.outfit(fontSize: 19.sp, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (ascDetails != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAscDetailPill('Sign', (ascDetails['sign'] is Map) ? (ascDetails['sign']['name']?.toString() ?? '-') : (ascDetails['sign']?.toString() ?? '-')),
                  _buildAscDetailPill('NL', ascDetails['star_lord']?.toString() ?? '-'),
                  _buildAscDetailPill('SL', ascDetails['sub_lord']?.toString() ?? '-'),
                  if ((ascDetails['sub_sub_lord']?.toString() ?? '').isNotEmpty)
                    _buildAscDetailPill('SSL', ascDetails['sub_sub_lord']?.toString() ?? '-'),
                ],
              ),
            ),
          ],
          SizedBox(height: 18.h),

          // SEGMENTED SWITCHER (PLANETS VS CUSPS)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _resultTabIndex = 0),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _resultTabIndex == 0 ? primaryIndigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          'Planetary Positions (${planets.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _resultTabIndex == 0 ? Colors.white : textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _resultTabIndex = 1),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _resultTabIndex == 1 ? primaryIndigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          'House Cusps (${cusps.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _resultTabIndex == 1 ? Colors.white : textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // TAB CONTENT
          if (_resultTabIndex == 0)
            _buildPlanetsList(planets)
          else
            _buildCuspsList(cusps),
        ],
      ),
    );
  }

  Widget _buildPlanetsList(List<dynamic> planets) {
    return Column(
      children: planets.map((p) {
        final name = p['planet']?.toString() ?? '';
        final lon = (p['longitude'] as num?)?.toDouble() ?? 0.0;
        final sign = (p['sign'] is Map)
            ? (p['sign']['name']?.toString() ?? '')
            : (p['sign']?.toString() ?? '');
        final starLord = p['star_lord']?.toString() ?? '-';
        final subLord = p['sub_lord']?.toString() ?? '-';
        final subSubLord = p['sub_sub_lord']?.toString() ?? '';

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: surfaceCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, name.length > 2 ? 2 : name.length) : 'Pl',
                    style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: primaryIndigo),
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
                            name,
                            style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        if (sign.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Text(sign, style: GoogleFonts.outfit(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${lon.toStringAsFixed(2)}°',
                      style: GoogleFonts.firaCode(fontSize: 12.sp, color: primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text('NL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(starLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Text('SL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(subLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (subSubLord.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text('SSL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(subSubLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCuspsList(List<dynamic> cusps) {
    return Column(
      children: cusps.map((c) {
        final house = c['house']?.toString() ?? '';
        final lon = (c['longitude'] as num?)?.toDouble() ?? 0.0;
        final sign = (c['sign'] is Map)
            ? (c['sign']['name']?.toString() ?? '')
            : (c['sign']?.toString() ?? '');
        final starLord = c['star_lord']?.toString() ?? '-';
        final subLord = c['sub_lord']?.toString() ?? '-';
        final subSubLord = c['sub_sub_lord']?.toString() ?? '';

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: surfaceCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    house,
                    style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6)),
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
                            'House $house',
                            style: GoogleFonts.outfit(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        if (sign.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Text(sign, style: GoogleFonts.outfit(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${lon.toStringAsFixed(2)}°',
                      style: GoogleFonts.firaCode(fontSize: 12.sp, color: primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text('NL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(starLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Text('SL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(subLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (subSubLord.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text('SSL: ', style: GoogleFonts.inter(fontSize: 10.5.sp, color: textMuted, fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(subSubLord, style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAscDetailPill(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: textMuted, fontWeight: FontWeight.w600)),
        SizedBox(height: 2.h),
        Text(value, style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textPrimary)),
      ],
    );
  }
}
