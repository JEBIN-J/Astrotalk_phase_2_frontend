import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _rating = 5;
  final List<String> _tags = ['Accurate Panchang', 'Beautiful Charts', 'Kundli Milan', 'Fast & Responsive', 'Accurate Gochara'];
  final Set<String> _selectedTags = {'Accurate Panchang', 'Beautiful Charts'};
  final TextEditingController _feedbackCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Rate ABC App',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCA8A04), Color(0xFFFACC15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_rounded, size: 54, color: Colors.white),
                const SizedBox(height: 10),
                Text('Enjoying ABC App?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Your rating helps us improve accurate astrological tools!', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Star Rating
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNum = index + 1;
                return IconButton(
                  iconSize: 42,
                  icon: Icon(
                    starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFACC15),
                  ),
                  onPressed: () => setState(() => _rating = starNum),
                );
              }),
            ),
          ),
          Center(
            child: Text(
              _rating == 5 ? 'Loved it! (5/5 Stars)' : '$_rating Stars',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFCA8A04)),
            ),
          ),
          const SizedBox(height: 24),

          Text('What did you like most?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSel = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                selectedColor: const Color(0xFFCA8A04).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFCA8A04),
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _feedbackCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write optional feedback or feature requests...',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for rating ABC App $_rating stars! ⭐', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFFCA8A04),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCA8A04),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Submit Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
