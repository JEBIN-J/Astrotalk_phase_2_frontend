import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KundliInteractiveChart extends StatelessWidget {
  final KundliChartStyle chartStyle;
  final bool isDark;
  final String
  chartTypeKey; // 'D-1', 'D-9', 'D-10', 'D-2', 'D-3', 'D-4', 'D-7', 'D-12', 'D-16', 'D-20', 'D-24', 'D-27', 'D-30', 'D-60', 'Bhava'
  final bool showUpagrahas;
  final bool showDegrees;
  final bool showKpCusps;
  final Map<String, dynamic>? kundliData;

  const KundliInteractiveChart({
    super.key,
    required this.chartStyle,
    required this.isDark,
    this.chartTypeKey = 'D-1',
    this.showUpagrahas = true,
    this.showDegrees = true,
    this.showKpCusps = false,
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
          showKpCusps: showKpCusps,
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
  final bool showKpCusps;
  final Map<String, dynamic>? kundliData;

  _MultiKundliPainter({
    required this.chartStyle,
    required this.isDark,
    required this.chartTypeKey,
    required this.showUpagrahas,
    required this.showDegrees,
    this.showKpCusps = false,
    required this.kundliData,
  });

  static const List<String> signNames = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
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
    } else if (lower.contains('jupiter') ||
        lower.contains('guru') ||
        lower.contains('brihaspati')) {
      code = 'Ju';
    } else if (lower.contains('venus') || lower.contains('shukra')) {
      code = 'Ve';
    } else if (lower.contains('saturn') || lower.contains('shani')) {
      code = 'Sa';
    } else if (lower.contains('rahu')) {
      code = 'Ra';
    } else if (lower.contains('ketu')) {
      code = 'Ke';
    } else if (lower.contains('uranus') || lower.contains('harshal')) {
      code = 'Ur';
    } else if (lower.contains('neptune') || lower.contains('varun')) {
      code = 'Ne';
    } else if (lower.contains('pluto') || lower.contains('yama')) {
      code = 'Pl';
    } else if (lower.contains('ascendant') || lower.contains('lagna')) {
      code = 'As';
    }

    String markers = '';
    if (isRetro) {
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
      if (parts.length >= 3) {
        int d = int.tryParse(parts[0].trim()) ?? 0;
        int m = int.tryParse(parts[1].trim()) ?? 0;
        int s = int.tryParse(parts[2].trim()) ?? 0;
        if (s >= 30) m += 1;
        if (m >= 60) {
          m -= 60;
          d += 1;
        }
        degStr =
            ' ${d.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      } else if (parts.length == 2) {
        final d = parts[0].trim().padLeft(2, '0');
        final m = parts[1].trim().padLeft(2, '0');
        degStr = ' $d:$m';
      }
    }

    return '$code$markers$degStr'.trim();
  }

  double? _getAbsoluteLongitude(dynamic item) {
    if (item == null || item is! Map) return null;
    if (item['longitude'] != null) return (item['longitude'] as num).toDouble();
    if (item['normDegree'] != null)
      return (item['normDegree'] as num).toDouble();
    if (item['abs_degree'] != null)
      return (item['abs_degree'] as num).toDouble();
    if (item['cusp_degree'] != null)
      return (item['cusp_degree'] as num).toDouble();

    final signIdx = (item['sign_index'] as num?)?.toInt();
    final degStr =
        item['degree_formatted']?.toString() ??
        item['degree_dms']?.toString() ??
        item['degree']?.toString() ??
        '';

    if (signIdx != null && degStr.isNotEmpty) {
      final cleaned = degStr
          .replaceAll('°', ':')
          .replaceAll("'", ':')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      final parts = cleaned.split(':');
      double d = 0.0;
      double m = 0.0;
      double s = 0.0;
      if (parts.isNotEmpty) d = double.tryParse(parts[0]) ?? 0.0;
      if (parts.length > 1) m = double.tryParse(parts[1]) ?? 0.0;
      if (parts.length > 2) s = double.tryParse(parts[2]) ?? 0.0;

      double degInSign = d + (m / 60.0) + (s / 3600.0);
      return ((signIdx - 1) * 30.0) + degInSign;
    }
    return null;
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

      for (final p in pList) {
        final pName = p['planet']?.toString() ?? '';
        final pNameLower = pName.toLowerCase();
        if (pNameLower.contains('uranus') ||
            pNameLower.contains('neptune') ||
            pNameLower.contains('pluto')) {
          continue;
        }

        // Use backend-provided sign_index directly — no frontend recalculation
        final sIdx = (p['sign_index'] as num?)?.toInt() ?? 1;
        // Use backend-provided house directly — no frontend recalculation
        final hNum = (p['house'] as num?)?.toInt() ?? sIdx;
        final isRetro = p['is_retrograde'] == true;
        final isCombust = p['is_combust'] == true;
        final marker = p['status_marker']?.toString() ?? '';

        final degStr =
            p['degree_formatted']?.toString() ??
            p['degree_dms']?.toString() ??
            p['degree']?.toString() ??
            '';

        final formatted = _formatPlanetLabel(
          pName,
          degStr,
          isRetro,
          isCombust,
          marker,
        );
        planetsInSign.putIfAbsent(sIdx, () => []).add(formatted);
        planetsInHouse.putIfAbsent(hNum, () => []).add(formatted);
      }
      if (showKpCusps) {
        _addKpCusps(planetsInSign, planetsInHouse, data, ascSignIdx);
      }
      return;
    }

    // Bhava Chalit placements - First try to use bhava_chalit object if provided by backend
    if (chartTypeKey == 'Bhava' && data['bhava_chalit'] != null) {
      final bData = data['bhava_chalit'];
      final pList = bData['planets'] as List<dynamic>? ?? [];

      // 1. Plot the Planets
      for (final p in pList) {
        final pName = p['planet']?.toString() ?? '';
        if (showKpCusps &&
            (pName.toLowerCase().contains('ascendant') ||
                pName.toLowerCase().contains('lagna'))) {
          continue;
        }
        final bhavaHouse = ((p['bhava_house'] ?? p['house']) as num?)?.toInt() ?? 1;
        final degStr = p['degree_formatted']?.toString() ?? '';
        final isRetro = p['is_retrograde'] == true;
        final isCombust = p['is_combust'] == true;

        final formatted = _formatPlanetLabel(
          pName,
          degStr,
          isRetro,
          isCombust,
          null,
        );

        // In Bhava Chalit, the North Indian grid (planetsInHouse) plots by house,
        // while the South Indian grid (planetsInSign) MUST plot by actual zodiac sign.
        final int actualSignIdx =
            (p['sign_index'] as num?)?.toInt() ??
            ((ascSignIdx - 1 + bhavaHouse - 1) % 12 + 1).toInt();

        planetsInHouse.putIfAbsent(bhavaHouse, () => []).add(formatted);
        planetsInSign.putIfAbsent(actualSignIdx, () => []).add(formatted);
      }
      if (showKpCusps) {
        _addKpCusps(planetsInSign, planetsInHouse, data, ascSignIdx);
      }
      return;
    }

    // KP Bhava Chalit Full Calculation Logic (if backend only gives cusps & planets)
    if (chartTypeKey == 'Bhava' &&
        data['bhava_chalit'] == null &&
        (data['bhava_cusps'] != null || data['cusps'] != null) &&
        data['planets'] != null) {
      final pList = data['planets'] as List<dynamic>;
      final rawCusps =
          (data['bhava_cusps'] as List<dynamic>?) ??
          (data['cusps'] as List<dynamic>?);

      // Parse cusps longitudes
      List<double> cuspLongitudes = List.filled(12, 0.0);
      bool hasCusps = false;
      if (rawCusps != null) {
        for (final c in rawCusps) {
          final hNum =
              (c['house'] ?? c['house_number'] ?? c['cusp_number'] as num?)
                  ?.toInt() ??
              0;
          if (hNum >= 1 && hNum <= 12) {
            final cDeg = _getAbsoluteLongitude(c);
            if (cDeg != null) {
              cuspLongitudes[hNum - 1] = cDeg;
              hasCusps = true;
            }
          }
        }
      }

      for (final p in pList) {
        final name = p['planet']?.toString() ?? p['name']?.toString() ?? '';
        final nameLower = name.toLowerCase();
        if (nameLower.contains('uranus') ||
            nameLower.contains('neptune') ||
            nameLower.contains('pluto') ||
            nameLower.contains('harshal') ||
            nameLower.contains('varun') ||
            nameLower.contains('yama')) {
          continue;
        }
        if (showKpCusps &&
            (nameLower.contains('ascendant') || nameLower.contains('lagna'))) {
          continue;
        }

        final isRetro = p['is_retrograde'] == true || p['retrograde'] == true;
        final isCombust = p['is_combust'] == true;
        final marker = p['status_marker']?.toString() ?? '';
        final String degFormatted =
            p['degree_formatted']?.toString() ??
            p['degree_dms']?.toString() ??
            p['degree']?.toString() ??
            '';
        final formatted = _formatPlanetLabel(
          name,
          degFormatted,
          isRetro,
          isCombust,
          marker,
        );

        final pDeg = _getAbsoluteLongitude(p as Map<String, dynamic>);
        int bhavaHouse = 1;

        if (pDeg != null && hasCusps) {
          for (int i = 0; i < 12; i++) {
            double startCusp = cuspLongitudes[i];
            double endCusp = cuspLongitudes[(i + 1) % 12];
            if (startCusp < endCusp) {
              if (pDeg >= startCusp && pDeg < endCusp) {
                bhavaHouse = i + 1;
                break;
              }
            } else {
              // Wraparound across 360 degrees
              if (pDeg >= startCusp || pDeg < endCusp) {
                bhavaHouse = i + 1;
                break;
              }
            }
          }
        } else {
          // Fallback if longitude missing
          final sIdx = (p['sign_index'] as num?)?.toInt() ?? 1;
          bhavaHouse = ((sIdx - ascSignIdx + 12) % 12) + 1;
        }

        int actualSignIdx =
            (p['sign_index'] as num?)?.toInt() ??
            (((ascSignIdx - 1) + (bhavaHouse - 1)) % 12 + 1);

        planetsInHouse.putIfAbsent(bhavaHouse, () => []).add(formatted);
        planetsInSign.putIfAbsent(actualSignIdx, () => []).add(formatted);
      }

      if (showKpCusps) {
        _addKpCusps(planetsInSign, planetsInHouse, data, ascSignIdx);
      }
      return;
    }

    // Lal Kitab Chart (Fixed Aries Lagna)
    if (chartTypeKey == 'LalKitab' && data['planets'] != null) {
      final pList = data['planets'] as List<dynamic>? ?? [];
      for (final p in pList) {
        final pName =
            p['planet']?.toString() ??
            p['planet_name_simple']?.toString() ??
            p['name']?.toString() ??
            '';
        final house = (p['house'] as num?)?.toInt() ?? 1;
        final degStr =
            p['longitude_formatted']?.toString() ??
            p['degree_formatted']?.toString() ??
            '';
        final isRetro = p['retrograde'] == true || p['is_retrograde'] == true;
        final isCombust = p['is_combust'] == true;

        final formatted = _formatPlanetLabel(
          pName,
          degStr,
          isRetro,
          isCombust,
          null,
        );

        // In Lal Kitab, House 1 = Aries (Sign 1), House 2 = Taurus (Sign 2), etc.
        planetsInHouse.putIfAbsent(house, () => []).add(formatted);
        planetsInSign.putIfAbsent(house, () => []).add(formatted);
      }
      return;
    }

    // Default D-1 Rashi, BNN, Jaimini (D-9 now handled in divisional charts branch above)
    if (data['planets'] != null) {
      final planetsList = data['planets'] as List<dynamic>;

      for (final p in planetsList) {
        final name = p['planet']?.toString() ?? p['name']?.toString() ?? '';
        final nameLower = name.toLowerCase();
        if (nameLower.contains('uranus') ||
            nameLower.contains('neptune') ||
            nameLower.contains('pluto') ||
            nameLower.contains('harshal') ||
            nameLower.contains('varun') ||
            nameLower.contains('yama')) {
          continue;
        }

        // When showing KP Cusps, Cusp 1 (I) represents the Ascendant
        if (showKpCusps &&
            (nameLower.contains('ascendant') || nameLower.contains('lagna'))) {
          continue;
        }

        // Use backend sign_index directly — no frontend sign name matching
        int signIdx = -1;
        final String degFormatted =
            p['degree_formatted']?.toString() ??
            p['degree_dms']?.toString() ??
            p['degree']?.toString() ??
            '';

        if (p['sign_index'] != null) {
          signIdx = (p['sign_index'] as num).toInt();
        } else {
          // Fallback: derive from sign name only if sign_index missing
          final signName = p['sign']?.toString() ?? '';
          for (int i = 0; i < signNames.length; i++) {
            if (signNames[i].toLowerCase() == signName.toLowerCase()) {
              signIdx = i + 1;
              break;
            }
          }
        }

        if (signIdx != -1) {
          final isRetro = p['is_retrograde'] == true || p['retrograde'] == true;
          final isCombust = p['is_combust'] == true;
          final marker = p['status_marker']?.toString() ?? '';

          final formatted = _formatPlanetLabel(
            name,
            degFormatted,
            isRetro,
            isCombust,
            marker,
          );

          planetsInSign.putIfAbsent(signIdx, () => []).add(formatted);
          // Use backend-provided house, otherwise calculate from sign index
          final houseNum =
              (p['house'] as num?)?.toInt() ??
              ((signIdx - ascSignIdx + 12) % 12) + 1;
          planetsInHouse.putIfAbsent(houseNum, () => []).add(formatted);
        }
      }
    }

    // Upagrahas — only show on D-1 Rashi chart, not on divisional charts
    if (showUpagrahas && chartTypeKey == 'D-1' && data['upagrahas'] != null) {
      final upagrahasList = data['upagrahas'] as List<dynamic>;
      for (final u in upagrahasList) {
        final code = u['short_code']?.toString() ?? 'Up';
        if (code == 'Md') {
          final sIdx = (u['sign_index'] as num?)?.toInt() ?? 1;
          final hNum = (u['house'] as num?)?.toInt() ?? 1;
          final degStr = u['degree_formatted']?.toString() ?? '';
          String label = code;
          if (showDegrees && degStr.isNotEmpty) {
            final parts = degStr.split(':');
            if (parts.length >= 2) {
              label += ' ${parts[0]}:${parts[1]}';
            }
          }
          planetsInSign.putIfAbsent(sIdx, () => []).add(label);
          planetsInHouse.putIfAbsent(hNum, () => []).add(label);
        }
      }
    }

    // Ensure Ascendant is always present in planetsInSign and planetsInHouse
    if (!showKpCusps) {
      final hasAscInSign = (planetsInSign[ascSignIdx] ?? []).any(
        (p) => p.startsWith('As') || p.startsWith('ASC'),
      );
      if (!hasAscInSign) {
        final ascDeg =
            data['ascendant_degree_formatted']?.toString() ??
            data['ascendant_degree']?.toString() ??
            '';
        final ascLabel = _formatPlanetLabel(
          'Ascendant',
          ascDeg,
          false,
          false,
          null,
        );
        planetsInSign
            .putIfAbsent(ascSignIdx, () => [])
            .insert(0, ascLabel.isNotEmpty ? ascLabel : 'As');
        planetsInHouse
            .putIfAbsent(1, () => [])
            .insert(0, ascLabel.isNotEmpty ? ascLabel : 'As');
      }
    } else {
      _addKpCusps(planetsInSign, planetsInHouse, data, ascSignIdx);
    }
  }

  void _addKpCusps(
    Map<int, List<String>> planetsInSign,
    Map<int, List<String>> planetsInHouse,
    Map<String, dynamic> data,
    int ascSignIdx,
  ) {
    final rawCusps =
        (data['bhava_cusps'] as List<dynamic>?) ??
        (data['bhava_chalit'] != null
            ? data['bhava_chalit']['cusps'] as List<dynamic>?
            : null) ??
        (data['cusps'] as List<dynamic>?);

    if (rawCusps == null || rawCusps.isEmpty) return;

    const romanNumerals = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];

    for (final c in rawCusps) {
      final hNum =
          (c['house'] ?? c['house_number'] ?? c['cusp_number'] as num?)
              ?.toInt() ??
          0;
      if (hNum < 1 || hNum > 12) continue;

      int sIdx = (c['sign_index'] as num?)?.toInt() ?? 0;
      String degStrRaw =
          c['degree_formatted']?.toString() ??
          c['cusp_midpoint_formatted']?.toString() ??
          c['degree']?.toString() ??
          '';

      final cuspDeg =
          (c['cusp_degree'] ??
                  c['cusp_midpoint_degree'] ??
                  c['longitude'] as num?)
              ?.toDouble();
      if (cuspDeg != null) {
        if (sIdx < 1 || sIdx > 12) {
          sIdx = ((cuspDeg / 30.0).floor() % 12) + 1;
        }
        if (degStrRaw.isEmpty) {
          final degInSign = cuspDeg % 30.0;
          final d = degInSign.floor();
          final m = ((degInSign - d) * 60).round();
          degStrRaw = '$d° $m\' 00"';
        }
      }

      if (sIdx < 1 || sIdx > 12) continue;

      int targetSignIdx = sIdx;
      if (chartTypeKey == 'D-9' && cuspDeg != null) {
        // Navamsa sign calculation (each pada/navamsa is 3° 20' = 30° / 9)
        targetSignIdx = ((cuspDeg / (30.0 / 9.0)).floor() % 12) + 1;
      }

      final roman = romanNumerals[hNum - 1];
      String degFormatted = '';
      if (showDegrees && degStrRaw.isNotEmpty) {
        final cleaned = degStrRaw
            .replaceAll('°', ':')
            .replaceAll("'", ':')
            .replaceAll('"', '')
            .replaceAll(' ', '');
        final parts = cleaned.split(':');
        if (parts.length >= 3) {
          int d = int.tryParse(parts[0].trim()) ?? 0;
          int m = int.tryParse(parts[1].trim()) ?? 0;
          int s = int.tryParse(parts[2].trim()) ?? 0;
          if (s >= 30) m += 1;
          if (m >= 60) {
            m -= 60;
            d += 1;
          }
          degFormatted =
              ' ${d.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        } else if (parts.length == 2) {
          final d = parts[0].trim().padLeft(2, '0');
          final m = parts[1].trim().padLeft(2, '0');
          degFormatted = ' $d:$m';
        }
      }

      final cuspLabel = '[CUSP] $roman$degFormatted';

      final signList = planetsInSign.putIfAbsent(targetSignIdx, () => []);
      if (!signList.any(
        (item) =>
            item.contains('[CUSP] $roman') || item.startsWith('[CUSP] $roman '),
      )) {
        int insertIdx = 0;
        while (insertIdx < signList.length &&
            signList[insertIdx].startsWith('[CUSP] ')) {
          insertIdx++;
        }
        signList.insert(insertIdx, cuspLabel);
      }

      final houseList = planetsInHouse.putIfAbsent(hNum, () => []);
      if (!houseList.any(
        (item) =>
            item.contains('[CUSP] $roman') || item.startsWith('[CUSP] $roman '),
      )) {
        int hInsertIdx = 0;
        while (hInsertIdx < houseList.length &&
            houseList[hInsertIdx].startsWith('[CUSP] ')) {
          hInsertIdx++;
        }
        houseList.insert(hInsertIdx, cuspLabel);
      }
    }
  }

  int _getAscendantSignIndex(Map<String, dynamic>? data) {
    if (chartTypeKey == 'LalKitab')
      return 1; // Always Aries Ascendant in Lal Kitab

    if (data == null) return 11; // Default Aquarius (Kumbha)

    if (chartTypeKey != 'D-1' &&
        chartTypeKey != 'Bhava' &&
        data['divisional_charts'] != null &&
        data['divisional_charts'][chartTypeKey] != null) {
      return (data['divisional_charts'][chartTypeKey]['ascendant_sign_index']
                  as num?)
              ?.toInt() ??
          11;
    }

    if (data['ascendant_sign_index'] != null) {
      return (data['ascendant_sign_index'] as num).toInt();
    }

    String ascSign =
        data['ascendant_sign']?.toString() ??
        data['ascendant_lagna']?.toString() ??
        '';
    if (ascSign.isEmpty &&
        data['overview'] != null &&
        data['overview']['ascendant_sign'] != null) {
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
  // 1. SOUTH INDIAN CHART (12 Fixed Sign Grid)
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
    final gridStrokeColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
        : const Color(0xFF475569);
    final bgFillColor = isDark
        ? const Color(0xFF13222E)
        : const Color(0xFFF8FAFC);
    final centerBoxBg = isDark
        ? const Color(0xFF0D1821)
        : const Color(0xFFEEF2F6);
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

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
    const chartNames = {
      'D-1': 'Rashi (D-1)',
      'D-2': 'Hora (D-2)',
      'D-3': 'Drekkana (D-3)',
      'D-4': 'Chaturthamsha (D-4)',
      'D-5': 'Panchamsha (D-5)',
      'D-6': 'Shashtamsha (D-6)',
      'D-7': 'Saptamsha (D-7)',
      'D-8': 'Ashtamsha (D-8)',
      'D-9': 'Navamsha (D-9)',
      'D-10': 'Dasamsha (D-10)',
      'D-11': 'Ekadashamsha (D-11)',
      'D-12': 'Dwadasamsha (D-12)',
      'D-16': 'Shodashamsha (D-16)',
      'D-20': 'Vimsamsha (D-20)',
      'D-24': 'Chaturvimsamsha (D-24)',
      'D-27': 'Saptavimsamsha (D-27)',
      'D-30': 'Trimshamsha (D-30)',
      'D-40': 'Khavedamsha (D-40)',
      'D-45': 'Akshavedamsha (D-45)',
      'D-60': 'Shashtiamsha (D-60)',
      'Bhava': 'Bhava Chalit',
      'LalKitab': 'Lal Kitab',
      'BNN': 'Progressive (BNN)',
      'Jaimini': 'Jaimini Rasi',
    };
    final centerTitle = chartNames[chartTypeKey] ?? chartTypeKey;

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
      (0, 0, 12), // Pisces - Top Left
      (1, 0, 1), // Aries - Top Mid-Left
      (2, 0, 2), // Taurus - Top Mid-Right
      (3, 0, 3), // Gemini - Top Right
      (3, 1, 4), // Cancer - Right Top-Mid
      (3, 2, 5), // Leo - Right Bottom-Mid
      (3, 3, 6), // Virgo - Bottom Right
      (2, 3, 7), // Libra - Bottom Mid-Right
      (1, 3, 8), // Scorpio - Bottom Mid-Left
      (0, 3, 9), // Sagittarius - Bottom Left
      (0, 2, 10), // Capricorn - Left Bottom-Mid
      (0, 1, 11), // Aquarius - Left Top-Mid
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
      // Moved to top-right corner to avoid overlapping with text
      if (isAsc) {
        final ascSlashPaint = Paint()
          ..color = (isDark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48))
              .withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawLine(
          Offset(cellLeft + dx - 16, cellTop + 8),
          Offset(cellLeft + dx - 8, cellTop + 16),
          ascSlashPaint,
        );
        canvas.drawLine(
          Offset(cellLeft + dx - 22, cellTop + 8),
          Offset(cellLeft + dx - 14, cellTop + 16),
          ascSlashPaint,
        );
      }

      // Small subtle Sign abbreviation in top-left corner (e.g. Ar, Ta, Ge)
      final signShort = [
        'Ar',
        'Ta',
        'Ge',
        'Cn',
        'Le',
        'Vi',
        'Li',
        'Sc',
        'Sg',
        'Cp',
        'Aq',
        'Pi',
      ][sIdx - 1];
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
        final fontSize = count > 4
            ? 8.0
            : (count > 3 ? 8.8 : (count > 2 ? 9.8 : 10.5));
        final lineHeight = fontSize * 1.35;
        final totalTextHeight = count * lineHeight;
        final startY =
            (cellTop + (dy - totalTextHeight) / 2) + (fontSize * 0.4);

        for (int pIdx = 0; pIdx < count; pIdx++) {
          String pText = rawPlanets[pIdx];

          final isCusp = pText.startsWith('[CUSP] ');
          if (isCusp) pText = pText.replaceAll('[CUSP] ', '');

          final isPAs = pText.startsWith('As');
          final isPMo = pText.startsWith('Mo');
          final isUp =
              pText.startsWith('Md') ||
              pText.startsWith('Gk') ||
              pText.startsWith('Dh') ||
              pText.startsWith('Vy') ||
              pText.startsWith('Pv');

          Color textColor = isDark
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF0F172A);
          if (isCusp) {
            textColor = isDark
                ? const Color(0xFFA78BFA)
                : const Color(0xFF7C3AED); // Distinct Violet for KP Cusps
          } else if (isPAs) {
            textColor = ascColor;
          } else if (isPMo) {
            textColor = moonColor;
          } else if (isUp) {
            textColor = const Color(0xFF94A3B8);
          } else if (pText.contains('(R)')) {
            textColor = isDark
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFDC2626);
          }

          _drawText(
            canvas,
            pText,
            Offset(cellLeft + dx * 0.5, startY + (pIdx * lineHeight)),
            textColor,
            isPAs || isPMo || isCusp || pText.contains('(R)'),
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
    final strokeColor = isDark
        ? const Color(0xFF6366F1)
        : const Color(0xFF4338CA);
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      bgFill,
    );

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
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      linePaint,
    );

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
        final fontSize = count > 4
            ? 7.8
            : (count > 3 ? 8.5 : (count > 2 ? 9.5 : 10.5));
        final lineHeight = fontSize * 1.32;
        final startY =
            housePlanetCenters[hIdx - 1].dy - ((count - 1) * lineHeight / 2);

        for (int p = 0; p < count; p++) {
          String pText = planets[p];

          final isCusp = pText.startsWith('[CUSP] ');
          if (isCusp) pText = pText.replaceAll('[CUSP] ', '');

          final isPAs = pText.startsWith('As');
          final isUp =
              pText.startsWith('Md') ||
              pText.startsWith('Gk') ||
              pText.startsWith('Dh') ||
              pText.startsWith('Vy') ||
              pText.startsWith('Pv');

          Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          if (isCusp) {
            textColor = isDark
                ? const Color(0xFFA78BFA)
                : const Color(0xFF7C3AED); // Distinct Violet for KP Cusps
          } else if (isPAs) {
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
            isPAs || isCusp || pText.contains('(R)'),
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
    final strokeColor = isDark
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(14),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(14),
      ),
      paint,
    );

    canvas.drawLine(Offset.zero, Offset(w, h), paint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), paint);

    final midBox = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w * 0.5,
      height: h * 0.5,
    );
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
      bool hasCusp = false;

      if (planets.isNotEmpty) {
        for (String p in planets) {
          if (p.startsWith('[CUSP] ')) {
            hasCusp = true;
            lines.add(p.replaceAll('[CUSP] ', ''));
          } else {
            lines.add(p);
          }
        }
      }

      final label = lines.join('\n');
      final textColor = isAsc
          ? ascColor
          : (hasCusp
                ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                : (isDark ? Colors.white : const Color(0xFF1E293B)));
      _drawText(
        canvas,
        label,
        eastPositions[sIdx - 1],
        textColor,
        isAsc || planets.isNotEmpty,
        9.5,
      );
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
          height: 1.15.h,
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
