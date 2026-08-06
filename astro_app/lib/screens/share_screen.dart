import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const shareUrl = 'https://abc-app.vedicastrology.io/download';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Share ABC App',
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
                colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.share_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 10),
                Text('Share Vedic Wisdom', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Invite family & friends to get accurate Janam Kundli, Daily Panchang & Gochara transits!', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Your Referral Link', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareUrl,
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0D9488), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF0D9488)),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: shareUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('App share link copied to clipboard!', style: GoogleFonts.outfit()),
                        backgroundColor: const Color(0xFF0D9488),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Share via', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareBtn(context, 'WhatsApp', Icons.chat_rounded, const Color(0xFF25D366)),
              _buildShareBtn(context, 'Telegram', Icons.send_rounded, const Color(0xFF0088CC)),
              _buildShareBtn(context, 'Messages', Icons.message_rounded, const Color(0xFF3B82F6)),
              _buildShareBtn(context, 'More', Icons.more_horiz_rounded, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareBtn(BuildContext context, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing via $label...', style: GoogleFonts.outfit()),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
