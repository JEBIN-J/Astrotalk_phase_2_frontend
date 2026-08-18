import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final Color goldColor = const Color(0xFFD4AF37);
  bool _isLoading = false;

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    
    final res = await AstroApiService.adminLogin(username, password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (res['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Invalid credentials', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF9F9FB);
    final cardColor = isDark ? const Color(0xFF161A25) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A24);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Admin Login', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 22.sp, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, size: 64.w, color: goldColor),
                SizedBox(height: 16.h),
                Text('Secure Access', style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
                SizedBox(height: 8.h),
                Text('Enter your admin credentials to continue', style: GoogleFonts.outfit(fontSize: 14.sp, color: isDark ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),
                SizedBox(height: 32.h),
                
                TextField(
                  controller: _usernameController,
                  style: GoogleFonts.outfit(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54),
                    prefixIcon: Icon(Icons.person, color: goldColor),
                    filled: true,
                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: goldColor, width: 1.5)),
                  ),
                ),
                SizedBox(height: 16.h),
                
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.outfit(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54),
                    prefixIcon: Icon(Icons.lock, color: goldColor),
                    filled: true,
                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: goldColor, width: 1.5)),
                  ),
                ),
                SizedBox(height: 32.h),
                
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Login to Dashboard', style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
