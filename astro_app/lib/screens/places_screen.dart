import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'api_settings_screen.dart';

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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.api_rounded, color: Color(0xFF059669)),
            tooltip: 'Live Backend Hub',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiSettingsScreen()),
              ).then((_) => _fetchPlaces(query: _searchQuery));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _fetchPlaces(query: v);
            },
            decoration: InputDecoration(
              hintText: 'Search city, state or country...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saved Places Database (${filtered.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: _showAddPlaceDialog,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18, color: Color(0xFFEA580C)),
                label: Text('Add Custom Place', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFEA580C))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...filtered.map((place) {
            final isDef = place['isDefault'] == 'true';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDef ? const Color(0xFFEA580C) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFFEA580C), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(place['city']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            ),
                            if (isDef) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(6)),
                                child: Text('DEFAULT', style: GoogleFonts.outfit(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${place['coords']} • ${place['tz']}', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
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
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF431407), const Color(0xFF7C2D12)]
                          : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
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
                        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Custom Place',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF7C2D12),
                              ),
                            ),
                            Text(
                              'Store coordinates for astrological ephemeris',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                        const SizedBox(height: 12),
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
                            const SizedBox(width: 10),
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
                        const SizedBox(height: 12),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_location_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Add Place',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
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
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFEA580C), size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
