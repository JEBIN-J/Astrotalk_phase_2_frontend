import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<Map<String, String>> _places = [
    {'city': 'New Delhi, India', 'coords': '28.6139° N, 77.2090° E', 'tz': 'GMT +05:30', 'isDefault': 'true'},
    {'city': 'Mumbai, Maharashtra', 'coords': '19.0760° N, 72.8777° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'Varanasi, Uttar Pradesh', 'coords': '25.3176° N, 82.9739° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'Bengaluru, Karnataka', 'coords': '12.9716° N, 77.5946° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'London, United Kingdom', 'coords': '51.5074° N, 0.1278° W', 'tz': 'GMT +00:00', 'isDefault': 'false'},
    {'city': 'New York, United States', 'coords': '40.7128° N, 74.0060° W', 'tz': 'GMT -05:00', 'isDefault': 'false'},
  ];

  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces({String query = ''}) async {
    setState(() => _isLoading = true);
    final data = await AstroApiService.getPlaces(query: query);
    if (mounted) {
      setState(() {
        if (data.isNotEmpty) {
          _places = data;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _places.where((p) => p['city']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Manage Astrological Places',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          TextField(
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _fetchPlaces(query: v);
            },
            decoration: InputDecoration(
              hintText: 'Search city, state or country...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saved Places Database (${filtered.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              TextButton.icon(
                onPressed: _showAddPlaceDialog,
                icon: Icon(Icons.add_location_alt_rounded, size: 18, color: Color(0xFFEA580C)),
                label: Text('Add Custom Place', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFEA580C))),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...filtered.map((place) {
            final isDef = place['isDefault'] == 'true';
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDef ? const Color(0xFFEA580C) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded, color: Color(0xFFEA580C), size: 20),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(place['city']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp), overflow: TextOverflow.ellipsis),
                            ),
                            if (isDef) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(6.r)),
                                child: Text('DEFAULT', style: GoogleFonts.outfit(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text('${place['coords']} • ${place['tz']}', style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (val) {
                      if (val == 'default') {
                        setState(() {
                          for (var p in _places) {
                            p['isDefault'] = 'false';
                          }
                          place['isDefault'] = 'true';
                        });
                      } else if (val == 'delete') {
                        setState(() {
                          _places.remove(place);
                        });
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'default', child: Text('Set as Default Location')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Place', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddPlaceDialog() {
    final cityCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final tzCtrl = TextEditingController(text: 'GMT +05:30');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(20, 18, 14, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF431407), const Color(0xFF7C2D12)]
                          : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Custom Place',
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF7C2D12),
                              ),
                            ),
                            Text(
                              'Store coordinates for astrological ephemeris',
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlaceField(
                          label: 'City & State Name',
                          hint: 'e.g. Jaipur, Rajasthan',
                          icon: Icons.location_city_rounded,
                          controller: cityCtrl,
                          isDark: isDark,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPlaceField(
                                label: 'Latitude',
                                hint: '26.9124° N',
                                icon: Icons.explore_rounded,
                                controller: latCtrl,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildPlaceField(
                                label: 'Longitude',
                                hint: '75.7873° E',
                                icon: Icons.explore_outlined,
                                controller: lonCtrl,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildPlaceField(
                          label: 'Timezone Offset',
                          hint: 'GMT +05:30',
                          icon: Icons.access_time_filled_rounded,
                          controller: tzCtrl,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions Footer
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            if (cityCtrl.text.trim().isNotEmpty) {
                              setState(() {
                                _places.add({
                                  'city': cityCtrl.text.trim(),
                                  'coords': '${latCtrl.text.trim().isEmpty ? '28.6139° N' : latCtrl.text.trim()}, ${lonCtrl.text.trim().isEmpty ? '77.2090° E' : lonCtrl.text.trim()}',
                                  'tz': tzCtrl.text.trim().isEmpty ? 'GMT +05:30' : tzCtrl.text.trim(),
                                  'isDefault': 'false',
                                });
                              });
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_location_rounded, size: 18),
                              SizedBox(width: 6.w),
                              Text(
                                'Add Place',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp),
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
          ),
        );
      },
    );
  }

  Widget _buildPlaceField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFEA580C), size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Color(0xFFEA580C), width: 1.8.w),
            ),
          ),
        ),
      ],
    );
  }
}
