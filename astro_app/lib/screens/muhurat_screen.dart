import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';

class MuhuratScreen extends StatefulWidget {
  const MuhuratScreen({super.key});

  @override
  State<MuhuratScreen> createState() => _MuhuratScreenState();
}

class _MuhuratScreenState extends State<MuhuratScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _muhurat;

  @override
  void initState() {
    super.initState();
    _fetchMuhurat();
  }

  Future<void> _fetchMuhurat() async {
    try {
      final data = await AstroApiService.getMuhurat();
      if (mounted) {
        setState(() {
          _muhurat = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Muhurat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Today\'s Muhurat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMuhurat,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Date and Sun Info
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _muhurat?['date'] ?? 'Today',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSunItem(Icons.brightness_5_rounded, 'Sunrise', _muhurat?['sunrise'] ?? '--:--'),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                            _buildSunItem(Icons.brightness_4_rounded, 'Sunset', _muhurat?['sunset'] ?? '--:--'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Auspicious Section
                  Text(
                    'Auspicious Timings (Shubh)',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimingCard(
                    title: 'Abhijit Muhurta',
                    time: _muhurat?['abhijit_muhurta'] ?? '--:--',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Inauspicious Section
                  Text(
                    'Inauspicious Timings (Ashubh)',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimingCard(
                    title: 'Rahu Kaal',
                    time: _muhurat?['rahu_kaal'] ?? '--:--',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTimingCard(
                    title: 'Yamaganda Kaal',
                    time: _muhurat?['yamaganda'] ?? '--:--',
                    icon: Icons.error_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTimingCard(
                    title: 'Gulika Kaal',
                    time: _muhurat?['gulika_kaal'] ?? '--:--',
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSunItem(IconData icon, String label, String time) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimingCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
