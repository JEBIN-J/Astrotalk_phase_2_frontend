import re

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_frontend/astro_app/lib/screens/kp_system_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

new_func = '''  Widget _buildPlanetAspectsTable(List<dynamic> planets, List<dynamic> aspects, bool isDark) {
    if (planets.isEmpty) return _buildInfoCard('No planets available.', isDark);
    if (aspects.isEmpty) return _buildInfoCard('No major planetary aspects within orb.', isDark);

    final colNames = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Uranus", "Neptune", "Pluto"];
    final rowNames = ["Ascendant", "Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu", "Uranus", "Neptune", "Pluto"];

    Map<String, double> longitudes = {};
    for (var p in planets) {
      longitudes[p['name'].toString()] = (p['longitude'] as num).toDouble();
    }
    
    Map<String, Map<String, dynamic>> aspectMatrix = {};
    for (var p in rowNames) {
      aspectMatrix[p] = {};
    }
    
    for (var asp in aspects) {
      String p1 = asp['planet_1']?.toString() ?? asp['p1_name']?.toString() ?? '';
      String p2 = asp['planet_2']?.toString() ?? asp['p2_name']?.toString() ?? '';
      if (aspectMatrix.containsKey(p1)) aspectMatrix[p1]![p2] = asp;
      if (aspectMatrix.containsKey(p2)) aspectMatrix[p2]![p1] = asp;
    }

    final cellWidth = 55.w;
    final cellHeight = 50.h;
    final headerBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
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
                  child: Text('Planet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.sp, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                ),
                ...rowNames.map((rName) {
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
                    child: Text(rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  );
                }).toList(),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: colNames.map((cName) {
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
                          child: Text(_getLordShort(cName), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                        );
                      }).toList(),
                    ),
                    ...rowNames.map((rowP) {
                      return Row(
                        children: colNames.map((colP) {
                          Widget content = const SizedBox();
                          Color bgColor = Colors.transparent;
                          bool hasText = false;

                          if (rowP == colP) {
                            content = Text('0', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.sp, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)));
                            hasText = true;
                          } else {
                            if (longitudes.containsKey(rowP) && longitudes.containsKey(colP)) {
                              double colLon = longitudes[colP]!;
                              double rowLon = longitudes[rowP]!;
                              double forwardAngle = (rowLon - colLon) % 360.0;
                              if (forwardAngle < 0) forwardAngle += 360.0;
                              
                              final asp = aspectMatrix[rowP]?[colP];
                              bool shouldDisplay = false;
                              
                              if (asp != null) {
                                double aspectAngle = (asp['aspect_angle'] as num?)?.toDouble() ?? 0.0;
                                // Use a 20 degree tolerance just to pick the correct side of the matrix to display the aspect
                                if ((forwardAngle - aspectAngle).abs() <= 20.0) {
                                  shouldDisplay = true;
                                } else if (aspectAngle == 90.0 && (forwardAngle - 270.0).abs() <= 20.0) {
                                  shouldDisplay = true;
                                } else if (aspectAngle == 120.0 && (forwardAngle - 240.0).abs() <= 20.0) {
                                  shouldDisplay = true;
                                } else if (aspectAngle == 0.0 && (forwardAngle - 360.0).abs() <= 20.0) {
                                  shouldDisplay = true;
                                } else if (aspectAngle == 180.0 && (forwardAngle - 180.0).abs() <= 20.0) {
                                  shouldDisplay = true;
                                }
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
  }'''

pattern = re.compile(r'  Widget _buildPlanetAspectsTable\(.*?Widget _buildCuspAspectsTable', re.DOTALL)
new_code = pattern.sub(new_func + '\n\n  Widget _buildCuspAspectsTable', code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_code)
print('Updated kp_system_view.dart with lagna fix')
