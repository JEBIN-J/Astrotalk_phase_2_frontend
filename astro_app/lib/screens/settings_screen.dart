import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/astro_api_service.dart';
import '../services/astrologer_location_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const SettingsScreen({
    super.key,
    this.onToggleTheme,
    this.isDark = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _chartStyle = 'North Indian';
  String _ayanamsa = 'Lahiri (Chitra Paksha)';
  String _language = 'English';
  bool _notifyRahuKaal = true;
  bool _notifyTithi = false;
  bool _highPrecisionEphemeris = true;
  AstrologerLocation? _astrologerLocation;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    AstrologerLocationService.locationNotifier.addListener(_onLocationChanged);
  }

  Future<void> _loadLocation() async {
    final loc = await AstrologerLocationService.getLocation();
    if (mounted) {
      setState(() {
        _astrologerLocation = loc;
      });
    }
  }

  void _onLocationChanged() {
    if (mounted) {
      setState(() {
        _astrologerLocation = AstrologerLocationService.locationNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    AstrologerLocationService.locationNotifier.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _showLocationPicker() async {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> places = await AstroApiService.getPlaces();

    if (!mounted) return;

    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const primaryIndigo = Color(0xFF4F46E5);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollCtrl) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  ),
                  child: Column(
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
                              'Set Default Astrologer Location',
                              style: GoogleFonts.outfit(fontSize: 16.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                        child: Text(
                          'All KP Horary, Prashna, and Transit charts will calculate using this vantage location.',
                          style: GoogleFonts.inter(fontSize: 12.sp, color: textMuted),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TextField(
                          controller: searchCtrl,
                          style: GoogleFonts.outfit(fontSize: 14.sp, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search city (e.g. Bijapur, Pune, London)...',
                            hintStyle: GoogleFonts.outfit(fontSize: 13.5.sp, color: textMuted),
                            prefixIcon: Icon(Icons.search, color: textMuted, size: 20.sp),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
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
                                  final isCurrentSelected = p['city'] == _astrologerLocation?.city;
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
                                    trailing: isCurrentSelected
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
                                      final city = p['city'] ?? 'Custom Location';
                                      final lat = double.tryParse(p['lat_val'] ?? '') ?? 28.6139;
                                      final lon = double.tryParse(p['lon_val'] ?? '') ?? 77.2090;
                                      final tz = double.tryParse(p['tz_val'] ?? '') ?? 5.5;

                                      final newLoc = AstrologerLocation(
                                        city: city,
                                        latitude: lat,
                                        longitude: lon,
                                        timezone: tz,
                                      );

                                      AstrologerLocationService.setLocation(newLoc);

                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Default Astrologer location updated to $city'),
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Settings & Preferences',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSectionHeader('Astrologer Working Location'),
          _buildActionTile(
            'Default Location (Horary / Prashna / Transit)',
            _astrologerLocation != null
                ? '${_astrologerLocation!.city}\nLat: ${_astrologerLocation!.latitude.toStringAsFixed(4)}°, Lon: ${_astrologerLocation!.longitude.toStringAsFixed(4)}°, TZ: ${_astrologerLocation!.timezone}'
                : 'Fetching saved location...',
            Icons.my_location_rounded,
            _showLocationPicker,
            isDark,
          ),
          SizedBox(height: 16.h),

          _buildSectionHeader('Astrological Calculations'),
          _buildSelectTile('Default Kundli Format', _chartStyle, ['North Indian', 'South Indian', 'East Indian'], (v) => setState(() => _chartStyle = v), isDark),
          _buildSelectTile('Default Ayanamsa', _ayanamsa, ['Lahiri (Chitra Paksha)', 'Krishnamurti (KP)', 'B.V. Raman', 'Fagan / Bradley'], (v) => setState(() => _ayanamsa = v), isDark),
          _buildSwitchTile('High Precision Ephemeris (0.01")', _highPrecisionEphemeris, (v) => setState(() => _highPrecisionEphemeris = v), isDark),
          SizedBox(height: 16.h),

          _buildSectionHeader('Localization & Appearance'),
          _buildSelectTile('Language', _language, ['English', 'Hindi', 'Tamil', 'Telugu', 'Marathi'], (v) => setState(() => _language = v), isDark),
          _buildActionTile('Dark Mode Theme', isDark ? 'Active (Cosmic Midnight)' : 'Active (Celestial Light)', Icons.dark_mode_rounded, widget.onToggleTheme, isDark),
          SizedBox(height: 16.h),

          _buildSectionHeader('Daily Notifications & Alerts'),
          _buildSwitchTile('Rahu Kaal Daily Alert (15 min prior)', _notifyRahuKaal, (v) => setState(() => _notifyRahuKaal = v), isDark),
          _buildSwitchTile('Daily Tithi & Nakshatra Change Notice', _notifyTithi, (v) => setState(() => _notifyTithi = v), isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, left: 4.w),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSelectTile(String title, String currentVal, List<String> options, ValueChanged<String> onChanged, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 8.w),
          DropdownButton<String>(
            value: currentVal,
            underline: SizedBox(),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF4338CA),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback? onTap, bool isDark, {Color? iconColor}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF4338CA)),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12.sp, color: Colors.grey)),
        trailing: Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
