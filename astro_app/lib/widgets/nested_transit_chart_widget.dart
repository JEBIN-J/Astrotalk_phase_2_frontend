import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NestedNorthIndianTransitChart extends StatelessWidget {
  final Map<String, dynamic>? natalData;
  final Map<String, dynamic>? transitData;
  final bool isDark;
  final bool showDegrees;
  final String title;
  final String? subtitle;
  final String chartTypeKey;
  final bool isRealTime;

  const NestedNorthIndianTransitChart({
    super.key,
    required this.natalData,
    required this.transitData,
    required this.isDark,
    this.showDegrees = true,
    this.title = 'Transit Chart',
    this.subtitle,
    this.chartTypeKey = 'D-1',
    this.isRealTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF0284C7).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Classic Blue Header Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4.w),
                if (isRealTime) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'LIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 11.sp, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        'Pinch to zoom',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Chart Canvas matching the standard chart aspect ratio (1.0)
          ClipRRect(
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: AspectRatio(
                aspectRatio: 1.0, // Matches standard chart height exactly
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  clipBehavior: Clip.hardEdge,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _NestedNorthIndianTransitPainter(
                      natalData: natalData,
                      transitData: transitData,
                      isDark: isDark,
                      showDegrees: showDegrees,
                      chartTypeKey: chartTypeKey,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Compact Legend
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14.r)),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Inner: Natal Chart',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Outer: Transit Planets',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NestedNorthIndianTransitPainter extends CustomPainter {
  final Map<String, dynamic>? natalData;
  final Map<String, dynamic>? transitData;
  final bool isDark;
  final bool showDegrees;
  final String chartTypeKey;

  _NestedNorthIndianTransitPainter({
    required this.natalData,
    required this.transitData,
    required this.isDark,
    required this.showDegrees,
    this.chartTypeKey = 'D-1',
  });

  static const List<String> signNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  int _getAscSignIdx(Map<String, dynamic>? data) {
    if (data == null) return 8; // Scorpio fallback

    // If Navamsa (D-9), get Navamsa ascendant
    if (chartTypeKey == 'D-9') {
      if (data['divisional_charts'] != null &&
          data['divisional_charts']['D-9'] != null) {
        final d9 = data['divisional_charts']['D-9'];
        if (d9['ascendant_sign_index'] != null) {
          return (d9['ascendant_sign_index'] as num).toInt();
        }
        final ascP = (d9['planets'] as List<dynamic>?)?.firstWhere(
          (p) {
            final n = (p['planet'] ?? p['name'] ?? '').toString().toLowerCase();
            return n.contains('ascendant') || n.contains('lagna');
          },
          orElse: () => null,
        );
        if (ascP != null && ascP['sign_index'] != null) {
          return (ascP['sign_index'] as num).toInt();
        }
      }
      if (data['navamsha_ascendant_sign_index'] != null) {
        return (data['navamsha_ascendant_sign_index'] as num).toInt();
      }
    }

    if (data['ascendant_sign_index'] != null) {
      return (data['ascendant_sign_index'] as num).toInt();
    }
    String ascSign = data['ascendant_sign']?.toString() ??
        data['ascendant_lagna']?.toString() ??
        '';
    if (ascSign.isEmpty && data['overview'] != null && data['overview']['ascendant_sign'] != null) {
      ascSign = data['overview']['ascendant_sign'].toString();
    }
    for (int i = 0; i < signNames.length; i++) {
      if (ascSign.toLowerCase().contains(signNames[i].toLowerCase())) {
        return i + 1;
      }
    }
    if (data['planets'] != null) {
      for (final p in data['planets']) {
        final pName = (p['planet'] ?? p['name'] ?? '').toString().toLowerCase();
        if (pName.contains('ascendant') || pName.contains('lagna')) {
          if (p['sign_index'] != null) return (p['sign_index'] as num).toInt();
          final sName = p['sign']?.toString() ?? '';
          for (int i = 0; i < signNames.length; i++) {
            if (sName.toLowerCase() == signNames[i].toLowerCase()) return i + 1;
          }
        }
      }
    }
    return 8;
  }

  void _extractHousePlacements(
    Map<int, List<_PlanetEntry>> targetMap,
    Map<String, dynamic>? data,
    int natalAscSignIdx, {
    bool isTransit = false,
  }) {
    if (data == null) return;

    // 1. If Navamsa (D-9)
    if (chartTypeKey == 'D-9') {
      List<dynamic>? pList;
      if (data['divisional_charts'] != null &&
          data['divisional_charts']['D-9'] != null &&
          data['divisional_charts']['D-9']['planets'] != null) {
        pList = data['divisional_charts']['D-9']['planets'] as List<dynamic>;
      } else if (data['planets'] != null) {
        pList = data['planets'] as List<dynamic>;
      }

      if (pList != null) {
        for (final p in pList) {
          final pName = (p['planet'] ?? p['name'] ?? '').toString().trim();
          if (pName.isEmpty) continue;
          final lower = pName.toLowerCase();
          if (lower.contains('fortuna') || lower.contains('for ') || lower == 'for') continue;

          int signIdx = (p['navamsha_sign_index'] ?? p['sign_index'] as num?)?.toInt() ?? 0;
          if (signIdx < 1 || signIdx > 12) {
            final sName = (p['navamsha_sign'] ?? p['sign'] ?? '').toString().trim();
            for (int i = 0; i < signNames.length; i++) {
              if (sName.toLowerCase() == signNames[i].toLowerCase()) {
                signIdx = i + 1;
                break;
              }
            }
          }
          if (signIdx < 1 || signIdx > 12) continue;

          final isRetro = p['is_retrograde'] == true;
          final degFormatted = (p['degree_formatted'] ?? p['degree'] ?? '').toString().trim();

          String label = _formatCode(pName);
          if (isRetro && label != 'Asc') label += '(R)';

          String degLabel = '';
          if (showDegrees && degFormatted.isNotEmpty) {
            degLabel = degFormatted;
          }

          final houseNum = ((signIdx - natalAscSignIdx + 12) % 12) + 1;
          targetMap.putIfAbsent(houseNum, () => []).add(
            _PlanetEntry(
              rawName: pName,
              displayLabel: label,
              degLabel: degLabel,
              color: _getPlanetColor(pName, isDark),
            ),
          );
        }
      }
      return;
    }

    // 2. If Bhava Chalit
    if (chartTypeKey == 'Bhava') {
      if (data['bhava_chalit'] != null && data['bhava_chalit']['planets'] != null) {
        final pList = data['bhava_chalit']['planets'] as List<dynamic>;
        for (final p in pList) {
          final pName = (p['planet'] ?? p['name'] ?? '').toString().trim();
          if (pName.isEmpty) continue;
          final bhavaHouse = ((p['bhava_house'] ?? p['house']) as num?)?.toInt() ?? 1;
          final isRetro = p['is_retrograde'] == true;
          final degFormatted = (p['degree_formatted'] ?? p['degree'] ?? '').toString().trim();

          String label = _formatCode(pName);
          if (isRetro && label != 'Asc') label += '(R)';

          targetMap.putIfAbsent(bhavaHouse, () => []).add(
            _PlanetEntry(
              rawName: pName,
              displayLabel: label,
              degLabel: showDegrees ? degFormatted : '',
              color: _getPlanetColor(pName, isDark),
            ),
          );
        }
        return;
      }
    }

    // 3. Default D-1 Rashi
    if (data['planets'] != null) {
      for (final p in data['planets']) {
        final pName = (p['planet'] ?? p['name'] ?? '').toString().trim();
        if (pName.isEmpty) continue;

        final lower = pName.toLowerCase();
        if (lower.contains('fortuna') || lower.contains('for ') || lower == 'for') continue;

        int signIdx = (p['sign_index'] as num?)?.toInt() ?? 0;
        if (signIdx < 1 || signIdx > 12) {
          final sName = (p['sign'] ?? '').toString().trim();
          for (int i = 0; i < signNames.length; i++) {
            if (sName.toLowerCase() == signNames[i].toLowerCase()) {
              signIdx = i + 1;
              break;
            }
          }
        }
        if (signIdx < 1 || signIdx > 12) continue;

        final isRetro = p['is_retrograde'] == true;
        final degFormatted = (p['degree_formatted'] ?? p['degree'] ?? '').toString().trim();
        final degDouble = (p['norm_degree'] ?? p['degree'] ?? p['longitude'] as num?)?.toDouble();

        String label = _formatCode(pName);
        if (isRetro && label != 'Asc') {
          label += '(R)';
        }

        String degLabel = '';
        if (showDegrees) {
          if (degFormatted.isNotEmpty && degFormatted.contains('°')) {
            final clean = degFormatted.replaceAll('°', ':').replaceAll("'", '').replaceAll('"', '');
            final parts = clean.split(':');
            if (parts.length >= 2) {
              degLabel = '${parts[0].trim()}°${parts[1].trim()}\'';
            } else {
              degLabel = degFormatted;
            }
          } else if (degDouble != null) {
            final degInSign = degDouble % 30.0;
            final d = degInSign.floor();
            final m = ((degInSign - d) * 60).round();
            degLabel = '$d°$m\'';
          }
        }

        final houseNum = (chartTypeKey == 'Bhava' && p['house'] != null)
            ? (p['house'] as num).toInt()
            : (((signIdx - natalAscSignIdx + 12) % 12) + 1);

        targetMap.putIfAbsent(houseNum, () => []).add(
          _PlanetEntry(
            rawName: pName,
            displayLabel: label,
            degLabel: degLabel,
            color: _getPlanetColor(pName, isDark),
          ),
        );
      }
    }

    final ascDeg = data['ascendant_degree_formatted']?.toString() ??
        data['ascendant_degree']?.toString() ??
        '';
    String ascDegLabel = '';
    if (showDegrees && ascDeg.isNotEmpty) {
      final clean = ascDeg.replaceAll('°', ':').replaceAll("'", '').replaceAll('"', '');
      final parts = clean.split(':');
      if (parts.length >= 2) {
        ascDegLabel = '${parts[0].trim()}°${parts[1].trim()}\'';
      }
    }

    if (!isTransit) {
      final hasAsc = (targetMap[1] ?? []).any((e) => e.displayLabel.startsWith('Asc'));
      if (!hasAsc) {
        targetMap.putIfAbsent(1, () => []).insert(
          0,
          _PlanetEntry(
            rawName: 'Ascendant',
            displayLabel: 'Asc',
            degLabel: ascDegLabel,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        );
      }
    } else {
      final transitAscSign = _getAscSignIdx(data);
      final transitAscHouse = ((transitAscSign - natalAscSignIdx + 12) % 12) + 1;
      final hasAsc = (targetMap[transitAscHouse] ?? []).any((e) => e.displayLabel.startsWith('Asc'));
      if (!hasAsc) {
        targetMap.putIfAbsent(transitAscHouse, () => []).add(
          _PlanetEntry(
            rawName: 'Transit Ascendant',
            displayLabel: 'Asc',
            degLabel: ascDegLabel,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          ),
        );
      }
    }
  }

  String _formatCode(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('sun') || lower.contains('surya')) return 'Sun';
    if (lower.contains('moon') || lower.contains('chandra')) return 'Mon';
    if (lower.contains('mars') || lower.contains('mangal')) return 'Mar';
    if (lower.contains('mercury') || lower.contains('budha')) return 'Mer';
    if (lower.contains('jupiter') || lower.contains('guru') || lower.contains('brihaspati')) return 'Jup';
    if (lower.contains('venus') || lower.contains('shukra')) return 'Ve';
    if (lower.contains('saturn') || lower.contains('shani')) return 'Sat';
    if (lower.contains('rahu') || lower.contains('north node')) return 'Ra';
    if (lower.contains('ketu') || lower.contains('south node')) return 'Ke';
    if (lower.contains('uranus') || lower.contains('harshal')) return 'Ura';
    if (lower.contains('neptune')) return 'Nep';
    if (lower.contains('pluto')) return 'Plu';
    if (lower.contains('ascendant') || lower.contains('lagna')) return 'Asc';
    return raw.length > 3 ? raw.substring(0, 3) : raw;
  }

  Color _getPlanetColor(String pName, bool dark) {
    final l = pName.toLowerCase();
    if (l.contains('mer') || l.contains('budh')) return const Color(0xFF059669);
    if (l.contains('ve') || l.contains('shuk')) return const Color(0xFFDB2777);
    if (l.contains('sun') || l.contains('sur')) return const Color(0xFFEA580C);
    if (l.contains('mon') || l.contains('moo') || l.contains('chan')) return const Color(0xFF0284C7);
    if (l.contains('mar') || l.contains('man')) return const Color(0xFFDC2626);
    if (l.contains('jup') || l.contains('gur') || l.contains('bri')) return const Color(0xFFD97706);
    if (l.contains('sat') || l.contains('shan')) return const Color(0xFF7C3AED);
    if (l.contains('rah') || l.contains('ra(') || l.startsWith('ra')) return const Color(0xFF6D28D9);
    if (l.contains('ket') || l.contains('ke(') || l.startsWith('ke')) return const Color(0xFF92400E);
    if (l.contains('asc') || l.contains('lag')) return dark ? Colors.white : const Color(0xFF0F172A);
    if (l.contains('ura')) return const Color(0xFF0284C7);
    if (l.contains('nep')) return const Color(0xFF2563EB);
    if (l.contains('plu')) return const Color(0xFF475569);
    return dark ? Colors.white70 : const Color(0xFF334155);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final natalAscSignIdx = _getAscSignIdx(natalData);
    final Map<int, List<_PlanetEntry>> innerPlanets = {};
    final Map<int, List<_PlanetEntry>> outerPlanets = {};

    _extractHousePlacements(innerPlanets, natalData, natalAscSignIdx, isTransit: false);
    _extractHousePlacements(outerPlanets, transitData, natalAscSignIdx, isTransit: true);

    final lineColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    final bgFill = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;

    final kendraFill = Paint()
      ..color = lineColor.withValues(alpha: isDark ? 0.08 : 0.035)
      ..style = PaintingStyle.fill;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgFill);

    // =========================================================================
    // OUTER NORTH INDIAN LINES (Wide Landscape)
    // =========================================================================
    final oTopMid = Offset(w * 0.5, 0);
    final oRightMid = Offset(w, h * 0.5);
    final oBottomMid = Offset(w * 0.5, h);
    final oLeftMid = Offset(0, h * 0.5);

    final outerDiamond = Path()
      ..moveTo(oTopMid.dx, oTopMid.dy)
      ..lineTo(oRightMid.dx, oRightMid.dy)
      ..lineTo(oBottomMid.dx, oBottomMid.dy)
      ..lineTo(oLeftMid.dx, oLeftMid.dy)
      ..close();

    canvas.drawPath(outerDiamond, kendraFill);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    canvas.drawLine(Offset.zero, Offset(w, h), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);
    canvas.drawPath(outerDiamond, linePaint);

    // =========================================================================
    // INNER NORTH INDIAN WINDOW (Square Proportional Cutout)
    // =========================================================================
    final double inLeft = w * 0.22;
    final double inRight = w * 0.78;
    final double inTop = h * 0.22;
    final double inBottom = h * 0.78;
    final inRect = Rect.fromLTRB(inLeft, inTop, inRight, inBottom);

    canvas.drawRect(inRect, bgFill);

    final iTopMid = Offset(w * 0.5, inTop);
    final iRightMid = Offset(inRight, h * 0.5);
    final iBottomMid = Offset(w * 0.5, inBottom);
    final iLeftMid = Offset(inLeft, h * 0.5);

    final innerDiamond = Path()
      ..moveTo(iTopMid.dx, iTopMid.dy)
      ..lineTo(iRightMid.dx, iRightMid.dy)
      ..lineTo(iBottomMid.dx, iBottomMid.dy)
      ..lineTo(iLeftMid.dx, iLeftMid.dy)
      ..close();

    canvas.drawPath(innerDiamond, kendraFill);
    canvas.drawRect(inRect, linePaint);

    canvas.drawLine(Offset(inLeft, inTop), Offset(inRight, inBottom), linePaint);
    canvas.drawLine(Offset(inRight, inTop), Offset(inLeft, inBottom), linePaint);
    canvas.drawPath(innerDiamond, linePaint);

    // =========================================================================
    // HOUSE ANNOTATIONS (Clean Classic North Indian Dual Layout)
    // =========================================================================
    // Outer House Signs (1-12 relative to Ascendant)
    final outerSignPositions = [
      Offset(w * 0.49, h * 0.11),  // H1 (Top Diamond)
      Offset(w * 0.39, h * 0.08),  // H2 (Top-Left)
      Offset(w * 0.16, h * 0.46),  // H3 (Far Left Top)
      Offset(w * 0.38, h * 0.50),  // H4 (Left Diamond)
      Offset(w * 0.16, h * 0.54),  // H5 (Far Left Bottom)
      Offset(w * 0.39, h * 0.92),  // H6 (Bottom Left)
      Offset(w * 0.49, h * 0.89),  // H7 (Bottom Diamond)
      Offset(w * 0.59, h * 0.92),  // H8 (Bottom Right)
      Offset(w * 0.84, h * 0.54),  // H9 (Far Right Bottom)
      Offset(w * 0.62, h * 0.50),  // H10 (Right Diamond)
      Offset(w * 0.84, h * 0.46),  // H11 (Far Right Top)
      Offset(w * 0.59, h * 0.08),  // H12 (Top Right)
    ];

    // Outer Transit Planet Centers (in the 12 outer house compartments)
    final outerPlanetCenters = [
      Offset(w * 0.50, h * 0.06),  // H1 (Top Diamond apex)
      Offset(w * 0.28, h * 0.14),  // H2 (Top Left triangle)
      Offset(w * 0.10, h * 0.25),  // H3 (Far Left Top triangle)
      Offset(w * 0.14, h * 0.50),  // H4 (Left Diamond center)
      Offset(w * 0.10, h * 0.75),  // H5 (Far Left Bottom triangle)
      Offset(w * 0.28, h * 0.86),  // H6 (Bottom Left triangle)
      Offset(w * 0.50, h * 0.94),  // H7 (Bottom Diamond apex)
      Offset(w * 0.72, h * 0.86),  // H8 (Bottom Right triangle)
      Offset(w * 0.90, h * 0.75),  // H9 (Far Right Bottom triangle)
      Offset(w * 0.86, h * 0.50),  // H10 (Right Diamond center)
      Offset(w * 0.90, h * 0.25),  // H11 (Far Right Top triangle)
      Offset(w * 0.72, h * 0.14),  // H12 (Top Right triangle)
    ];

    final inW = inRight - inLeft;
    final inH = inBottom - inTop;

    // Inner Natal House Signs
    final innerSignPositions = [
      Offset(w * 0.50, inTop + inH * 0.12),          // H1 (Top Diamond)
      Offset(inLeft + inW * 0.34, inTop + inH * 0.13), // H2 (Top-Left)
      Offset(inLeft + inW * 0.14, inTop + inH * 0.34), // H3 (Far Left Top)
      Offset(inLeft + inW * 0.35, inTop + inH * 0.50), // H4 (Left Diamond)
      Offset(inLeft + inW * 0.14, inTop + inH * 0.66), // H5 (Far Left Bottom)
      Offset(inLeft + inW * 0.34, inTop + inH * 0.87), // H6 (Bottom Left)
      Offset(w * 0.50, inTop + inH * 0.60),          // H7 (Bottom Diamond)
      Offset(inLeft + inW * 0.66, inTop + inH * 0.87), // H8 (Bottom Right)
      Offset(inLeft + inW * 0.86, inTop + inH * 0.66), // H9 (Far Right Bottom)
      Offset(inLeft + inW * 0.65, inTop + inH * 0.50), // H10 (Right Diamond)
      Offset(inLeft + inW * 0.86, inTop + inH * 0.34), // H11 (Far Right Top)
      Offset(inLeft + inW * 0.66, inTop + inH * 0.13), // H12 (Top Right)
    ];

    // Inner Natal Planet Centers (properly spaced in inner chart)
    final innerPlanetCenters = [
      Offset(w * 0.50, inTop + inH * 0.28),          // H1 (Top Diamond center)
      Offset(inLeft + inW * 0.25, inTop + inH * 0.22), // H2 (Top-Left)
      Offset(inLeft + inW * 0.14, inTop + inH * 0.23), // H3 (Far Left Top)
      Offset(inLeft + inW * 0.23, inTop + inH * 0.50), // H4 (Left Diamond center)
      Offset(inLeft + inW * 0.14, inTop + inH * 0.77), // H5 (Far Left Bottom)
      Offset(inLeft + inW * 0.25, inTop + inH * 0.78), // H6 (Bottom Left)
      Offset(w * 0.50, inTop + inH * 0.72),          // H7 (Bottom Diamond center)
      Offset(inLeft + inW * 0.75, inTop + inH * 0.78), // H8 (Bottom Right)
      Offset(inLeft + inW * 0.86, inTop + inH * 0.77), // H9 (Far Right Bottom)
      Offset(inLeft + inW * 0.77, inTop + inH * 0.50), // H10 (Right Diamond center)
      Offset(inLeft + inW * 0.86, inTop + inH * 0.23), // H11 (Far Right Top)
      Offset(inLeft + inW * 0.75, inTop + inH * 0.22), // H12 (Top Right)
    ];

    for (int hIdx = 1; hIdx <= 12; hIdx++) {
      final signNumber = ((natalAscSignIdx + hIdx - 2) % 12) + 1;
      final isAscHouse = (hIdx == 1);

      // OUTER SIGN NUMBER
      _drawText(
        canvas: canvas,
        text: '$signNumber',
        center: outerSignPositions[hIdx - 1],
        fontSize: 11.0,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      );

      // INNER SIGN NUMBER
      _drawText(
        canvas: canvas,
        text: '$signNumber',
        center: innerSignPositions[hIdx - 1],
        fontSize: isAscHouse ? 13.0 : 10.5,
        fontWeight: isAscHouse ? FontWeight.w900 : FontWeight.bold,
        color: isAscHouse
            ? const Color(0xFFE11D48)
            : (isDark ? Colors.white70 : const Color(0xFF334155)),
      );

      // OUTER TRANSIT PLANETS
      final outPlanets = outerPlanets[hIdx] ?? [];
      if (outPlanets.isNotEmpty) {
        _drawPlanetStack(
          canvas: canvas,
          center: outerPlanetCenters[hIdx - 1],
          planets: outPlanets,
          baseFontSize: 11.0,
        );
      }

      // INNER NATAL PLANETS
      final inPlanets = innerPlanets[hIdx] ?? [];
      if (inPlanets.isNotEmpty) {
        _drawPlanetStack(
          canvas: canvas,
          center: innerPlanetCenters[hIdx - 1],
          planets: inPlanets,
          baseFontSize: 10.5,
        );
      }
    }
  }

  void _drawPlanetStack({
    required Canvas canvas,
    required Offset center,
    required List<_PlanetEntry> planets,
    required double baseFontSize,
  }) {
    if (planets.isEmpty) return;

    double fontSize = baseFontSize;
    if (planets.length > 2) fontSize = baseFontSize * 0.90;
    if (planets.length > 4) fontSize = baseFontSize * 0.80;

    final double lineHeight = fontSize * 1.25;
    final double totalHeight = planets.length * lineHeight;
    double startY = center.dy - (totalHeight / 2) + (lineHeight / 2);

    for (final p in planets) {
      final span = TextSpan(
        children: [
          TextSpan(
            text: p.displayLabel,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: p.color,
            ),
          ),
          if (p.degLabel.isNotEmpty)
            TextSpan(
              text: ' ${p.degLabel}',
              style: GoogleFonts.outfit(
                fontSize: fontSize * 0.86,
                fontWeight: FontWeight.w600,
                color: p.color.withValues(alpha: 0.95),
              ),
            ),
        ],
      );

      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(center.dx - (tp.width / 2), startY - (tp.height / 2)));
      startY += lineHeight;
    }
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _NestedNorthIndianTransitPainter oldDelegate) {
    return oldDelegate.natalData != natalData ||
        oldDelegate.transitData != transitData ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showDegrees != showDegrees ||
        oldDelegate.chartTypeKey != chartTypeKey;
  }
}

class _PlanetEntry {
  final String rawName;
  final String displayLabel;
  final String degLabel;
  final Color color;

  _PlanetEntry({
    required this.rawName,
    required this.displayLabel,
    required this.degLabel,
    required this.color,
  });
}
