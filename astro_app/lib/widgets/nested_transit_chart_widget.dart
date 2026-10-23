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
  final bool useTransitCusps;

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
    this.useTransitCusps = true,
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
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
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
                aspectRatio: 1.0, // Increased height & width for spacious layout matching reference app
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
                      chartTitle: title,
                      useTransitCusps: useTransitCusps,
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
                      useTransitCusps
                          ? 'Outer: Transit Chart (Transit Cusps)'
                          : 'Outer: Transit Planets (Natal Cusps)',
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
  final String chartTitle;
  final bool useTransitCusps;

  _NestedNorthIndianTransitPainter({
    required this.natalData,
    required this.transitData,
    required this.isDark,
    required this.showDegrees,
    this.chartTypeKey = 'D-1',
    this.chartTitle = '',
    this.useTransitCusps = true,
  });

  static const List<String> signNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  int _getAscSignIdx(Map<String, dynamic>? data) {
    if (data == null) return 1; // Aries fallback

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

    if (data['ascendant'] is Map) {
      final aMap = data['ascendant'] as Map;
      if (aMap['sign_index'] != null) {
        return (aMap['sign_index'] as num).toInt();
      }
      final sName = aMap['sign_name']?.toString() ?? aMap['sign']?.toString() ?? '';
      for (int i = 0; i < signNames.length; i++) {
        if (sName.toLowerCase() == signNames[i].toLowerCase()) {
          return i + 1;
        }
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
    return 1;
  }

  String _formatDegString(String degFormatted, double? degDouble) {
    if (!showDegrees) return '';
    final s = degFormatted.trim();
    if (s.isNotEmpty) {
      final cleaned = s
          .replaceAll('°', ':')
          .replaceAll("'", ':')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        int d = int.tryParse(parts[0].trim()) ?? 0;
        int m = int.tryParse(parts[1].trim()) ?? 0;
        int sec = parts.length > 2 ? (int.tryParse(parts[2].trim()) ?? 0) : 0;
        if (sec >= 30) m += 1;
        if (m >= 60) {
          m -= 60;
          d += 1;
        }
        return '${d.toString().padLeft(2, '0')}°${m.toString().padLeft(2, '0')}\'';
      }
    }
    if (degDouble != null) {
      final degInSign = degDouble % 30.0;
      int d = degInSign.floor();
      double minDouble = (degInSign - d) * 60;
      int m = minDouble.floor();
      int sec = ((minDouble - m) * 60).round();
      if (sec >= 30) m += 1;
      if (m >= 60) {
        m -= 60;
        d += 1;
      }
      return '${d.toString().padLeft(2, '0')}°${m.toString().padLeft(2, '0')}\'';
    }
    return '';
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
          if (isTransit) {
            if (lower.contains('uranus') || lower.contains('harshal') ||
                lower.contains('neptune') || lower.contains('pluto')) {
              continue;
            }
          }

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
          final degDouble = (p['norm_degree'] ?? p['degree'] ?? p['longitude'] as num?)?.toDouble();

          String label = _formatCode(pName);
          if (isRetro && label != 'Asc') label += '(R)';

          final degLabel = _formatDegString(degFormatted, degDouble);

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
          final lower = pName.toLowerCase();
          if (lower.contains('fortuna') || lower.contains('for ') || lower == 'for') continue;
          if (isTransit) {
            if (lower.contains('uranus') || lower.contains('harshal') ||
                lower.contains('neptune') || lower.contains('pluto')) {
              continue;
            }
          }
          final bhavaHouse = ((p['bhava_house'] ?? p['house']) as num?)?.toInt() ?? 1;
          final isRetro = p['is_retrograde'] == true;
          final degFormatted = (p['degree_formatted'] ?? p['degree'] ?? '').toString().trim();
          final degDouble = (p['norm_degree'] ?? p['degree'] ?? p['longitude'] as num?)?.toDouble();

          String label = _formatCode(pName);
          if (isRetro && label != 'Asc') label += '(R)';

          targetMap.putIfAbsent(bhavaHouse, () => []).add(
            _PlanetEntry(
              rawName: pName,
              displayLabel: label,
              degLabel: _formatDegString(degFormatted, degDouble),
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
        if (isTransit) {
          if (lower.contains('uranus') || lower.contains('harshal') ||
              lower.contains('neptune') || lower.contains('pluto')) {
            continue;
          }
        }

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

        final degLabel = _formatDegString(degFormatted, degDouble);

        final houseNum = (chartTypeKey == 'Bhava')
            ? ((isTransit ? (useTransitCusps ? (p['transit_house'] ?? p['house']) : (p['natal_house'] ?? p['house'])) : p['house']) as num? ?? 1).toInt()
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

    final ascDeg = (data['ascendant'] is Map ? data['ascendant']['degree_formatted'] : null)?.toString() ??
        data['ascendant_degree_formatted']?.toString() ??
        data['ascendant_degree']?.toString() ??
        '';
    final ascDegDouble = (data['ascendant'] is Map ? data['ascendant']['degree'] : null) as num? ??
        (data['ascendant_degree'] as num?);
    final ascDegLabel = _formatDegString(ascDeg, ascDegDouble?.toDouble());

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
      if (useTransitCusps) {
        final hasAsc = (targetMap[1] ?? []).any((e) => e.displayLabel.startsWith('Asc'));
        if (!hasAsc) {
          targetMap.putIfAbsent(1, () => []).insert(
            0,
            _PlanetEntry(
              rawName: 'Transit Ascendant',
              displayLabel: 'Asc',
              degLabel: ascDegLabel,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
    final transitAscSignIdx = _getAscSignIdx(transitData);
    final outerAscSignIdx = useTransitCusps ? transitAscSignIdx : natalAscSignIdx;

    final Map<int, List<_PlanetEntry>> innerPlanets = {};
    final Map<int, List<_PlanetEntry>> outerPlanets = {};

    _extractHousePlacements(innerPlanets, natalData, natalAscSignIdx, isTransit: false);
    _extractHousePlacements(outerPlanets, transitData, outerAscSignIdx, isTransit: true);

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
    // INNER & OUTER BOUNDARIES (Exact Reference Desktop Geometry)
    // =========================================================================
    final double inLeft = w * 0.235;
    final double inRight = w * 0.765;
    final double inTop = h * 0.235;
    final double inBottom = h * 0.765;
    final double inW = inRight - inLeft;
    final double inH = inBottom - inTop;

    final inRect = Rect.fromLTRB(inLeft, inTop, inRight, inBottom);

    // 1. Draw Outer Frame Rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // 2. Draw Inner Frame Rectangle
    canvas.drawRect(inRect, bgFill);
    canvas.drawRect(inRect, linePaint);

    // =========================================================================
    // OUTER CONNECTING LINES (Connecting Outer Frame to Inner Frame)
    // =========================================================================
    // 4 Corner Lines
    canvas.drawLine(Offset.zero, Offset(inLeft, inTop), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(inRight, inTop), linePaint);
    canvas.drawLine(Offset(0, h), Offset(inLeft, inBottom), linePaint);
    canvas.drawLine(Offset(w, h), Offset(inRight, inBottom), linePaint);

    // 2 Top-mid Lines to Inner Corners
    canvas.drawLine(Offset(w * 0.5, 0), Offset(inLeft, inTop), linePaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(inRight, inTop), linePaint);

    // 2 Bottom-mid Lines to Inner Corners
    canvas.drawLine(Offset(w * 0.5, h), Offset(inLeft, inBottom), linePaint);
    canvas.drawLine(Offset(w * 0.5, h), Offset(inRight, inBottom), linePaint);

    // 2 Left-mid Lines to Inner Corners
    canvas.drawLine(Offset(0, h * 0.5), Offset(inLeft, inTop), linePaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(inLeft, inBottom), linePaint);

    // 2 Right-mid Lines to Inner Corners
    canvas.drawLine(Offset(w, h * 0.5), Offset(inRight, inTop), linePaint);
    canvas.drawLine(Offset(w, h * 0.5), Offset(inRight, inBottom), linePaint);

    // =========================================================================
    // INNER CHART LINES (Standard North Indian Kendra & Trikona Lines)
    // =========================================================================
    // 2 Diagonals inside inner frame
    canvas.drawLine(Offset(inLeft, inTop), Offset(inRight, inBottom), linePaint);
    canvas.drawLine(Offset(inRight, inTop), Offset(inLeft, inBottom), linePaint);

    // Inner Diamond connecting midpoints of inner frame
    final iTopMid = Offset(w * 0.5, inTop);
    final iRightMid = Offset(inRight, inTop + inH * 0.5);
    final iBottomMid = Offset(w * 0.5, inBottom);
    final iLeftMid = Offset(inLeft, inTop + inH * 0.5);

    final innerDiamond = Path()
      ..moveTo(iTopMid.dx, iTopMid.dy)
      ..lineTo(iRightMid.dx, iRightMid.dy)
      ..lineTo(iBottomMid.dx, iBottomMid.dy)
      ..lineTo(iLeftMid.dx, iLeftMid.dy)
      ..close();

    canvas.drawPath(innerDiamond, kendraFill);
    canvas.drawPath(innerDiamond, linePaint);

    // =========================================================================
    // HOUSE ALIGNMENT & ANNOTATIONS — Exact Reference App Layout (Image 2)
    // =========================================================================
    //
    // GEOMETRIC CONVENTION:
    //
    // Outer Sign Numbers (1 to 12):
    //   - 4 Kendra houses (H1, H4, H7, H10) place sign number at the outer wall midpoints:
    //       H1  : top wall center (w * 0.5, sOff)
    //       H4  : left wall center (sOff, h * 0.5)
    //       H7  : bottom wall center (w * 0.5, h - sOff)
    //       H10 : right wall center (w - sOff, h * 0.5)
    //   - 8 Non-kendra houses (H2, H3, H5, H6, H8, H9, H11, H12) place sign numbers
    //     at the 4 outer vertices of the inner box (flanking the corner diagonals):
    //       H2/H3   : inner top-left corner (H2 above diagonal, H3 below diagonal)
    //       H5/H6   : inner bottom-left corner (H5 above diagonal, H6 below diagonal)
    //       H8/H9   : inner bottom-right corner (H8 below diagonal, H9 above diagonal)
    //       H11/H12 : inner top-right corner (H11 below diagonal, H12 above diagonal)
    //
    // Inner Sign Numbers (1 to 12):
    //   - 4 Kendra houses cluster at the center intersection (cx, cy):
    //       H1  : just above center
    //       H4  : just left of center
    //       H7  : just below center
    //       H10 : just right of center
    //   - 8 Trikona/Apoklima houses cluster at the 4 diagonal/diamond intersections:
    //       (cx_tl, cy_tl), (cx_bl, cy_bl), (cx_br, cy_br), (cx_tr, cy_tr)
    //
    // All numbers and positions are 100% computed from geometry and backend data.

    final double cx = inLeft + inW * 0.5;
    final double cy = inTop + inH * 0.5;

    final double cxTl = inLeft + inW * 0.25;
    final double cyTl = inTop + inH * 0.25;

    final double cxBl = inLeft + inW * 0.25;
    final double cyBl = inTop + inH * 0.75;

    final double cxBr = inLeft + inW * 0.75;
    final double cyBr = inTop + inH * 0.75;

    final double cxTr = inLeft + inW * 0.75;
    final double cyTr = inTop + inH * 0.25;

    // ── Outer Sign Number positions (Matching Horosoft Reference Image 1) ────
    final outerSignPositions = [
      Offset(w * 0.50, 11.0),                                               // H1  : top wall center
      Offset(inLeft + 6.0, inTop - 8.0),                                    // H2  : top-left corner (horizontal edge, facing H2)
      Offset(inLeft - 10.0, inTop + 6.0),                                   // H3  : top-left corner (vertical edge, facing H3)
      Offset(11.0, h * 0.50),                                               // H4  : left wall center
      Offset(inLeft - 10.0, inBottom - 6.0),                                // H5  : bottom-left corner (vertical edge, facing H5)
      Offset(inLeft + 6.0, inBottom + 8.0),                                 // H6  : bottom-left corner (horizontal edge, facing H6)
      Offset(w * 0.50, h - 11.0),                                           // H7  : bottom wall center
      Offset(inRight - 6.0, inBottom + 8.0),                                // H8  : bottom-right corner (horizontal edge, facing H8)
      Offset(inRight + 10.0, inBottom - 6.0),                               // H9  : bottom-right corner (vertical edge, facing H9)
      Offset(w - 11.0, h * 0.50),                                           // H10 : right wall center
      Offset(inRight + 10.0, inTop + 6.0),                                  // H11 : top-right corner (vertical edge, facing H11)
      Offset(inRight - 6.0, inTop - 8.0),                                   // H12 : top-right corner (horizontal edge, facing H12)
    ];

    // ── Inner Sign Number positions (Matching Horosoft Reference Image 1) ────
    final innerSignPositions = [
      Offset(cx, cy - 10.0),                                                // H1  : center junction (above cross)
      Offset(cxTl + 6.0, cyTl - 8.0),                                       // H2  : top-left junction (horizontal edge, facing H2)
      Offset(cxTl - 10.0, cyTl + 6.0),                                      // H3  : top-left junction (vertical edge, facing H3)
      Offset(cx - 12.0, cy),                                                // H4  : center junction (left of cross)
      Offset(cxBl - 10.0, cyBl - 6.0),                                      // H5  : bottom-left junction (vertical edge, facing H5)
      Offset(cxBl + 6.0, cyBl + 8.0),                                       // H6  : bottom-left junction (horizontal edge, facing H6)
      Offset(cx, cy + 10.0),                                                // H7  : center junction (below cross)
      Offset(cxBr - 6.0, cyBr + 8.0),                                       // H8  : bottom-right junction (horizontal edge, facing H8)
      Offset(cxBr + 10.0, cyBr - 6.0),                                      // H9  : bottom-right junction (vertical edge, facing H9)
      Offset(cx + 12.0, cy),                                                // H10 : center junction (right of cross)
      Offset(cxTr + 10.0, cyTr + 6.0),                                      // H11 : top-right junction (vertical edge, facing H11)
      Offset(cxTr - 6.0, cyTr - 8.0),                                       // H12 : top-right junction (horizontal edge, facing H12)
    ];

    // ── Outer Transit Planet Centers ─────────────────────────────────────────
    final outerPlanetCenters = [
      Offset(w * 0.50, inTop * 0.55),                                       // H1  : Top Kendra wall center
      Offset(inLeft * 0.60, inTop * 0.36),                                  // H2  : Top-left upper triangle
      Offset(inLeft * 0.38, inTop + (h * 0.5 - inTop) * 0.40),              // H3  : Left-top lower triangle
      Offset(inLeft * 0.58, h * 0.50),                                      // H4  : Left Kendra wall center (gap from 11)
      Offset(inLeft * 0.38, inBottom + (h - inBottom) * 0.60),              // H5  : Left-bottom upper triangle
      Offset(inLeft * 0.60, h - inTop * 0.36),                              // H6  : Bottom-left lower triangle
      Offset(w * 0.50, h - inTop * 0.55),                                   // H7  : Bottom Kendra wall center
      Offset(w - inLeft * 0.60, h - inTop * 0.36),                          // H8  : Bottom-right lower triangle (Asc in Gemini!)
      Offset(w - inLeft * 0.38, inBottom + (h - inBottom) * 0.60),          // H9  : Right-bottom upper triangle (Mar, Jup in Cancer!)
      Offset(w - inLeft * 0.58, h * 0.50),                                  // H10 : Right Kendra wall center (gap from 5)
      Offset(w - inLeft * 0.38, inTop + (h * 0.5 - inTop) * 0.40),          // H11 : Right-top lower triangle (Sun, Mon in Virgo!)
      Offset(w - inLeft * 0.60, inTop * 0.36),                              // H12 : Top-right upper triangle (Mer, Ve in Libra!)
    ];

    // ── Inner Natal Planet Centers ───────────────────────────────────────────
    final innerPlanetCenters = [
      Offset(cx, inTop + inH * 0.22),                                       // H1 top kendra
      Offset(inLeft + inW * 0.26, inTop + inH * 0.14),                      // H2 top-left
      Offset(inLeft + inW * 0.14, inTop + inH * 0.26),                      // H3 left-top
      Offset(inLeft + inW * 0.22, cy),                                      // H4 left kendra
      Offset(inLeft + inW * 0.14, inBottom - inH * 0.26),                   // H5 left-bottom
      Offset(inLeft + inW * 0.26, inBottom - inH * 0.14),                   // H6 bottom-left
      Offset(cx, inBottom - inH * 0.22),                                    // H7 bottom kendra
      Offset(inRight - inW * 0.26, inBottom - inH * 0.14),                  // H8 bottom-right
      Offset(inRight - inW * 0.14, inBottom - inH * 0.26),                  // H9 right-bottom
      Offset(inRight - inW * 0.22, cy),                                     // H10 right kendra
      Offset(inRight - inW * 0.14, inTop + inH * 0.26),                     // H11 right-top
      Offset(inRight - inW * 0.26, inTop + inH * 0.14),                     // H12 top-right
    ];

    for (int hIdx = 1; hIdx <= 12; hIdx++) {
      // Outer Zodiac sign: based on outerAscSignIdx (transit cusps if enabled, else natal)
      final outerSignNumber = ((outerAscSignIdx + hIdx - 2) % 12) + 1;
      
      // Inner Zodiac sign: always natal cusps
      final innerSignNumber = ((natalAscSignIdx + hIdx - 2) % 12) + 1;

      // OUTER SIGN NUMBER (at frame edge / corner)
      _drawText(
        canvas: canvas,
        text: '$outerSignNumber',
        center: outerSignPositions[hIdx - 1],
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
      );

      // INNER SIGN NUMBER (at inner-box edge / corner)
      _drawText(
        canvas: canvas,
        text: '$innerSignNumber',
        center: innerSignPositions[hIdx - 1],
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      );

      // OUTER TRANSIT PLANETS
      final outPlanets = outerPlanets[hIdx] ?? [];
      if (outPlanets.isNotEmpty) {
        _drawPlanetStack(
          canvas: canvas,
          center: outerPlanetCenters[hIdx - 1],
          planets: outPlanets,
          baseFontSize: 11.0,
          isWide: (hIdx == 1 || hIdx == 2 || hIdx == 6 || hIdx == 7 || hIdx == 8 || hIdx == 12),
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
          isWide: (hIdx == 1 || hIdx == 2 || hIdx == 6 || hIdx == 7 || hIdx == 8 || hIdx == 12),
        );
      }
    }
  }

  void _drawPlanetStack({
    required Canvas canvas,
    required Offset center,
    required List<_PlanetEntry> planets,
    required double baseFontSize,
    bool isWide = false,
  }) {
    if (planets.isEmpty) return;

    final bool useTwoPerRow = planets.length >= 3 && isWide;

    double fontSize = baseFontSize;
    if (planets.length > 2) fontSize = baseFontSize * 0.88;
    if (planets.length > 4) fontSize = baseFontSize * 0.78;

    final double lineHeight = fontSize * 1.20;

    if (!useTwoPerRow) {
      final double totalHeight = planets.length * lineHeight;
      double startY = center.dy - (totalHeight / 2) + (lineHeight / 2);

      for (final p in planets) {
        final tp = TextPainter(
          text: _buildPlanetSpan(p, fontSize),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(center.dx - (tp.width / 2), startY - (tp.height / 2)));
        startY += lineHeight;
      }
    } else {
      final rows = <List<_PlanetEntry>>[];
      for (int i = 0; i < planets.length; i += 2) {
        rows.add(planets.sublist(i, (i + 2 > planets.length) ? planets.length : i + 2));
      }

      final double totalHeight = rows.length * lineHeight;
      double startY = center.dy - (totalHeight / 2) + (lineHeight / 2);

      for (final row in rows) {
        final children = <InlineSpan>[];
        for (int i = 0; i < row.length; i++) {
          if (i > 0) {
            children.add(const TextSpan(text: '  '));
          }
          final p = row[i];
          children.add(TextSpan(
            text: p.displayLabel,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: p.color,
            ),
          ));
          if (p.degLabel.isNotEmpty) {
            children.add(TextSpan(
              text: ' ${p.degLabel}',
              style: GoogleFonts.outfit(
                fontSize: fontSize * 0.86,
                fontWeight: FontWeight.w600,
                color: p.color.withValues(alpha: 0.95),
              ),
            ));
          }
        }

        final tp = TextPainter(
          text: TextSpan(children: children),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(center.dx - (tp.width / 2), startY - (tp.height / 2)));
        startY += lineHeight;
      }
    }
  }

  TextSpan _buildPlanetSpan(_PlanetEntry p, double fontSize) {
    return TextSpan(
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
        oldDelegate.chartTypeKey != chartTypeKey ||
        oldDelegate.useTransitCusps != useTransitCusps;
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
