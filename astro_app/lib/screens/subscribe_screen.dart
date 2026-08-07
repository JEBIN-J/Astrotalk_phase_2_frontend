import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  int _selectedPlanIndex = 1; // Annual (best value)

  final List<Map<String, String>> _plans = [
    {'title': 'Monthly', 'price': '\$2.99 / mo', 'sub': 'Billed monthly', 'badge': ''},
    {'title': 'Annual', 'price': '\$19.99 / yr', 'sub': 'Save 45% (\$1.66/mo)', 'badge': 'MOST POPULAR'},
    {'title': 'Lifetime', 'price': '\$49.99', 'sub': 'One-time payment forever', 'badge': 'BEST VALUE'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ABC App PRO',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  blurRadius: 16,
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                      child: Text('PRO VIP', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black87)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Unlock Full Vedic Astrology Power', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Unlimited Kundli PDFs, advanced Dasha & Sade Sati analysis, and 100% ad-free.', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Selector
          Text('Select Your Plan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...List.generate(_plans.length, (index) {
            final plan = _plans[index];
            final isSelected = index == _selectedPlanIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.2 : 0.08)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7C3AED) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(plan['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                    if (plan['badge']!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                                        child: Text(plan['badge']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(plan['sub']!, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan['price']!,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF7C3AED)),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Features List
          Text('Everything Included in PRO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildProFeature('Unlimited High-Res PDF Horoscope Downloads', isDark),
          _buildProFeature('Complete 120-Year Vimshottari Dasha & Antardasha', isDark),
          _buildProFeature('36 Guna Detailed Ashtakoota Milan Compatibility', isDark),
          _buildProFeature('Swiss Ephemeris 0.001" High Precision Astronomical Engines', isDark),
          _buildProFeature('100% Ad-Free Pure Vedic Experience', isDark),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you! ABC App PRO activated successfully.', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              'Upgrade to PRO (${_plans[_selectedPlanIndex]['price']})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Cancel anytime. 7-day money back guarantee.', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeature(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
