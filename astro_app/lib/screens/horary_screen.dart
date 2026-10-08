import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/astro_api_service.dart';

class HoraryScreen extends StatefulWidget {
  const HoraryScreen({super.key});

  @override
  State<HoraryScreen> createState() => _HoraryScreenState();
}

class _HoraryScreenState extends State<HoraryScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _horaryData;
  String _errorMsg = '';
  List<dynamic> _questions = [];

  TextEditingController _questionCtrl = TextEditingController();
  TextEditingController _kpNumberCtrl = TextEditingController();
  TextEditingController _dateCtrl = TextEditingController(text: DateTime.now().toString().substring(0,10));
  TextEditingController _timeCtrl = TextEditingController();
  TextEditingController _latCtrl = TextEditingController(text: '28.6139');
  TextEditingController _lonCtrl = TextEditingController(text: '77.2090');
  TextEditingController _tzCtrl = TextEditingController(text: '5.5');
  String _selectedAyanamsa = 'KP_NEW';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final q = await AstroApiService.getHoraryQuestions();
      setState(() {
        _questions = q;
      });
    } catch (e) {
      debugPrint("Failed to load questions: ");
    }
  }

  Future<void> _fetchHorary() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final data = await AstroApiService.getHoraryChart(
        question: _questionCtrl.text,
        questionDate: _dateCtrl.text,
        questionTime: _timeCtrl.text,
        latitude: double.tryParse(_latCtrl.text) ?? 28.6139,
        longitude: double.tryParse(_lonCtrl.text) ?? 77.2090,
        timezone: double.tryParse(_tzCtrl.text) ?? 5.5,
        ayanamsa: _selectedAyanamsa,
        horaryNumber: int.tryParse(_kpNumberCtrl.text),
      );
      setState(() {
        _horaryData = data['data'];
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showQuestionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            final cat = _questions[index];
            final catName = cat['category'];
            final qs = cat['questions'] as List<dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(catName, style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
                ...qs.map((q) => ListTile(
                  title: Text(q, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    _questionCtrl.text = q;
                    Navigator.pop(context);
                  },
                )).toList(),
              ],
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('Horary Astrology (KP)', style: GoogleFonts.outfit(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Your Question',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFF1E293B),
                      filled: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.blueAccent),
                  onPressed: _showQuestionPicker,
                )
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _timeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Time (e.g. 3:15 PM)', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Latitude', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Longitude', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _tzCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Timezone', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedAyanamsa,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Ayanamsa', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), fillColor: Color(0xFF1E293B), filled: true),
              items: ['LAHIRI', 'BV_RAMAN', 'SRI_YUKTESWAR', 'DE_LUCE', 'USHA_SHASHI', 'DJWHAL_KHOOL', 'JN_BHASIN', 'FAGAN_BRADLEY', 'KP_OLD', 'KP_NEW', 'KP_STRAIGHT_LINE', 'KHULLAR', 'CHANDRA_HARI'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAyanamsa = val);
                }
              },
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kpNumberCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'KP Number (1-249)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFF1E293B),
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final n = await AstroApiService.getHoraryRandomNumber();
                      setState(() {
                        _kpNumberCtrl.text = n.toString();
                      });
                    } catch (e) {
                      debugPrint('Error generating number');
                    }
                  },
                  icon: const Icon(Icons.casino),
                  label: const Text('Auto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  ),
                )
              ],
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchHorary,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Calculate Horary Chart'),
            ),
            SizedBox(height: 24.h),
            if (_errorMsg.isNotEmpty)
              Text(_errorMsg, style: const TextStyle(color: Colors.red)),
            
            
            if (_horaryData != null)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Horary Engine Result:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ascendant: ${(_horaryData!['ascendant'] as num).toStringAsFixed(2)}\u00B0', style: const TextStyle(color: Colors.blueAccent, fontSize: 16)),
                        Text('Ayanamsa: ${(_horaryData!['ayanamsa_value'] as num).toStringAsFixed(6)}\u00B0', style: const TextStyle(color: Colors.blueAccent, fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text('Planetary Positions', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DataTable(
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                          columns: const [
                            DataColumn(label: Text('Planet', style: TextStyle(color: Colors.white70))),
                          ],
                          rows: (_horaryData!['planets'] as List).map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p['planet'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ]);
                          }).toList(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                              columns: const [
                                DataColumn(label: Text('Longitude', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Sign', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Star Lord', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Sub Lord', style: TextStyle(color: Colors.white70))),
                              ],
                              rows: (_horaryData!['planets'] as List).map((p) {
                                return DataRow(cells: [
                                  DataCell(Text((p['longitude'] as num).toStringAsFixed(2) + '\u00B0', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(p['sign']?['name']?.toString() ?? p['sign']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(p['star_lord']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(p['sub_lord']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text('House Cusps', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DataTable(
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                          columns: const [
                            DataColumn(label: Text('House', style: TextStyle(color: Colors.white70))),
                          ],
                          rows: (_horaryData!['cusps'] as List).map((c) {
                            return DataRow(cells: [
                              DataCell(Text(c['house'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ]);
                          }).toList(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                              columns: const [
                                DataColumn(label: Text('Longitude', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Sign', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Star Lord', style: TextStyle(color: Colors.white70))),
                                DataColumn(label: Text('Sub Lord', style: TextStyle(color: Colors.white70))),
                              ],
                              rows: (_horaryData!['cusps'] as List).map((c) {
                                return DataRow(cells: [
                                  DataCell(Text((c['longitude'] as num).toStringAsFixed(2) + '\u00B0', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(c['sign']?['name']?.toString() ?? c['sign']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(c['star_lord']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(c['sub_lord']?.toString() ?? '', style: const TextStyle(color: Colors.white))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }
}
