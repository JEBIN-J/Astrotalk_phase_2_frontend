import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final List<Map<String, String>> _places = [
    {'city': 'New Delhi, India', 'coords': '28.6139° N, 77.2090° E', 'tz': 'GMT +05:30', 'isDefault': 'true'},
    {'city': 'Mumbai, Maharashtra', 'coords': '19.0760° N, 72.8777° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'Varanasi, Uttar Pradesh', 'coords': '25.3176° N, 82.9739° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'Bengaluru, Karnataka', 'coords': '12.9716° N, 77.5946° E', 'tz': 'GMT +05:30', 'isDefault': 'false'},
    {'city': 'London, United Kingdom', 'coords': '51.5074° N, 0.1278° W', 'tz': 'GMT +00:00', 'isDefault': 'false'},
    {'city': 'New York, United States', 'coords': '40.7128° N, 74.0060° W', 'tz': 'GMT -05:00', 'isDefault': 'false'},
  ];

  String _searchQuery = '';

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search city, state or country...',
              prefixIcon: const Icon(Icons.search_rounded),
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
                            Text(place['city']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
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
      builder: (ctx) => AlertDialog(
        title: Text('Add Custom Place', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City & State Name')),
              TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude (e.g. 26.9124 N)')),
              TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude (e.g. 75.7873 E)')),
              TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'Timezone Offset (e.g. GMT +05:30)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (cityCtrl.text.isNotEmpty) {
                setState(() {
                  _places.add({
                    'city': cityCtrl.text,
                    'coords': '${latCtrl.text}, ${lonCtrl.text}',
                    'tz': tzCtrl.text,
                    'isDefault': 'false',
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Place'),
          ),
        ],
      ),
    );
  }
}
