import os
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

    final cellWidth = 65.w;
    final cellHeight = 55.h;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
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
                    color: headerColor,
                    border: Border(
                      right: BorderSide(color: borderColor),
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  child: Text('Lagna', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.sp, color: isDark ? Colors.white70 : const Color(0xFF4338CA))),
                ),
                ...rowNames.map((rName) {
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: headerColor,
                      border: Border(
                        right: BorderSide(color: borderColor),
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text(rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName), style: _cellBoldStyle(isDark)),
                  );
                }).toList(),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                            color: headerColor,
                            border: Border(
                              right: BorderSide(color: borderColor),
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Text(_getLordShort(cName), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.sp, color: isDark ? Colors.white70 : const Color(0xFF4338CA))),
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
                            content = Text('0', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white24 : Colors.black26));
                            hasText = true;
                          } else {
                            final asp = aspectMatrix[rowP]?[colP];
                            if (asp != null && longitudes.containsKey(rowP) && longitudes.containsKey(colP)) {
                              double colLon = longitudes[colP]!;
                              double rowLon = longitudes[rowP]!;
                              double forwardAngle = (rowLon - colLon) % 360.0;
                              if (forwardAngle < 0) forwardAngle += 360.0;
                              
                              double aspectAngle = (asp['aspect_angle'] as num?)?.toDouble() ?? 0.0;
                              double orb = (asp['orb'] as num?)?.toDouble() ?? 5.0;
                              
                              bool shouldDisplay = false;
                              if ((forwardAngle - aspectAngle).abs() <= orb) {
                                shouldDisplay = true;
                              } else if (aspectAngle == 90.0 && (forwardAngle - 270.0).abs() <= orb) {
                                shouldDisplay = true; // Waning Square
                              } else if (aspectAngle == 120.0 && (forwardAngle - 240.0).abs() <= orb) {
                                shouldDisplay = true; // Waning Trine
                              } else if (aspectAngle == 0.0 && (forwardAngle - 360.0).abs() <= orb) {
                                shouldDisplay = true; // Conjunction overflow
                              }
                              
                              if (shouldDisplay) {
                                String shortAsp = asp['aspect_name']?.toString() ?? '';
                                if (shortAsp.length > 15) shortAsp = shortAsp.substring(0, 15);
                                String orbText = forwardAngle.toStringAsFixed(2);
                                    
                                String nature = asp['nature']?.toString() ?? '';
                                Color textColor = isDark ? Colors.white : Colors.black;
                                
                                if (nature == "Yellow") {
                                  bgColor = const Color(0xFFFEF08A); // Yellow
                                } else if (nature == "Green") {
                                  bgColor = const Color(0xFFBBF7D0); // Light Green
                                } else if (nature == "DarkGreen") {
                                  bgColor = const Color(0xFF166534); // Dark Green
                                  textColor = Colors.white;
                                } else if (nature == "Red") {
                                  bgColor = const Color(0xFFDC2626); // Red
                                  textColor = Colors.white;
                                } else if (nature == "LightRed") {
                                  bgColor = const Color(0xFFFECACA); // Light Red
                                } else {
                                  bgColor = const Color(0xFFBBF7D0); 
                                }

                                content = Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(orbText, style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: textColor)),
                                    SizedBox(height: 1.h),
                                    Text(shortAsp, style: GoogleFonts.outfit(fontSize: 9.sp, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
                                  ],
                                );
                                hasText = true;
                              } else {
                                // Just show the forward angle (blank cell)
                                String orbText = forwardAngle.toStringAsFixed(2);
                                content = Text(orbText, style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54));
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
print('Updated kp_system_view.dart with new logic and colors')
