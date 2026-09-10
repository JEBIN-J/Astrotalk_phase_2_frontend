import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/astro_api_service.dart';
import '../widgets/kundli_chart_painter.dart';
import '../models/astro_models.dart';

class PrashnaScreen extends StatefulWidget {
  final String? appBarTitle;
  const PrashnaScreen({super.key, this.appBarTitle});

  @override
  State<PrashnaScreen> createState() => _PrashnaScreenState();
}

class _PrashnaScreenState extends State<PrashnaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _prashnaData;

  // Prashna inputs
  DateTime _questionDate = DateTime.now();
  TimeOfDay _questionTime = TimeOfDay.now();
  String _place = "Delhi, India";
  double _latitude = 28.6139;
  double _longitude = 77.2090;
  double _timezone = 5.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _fetchPrashnaChart();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrashnaChart() async {
    setState(() => _isLoading = true);
    try {
      final qDate = DateFormat('yyyy-MM-dd').format(_questionDate);
      final qTime = '${_questionTime.hour.toString().padLeft(2, '0')}:${_questionTime.minute.toString().padLeft(2, '0')}:00';
      
      final data = await AstroApiService.getPrashnaChart(
        questionDate: qDate,
        questionTime: qTime,
        placeOfQuestion: _place,
        latitude: _latitude,
        longitude: _longitude,
        timezone: _timezone,
      );
      if (mounted) {
        setState(() {
          _prashnaData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showEditDetailsDialog() async {
    DateTime tempDate = _questionDate;
    TimeOfDay tempTime = _questionTime;
    TextEditingController placeCtrl = TextEditingController(text: _place);
    TextEditingController latCtrl = TextEditingController(text: _latitude.toString());
    TextEditingController lonCtrl = TextEditingController(text: _longitude.toString());
    TextEditingController tzCtrl = TextEditingController(text: _timezone.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              contentPadding: EdgeInsets.all(24.w),
              titlePadding: EdgeInsets.only(left: 24.w, top: 24.h, right: 24.w, bottom: 8.h),
              title: Text('Edit Question Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20.sp)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Date', style: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(tempDate), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87)),
                        trailing: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5), size: 22),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => tempDate = picked);
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Time', style: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey)),
                        subtitle: Text(tempTime.format(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87)),
                        trailing: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(Icons.access_time_rounded, color: Color(0xFF4F46E5), size: 22),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: tempTime,
                          );
                          if (picked != null) {
                            setDialogState(() => tempTime = picked);
                          }
                        },
                      ),
                      SizedBox(height: 20.h),
                      Autocomplete<Map<String, String>>(
                        initialValue: TextEditingValue(text: placeCtrl.text),
                        displayStringForOption: (option) => option['city'] ?? '',
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, String>>.empty();
                          }
                          try {
                            return await AstroApiService.getPlaces(query: textEditingValue.text);
                          } catch (_) {
                            return const Iterable<Map<String, String>>.empty();
                          }
                        },
                        onSelected: (Map<String, String> selection) {
                          placeCtrl.text = selection['city'] ?? '';
                          latCtrl.text = selection['lat_val'] ?? '';
                          lonCtrl.text = selection['lon_val'] ?? '';
                          tzCtrl.text = selection['tz_val'] ?? '';
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          // Sync initial text if controller is empty but placeCtrl isn't
                          if (controller.text.isEmpty && placeCtrl.text.isNotEmpty) {
                            controller.text = placeCtrl.text;
                          }
                          // Update placeCtrl whenever this changes
                          controller.addListener(() {
                            placeCtrl.text = controller.text;
                          });
                          
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: GoogleFonts.outfit(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Location Name (Search)',
                              hintText: 'Type to search city...',
                              labelStyle: GoogleFonts.outfit(fontSize: 14.sp),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              suffixIcon: const Icon(Icons.search_rounded),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 300.w),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option['city'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                                      subtitle: Text('${option['coords']} • ${option['tz']}', style: GoogleFonts.outfit(fontSize: 12.sp)),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latCtrl,
                              style: GoogleFonts.outfit(fontSize: 16.sp),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                labelStyle: GoogleFonts.outfit(fontSize: 14.sp),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: lonCtrl,
                              style: GoogleFonts.outfit(fontSize: 16.sp),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                labelStyle: GoogleFonts.outfit(fontSize: 14.sp),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: tzCtrl,
                        style: GoogleFonts.outfit(fontSize: 16.sp),
                        decoration: InputDecoration(
                          labelText: 'Timezone Offset (e.g., 5.5)',
                          labelStyle: GoogleFonts.outfit(fontSize: 14.sp),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (mounted) {
                      setState(() {
                        _questionDate = tempDate;
                        _questionTime = tempTime;
                        _place = placeCtrl.text;
                        _latitude = double.tryParse(latCtrl.text) ?? _latitude;
                        _longitude = double.tryParse(lonCtrl.text) ?? _longitude;
                        _timezone = double.tryParse(tzCtrl.text) ?? _timezone;
                      });
                      _fetchPrashnaChart();
                    }
                  },
                  child: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.appBarTitle ?? 'Prashna Chart', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF4F46E5),
              indicatorWeight: 3,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14.sp),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Vimshottari'),
                Tab(text: 'Yogini'),
                Tab(text: 'Kala Chakra'),
                Tab(text: 'Ashtottari'),
                Tab(text: 'Chara'),
                Tab(text: 'Navamsa'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                        SizedBox(height: 16.h),
                        Text(
                          'Calculating Prashna Matrix...',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : _prashnaData == null
                    ? const Center(child: Text('No data available'))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildDashaTimelineTab(_prashnaData!['vimshottari']),
                          _buildDashaTimelineTab(_prashnaData!['yogini']),
                          _buildKalaChakraTab(_prashnaData!['kala_chakra']),
                          _buildDashaTimelineTab(_prashnaData!['ashtottari']),
                          _buildCharaTab(_prashnaData!['chara']),
                          _buildNavamsaTab(_prashnaData!['navamsa']),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Details',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6.w),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(_questionDate)} • ${_questionTime.format(context)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        _place,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showEditDetailsDialog,
            icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF4F46E5)),
            label: Text(
              'Edit',
              style: GoogleFonts.outfit(
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final ov = _prashnaData!['overview'];
    final planets = _prashnaData!['planets'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoRow('Prashna Lagna', ov['prashna_lagna'], isDark, isTop: true),
              _divider(isDark),
              _infoRow('Moon Sign', ov['moon_sign'], isDark),
              _divider(isDark),
              _infoRow('Nakshatra', '${ov['moon_nakshatra']} (Pada ${ov['moon_pada']})', isDark),
              _divider(isDark),
              _infoRow('Ayanamsa', ov['ayanamsa'], isDark, isBottom: true),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Planetary Positions',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                ),
                headingTextStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
                dataTextStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
                columns: const [
                  DataColumn(label: Text('Planet')),
                  DataColumn(label: Text('Sign')),
                  DataColumn(label: Text('Degree')),
                  DataColumn(label: Text('Nakshatra')),
                ],
                rows: planets.map((p) => DataRow(
                  cells: [
                    DataCell(Text(p['planet_name_simple'] ?? '-')),
                    DataCell(Text(p['sign'] ?? '-')),
                    DataCell(Text(p['degree_formatted'] ?? '-')),
                    DataCell(Text('${p['nakshatra'] ?? '-'} (${p['pada'] ?? '-'})')),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

  Widget _infoRow(String label, String value, bool isDark, {bool isTop = false, bool isBottom = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashaTimelineTab(Map<String, dynamic>? dashaData) {
    if (dashaData == null || dashaData['timeline'] == null) {
      return const Center(child: Text('Data not available'));
    }
    final timeline = dashaData['timeline'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final md = timeline[index];
        final ads = md['antardashas'] as List? ?? [];
        final isActive = md['is_active'] == true;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isActive 
                  ? const Color(0xFF4F46E5) 
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive 
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isActive ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              childrenPadding: EdgeInsets.only(bottom: 12.h),
              leading: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: isActive 
                      ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                      : LinearGradient(
                          colors: isDark 
                              ? [const Color(0xFF334155), const Color(0xFF475569)]
                              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (md['lord'] ?? md['planet']).toString().substring(0, 1).toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isActive ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              title: Text(
                '${md['lord'] ?? md['planet']} Mahadasha',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      '${md['start_date'] ?? md['start']} - ${md['end_date'] ?? md['end']}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              children: ads.map((ad) {
                final adActive = ad['is_active'] == true;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: adActive 
                        ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(8.r),
                    border: adActive 
                        ? Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (adActive) ...[
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            '${ad['lord'] ?? ad['planet']} Antardasha',
                            style: GoogleFonts.outfit(
                              fontWeight: adActive ? FontWeight.bold : FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${ad['start_date'] ?? ad['start']} - ${ad['end_date'] ?? ad['end']}',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: adActive ? const Color(0xFF4F46E5) : Colors.grey,
                          fontWeight: adActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKalaChakraTab(Map<String, dynamic>? kcData) {
    if (kcData == null) return const Center(child: Text('Data not available'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0083B0).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kcStat('Deha', kcData['deha']),
              Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
              _kcStat('Jeeva', kcData['jeeva']),
              Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
              _kcStat('Direction', kcData['direction']),
            ],
          ),
        ),
        Expanded(child: _buildDashaTimelineTab(kcData)),
      ],
    );
  }

  Widget _kcStat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label, 
          style: GoogleFonts.outfit(
            fontSize: 12.sp, 
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.toString(), 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, 
            fontSize: 16.sp,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCharaTab(Map<String, dynamic>? charaData) {
    return _buildDashaTimelineTab(charaData);
  }

  Widget _buildNavamsaTab(Map<String, dynamic>? navamsaData) {
    if (navamsaData == null || navamsaData['chart'] == null) {
      return const Center(child: Text('Data not available'));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vargottama = navamsaData['vargottama_planets'] as List? ?? [];
    final vargottamaPlanets = vargottama.where((p) => p['vargottama'] == true).toList();
    
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 350.h,
            child: KundliInteractiveChart(
              kundliData: navamsaData,
              chartTypeKey: 'D-9',
              chartStyle: KundliChartStyle.southIndian,
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        if (vargottamaPlanets.isNotEmpty) ...[
          Text(
            'Vargottama Planets', 
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, 
              fontSize: 18.sp,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12.h),
          ...vargottamaPlanets.map((p) => Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
              ),
              title: Text(
                p['planet'],
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              subtitle: Text(
                'Sign: ${p['d1_sign']}',
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                ),
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Strong',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          )),
        ] else ...[
          Container(
            padding: EdgeInsets.all(20.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.stars_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 40),
                SizedBox(height: 8.h),
                Text(
                  'No Vargottama Planets',
                  style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}
