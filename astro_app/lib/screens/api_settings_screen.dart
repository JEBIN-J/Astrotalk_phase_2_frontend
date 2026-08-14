import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Interactive API Settings & Live Backend Testing Console
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isChecking = false;
  Map<String, dynamic> _healthStatus = {};
  String _activeTest = '';
  String _testResult = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = AstroApiService.baseUrl;
    _runHealthCheck();
  }

  Future<void> _runHealthCheck() async {
    setState(() => _isChecking = true);
    final status = await AstroApiService.checkHealth();
    if (mounted) {
      setState(() {
        _healthStatus = status;
        _isChecking = false;
      });
    }
  }

  Future<void> _testEndpoint(String title, Future<dynamic> Function() caller) async {
    setState(() {
      _activeTest = title;
      _isTesting = true;
      _testResult = 'Executing $title request to ${AstroApiService.baseUrl}...';
    });

    try {
      final start = DateTime.now();
      final res = await caller();
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(res);
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testResult = '⚡ Response ($elapsed ms):\n\n$formatted';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testResult = '❌ Error executing $title:\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = _healthStatus['online'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flask API & Backend Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'Recheck Server Health',
            onPressed: _runHealthCheck,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend Status Banner Card
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [const Color(0xFF7C2D12), const Color(0xFF9A3412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? const Color(0xFF059669) : const Color(0xFFEA580C))
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isOnline ? 'Flask Backend Online' : 'Local Dynamic Engine',
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (_isChecking)
                              SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isOnline
                              ? 'Live connected to ${_healthStatus['url']} (v${_healthStatus['version']})'
                              : 'Flask server is offline. Serving local ephemeris calculations without crashes.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Base URL Configuration Card
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link_rounded, color: Color(0xFF4338CA), size: 22),
                      SizedBox(width: 8.w),
                      Text(
                        'Flask API Base URL',
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text('Quick Presets:', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey)),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip('Localhost :5000', 'http://127.0.0.1:5000/api/v1', isDark),
                      _buildPresetChip('Android Emulator :5000', 'http://10.0.2.2:5000/api/v1', isDark),
                      _buildPresetChip('Localhost :8000', 'http://127.0.0.1:8000/api/v1', isDark),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.firaCode(fontSize: 13.sp, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'http://127.0.0.1:5000/api/v1',
                      prefixIcon: Icon(Icons.lan_rounded, size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          AstroApiService.baseUrl = _urlController.text;
                          _runHealthCheck();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Updated Base URL to: ${AstroApiService.baseUrl}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(Icons.save_rounded, size: 16),
                        label: Text('Save & Reconnect', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      OutlinedButton(
                        onPressed: () {
                          _urlController.text = AstroApiService.defaultBaseUrl;
                          AstroApiService.baseUrl = AstroApiService.defaultBaseUrl;
                          _runHealthCheck();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Reset Default', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Live API Test Triggers
            Text(
              '1-Click Live Endpoint Testers',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 10.h),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestChip('Shubh Muhurat', () => AstroApiService.getMuhurat()),
                _buildTestChip('Janam Kundli', () => AstroApiService.getSampleKundli()),
                _buildTestChip('Admin Stats', () => AstroApiService.getAdminStats()),
                _buildTestChip('Notifications', () => AstroApiService.getNotifications()),
                _buildTestChip('Daily Quotes', () => AstroApiService.getDailyQuotes()),
                _buildTestChip('Search Cities', () => AstroApiService.searchPlaces('Delhi')),
                _buildTestChip('AI Astrologer', () => AstroApiService.chatAiAstrologer(question: 'How is my career?')),
              ],
            ),

            SizedBox(height: 20.h),

            // Response Inspector Box
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: _isTesting ? Colors.amber : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _activeTest.isEmpty ? 'Live Response Inspector' : 'Testing: $_activeTest',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      if (_testResult.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_all_rounded, color: Colors.white70, size: 20),
                          onPressed: () {
                            setState(() {
                              _testResult = '';
                              _activeTest = '';
                            });
                          },
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFF1E293B)),
                  SizedBox(height: 6.h),
                  SelectableText(
                    _testResult.isEmpty
                        ? 'Tap any test button above to fire live requests against your Flask backend.\nResults and execution latency will be displayed here in JSON format.'
                        : _testResult,
                    style: GoogleFonts.firaCode(
                      color: _testResult.startsWith('❌') ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      fontSize: 12.sp,
                      height: 1.45.h,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url, bool isDark) {
    final isSelected = AstroApiService.baseUrl == url;
    return InkWell(
      onTap: () {
        _urlController.text = url;
        AstroApiService.baseUrl = url;
        _runHealthCheck();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched Base URL to: $url'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4338CA).withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF818CF8) : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTestChip(String title, Future<dynamic> Function() caller) {
    return ActionChip(
      avatar: Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF4338CA)),
      label: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.sp)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : const Color(0xFFEEF2FF),
      side: BorderSide(color: Color(0xFF6366F1), width: 1.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      onPressed: () => _testEndpoint(title, caller),
    );
  }
}
