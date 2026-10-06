import os
import re

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_frontend/astro_app/lib/screens/kp_system_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

matrix_ui_code = '''  Widget _buildAspectsSection(bool isDark) {
    if (_kpData == null) return const Center(child: CircularProgressIndicator());
    final aspects = _kpData!['aspects'] as Map<String, dynamic>? ?? {};
    final planetAspects = (aspects['planet_aspects'] as List<dynamic>?) ?? [];
    final cuspAspects = (aspects['cusp_aspects'] as List<dynamic>?) ?? [];
    final planets = (_kpData!['planets'] as List<dynamic>?) ?? [];
    final cusps = (_kpData!['bhava_cusps'] as List<dynamic>?) ?? [];

    // Precompute matrices
    Map<String, Map<String, dynamic>> planetAspectMatrix = {};
    for (var asp in planetAspects) {
      String p1 = asp['planet_1']?.toString() ?? '';
      String p2 = asp['planet_2']?.toString() ?? '';
      if (!planetAspectMatrix.containsKey(p1)) planetAspectMatrix[p1] = {};
      planetAspectMatrix[p1]![p2] = asp;
      if (!planetAspectMatrix.containsKey(p2)) planetAspectMatrix[p2] = {};
      planetAspectMatrix[p2]![p1] = asp;
    }
    
    Map<String, Map<String, dynamic>> cuspAspectMatrix = {};
    for (var asp in cuspAspects) {
      String p = asp['planet']?.toString() ?? '';
      String c = asp['cusp_house']?.toString() ?? '';
      if (!cuspAspectMatrix.containsKey(p)) cuspAspectMatrix[p] = {};
      cuspAspectMatrix[p]![c] = asp;
    }

    // Longitudes
    Map<String, double> longitudes = {};
    for (var p in planets) {
      String pName = p['name']?.toString() ?? '';
      longitudes[pName] = (p['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    for (var c in cusps) {
      String cName = c['house']?.toString() ?? c['cusp']?.toString() ?? '';
      longitudes[cName] = (c['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    final colNamesPlanet = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Uranus', 'Neptune', 'Pluto'];
    final rowNamesPlanet = ['Ascendant', 'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu', 'Uranus', 'Neptune', 'Pluto'];
    
    final colNamesCusp = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    final rowNamesCusp = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu', 'Uranus', 'Neptune', 'Pluto'];

    double cellWidth = 55.w;
    double cellHeight = 45.h;
    Color headerBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    Color borderColor = isDark ? Colors.white24 : Colors.black12;

    String _getCuspLabel(String c) {
      switch (c) {
        case '1': return 'I';
        case '2': return 'II';
        case '3': return 'III';
        case '4': return 'IV';
        case '5': return 'V';
        case '6': return 'VI';
        case '7': return 'VII';
        case '8': return 'VIII';
        case '9': return 'IX';
        case '10': return 'X';
        case '11': return 'XI';
        case '12': return 'XII';
        default: return c;
      }
    }

    Widget buildMatrix(List<String> rNames, List<String> cNames, Map<String, Map<String, dynamic>> matrix, bool isCusp) {
      return Container(
        margin: EdgeInsets.only(top: 14.h),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left fixed column
              Column(
                children: [
                  Container(
                    width: 60.w,
                    height: cellHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: headerBgColor,
                      border: Border(
                        right: BorderSide(color: borderColor),
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text('Planet', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.sp, color: isDark ? Colors.white70 : Colors.black54)),
                  ),
                  ...rNames.map((rName) {
                    return Container(
                      width: 60.w,
                      height: cellHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: headerBgColor,
                        border: Border(
                          right: BorderSide(color: borderColor),
                          bottom: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Text(rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    );
                  }).toList(),
                ],
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: cNames.map((cName) {
                          return Container(
                            width: cellWidth,
                            height: cellHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: headerBgColor,
                              border: Border(
                                right: BorderSide(color: borderColor),
                                bottom: BorderSide(color: borderColor),
                              ),
                            ),
                            child: Text(isCusp ? _getCuspLabel(cName) : _getLordShort(cName), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          );
                        }).toList(),
                      ),
                      ...rNames.map((rName) {
                        return Row(
                          children: cNames.map((cName) {
                            Widget content = const SizedBox();
                            Color bgColor = Colors.transparent;
                            bool hasText = false;

                            if (!isCusp && rName == cName) {
                              content = Text('0', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.sp, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)));
                              hasText = true;
                            } else {
                              if (longitudes.containsKey(rName) && longitudes.containsKey(cName)) {
                                double colLon = longitudes[cName]!;
                                double rowLon = longitudes[rName]!;
                                double forwardAngle = (rowLon - colLon) % 360.0;
                                if (forwardAngle < 0) forwardAngle += 360.0;
                                
                                final asp = matrix[rName]?[cName];
                                bool shouldDisplay = false;
                                
                                if (asp != null) {
                                  double aspectAngle = (asp['aspect_angle'] as num?)?.toDouble() ?? 0.0;
                                  if ((forwardAngle - aspectAngle).abs() <= 20.0) shouldDisplay = true;
                                  else if (aspectAngle == 90.0 && (forwardAngle - 270.0).abs() <= 20.0) shouldDisplay = true;
                                  else if (aspectAngle == 120.0 && (forwardAngle - 240.0).abs() <= 20.0) shouldDisplay = true;
                                  else if (aspectAngle == 0.0 && (forwardAngle - 360.0).abs() <= 20.0) shouldDisplay = true;
                                  else if (aspectAngle == 180.0 && (forwardAngle - 180.0).abs() <= 20.0) shouldDisplay = true;
                                }
                                
                                if (shouldDisplay && asp != null) {
                                  String shortAsp = asp['aspect_name']?.toString() ?? '';
                                  if (shortAsp.length > 15) shortAsp = shortAsp.substring(0, 15);
                                  String orbText = forwardAngle.toStringAsFixed(2);
                                      
                                  String nature = (asp['nature']?.toString() ?? '').toLowerCase();
                                  Color textColor = isDark ? Colors.white : Colors.black87;
                                  
                                  if (nature.contains("yellow") || shortAsp.toLowerCase().contains("conj")) {
                                    bgColor = const Color(0xFFFDE047); 
                                  } else if (nature.contains("darkgreen") || shortAsp.toLowerCase().contains("trin") || shortAsp.toLowerCase().contains("bqui") || shortAsp.toLowerCase().contains("d126")) {
                                    bgColor = const Color(0xFF22C55E); 
                                    textColor = Colors.white;
                                  } else if (nature.contains("green") || nature.contains("harmonious") || shortAsp.toLowerCase().contains("sext") || shortAsp.toLowerCase().contains("semi") || shortAsp.toLowerCase().contains("quin") || shortAsp.toLowerCase().contains("tred") || shortAsp.toLowerCase().contains("vigi")) {
                                    bgColor = const Color(0xFF86EFAC); 
                                  } else if (nature.contains("lightred") || shortAsp.toLowerCase().contains("ssqu") || shortAsp.toLowerCase().contains("d54")) {
                                    bgColor = const Color(0xFFFCA5A5);
                                  } else if (nature.contains("red") || nature.contains("adverse") || shortAsp.toLowerCase().contains("squr") || shortAsp.toLowerCase().contains("oppn")) {
                                    bgColor = const Color(0xFFEF4444); 
                                    textColor = Colors.white;
                                  } else {
                                    bgColor = const Color(0xFFE2E8F0); 
                                  }

                                  content = Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(orbText, style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: textColor)),
                                      SizedBox(height: 2.h),
                                      Text(shortAsp, style: GoogleFonts.inter(fontSize: 8.5.sp, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.9)), textAlign: TextAlign.center),
                                    ],
                                  );
                                  hasText = true;
                                } else {
                                  String orbText = forwardAngle.toStringAsFixed(2);
                                  content = Text(orbText, style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)));
                                  hasText = true;
                                }
                              }
                            }

                            return Container(
                              width: cellWidth,
                              height: cellHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border(
                                  right: BorderSide(color: borderColor),
                                  bottom: BorderSide(color: borderColor),
                                ),
                              ),
                              child: hasText ? content : const SizedBox(),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dropdownOptions = [
      'Aspect Planet -> Planet',
      'Aspect Planet -> Cusp',
      'Aspect Transit Pl. -> Natal Cusp',
      'Aspect Natal Vs Transit Pl.'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Container
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.25)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _aspectSubTabIndex,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4338CA)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: GoogleFonts.outfit(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              items: dropdownOptions.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (newIdx) {
                if (newIdx != null && newIdx != _aspectSubTabIndex) {
                  setState(() => _aspectSubTabIndex = newIdx);
                }
              },
            ),
          ),
        ),
        
        if (_aspectSubTabIndex == 0) ...[
          if (planetAspects.isEmpty)
            _buildInfoCard('No major planetary aspects within orb.', isDark)
          else
            buildMatrix(rowNamesPlanet, colNamesPlanet, planetAspectMatrix, false),
        ] else if (_aspectSubTabIndex == 1) ...[
          if (cuspAspects.isEmpty)
            _buildInfoCard('No cusp aspects within orb.', isDark)
          else
            buildMatrix(rowNamesCusp, colNamesCusp, cuspAspectMatrix, true),
        ] else ...[
          _buildInfoCard('Coming Soon', isDark),
        ],
      ],
    );
  }
'''

# Find the start of _buildAspectsSection
start_idx = code.find('  Widget _buildAspectsSection(bool isDark) {')
if start_idx != -1:
    # Find the end of this method (approximate by finding the next Widget method)
    end_idx = code.find('  Widget _build', start_idx + 10)
    if end_idx == -1:
        # If it's the last method, just replace till end
        end_idx = len(code) - 2 # Keep the last '}'
        
    code = code[:start_idx] + matrix_ui_code + '\n' + code[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
print('Replaced aspects section with matrix and dropdown!')
