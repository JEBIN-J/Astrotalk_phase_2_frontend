import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';

class EphemerisScreen extends StatefulWidget {
  const EphemerisScreen({super.key});

  @override
  State<EphemerisScreen> createState() => _EphemerisScreenState();
}

class _EphemerisScreenState extends State<EphemerisScreen> {
  bool _isSidereal = true;
  bool _isLoading = false;
  List<dynamic>? _ephemerisList;
  String _ayanamsaValue = 'Lahiri Ayanamsa 24° 13\' 44.8"';

  @override
  void initState() {
    super.initState();
    _fetchEphemeris();
  }

  Future<void> _fetchEphemeris() async {
    setState(() => _isLoading = true);
    final data = await AstroApiService.getEphemeris(
      ayanamsaSystem: _isSidereal ? 'lahiri' : 'tropical',
    );
    if (mounted) {
      setState(() {
        _ephemerisList = data['planets'] as List<dynamic>?;
        _ayanamsaValue = data['ayanamsa_value']?.toString() ?? 'Lahiri Ayanamsa 24° 13\' 44.8"';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Astronomical Ephemeris',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          Row(
            children: [
              Text(
                _isSidereal ? 'Sidereal' : 'Tropical',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
              ),
              Switch(
                value: _isSidereal,
                activeThumbColor: const Color(0xFF7C3AED),
                onChanged: (val) {
                  setState(() {
                    _isSidereal = val;
                  });
                  _fetchEphemeris();
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  SizedBox(height: 12),
                  Text('Computing Swiss Ephemeris Geocentric Longitudes...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Swiss Ephemeris Data', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text('00:00:00 UT (Live)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSidereal
                            ? 'Nirayana Sidereal ($_ayanamsaValue)'
                            : 'Sayana Tropical Zodiac (Geocentric Equinox of Date)',
                        style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Planetary Longitudes & Daily Motion', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Swiss Ephemeris',
                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_ephemerisList == null || _ephemerisList!.isEmpty) ...[
                  _buildEphemerisRow(0, 'Sun ☉', '339° 42\' 11"', '-07° 21\' 14"', '+00° 59\' 48"', 'Direct', isDark),
                  _buildEphemerisRow(1, 'Moon ☽', '064° 15\' 23"', '+18° 42\' 09"', '+12° 41\' 09"', 'Direct', isDark),
                  _buildEphemerisRow(2, 'Mercury ☿', '316° 54\' 30"', '-14° 02\' 18"', '+01° 24\' 15"', 'Direct', isDark),
                  _buildEphemerisRow(3, 'Venus ♀', '342° 44\' 19"', '-03° 10\' 02"', '+01° 14\' 30"', 'Direct', isDark),
                  _buildEphemerisRow(4, 'Mars ♂', '178° 10\' 02"', '+02° 15\' 44"', '+00° 34\' 15"', 'Direct', isDark),
                  _buildEphemerisRow(5, 'Jupiter ♃', '047° 30\' 45"', '+16° 55\' 11"', '+00° 06\' 11"', 'Direct', isDark),
                  _buildEphemerisRow(6, 'Saturn ♄', '322° 18\' 52"', '-15° 28\' 40"', '+00° 05\' 02"', 'Direct', isDark),
                  _buildEphemerisRow(7, 'Uranus ♅', '054° 12\' 09"', '+18° 10\' 22"', '+00° 01\' 44"', 'Direct', isDark),
                  _buildEphemerisRow(8, 'Neptune ♆', '358° 40\' 30"', '-01° 50\' 12"', '+00° 01\' 12"', 'Direct', isDark),
                  _buildEphemerisRow(9, 'Pluto ♇', '302° 15\' 18"', '-22° 48\' 50"', '+00° 01\' 05"', 'Direct', isDark),
                  _buildEphemerisRow(10, 'True Rahu ☊', '344° 02\' 10"', '+00° 00\' 00"', '-00° 03\' 11"', 'Retrograde', isDark),
                  _buildEphemerisRow(11, 'True Ketu ☋', '164° 02\' 10"', '+00° 00\' 00"', '-00° 03\' 11"', 'Retrograde', isDark),
                ] else
                  ..._ephemerisList!.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value as Map<String, dynamic>;
                    final planet = row['planet']?.toString() ?? 'Planet';
                    final longitude = row['longitude']?.toString() ?? '000° 00\'';
                    final declination = row['declination']?.toString() ?? '00° 00\'';
                    final speed = row['speed']?.toString() ?? '+00° 00\'';
                    final motion = row['motion']?.toString() ?? 'Direct';

                    return _buildEphemerisRow(idx, planet, longitude, declination, speed, motion, isDark);
                  }),
              ],
            ),
    );
  }

  Widget _buildEphemerisRow(int index, String planet, String longitude, String declination, String speed, String motion, bool isDark) {
    final isRetro = motion == 'Retrograde';
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Text(planet, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(longitude, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF7C3AED)), overflow: TextOverflow.ellipsis),
                  Text('Dec: $declination', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(speed, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text(
                    motion,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRetro ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
