import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';

class VisionReadingScreen extends StatefulWidget {
  final bool isFace; // true for Face Reading, false for Palm Reading

  const VisionReadingScreen({super.key, required this.isFace});

  @override
  State<VisionReadingScreen> createState() => _VisionReadingScreenState();
}

class _VisionReadingScreenState extends State<VisionReadingScreen> with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _results;
  late AnimationController _scanController;
  
  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _results = null;
    });

    try {
      // Mock delay for scan effect
      await Future.delayed(const Duration(seconds: 3));
      final res = await AstroApiService.analyzeVision(isFace: widget.isFace);
      if (mounted) {
        setState(() {
          _results = res;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.isFace ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);
    final title = widget.isFace ? 'AI Face Reading' : 'AI Palm Reading';
    final icon = widget.isFace ? Icons.face_retouching_natural_rounded : Icons.back_hand_rounded;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Scanner Area
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 100, color: primaryColor.withValues(alpha: 0.2)),
                  
                  if (_isAnalyzing)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanController.value * 280,
                          child: Container(
                            width: 280,
                            height: 4,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            if (_results == null) ...[
              Text(
                widget.isFace 
                  ? 'Position your face clearly in the frame to analyze your planetary influences and facial aura.'
                  : 'Place your palm flat and well-lit. Our AI will map your life, heart, and head lines.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _startAnalysis,
                  icon: _isAnalyzing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.document_scanner_rounded),
                  label: Text(
                    _isAnalyzing ? 'Analyzing Energies...' : 'Start AI Scan',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ] else ...[
              // Results View
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Complete',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _results?['analysis'] ?? 'No data',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aura Score: ${_results?['aura_score'] ?? 0}/100',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() => _results = null),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Again'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
