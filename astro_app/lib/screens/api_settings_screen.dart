import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';

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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recheck Server Health',
            onPressed: _runHealthCheck,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend Status Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [const Color(0xFF7C2D12), const Color(0xFF9A3412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
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
                    padding: const EdgeInsets.all(12),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isOnline ? 'Flask Backend Online' : 'Local Dynamic Engine',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_isChecking)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnline
                              ? 'Live connected to ${_healthStatus['url']} (v${_healthStatus['version']})'
                              : 'Flask server is offline. Serving local ephemeris calculations without crashes.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Base URL Configuration Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Color(0xFF4338CA), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Flask API Base URL',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Quick Presets:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip('Localhost :5000', 'http://127.0.0.1:5000/api/v1', isDark),
                      _buildPresetChip('Android Emulator :5000', 'http://10.0.2.2:5000/api/v1', isDark),
                      _buildPresetChip('Localhost :8000', 'http://127.0.0.1:8000/api/v1', isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.firaCode(fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'http://127.0.0.1:5000/api/v1',
                      prefixIcon: const Icon(Icons.lan_rounded, size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text('Save & Reconnect', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          _urlController.text = AstroApiService.defaultBaseUrl;
                          AstroApiService.baseUrl = AstroApiService.defaultBaseUrl;
                          _runHealthCheck();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Reset Default', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live API Test Triggers
            Text(
              '1-Click Live Endpoint Testers',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

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

            const SizedBox(height: 20),

            // Response Inspector Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
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
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isTesting ? Colors.amber : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activeTest.isEmpty ? 'Live Response Inspector' : 'Testing: $_activeTest',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_testResult.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_all_rounded, color: Colors.white70, size: 20),
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
                  const SizedBox(height: 6),
                  SelectableText(
                    _testResult.isEmpty
                        ? 'Tap any test button above to fire live requests against your Flask backend.\nResults and execution latency will be displayed here in JSON format.'
                        : _testResult,
                    style: GoogleFonts.firaCode(
                      color: _testResult.startsWith('❌') ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      fontSize: 12,
                      height: 1.45,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4338CA).withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF818CF8) : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTestChip(String title, Future<dynamic> Function() caller) {
    return ActionChip(
      avatar: const Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF4338CA)),
      label: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : const Color(0xFFEEF2FF),
      side: const BorderSide(color: Color(0xFF6366F1), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _testEndpoint(title, caller),
    );
  }
}
