import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_models.dart';

class KundliInteractiveChart extends StatelessWidget {
  final KundliChartStyle chartStyle;
  final bool isDark;

  const KundliInteractiveChart({
    super.key,
    required this.chartStyle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: CustomPaint(
        painter: _MultiKundliPainter(
          chartStyle: chartStyle,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _MultiKundliPainter extends CustomPainter {
  final KundliChartStyle chartStyle;
  final bool isDark;

  _MultiKundliPainter({
    required this.chartStyle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (chartStyle) {
      case KundliChartStyle.northIndian:
        _drawNorthIndianChart(canvas, size);
        break;
      case KundliChartStyle.southIndian:
        _drawSouthIndianChart(canvas, size);
        break;
      case KundliChartStyle.eastIndian:
        _drawEastIndianChart(canvas, size);
        break;
    }
  }

  void _drawNorthIndianChart(Canvas canvas, Size size) {
    final strokeColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.06)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, paint);

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Mid Diamond
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, paint);

    // House texts
    _drawText(canvas, 'Asc (1)\nMo, Ju', Offset(size.width * 0.5, size.height * 0.22), const Color(0xFFE11D48), true);
    _drawText(canvas, '2 (Su)', Offset(size.width * 0.25, size.height * 0.12));
    _drawText(canvas, '3 (Me)', Offset(size.width * 0.12, size.height * 0.25));
    _drawText(canvas, '4 (Ve)', Offset(size.width * 0.24, size.height * 0.5));
    _drawText(canvas, '5 (Ma)', Offset(size.width * 0.12, size.height * 0.75));
    _drawText(canvas, '6 (Ra)', Offset(size.width * 0.25, size.height * 0.88));
    _drawText(canvas, '7 (Sa)', Offset(size.width * 0.5, size.height * 0.76), const Color(0xFF2563EB));
    _drawText(canvas, '8 (Ke)', Offset(size.width * 0.75, size.height * 0.88));
    _drawText(canvas, '9', Offset(size.width * 0.88, size.height * 0.75));
    _drawText(canvas, '10', Offset(size.width * 0.76, size.height * 0.5));
    _drawText(canvas, '11', Offset(size.width * 0.88, size.height * 0.25));
    _drawText(canvas, '12', Offset(size.width * 0.75, size.height * 0.12));
  }

  void _drawSouthIndianChart(Canvas canvas, Size size) {
    final strokeColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.06)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Outer box
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    // 4x4 Grid with hollow center (2x2 center)
    final dx = w / 4;
    final dy = h / 4;

    // Vertical lines
    canvas.drawLine(Offset(dx, 0), Offset(dx, h), paint);
    canvas.drawLine(Offset(dx * 2, 0), Offset(dx * 2, dy), paint);
    canvas.drawLine(Offset(dx * 2, dy * 3), Offset(dx * 2, h), paint);
    canvas.drawLine(Offset(dx * 3, 0), Offset(dx * 3, h), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, dy), Offset(w, dy), paint);
    canvas.drawLine(Offset(0, dy * 2), Offset(dx, dy * 2), paint);
    canvas.drawLine(Offset(dx * 3, dy * 2), Offset(w, dy * 2), paint);
    canvas.drawLine(Offset(0, dy * 3), Offset(w, dy * 3), paint);

    // Center title
    _drawText(canvas, 'South Indian\nKundli (रासी)', Offset(w * 0.5, h * 0.5), strokeColor, true, 12);

    // Fixed Signs in South Indian System:
    // Top row: Pisces (0,0), Aries (1,0), Taurus (2,0), Gemini (3,0)
    _drawText(canvas, 'Pisces\nVe(Ex)', Offset(dx * 0.5, dy * 0.5));
    _drawText(canvas, 'Aries\nASC //', Offset(dx * 1.5, dy * 0.5), const Color(0xFFE11D48), true);
    _drawText(canvas, 'Taurus\nMo, Ju', Offset(dx * 2.5, dy * 0.5));
    _drawText(canvas, 'Gemini\n--', Offset(dx * 3.5, dy * 0.5));

    // Right col: Cancer (3,1), Leo (3,2)
    _drawText(canvas, 'Cancer\n--', Offset(dx * 3.5, dy * 1.5));
    _drawText(canvas, 'Leo\n--', Offset(dx * 3.5, dy * 2.5));

    // Bottom row: Virgo (3,3), Libra (2,3), Scorpio (1,3), Sagittarius (0,3)
    _drawText(canvas, 'Virgo\nSu, Ke', Offset(dx * 3.5, dy * 3.5));
    _drawText(canvas, 'Libra\n--', Offset(dx * 2.5, dy * 3.5));
    _drawText(canvas, 'Scorpio\n--', Offset(dx * 1.5, dy * 3.5));
    _drawText(canvas, 'Sagittarius\n--', Offset(dx * 0.5, dy * 3.5));

    // Left col: Capricorn (0,2), Aquarius (0,1)
    _drawText(canvas, 'Capricorn\nMa(Ex)', Offset(dx * 0.5, dy * 2.5));
    _drawText(canvas, 'Aquarius\nSa, Me', Offset(dx * 0.5, dy * 1.5));
  }

  void _drawEastIndianChart(Canvas canvas, Size size) {
    final strokeColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.06)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    // Diagonals and inner box
    canvas.drawLine(Offset.zero, Offset(w, h), paint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), paint);

    final midBox = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.5, height: h * 0.5);
    canvas.drawRect(midBox, paint);

    _drawText(canvas, 'Aries\nASC', Offset(w * 0.5, h * 0.14), const Color(0xFFE11D48), true);
    _drawText(canvas, 'Taurus\nMo, Ju', Offset(w * 0.86, h * 0.14));
    _drawText(canvas, 'Gemini\n--', Offset(w * 0.86, h * 0.5));
    _drawText(canvas, 'Cancer\n--', Offset(w * 0.86, h * 0.86));
    _drawText(canvas, 'Leo\n--', Offset(w * 0.5, h * 0.86));
    _drawText(canvas, 'Virgo\nSu, Ke', Offset(w * 0.14, h * 0.86));
    _drawText(canvas, 'Aquarius\nSa, Me', Offset(w * 0.14, h * 0.5));
    _drawText(canvas, 'Pisces\nVe(Ex)', Offset(w * 0.14, h * 0.14));
  }

  void _drawText(Canvas canvas, String text, Offset pos, [Color? color, bool isBold = false, double fontSize = 11]) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MultiKundliPainter oldDelegate) =>
      oldDelegate.chartStyle != chartStyle || oldDelegate.isDark != isDark;
}
