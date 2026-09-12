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
  double _daysInYear = 365.256364; // Default to Savana Sidereal Year

  KundliChartStyle _chartStyle = KundliChartStyle.southIndian;

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
        daysInYear: _daysInYear,
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
    TextEditingController nameCtrl = TextEditingController(text: 'Prashna Chart');
    TextEditingController placeCtrl = TextEditingController(text: _place);
    TextEditingController latCtrl = TextEditingController(text: _latitude.toString());
    TextEditingController lonCtrl = TextEditingController(text: _longitude.toString());
    TextEditingController tzCtrl = TextEditingController(text: _timezone.toString());
    double tempDaysInYear = _daysInYear;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final outlineColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
            final textColor = isDark ? Colors.white : Colors.black87;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Header
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBBF24),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.star_rounded, color: const Color(0xFF1E1B4B), size: 24.sp),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Update Prashna Details', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4.h),
                                Text('Recalculate Swiss Ephemeris Placements', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13.sp)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Full Name
                            TextField(
                              controller: nameCtrl,
                              style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                              decoration: InputDecoration(
                                hintText: 'Full Name',
                                hintStyle: GoogleFonts.outfit(fontSize: 15.sp, color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.person, color: const Color(0xFF4F46E5), size: 22.sp),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            
                            // Date & Time
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime(1900), lastDate: DateTime(2100));
                                      if (picked != null) setDialogState(() => tempDate = picked);
                                    },
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                                      decoration: BoxDecoration(border: Border.all(color: outlineColor), borderRadius: BorderRadius.circular(16.r)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded, color: const Color(0xFF4F46E5), size: 20.sp),
                                          SizedBox(width: 8.w),
                                          Expanded(child: Text(DateFormat('dd MMM yyyy').format(tempDate), style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(context: context, initialTime: tempTime);
                                      if (picked != null) setDialogState(() => tempTime = picked);
                                    },
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                                      decoration: BoxDecoration(border: Border.all(color: outlineColor), borderRadius: BorderRadius.circular(16.r)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, color: const Color(0xFF4F46E5), size: 20.sp),
                                          SizedBox(width: 8.w),
                                          Expanded(child: Text(tempTime.format(context), style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            
                            // Location
                            Autocomplete<Map<String, String>>(
                              initialValue: TextEditingValue(text: placeCtrl.text),
                              displayStringForOption: (option) => option['city'] ?? '',
                              optionsBuilder: (TextEditingValue textEditingValue) async {
                                if (textEditingValue.text.isEmpty) return const Iterable<Map<String, String>>.empty();
                                try { return await AstroApiService.getPlaces(query: textEditingValue.text); } catch (_) { return const Iterable<Map<String, String>>.empty(); }
                              },
                              onSelected: (Map<String, String> selection) {
                                placeCtrl.text = selection['city'] ?? '';
                                latCtrl.text = selection['lat_val'] ?? '';
                                lonCtrl.text = selection['lon_val'] ?? '';
                                tzCtrl.text = selection['tz_val'] ?? '';
                              },
                              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                if (controller.text.isEmpty && placeCtrl.text.isNotEmpty) controller.text = placeCtrl.text;
                                controller.addListener(() { placeCtrl.text = controller.text; });
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Place of Birth / Location',
                                    hintStyle: GoogleFonts.outfit(fontSize: 15.sp, color: Colors.grey.shade500),
                                    prefixIcon: Icon(Icons.location_on, color: const Color(0xFF4F46E5), size: 22.sp),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
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
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            title: Text(option['city'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                                            subtitle: Text('${option['coords']} • ${option['tz']}', style: GoogleFonts.outfit(fontSize: 12.sp)),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                            
                            // Latitude & Longitude
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: latCtrl,
                                    style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Latitude',
                                      labelStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey.shade600),
                                      prefixIcon: Icon(Icons.explore, color: const Color(0xFF059669), size: 22.sp),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                      contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: TextField(
                                    controller: lonCtrl,
                                    style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Longitude',
                                      labelStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey.shade600),
                                      prefixIcon: Icon(Icons.explore, color: const Color(0xFF059669), size: 22.sp),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                      contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            
                            // Time Zone
                            TextField(
                              controller: tzCtrl,
                              style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Time Zone Offset (e.g. 5.5 for IST)',
                                labelStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey.shade600),
                                prefixIcon: Icon(Icons.access_time_filled, color: const Color(0xFFD97706), size: 22.sp),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                            SizedBox(height: 24.h),
                            
                            // Calculation Basis (Dasha Year Length)
                            DropdownButtonFormField<double>(
                              value: tempDaysInYear,
                              decoration: InputDecoration(
                                labelText: 'Dasha Year Length',
                                labelStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey.shade600),
                                prefixIcon: Icon(Icons.calculate, color: const Color(0xFF8B5CF6), size: 22.sp),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: outlineColor)),
                                contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                              ),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: GoogleFonts.outfit(fontSize: 15.sp, color: textColor),
                              items: const [
                                DropdownMenuItem(value: 365.256364, child: Text('365.25636 (Sidereal Year)')),
                                DropdownMenuItem(value: 365.2425, child: Text('365.2425 (Gregorian Year)')),
                                DropdownMenuItem(value: 360.0, child: Text('360.0 (Savana Year)')),
                                DropdownMenuItem(value: 354.367, child: Text('354.367 (Lunar Year)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => tempDaysInYear = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Actions
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 0,
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
                                  _daysInYear = tempDaysInYear;
                                });
                                _fetchPrashnaChart();
                              }
                            },
                            icon: Icon(Icons.check_circle_outline, size: 20.sp),
                            label: Text('Save & Calculate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
        centerTitle: true,
        title: Text(widget.appBarTitle ?? 'Prashna Chart', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20.sp, letterSpacing: 0.2)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: EdgeInsets.symmetric(horizontal: -12.w, vertical: 2.h),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
                border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), width: 1.5),
              ),
              labelColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14.sp),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
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
                          _buildVimshottariTab(_prashnaData!['vimshottari']),
                          _buildDashaTimelineTab(_prashnaData!['yogini'], showD1Chart: true),
                          _buildKalaChakraTab(_prashnaData!['kala_chakra']),
                          _buildDashaTimelineTab(_prashnaData!['ashtottari'], showD1Chart: true),
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

  Widget _buildD1ChartSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prashna Chart (D-1)',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<KundliChartStyle>(
                  value: _chartStyle,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF4F46E5), size: 20.sp),
                  isDense: true,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  onChanged: (KundliChartStyle? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _chartStyle = newValue;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: KundliChartStyle.southIndian,
                      child: Text('South Indian'),
                    ),
                    DropdownMenuItem(
                      value: KundliChartStyle.northIndian,
                      child: Text('North Indian'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.all(16.w),
          child: KundliInteractiveChart(
            kundliData: _prashnaData,
            chartTypeKey: 'D-1',
            chartStyle: _chartStyle,
            isDark: isDark,
          ),
        ),
      ],
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
              _infoRow('Question Date', ov['question_date']?.toString() ?? 'N/A', isDark, isTop: true),
              _divider(isDark),
              _infoRow('Question Time', ov['question_time']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Question Place', ov['place']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Latitude', ov['latitude']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Longitude', ov['longitude']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Timezone', ov['timezone']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('UTC Time', ov['utc_time']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Julian Day', ov['julian_day']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Ayanamsa', ov['ayanamsa']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Prashna Lagna', ov['prashna_lagna']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Lagna Degree', ov['lagna_degree']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Moon Sign', ov['moon_sign']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Moon Degree', ov['moon_degree']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Moon Nakshatra', ov['moon_nakshatra']?.toString() ?? 'N/A', isDark),
              _divider(isDark),
              _infoRow('Moon Pada', ov['moon_pada']?.toString() ?? 'N/A', isDark, isBottom: true),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        _buildD1ChartSection(isDark),
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
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
                        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                        child: Row(
                          children: [
                            SizedBox(width: 80.w, child: Text('Planet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 80.w, child: Text('Longitude', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 60.w, child: Text('Sign', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 60.w, child: Text('Degree', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 100.w, child: Text('Nakshatra', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 50.w, child: Text('Pada', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 50.w, child: Text('House', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                            SizedBox(width: 50.w, child: Text('Ret.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ...planets.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final p = entry.value;
                        final isEven = idx % 2 == 0;
                        final isModern = ['Uranus', 'Neptune', 'Pluto'].contains(p['planet_name_simple']);
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isEven ? Colors.transparent : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC)),
                            border: Border(
                              bottom: BorderSide(
                                color: idx == planets.length - 1 ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 80.w, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['planet_name_simple'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (isModern) Text('Modern', style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.grey)),
                              ])),
                              SizedBox(width: 80.w, child: Text(p['degree_decimal']?.toStringAsFixed(2) ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 60.w, child: Text(p['sign'] ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 60.w, child: Text(p['degree_formatted'] ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 100.w, child: Text(p['nakshatra'] ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 50.w, child: Text(p['pada']?.toString() ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 50.w, child: Text(p['house']?.toString() ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 50.w, child: Text(p['is_retrograde'] == true ? 'R' : '-', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: p['is_retrograde'] == true ? Colors.red : (isDark ? Colors.white70 : const Color(0xFF334155))), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
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


  Widget _buildVimshottariTab(Map<String, dynamic>? data) {
    if (data == null) {
      return const Center(child: Text('Data not available'));
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final current = data['current'] ?? {};
    final moon = data['moon'] ?? {};
    final balance = data['balance'] ?? {};
    final calcDetails = data['calculation_details'] ?? {};
    final timeline = data['timeline'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildD1ChartSection(isDark),
          SizedBox(height: 24.h),
          
          // Current Dasha Card
          _buildKeyValueTable(
            'CURRENT DASHA',
            Icons.timer,
            'Level',
            'Dasha Lord',
            [
              MapEntry('Mahadasha', current['mahadasha']?.toString() ?? '-'),
              MapEntry('Antardasha', current['antardasha']?.toString() ?? '-'),
              MapEntry('Pratyantardasha', current['pratyantardasha']?.toString() ?? '-'),
              MapEntry('Sookshma', current['sookshma']?.toString() ?? '-'),
              MapEntry('Prana', current['prana']?.toString() ?? '-'),
            ],
            isDark,
          ),
          
          SizedBox(height: 24.h),
          
          // Prashna Moon Details
          _buildKeyValueTable(
            'PRASHNA MOON DETAILS',
            Icons.nightlight_round,
            'Detail',
            'Value',
            [
              MapEntry('Moon Sign', moon['sign']?.toString() ?? '-'),
              MapEntry('Moon Longitude', '${(moon['longitude'] as num?)?.toStringAsFixed(4)}°'),
              MapEntry('Nakshatra', moon['nakshatra']?.toString() ?? '-'),
              MapEntry('Pada', moon['pada']?.toString() ?? '-'),
              MapEntry('Nakshatra Lord', moon['nakshatra_lord']?.toString() ?? '-'),
            ],
            isDark,
          ),
          
          SizedBox(height: 24.h),
          
          // Dasha Balance
          _buildKeyValueTable(
            'DASHA BALANCE',
            Icons.balance,
            'Parameter',
            'Value',
            [
              MapEntry('Starting Lord', balance['starting_lord']?.toString() ?? '-'),
              MapEntry('Remaining Arc', '${(balance['remaining_arc'] as num?)?.toStringAsFixed(4)}°'),
              MapEntry('Remaining %', '${(balance['remaining_percentage'] as num?)?.toStringAsFixed(2)}%'),
              MapEntry('Balance Years', '${(balance['balance_years'] as num?)?.toStringAsFixed(4)} Yrs'),
            ],
            isDark,
          ),
          
          SizedBox(height: 24.h),
          
          // Timeline
          _buildVimSectionHeader('VIMSHOTTARI TIMELINE', isDark, Icons.calendar_month),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Dasha', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                      Expanded(flex: 4, child: Text('Start Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                      Expanded(flex: 4, child: Text('End Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ...timeline.map((md) => _buildVimshottariMdNode(md, isDark)),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Calculation Details
          ExpansionTile(
            title: Text('Calculation Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp, color: isDark ? Colors.white : Colors.black)),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                ),
                child: Text(
                  'Calculated dynamically via Swiss Ephemeris.\nConvention: ${calcDetails['calendar_convention']}\nSystem: ${data['system']} (${data['calculation_basis']})',
                  style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              )
            ],
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildVimSectionHeader(String title, bool isDark, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyValueTable(String sectionTitle, IconData sectionIcon, String header1, String header2, List<MapEntry<String, String>> rows, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          title: Row(
            children: [
              Icon(sectionIcon, size: 20.sp, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
              SizedBox(width: 8.w),
              Text(
                sectionTitle,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          children: [
            Container(
              color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(header1, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                  Expanded(flex: 1, child: Text(header2, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ...rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text(entry.value.key, style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
                    Expanded(flex: 1, child: Text(entry.value.value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVimshottariMdNode(Map<String, dynamic> md, bool isDark) {
    final mdActive = md['is_active'] == true;
    final ads = md['antardashas'] as List? ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: mdActive ? const Color(0xFF4F46E5).withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: mdActive,
          tilePadding: EdgeInsets.only(left: 16.w, right: 8.w),
          title: Row(
            children: [
              Expanded(flex: 3, child: Text('${md['lord']} MD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white : Colors.black)))),
              Expanded(flex: 4, child: Text('${md['start_date']}', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: mdActive ? FontWeight.w600 : FontWeight.w500, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : Colors.black87)))),
              Expanded(flex: 4, child: Text('${md['end_date']}', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: mdActive ? FontWeight.w600 : FontWeight.w500, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : Colors.black87)))),
            ],
          ),
          children: ads.map((ad) => _buildVimshottariAdNode(ad, isDark)).toList(),
        ),
      ),
    );
  }

  Widget _buildVimshottariAdNode(dynamic ad, bool isDark) {
    final adActive = ad['is_active'] == true;
    final pds = ad['pratyantardashas'] as List? ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: adActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC)),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: ExpansionTile(
        initiallyExpanded: adActive,
        tilePadding: EdgeInsets.only(left: 32.w, right: 8.w),
        title: Row(
          children: [
            Expanded(flex: 3, child: Text('${ad['lord']} AD', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.sp, color: adActive ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87)))),
            Expanded(flex: 4, child: Text('${ad['start_date']}', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54))),
            Expanded(flex: 4, child: Text('${ad['end_date']}', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54))),
          ],
        ),
        children: pds.map((pd) {
          final pdActive = pd['is_active'] == true;
          return Container(
            padding: EdgeInsets.only(left: 48.w, right: 32.w, top: 12.h, bottom: 12.h),
            decoration: BoxDecoration(
              color: pdActive ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.transparent,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('${pd['lord']} PD', style: GoogleFonts.outfit(fontWeight: pdActive ? FontWeight.bold : FontWeight.w500, fontSize: 12.sp, color: pdActive ? const Color(0xFFD97706) : (isDark ? Colors.white60 : Colors.black54)))),
                Expanded(flex: 4, child: Text('${pd['start_date']}', style: GoogleFonts.outfit(fontSize: 11.sp, color: pdActive ? const Color(0xFFD97706) : (isDark ? Colors.white38 : Colors.black38)))),
                Expanded(flex: 4, child: Text('${pd['end_date']}', style: GoogleFonts.outfit(fontSize: 11.sp, color: pdActive ? const Color(0xFFD97706) : (isDark ? Colors.white38 : Colors.black38)))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashaTimelineTab(Map<String, dynamic>? dashaData, {bool showD1Chart = false}) {
    if (dashaData == null || dashaData['timeline'] == null) {
      return const Center(child: Text('Data not available'));
    }
    final timeline = dashaData['timeline'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showD1Chart) ...[
            _buildD1ChartSection(isDark),
            SizedBox(height: 24.h),
          ],
          if (dashaData.containsKey('applicable')) ...[
            Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: dashaData['applicable'] == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: dashaData['applicable'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        dashaData['applicable'] == true ? Icons.check_circle : Icons.cancel,
                        color: dashaData['applicable'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Ashtottari Applicable: ${dashaData['applicable'] == true ? 'YES' : 'NO'}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: dashaData['applicable'] == true ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Reason: ${dashaData['reason'] ?? ''}',
                    style: GoogleFonts.outfit(
                      color: dashaData['applicable'] == true ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
            Container(
              color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Dasha', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                  Expanded(flex: 4, child: Text('Start Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                  Expanded(flex: 4, child: Text('End Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ...timeline.asMap().entries.map((entry) {
              final int mdIdx = entry.key;
              final md = entry.value;
              final ads = md['antardashas'] as List? ?? [];
              final mdName = md['sign'] ?? md['lord'] ?? md['planet'] ?? '-';
              final mdStart = md['start_date'] ?? md['start'] ?? '-';
              final mdEnd = md['end_date'] ?? md['end'] ?? '-';
              final mdActive = md['is_active'] == true;
              
              return Column(
                children: [
                  // Mahadasha Row
                  Container(
                    color: mdActive ? const Color(0xFF4F46E5).withValues(alpha: 0.1) : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC)),
                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('$mdName MD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white : const Color(0xFF0F172A))))),
                        Expanded(flex: 4, child: Text(mdStart, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: mdActive ? FontWeight.w600 : FontWeight.w500, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : const Color(0xFF334155))))),
                        Expanded(flex: 4, child: Text(mdEnd, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: mdActive ? FontWeight.w600 : FontWeight.w500, color: mdActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : const Color(0xFF334155))))),
                      ],
                    ),
                  ),
                  // Antardashas
                  if (ads.isNotEmpty)
                    ...ads.map((ad) {
                      final adName = ad['sign'] ?? ad['lord'] ?? ad['planet'] ?? '-';
                      final adStart = ad['start_date'] ?? ad['start'] ?? '-';
                      final adEnd = ad['end_date'] ?? ad['end'] ?? '-';
                      final adActive = ad['is_active'] == true;
                      
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: adActive ? const Color(0xFF4F46E5).withValues(alpha: 0.05) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Padding(
                              padding: EdgeInsets.only(left: 12.w),
                              child: Text('$adName AD', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: adActive ? FontWeight.w600 : FontWeight.w500, color: adActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : const Color(0xFF475569)))),
                            )),
                            Expanded(flex: 4, child: Text(adStart, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: adActive ? FontWeight.w600 : FontWeight.normal, color: adActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white60 : const Color(0xFF64748B))))),
                            Expanded(flex: 4, child: Text(adEnd, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: adActive ? FontWeight.w600 : FontWeight.normal, color: adActive ? const Color(0xFF4F46E5) : (isDark ? Colors.white60 : const Color(0xFF64748B))))),
                          ],
                        ),
                      );
                    }),
                ],
              );
            }),
          ],
        ),
      ),
      ],
      ),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _kcStat('Deha', kcData['deha']),
                  Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                  _kcStat('Jeeva', kcData['jeeva']),
                  Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                  _kcStat('Direction', kcData['direction']),
                ],
              ),
              SizedBox(height: 16.h),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _kcStat('Nakshatra', '${kcData['moon_nakshatra']} (Pada ${kcData['pada']})'),
                  Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                  _kcStat('Lord', kcData['nakshatra_lord']),
                  Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                  _kcStat('Cycle', '${kcData['total_cycle_years']} Yrs'),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildDashaTimelineTab(kcData, showD1Chart: true)),
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
    return _buildDashaTimelineTab(charaData, showD1Chart: true);
  }

  Widget _buildNavamsaTab(Map<String, dynamic>? navamsaData) {
    if (navamsaData == null || navamsaData['chart'] == null) {
      return const Center(child: Text('Data not available'));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We now receive d9_planet_positions from the backend
    final allPositions = navamsaData['d9_planet_positions'] as List? ?? [];
    
    // Extract Ascendant for D9 Lagna
    final ascPos = allPositions.firstWhere((p) => p['planet'] == 'Ascendant', orElse: () => {'d1_sign': '-', 'd9_sign': '-'});
    final d1Lagna = ascPos['d1_sign'];
    final d9Lagna = ascPos['d9_sign'];
    
    // Filter regular planets (exclude Ascendant)
    final planetsOnly = allPositions.where((p) => p['planet'] != 'Ascendant').toList();
    final vargottamaPlanets = planetsOnly.where((p) => p['vargottama'] == true).toList();
    
    final karakas = navamsaData['karakas'] as List? ?? [];
    
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        // D9 Chart
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
              kundliData: navamsaData['chart'],
              chartTypeKey: 'D-9',
              chartStyle: _chartStyle,
              isDark: isDark,
              showDegrees: false,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        
        // D9 Lagna summary
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _infoRow('D1 Lagna', d1Lagna?.toString() ?? 'N/A', isDark, isTop: true),
              _divider(isDark),
              _infoRow('D9 Lagna', d9Lagna?.toString() ?? 'N/A', isDark, isBottom: true),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // D9 Planet Positions Table
        Text(
          'Prashna Navamsa Positions',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Planet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                    Expanded(flex: 2, child: Text('D1 Sign', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                    Expanded(flex: 2, child: Text('D9 Sign', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ...planetsOnly.map((p) {
                final isVar = p['vargottama'] == true;
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Row(
                        children: [
                          Text(p['planet'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          if (isVar) Padding(
                            padding: EdgeInsets.only(left: 4.w),
                            child: Icon(Icons.star, color: Colors.orange, size: 12.sp),
                          ),
                        ],
                      )),
                      Expanded(flex: 2, child: Text(p['d1_sign'] ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
                      Expanded(flex: 2, child: Text(p['d9_sign'] ?? '-', style: GoogleFonts.outfit(fontWeight: isVar ? FontWeight.bold : FontWeight.normal, fontSize: 13.sp, color: isVar ? Colors.orange : (isDark ? Colors.white70 : const Color(0xFF334155))))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // Vargottama summary
        if (vargottamaPlanets.isNotEmpty) ...[
          Text('Vargottama Planets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: vargottamaPlanets.map((p) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 4.w),
                  Text('${p['planet']} in ${p['d9_sign']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF92400E))),
                ],
              ),
            )).toList(),
          ),
          SizedBox(height: 24.h),
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
          SizedBox(height: 24.h),
        ],

        // Jaimini Karakas
        if (karakas.isNotEmpty) ...[
          Text('Jaimini Karakas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.2) : const Color(0xFFEEF2FF),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('Karaka', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                      Expanded(flex: 2, child: Text('Planet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA), fontSize: 13.sp))),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ...karakas.map((k) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(k['karaka'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                        Expanded(flex: 2, child: Text(k['planet'] ?? '-', style: GoogleFonts.outfit(fontSize: 13.sp, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ],
    );
  }
}
