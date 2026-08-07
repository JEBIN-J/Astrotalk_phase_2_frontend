import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_models.dart';

class KundliInteractiveChart extends StatelessWidget {
  final KundliChartStyle chartStyle;
  final bool isDark;
  final bool isNavamsha;
  final Map<String, dynamic>? kundliData;

  const KundliInteractiveChart({
    super.key,
    required this.chartStyle,
    required this.isDark,
    this.isNavamsha = false,
    this.kundliData,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: CustomPaint(
        painter: _MultiKundliPainter(
          chartStyle: chartStyle,
          isDark: isDark,
          isNavamsha: isNavamsha,
          kundliData: kundliData,
        ),
      ),
    );
  }
}

class _MultiKundliPainter extends CustomPainter {
  final KundliChartStyle chartStyle;
  final bool isDark;
  final bool isNavamsha;
  final Map<String, dynamic>? kundliData;

  _MultiKundliPainter({
    required this.chartStyle,
    required this.isDark,
    this.isNavamsha = false,
    this.kundliData,
  });

  // 12 Sign Names in order (1 to 12)
  static const List<String> signNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  String _planetShortCode(String fullName, String dignity, bool isRetro) {
    String code = 'Pl';
    final lower = fullName.toLowerCase();
    if (lower.contains('sun') || lower.contains('surya')) {
      code = 'Su';
    } else if (lower.contains('moon') || lower.contains('chandra')) {
      code = 'Mo';
    } else if (lower.contains('mars') || lower.contains('mangal')) {
      code = 'Ma';
    } else if (lower.contains('mercury') || lower.contains('budha')) {
      code = 'Me';
    } else if (lower.contains('jupiter') || lower.contains('guru') || lower.contains('brihaspati')) {
      code = 'Ju';
    } else if (lower.contains('venus') || lower.contains('shukra')) {
      code = 'Ve';
    } else if (lower.contains('saturn') || lower.contains('shani')) {
      code = 'Sa';
    } else if (lower.contains('rahu')) {
      code = 'Ra';
    } else if (lower.contains('ketu')) {
      code = 'Ke';
    } else if (lower.contains('ascendant') || lower.contains('lagna')) {
      code = 'ASC';
    }

    if (dignity.toLowerCase().contains('exalted') || dignity.contains('उच्च')) {
      code += '(Ex)';
    } else if (dignity.toLowerCase().contains('debilitated') || dignity.contains('नीच')) {
      code += '(Deb)';
    } else if (isRetro && !lower.contains('rahu') && !lower.contains('ketu')) {
      code += '(R)';
    }
    return code;
  }

  /// Map planets to signs (1 to 12) and houses (1 to 12)
  void _extractPlacements(
    Map<int, List<String>> planetsInSign,
    Map<int, List<String>> planetsInHouse,
    Map<String, dynamic>? data,
    int ascSignIdx,
  ) {
    if (data == null || data['planets'] == null) return;
    final planetsList = data['planets'] as List<dynamic>;

    for (final p in planetsList) {
      final name = p['name']?.toString() ?? '';
      if (name.toLowerCase().contains('ascendant') || name.toLowerCase().contains('lagna')) {
        continue;
      }
      
      int signIdx = -1;
      bool isVargottama = false;

      if (isNavamsha && p['navamsha'] != null && p['navamsha']['navamsha_sign_index'] != null) {
        signIdx = (p['navamsha']['navamsha_sign_index'] as num).toInt();
        isVargottama = p['navamsha']['is_vargottama'] == true;
      } else {
        final signName = p['sign']?.toString() ?? '';
        for (int i = 0; i < signNames.length; i++) {
          if (signNames[i].toLowerCase() == signName.toLowerCase()) {
            signIdx = i + 1;
            break;
          }
        }
      }

      final dignity = p['dignity']?.toString() ?? '';
      final isRetro = p['is_retrograde'] == true;
      String short = _planetShortCode(name, dignity, isRetro);
      if (isVargottama) {
        short += '(Vg)';
      }

      if (signIdx != -1) {
        planetsInSign.putIfAbsent(signIdx, () => []).add(short);
        final rawHouse = (((signIdx - ascSignIdx) % 12) + 1);
        final houseNum = rawHouse <= 0 ? rawHouse + 12 : rawHouse;
        planetsInHouse.putIfAbsent(houseNum, () => []).add(short);
      }
    }
  }

  int _getAscendantSignIndex(Map<String, dynamic>? data) {
    if (data == null) return 10; // Default Capricorn
    
    if (isNavamsha && data['planets'] != null) {
      for (final p in data['planets'] as List<dynamic>) {
        final name = p['name']?.toString().toLowerCase() ?? '';
        if ((name.contains('ascendant') || name.contains('lagna')) &&
            p['navamsha'] != null &&
            p['navamsha']['navamsha_sign_index'] != null) {
          return (p['navamsha']['navamsha_sign_index'] as num).toInt();
        }
      }
    }

    if (data['ascendant_sign_index'] != null) {
      return (data['ascendant_sign_index'] as num).toInt();
    }
    final ascSign = data['ascendant_sign']?.toString() ?? data['ascendant_lagna']?.toString() ?? '';
    for (int i = 0; i < signNames.length; i++) {
      if (ascSign.toLowerCase().contains(signNames[i].toLowerCase())) {
        return i + 1;
      }
    }
    return 10;
  }


  @override
  void paint(Canvas canvas, Size size) {
    final ascSignIdx = _getAscendantSignIndex(kundliData);
    final Map<int, List<String>> planetsInSign = {};
    final Map<int, List<String>> planetsInHouse = {};
    _extractPlacements(planetsInSign, planetsInHouse, kundliData, ascSignIdx);

    switch (chartStyle) {
      case KundliChartStyle.northIndian:
        _drawNorthIndianChart(canvas, size, ascSignIdx, planetsInHouse);
        break;
      case KundliChartStyle.southIndian:
        _drawSouthIndianChart(canvas, size, ascSignIdx, planetsInSign);
        break;
      case KundliChartStyle.eastIndian:
        _drawEastIndianChart(canvas, size, ascSignIdx, planetsInSign);
        break;
    }
  }

  // =========================================================================
  // 1. NORTH INDIAN DIAMOND CHART (Dynamic Houses 1-12)
  // =========================================================================
  void _drawNorthIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInHouse,
  ) {
    final strokeColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.05)
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

    // House Center Positions (1 to 12)
    final housePositions = [
      Offset(size.width * 0.50, size.height * 0.22), // H1 (Top Diamond)
      Offset(size.width * 0.25, size.height * 0.12), // H2 (Top Left)
      Offset(size.width * 0.12, size.height * 0.25), // H3 (Far Left Top)
      Offset(size.width * 0.24, size.height * 0.50), // H4 (Left Diamond)
      Offset(size.width * 0.12, size.height * 0.75), // H5 (Far Left Bottom)
      Offset(size.width * 0.25, size.height * 0.88), // H6 (Bottom Left)
      Offset(size.width * 0.50, size.height * 0.76), // H7 (Bottom Diamond)
      Offset(size.width * 0.75, size.height * 0.88), // H8 (Bottom Right)
      Offset(size.width * 0.88, size.height * 0.75), // H9 (Far Right Bottom)
      Offset(size.width * 0.76, size.height * 0.50), // H10 (Right Diamond)
      Offset(size.width * 0.88, size.height * 0.25), // H11 (Far Right Top)
      Offset(size.width * 0.75, size.height * 0.12), // H12 (Top Right)
    ];

    for (int h = 1; h <= 12; h++) {
      final signNumber = ((ascSignIdx + h - 2) % 12) + 1;
      final planets = planetsInHouse[h] ?? [];
      final planetsText = planets.isNotEmpty ? planets.join(', ') : '';

      String label;
      if (h == 1) {
        label = 'Asc ($signNumber)\n${planetsText.isNotEmpty ? planetsText : '--'}';
      } else {
        label = '$signNumber\n${planetsText.isNotEmpty ? planetsText : ''}'.trim();
      }

      final isAsc = (h == 1);
      final isKendra = [1, 4, 7, 10].contains(h);
      final textColor = isAsc
          ? const Color(0xFFE11D48)
          : (isKendra ? const Color(0xFF4338CA) : (isDark ? Colors.white : const Color(0xFF0F172A)));

      _drawText(
        canvas,
        label,
        housePositions[h - 1],
        textColor,
        isAsc || planetsText.isNotEmpty,
        isAsc ? 11.5 : 10.5,
      );
    }
  }

  // =========================================================================
  // 2. SOUTH INDIAN FIXED SIGN CHART (Clockwise 12 Signs)
  // =========================================================================
  void _drawSouthIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInSign,
  ) {
    final strokeColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.05)
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

    // Center Title Box
    final centerTitle = isNavamsha
        ? 'D9 Navamsha\nKundli (Dharma)'
        : 'D1 Rashi\nKundli (Natal)';
    _drawText(
      canvas,
      centerTitle,
      Offset(w * 0.5, h * 0.5),
      strokeColor,
      true,
      13.0,
    );

    // Fixed Signs in South Indian System Grid Layout:
    // (col, row, sign_index_1_based)
    final gridPositions = [
      (0, 0, 12), // Pisces (मीन)
      (1, 0, 1),  // Aries (मेष)
      (2, 0, 2),  // Taurus (वृषभ)
      (3, 0, 3),  // Gemini (मिथुन)
      (3, 1, 4),  // Cancer (कर्क)
      (3, 2, 5),  // Leo (सिंह)
      (3, 3, 6),  // Virgo (कन्या)
      (2, 3, 7),  // Libra (तुला)
      (1, 3, 8),  // Scorpio (वृश्चिक)
      (0, 3, 9),  // Sagittarius (धनु)
      (0, 2, 10), // Capricorn (मकर)
      (0, 1, 11), // Aquarius (कुम्भ)
    ];

    for (final item in gridPositions) {
      final col = item.$1;
      final row = item.$2;
      final sIdx = item.$3;
      final sName = signNames[sIdx - 1];
      final isAsc = (sIdx == ascSignIdx);
      final planets = planetsInSign[sIdx] ?? [];

      final cellLeft = dx * col;
      final cellTop = dy * row;

      // Draw Sign Name at top center of box
      _drawText(
        canvas,
        sName,
        Offset(cellLeft + dx * 0.5, cellTop + 14),
        isDark ? Colors.white60 : Colors.black45,
        false,
        9.5,
      );

      // Draw Planets and ASC centered in the cell body
      List<String> centerItems = [];
      if (isAsc) {
        centerItems.add('ASC //');
      }
      if (planets.isNotEmpty) {
        centerItems.addAll(planets);
      }

      if (centerItems.isNotEmpty) {
        final label = centerItems.join('\n');
        final textColor = isAsc
            ? const Color(0xFFE11D48)
            : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857));

        _drawText(
          canvas,
          label,
          Offset(cellLeft + dx * 0.5, cellTop + dy * 0.58),
          textColor,
          true,
          11.0,
        );
      } else {
        _drawText(
          canvas,
          '—',
          Offset(cellLeft + dx * 0.5, cellTop + dy * 0.58),
          isDark ? Colors.white24 : Colors.black26,
          false,
          11.0,
        );
      }
    }
  }

  // =========================================================================
  // 3. EAST INDIAN SUN CHART (सूर्य चार्ट)
  // =========================================================================
  void _drawEastIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInSign,
  ) {
    final strokeColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.12 : 0.05)
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

    final eastPositions = [
      Offset(w * 0.50, h * 0.14), // Aries (Top Center)
      Offset(w * 0.86, h * 0.14), // Taurus (Top Right)
      Offset(w * 0.86, h * 0.50), // Gemini (Right Mid)
      Offset(w * 0.86, h * 0.86), // Cancer (Bottom Right)
      Offset(w * 0.50, h * 0.86), // Leo (Bottom Center)
      Offset(w * 0.14, h * 0.86), // Virgo (Bottom Left)
      Offset(w * 0.14, h * 0.50), // Libra (Left Mid)
      Offset(w * 0.14, h * 0.14), // Scorpio (Top Left)
    ];

    for (int sIdx = 1; sIdx <= 8; sIdx++) {
      final sName = signNames[sIdx - 1];
      final isAsc = (sIdx == ascSignIdx);
      final planets = planetsInSign[sIdx] ?? [];

      List<String> lines = [sName];
      if (isAsc) lines.add('ASC');
      if (planets.isNotEmpty) {
        lines.add(planets.join(', '));
      } else if (!isAsc) {
        lines.add('--');
      }

      final label = lines.join('\n');
      final textColor = isAsc ? const Color(0xFFE11D48) : (isDark ? Colors.white : const Color(0xFF1E293B));
      _drawText(canvas, label, eastPositions[sIdx - 1], textColor, isAsc || planets.isNotEmpty, 10.5);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, [
    Color? color,
    bool isBold = false,
    double fontSize = 11,
  ]) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          height: 1.15,
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
      oldDelegate.chartStyle != chartStyle ||
      oldDelegate.isDark != isDark ||
      oldDelegate.kundliData != kundliData;
}
