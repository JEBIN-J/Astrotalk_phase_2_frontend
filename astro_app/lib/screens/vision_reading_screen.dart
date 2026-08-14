import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VisionReadingScreen extends StatefulWidget {
  final bool isFace; // true for Face Reading, false for Palm Reading

  const VisionReadingScreen({super.key, required this.isFace});

  @override
  State<VisionReadingScreen> createState() => _VisionReadingScreenState();
}

class _VisionReadingScreenState extends State<VisionReadingScreen> with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _results;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _results = null; // reset results if new image selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _results = null;
    });

    try {
      final res = await AstroApiService.analyzeVision(
        isFace: widget.isFace,
        filePath: _selectedImage!.path,
      );
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Scanner Area
            Container(
              height: 350.h,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2.w),
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
                fit: StackFit.expand,
                children: [
                  if (_selectedImage != null)
                    Image.file(_selectedImage!, fit: BoxFit.cover)
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 80, color: primaryColor.withValues(alpha: 0.2)),
                        SizedBox(height: 16.h),
                        Text(
                          'No Image Selected',
                          style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54),
                        )
                      ],
                    ),
                  
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    
                  if (_isAnalyzing)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanController.value * 330,
                          child: Container(
                            width: 300.w,
                            height: 4.h,
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
            
            SizedBox(height: 30.h),
            
            if (_results == null && !_isAnalyzing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt_rounded),
                      label: Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library_rounded),
                      label: Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              
              if (_selectedImage != null)
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton.icon(
                    onPressed: _startAnalysis,
                    icon: Icon(Icons.document_scanner_rounded),
                    label: Text(
                      'Start AI Scan',
                      style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                  ),
                ),
            ] else if (_isAnalyzing) ...[
               Text(
                 'Analyzing cosmic imprints...',
                 style: GoogleFonts.outfit(
                   fontSize: 16.sp,
                   fontWeight: FontWeight.w500,
                   color: primaryColor,
                 ),
               ),
            ] else if (_results != null) ...[
              // Results View
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: primaryColor),
                        SizedBox(width: 8.w),
                        Text(
                          'AI Analysis Complete',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Confidence: ${_results?['confidence'] ?? '90%'}',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    
                    if (_results?['analysis'] is Map)
                      ...(_results!['analysis'] as Map<String, dynamic>).entries.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.0.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                e.value.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  height: 1.4.h,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                    SizedBox(height: 8.h),
                    const Divider(),
                    SizedBox(height: 8.h),
                    
                    Text(
                      'OVERALL SUMMARY',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black54,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _results?['overall_summary'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        height: 1.5.h,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              TextButton.icon(
                onPressed: () => setState(() {
                  _results = null;
                  _selectedImage = null;
                }),
                icon: Icon(Icons.refresh_rounded),
                label: Text('Scan Another Image'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
