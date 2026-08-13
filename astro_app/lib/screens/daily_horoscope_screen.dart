import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';

class DailyHoroscopeScreen extends StatefulWidget {
  const DailyHoroscopeScreen({super.key});

  @override
  State<DailyHoroscopeScreen> createState() => _DailyHoroscopeScreenState();
}

class _DailyHoroscopeScreenState extends State<DailyHoroscopeScreen> {
  final List<Map<String, dynamic>> _signs = [
    {"name": "Aries", "icon": Icons.local_fire_department_rounded, "date": "Mar 21 - Apr 19"},
    {"name": "Taurus", "icon": Icons.terrain_rounded, "date": "Apr 20 - May 20"},
    {"name": "Gemini", "icon": Icons.air_rounded, "date": "May 21 - Jun 20"},
    {"name": "Cancer", "icon": Icons.water_drop_rounded, "date": "Jun 21 - Jul 22"},
    {"name": "Leo", "icon": Icons.local_fire_department_rounded, "date": "Jul 23 - Aug 22"},
    {"name": "Virgo", "icon": Icons.terrain_rounded, "date": "Aug 23 - Sep 22"},
    {"name": "Libra", "icon": Icons.air_rounded, "date": "Sep 23 - Oct 22"},
    {"name": "Scorpio", "icon": Icons.water_drop_rounded, "date": "Oct 23 - Nov 21"},
    {"name": "Sagittarius", "icon": Icons.local_fire_department_rounded, "date": "Nov 22 - Dec 21"},
    {"name": "Capricorn", "icon": Icons.terrain_rounded, "date": "Dec 22 - Jan 19"},
    {"name": "Aquarius", "icon": Icons.air_rounded, "date": "Jan 20 - Feb 18"},
    {"name": "Pisces", "icon": Icons.water_drop_rounded, "date": "Feb 19 - Mar 20"},
  ];

  String? _selectedSign;
  String _prediction = '';
  bool _isLoading = false;

  void _getPrediction(String sign) async {
    setState(() {
      _selectedSign = sign;
      _isLoading = true;
    });

    try {
      final res = await AstroApiService.chatAiAstrologer(question: "What is the daily horoscope for $sign?", category: "general");
      if (mounted) {
        setState(() {
          final analysis = res['analysis'] ?? res['answer'] ?? "The cosmos are aligning for $sign. Maintain positivity.";
          final predictions = res['predictions'] != null ? (res['predictions'] as List).join('\n• ') : '';
          
          if (predictions.isNotEmpty) {
            _prediction = "$analysis\n\nPredictions:\n• $predictions";
          } else {
            _prediction = analysis;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _prediction = "Error connecting to the cosmic energies for $sign. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Daily Horoscope', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _selectedSign == null
          ? _buildSignSelector(isDark)
          : _buildPredictionView(isDark),
    );
  }

  Widget _buildSignSelector(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select your Sun Sign to read your personalized daily cosmic prediction.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _signs.length,
            itemBuilder: (context, index) {
              final sign = _signs[index];
              return GestureDetector(
                onTap: () => _getPrediction(sign['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sign['icon'], color: const Color(0xFF0EA5E9), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        sign['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sign['date'],
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionView(bool isDark) {
    final signData = _signs.firstWhere((s) => s['name'] == _selectedSign);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(signData['icon'], size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            '$_selectedSign Horoscope',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: const Color(0xFF0EA5E9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator(color: Color(0xFF0EA5E9))
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Text(
                _prediction,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedSign = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Choose Another Sign'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0EA5E9),
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
