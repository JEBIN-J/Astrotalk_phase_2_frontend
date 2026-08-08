import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_models.dart';

class KundliInteractiveChart extends StatelessWidget {
  final KundliChartStyle chartStyle;
  final bool isDark;
  final String chartTypeKey; // 'D-1', 'D-9', 'D-10', 'D-2', 'D-3', 'D-4', 'D-7', 'D-12', 'D-16', 'D-20', 'D-24', 'D-27', 'D-30', 'D-60', 'Bhava'
  final bool showUpagrahas;
  final bool showDegrees;
  final Map<String, dynamic>? kundliData;

  const KundliInteractiveChart({
    super.key,
    required this.chartStyle,
    required this.isDark,
    this.chartTypeKey = 'D-1',
    this.showUpagrahas = true,
    this.showDegrees = true,
    this.kundliData,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: _MultiKundliPainter(
          chartStyle: chartStyle,
          isDark: isDark,
          chartTypeKey: chartTypeKey,
          showUpagrahas: showUpagrahas,
          showDegrees: showDegrees,
          kundliData: kundliData,
        ),
      ),
    );
  }
}

class _MultiKundliPainter extends CustomPainter {
  final KundliChartStyle chartStyle;
  final bool isDark;
  final String chartTypeKey;
  final bool showUpagrahas;
  final bool showDegrees;
  final Map<String, dynamic>? kundliData;

  _MultiKundliPainter({
    required this.chartStyle,
    required this.isDark,
    required this.chartTypeKey,
    required this.showUpagrahas,
    required this.showDegrees,
    required this.kundliData,
  });

  static const List<String> signNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];



  String _formatPlanetLabel(
    String pName,
    String degreeFormatted,
    bool isRetro,
    bool isCombust,
    String? customMarker,
  ) {
    String code = 'Pl';
    final lower = pName.toLowerCase();
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
      code = 'As';
    }

    String markers = '';
    if (isRetro && !lower.contains('rahu') && !lower.contains('ketu')) {
      markers += '(R)';
    }
    if (isCombust && !lower.contains('sun')) {
      markers += '(C)';
    }
    if (markers.isEmpty && customMarker != null && customMarker.isNotEmpty) {
      markers = customMarker;
    }

    String degStr = '';
    if (showDegrees && degreeFormatted.isNotEmpty) {
      final cleaned = degreeFormatted
          .replaceAll('°', ':')
          .replaceAll("'", ':')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        final d = parts[0].trim();
        final m = parts[1].trim();
        degStr = ' $d:$m';
      }
    }

    return '$code$markers$degStr'.trim();
  }

  void _extractPlacements(
    Map<int, List<String>> planetsInSign,
    Map<int, List<String>> planetsInHouse,
    Map<String, dynamic>? data,
    int ascSignIdx,
  ) {
    if (data == null) return;

    // Divisional Chart (D-2..D-60)
    if (chartTypeKey != 'D-1' &&
        chartTypeKey != 'Bhava' &&
        data['divisional_charts'] != null &&
        data['divisional_charts'][chartTypeKey] != null) {
      final vData = data['divisional_charts'][chartTypeKey];
      final pList = vData['planets'] as List<dynamic>? ?? [];
      final vAscSignIdx = (vData['ascendant_sign_index'] as num?)?.toInt() ?? ascSignIdx;

      for (final p in pList) {
        final pName = p['planet']?.toString() ?? '';
        final sIdx = (p['sign_index'] as num?)?.toInt() ?? 1;
        final rawHouse = ((sIdx - vAscSignIdx) % 12) + 1;
        final hNum = rawHouse <= 0 ? rawHouse + 12 : rawHouse;
        final isRetro = p['is_retrograde'] == true;
        final isCombust = p['is_combust'] == true;
        final marker = p['status_marker']?.toString() ?? '';

        final formatted = _formatPlanetLabel(pName, '', isRetro, isCombust, marker);
        planetsInSign.putIfAbsent(sIdx, () => []).add(formatted);
        planetsInHouse.putIfAbsent(hNum, () => []).add(formatted);
      }
      return;
    }

    // Bhava Chalit placements
    if (chartTypeKey == 'Bhava' && data['bhava_chalit'] != null) {
      final bData = data['bhava_chalit'];
      final pList = bData['planets'] as List<dynamic>? ?? [];

      for (final p in pList) {
        final pName = p['planet']?.toString() ?? '';
        final bhavaHouse = (p['bhava_house'] as num?)?.toInt() ?? 1;
        final degStr = p['degree_formatted']?.toString() ?? '';
        final isRetro = p['is_retrograde'] == true;
        final isCombust = p['is_combust'] == true;

        final formatted = _formatPlanetLabel(pName, degStr, isRetro, isCombust, null);
        planetsInHouse.putIfAbsent(bhavaHouse, () => []).add(formatted);
        final sIdx = ((ascSignIdx + bhavaHouse - 2) % 12) + 1;
        planetsInSign.putIfAbsent(sIdx, () => []).add(formatted);
      }
      return;
    }

    // Default D-1 Rashi or D-9 Navamsha
    final isD9 = chartTypeKey == 'D-9';
    if (data['planets'] != null) {
      final planetsList = data['planets'] as List<dynamic>;

      for (final p in planetsList) {
        final name = p['name']?.toString() ?? '';

        int signIdx = -1;
        String degFormatted = p['degree_formatted']?.toString() ?? p['degree_dms']?.toString() ?? '';

        if (isD9 && p['navamsha'] != null && p['navamsha']['navamsha_sign_index'] != null) {
          signIdx = (p['navamsha']['navamsha_sign_index'] as num).toInt();
        } else {
          if (p['sign_index'] != null) {
            signIdx = (p['sign_index'] as num).toInt();
          } else {
            final signName = p['sign']?.toString() ?? '';
            for (int i = 0; i < signNames.length; i++) {
              if (signNames[i].toLowerCase() == signName.toLowerCase()) {
                signIdx = i + 1;
                break;
              }
            }
          }
        }

        if (signIdx != -1) {
          final isRetro = p['is_retrograde'] == true;
          final isCombust = p['is_combust'] == true;
          final marker = p['status_marker']?.toString() ?? '';

          final formatted = _formatPlanetLabel(name, degFormatted, isRetro, isCombust, marker);

          planetsInSign.putIfAbsent(signIdx, () => []).add(formatted);
          final rawHouse = (((signIdx - ascSignIdx) % 12) + 1);
          final houseNum = rawHouse <= 0 ? rawHouse + 12 : rawHouse;
          planetsInHouse.putIfAbsent(houseNum, () => []).add(formatted);
        }
      }
    }

    // Upagrahas in D-1 chart
    if (showUpagrahas && !isD9 && data['upagrahas'] != null) {
      final upagrahasList = data['upagrahas'] as List<dynamic>;
      for (final u in upagrahasList) {
        final code = u['short_code']?.toString() ?? 'Up';
        if (code == 'Md' || code == 'Gk' || code == 'Dh' || code == 'Vy' || code == 'Pv') {
          final sIdx = (u['sign_index'] as num?)?.toInt() ?? 1;
          final degStr = u['degree_formatted']?.toString() ?? '';
          String label = code;
          if (showDegrees && degStr.isNotEmpty) {
            final parts = degStr.split(':');
            if (parts.length >= 2) {
              label += ' ${parts[0]}:${parts[1]}';
            }
          }
          planetsInSign.putIfAbsent(sIdx, () => []).add(label);
          final rawHouse = ((sIdx - ascSignIdx) % 12) + 1;
          final hNum = rawHouse <= 0 ? rawHouse + 12 : rawHouse;
          planetsInHouse.putIfAbsent(hNum, () => []).add(label);
        }
      }
    }

    // Ensure Ascendant is always present in planetsInSign and planetsInHouse
    final hasAscInSign = (planetsInSign[ascSignIdx] ?? []).any((p) => p.startsWith('As') || p.startsWith('ASC'));
    if (!hasAscInSign) {
      final ascDeg = data['ascendant_degree_formatted']?.toString() ?? data['ascendant_degree']?.toString() ?? '';
      final ascLabel = _formatPlanetLabel('Ascendant', ascDeg, false, false, null);
      planetsInSign.putIfAbsent(ascSignIdx, () => []).insert(0, ascLabel.isNotEmpty ? ascLabel : 'As');
      planetsInHouse.putIfAbsent(1, () => []).insert(0, ascLabel.isNotEmpty ? ascLabel : 'As');
    }
  }

  int _getAscendantSignIndex(Map<String, dynamic>? data) {
    if (data == null) return 11; // Default Aquarius (Kumbha)

    if (chartTypeKey != 'D-1' &&
        chartTypeKey != 'Bhava' &&
        data['divisional_charts'] != null &&
        data['divisional_charts'][chartTypeKey] != null) {
      return (data['divisional_charts'][chartTypeKey]['ascendant_sign_index'] as num?)?.toInt() ?? 11;
    }

    if (chartTypeKey == 'D-9' && data['planets'] != null) {
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
    return 11;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ascSignIdx = _getAscendantSignIndex(kundliData);
    final Map<int, List<String>> planetsInSign = {};
    final Map<int, List<String>> planetsInHouse = {};
    _extractPlacements(planetsInSign, planetsInHouse, kundliData, ascSignIdx);

    switch (chartStyle) {
      case KundliChartStyle.southIndian:
        _drawSouthIndianChart(canvas, size, ascSignIdx, planetsInSign);
        break;
      case KundliChartStyle.northIndian:
        _drawNorthIndianChart(canvas, size, ascSignIdx, planetsInHouse);
        break;
      case KundliChartStyle.eastIndian:
        _drawEastIndianChart(canvas, size, ascSignIdx, planetsInSign);
        break;
    }
  }

  // =========================================================================
  // 1. SOUTH INDIAN SQUARE MODEL CHART (12 Fixed Sign Grid)
  // =========================================================================
  void _drawSouthIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInSign,
  ) {
    final w = size.width;
    final h = size.height;

    // Palette matching modern South Indian Vedic charts (Teal / Slate / Indigo)
    final gridStrokeColor = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.45) : const Color(0xFF475569);
    final bgFillColor = isDark ? const Color(0xFF13222E) : const Color(0xFFF8FAFC);
    final centerBoxBg = isDark ? const Color(0xFF0D1821) : const Color(0xFFEEF2F6);
    final ascColor = const Color(0xFF38BDF8); // Sky Blue for Ascendant / Lagna
    final moonColor = const Color(0xFF38BDF8); // Cyan for Moon

    final linePaint = Paint()
      ..color = gridStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final borderPaint = Paint()
      ..color = gridStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final bgPaint = Paint()
      ..color = bgFillColor
      ..style = PaintingStyle.fill;

    // Outer Card Rect
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    final dx = w / 4;
    final dy = h / 4;

    // 4x4 Grid Outer Lines
    // Vertical lines
    canvas.drawLine(Offset(dx, 0), Offset(dx, h), linePaint);
    canvas.drawLine(Offset(dx * 2, 0), Offset(dx * 2, dy), linePaint);
    canvas.drawLine(Offset(dx * 2, dy * 3), Offset(dx * 2, h), linePaint);
    canvas.drawLine(Offset(dx * 3, 0), Offset(dx * 3, h), linePaint);

    // Horizontal lines
    canvas.drawLine(Offset(0, dy), Offset(w, dy), linePaint);
    canvas.drawLine(Offset(0, dy * 2), Offset(dx, dy * 2), linePaint);
    canvas.drawLine(Offset(dx * 3, dy * 2), Offset(w, dy * 2), linePaint);
    canvas.drawLine(Offset(0, dy * 3), Offset(w, dy * 3), linePaint);

    // Center Hollow 2x2 Box
    final centerRect = Rect.fromLTWH(dx, dy, dx * 2, dy * 2);
    final centerPaint = Paint()
      ..color = centerBoxBg
      ..style = PaintingStyle.fill;
    canvas.drawRect(centerRect, centerPaint);
    canvas.drawRect(centerRect, linePaint);

    // Center Chart Title
    String centerTitle = 'Rashi (D-1)';
    if (chartTypeKey == 'D-9') {
      centerTitle = 'Navamsha (D-9)';
    } else if (chartTypeKey == 'Bhava') {
      centerTitle = 'Bhava Chalit';
    } else if (chartTypeKey != 'D-1') {
      centerTitle = chartTypeKey;
    }

    _drawText(
      canvas,
      centerTitle,
      Offset(w * 0.5, h * 0.50),
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
      true,
      14.0,
    );

    // Fixed 12 Signs in South Indian System Layout (Clockwise from Pisces):
    final gridPositions = [
      (0, 0, 12), // Pisces (मीन) - Top Left
      (1, 0, 1),  // Aries (मेष) - Top Mid-Left
      (2, 0, 2),  // Taurus (वृषभ) - Top Mid-Right
      (3, 0, 3),  // Gemini (मिथुन) - Top Right
      (3, 1, 4),  // Cancer (कर्क) - Right Top-Mid
      (3, 2, 5),  // Leo (सिंह) - Right Bottom-Mid
      (3, 3, 6),  // Virgo (कन्या) - Bottom Right
      (2, 3, 7),  // Libra (तुला) - Bottom Mid-Right
      (1, 3, 8),  // Scorpio (वृश्चिक) - Bottom Mid-Left
      (0, 3, 9),  // Sagittarius (धनु) - Bottom Left
      (0, 2, 10), // Capricorn (मकर) - Left Bottom-Mid
      (0, 1, 11), // Aquarius (कुम्भ) - Left Top-Mid
    ];

    for (final item in gridPositions) {
      final col = item.$1;
      final row = item.$2;
      final sIdx = item.$3;
      final isAsc = (sIdx == ascSignIdx);
      final rawPlanets = planetsInSign[sIdx] ?? [];

      final cellLeft = dx * col;
      final cellTop = dy * row;

      // Draw classical South Indian double diagonal lines for Lagna / Ascendant
      if (isAsc) {
        final ascSlashPaint = Paint()
          ..color = (isDark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48)).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawLine(
          Offset(cellLeft + 4, cellTop + 14),
          Offset(cellLeft + dx - 14, cellTop + dy - 4),
          ascSlashPaint,
        );
        canvas.drawLine(
          Offset(cellLeft + 14, cellTop + 4),
          Offset(cellLeft + dx - 4, cellTop + dy - 14),
          ascSlashPaint,
        );
      }

      // Small subtle Sign abbreviation in top-left corner (e.g. Ar, Ta, Ge)
      final signShort = ['Ar', 'Ta', 'Ge', 'Cn', 'Le', 'Vi', 'Li', 'Sc', 'Sg', 'Cp', 'Aq', 'Pi'][sIdx - 1];
      _drawText(
        canvas,
        signShort,
        Offset(cellLeft + 12, cellTop + 9),
        isDark ? Colors.white24 : Colors.black26,
        false,
        8.5,
      );

      // Draw Planets inside the cell
      if (rawPlanets.isNotEmpty) {
        final count = rawPlanets.length;
        final fontSize = count > 3 ? 9.0 : (count > 2 ? 10.0 : 10.5);
        final lineHeight = fontSize * 1.35;
        final totalTextHeight = count * lineHeight;
        final startY = (cellTop + (dy - totalTextHeight) / 2) + (fontSize * 0.4);

        for (int pIdx = 0; pIdx < count; pIdx++) {
          final pText = rawPlanets[pIdx];
          final isPAs = pText.startsWith('As');
          final isPMo = pText.startsWith('Mo');
          final isUp = pText.startsWith('Md') || pText.startsWith('Gk') || pText.startsWith('Dh') || pText.startsWith('Vy') || pText.startsWith('Pv');

          Color textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
          if (isPAs) {
            textColor = ascColor;
          } else if (isPMo) {
            textColor = moonColor;
          } else if (isUp) {
            textColor = const Color(0xFF94A3B8);
          } else if (pText.contains('(R)')) {
            textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
          }

          _drawText(
            canvas,
            pText,
            Offset(cellLeft + dx * 0.5, startY + (pIdx * lineHeight)),
            textColor,
            isPAs || isPMo || pText.contains('(R)'),
            fontSize,
          );
        }
      }
    }
  }

  // =========================================================================
  // 2. NORTH INDIAN DIAMOND CHART (Dynamic Houses 1-12)
  // =========================================================================
  void _drawNorthIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInHouse,
  ) {
    final strokeColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4338CA);
    final ascColor = const Color(0xFFE11D48);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bgFill = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;

    final kendraFill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.09 : 0.04)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), bgFill);

    final w = size.width;
    final h = size.height;

    final kendraPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(kendraPath, kendraFill);

    // Outer border
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), linePaint);

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(w, h), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);

    // Inner Diamond
    canvas.drawPath(kendraPath, linePaint);

    final houseSignPositions = [
      Offset(w * 0.50, h * 0.08), // H1 (Top Diamond)
      Offset(w * 0.32, h * 0.07), // H2 (Top Left)
      Offset(w * 0.07, h * 0.32), // H3 (Far Left Top)
      Offset(w * 0.40, h * 0.50), // H4 (Left Diamond)
      Offset(w * 0.07, h * 0.68), // H5 (Far Left Bottom)
      Offset(w * 0.32, h * 0.93), // H6 (Bottom Left)
      Offset(w * 0.50, h * 0.60), // H7 (Bottom Diamond)
      Offset(w * 0.68, h * 0.93), // H8 (Bottom Right)
      Offset(w * 0.93, h * 0.68), // H9 (Far Right Bottom)
      Offset(w * 0.60, h * 0.50), // H10 (Right Diamond)
      Offset(w * 0.93, h * 0.32), // H11 (Far Right Top)
      Offset(w * 0.68, h * 0.07), // H12 (Top Right)
    ];

    final housePlanetCenters = [
      Offset(w * 0.50, h * 0.23), // H1
      Offset(w * 0.24, h * 0.14), // H2
      Offset(w * 0.12, h * 0.25), // H3
      Offset(w * 0.24, h * 0.50), // H4
      Offset(w * 0.12, h * 0.75), // H5
      Offset(w * 0.24, h * 0.86), // H6
      Offset(w * 0.50, h * 0.77), // H7
      Offset(w * 0.76, h * 0.86), // H8
      Offset(w * 0.88, h * 0.75), // H9
      Offset(w * 0.76, h * 0.50), // H10
      Offset(w * 0.88, h * 0.25), // H11
      Offset(w * 0.76, h * 0.14), // H12
    ];

    for (int hIdx = 1; hIdx <= 12; hIdx++) {
      final signNumber = ((ascSignIdx + hIdx - 2) % 12) + 1;
      final isAscHouse = (hIdx == 1);
      final planets = planetsInHouse[hIdx] ?? [];

      _drawText(
        canvas,
        '$signNumber',
        houseSignPositions[hIdx - 1],
        isAscHouse
            ? ascColor
            : (isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1)),
        true,
        isAscHouse ? 11.5 : 10.0,
      );

      if (planets.isNotEmpty) {
        final count = planets.length;
        final fontSize = count > 3 ? 8.5 : (count > 2 ? 9.5 : 10.5);
        final lineHeight = fontSize * 1.32;
        final startY = housePlanetCenters[hIdx - 1].dy - ((count - 1) * lineHeight / 2);

        for (int p = 0; p < count; p++) {
          final pText = planets[p];
          final isPAs = pText.startsWith('As');
          final isUp = pText.startsWith('Md') || pText.startsWith('Gk') || pText.startsWith('Dh') || pText.startsWith('Vy') || pText.startsWith('Pv');

          Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          if (isPAs) {
            textColor = ascColor;
          } else if (isUp) {
            textColor = const Color(0xFF6366F1);
          } else if (pText.contains('(R)')) {
            textColor = const Color(0xFFDC2626);
          }

          _drawText(
            canvas,
            pText,
            Offset(housePlanetCenters[hIdx - 1].dx, startY + (p * lineHeight)),
            textColor,
            isPAs || pText.contains('(R)'),
            fontSize,
          );
        }
      }
    }
  }

  // =========================================================================
  // 3. EAST INDIAN SUN CHART
  // =========================================================================
  void _drawEastIndianChart(
    Canvas canvas,
    Size size,
    int ascSignIdx,
    Map<int, List<String>> planetsInSign,
  ) {
    final strokeColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    final ascColor = const Color(0xFFE11D48);

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fill = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.08 : 0.04)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(14)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(14)), paint);

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
      if (planets.isNotEmpty) {
        lines.addAll(planets);
      }

      final label = lines.join('\n');
      final textColor = isAsc ? ascColor : (isDark ? Colors.white : const Color(0xFF1E293B));
      _drawText(canvas, label, eastPositions[sIdx - 1], textColor, isAsc || planets.isNotEmpty, 9.5);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, [
    Color? color,
    bool isBold = false,
    double fontSize = 10,
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
      oldDelegate.chartTypeKey != chartTypeKey ||
      oldDelegate.showUpagrahas != showUpagrahas ||
      oldDelegate.showDegrees != showDegrees ||
      oldDelegate.kundliData != kundliData;
}
