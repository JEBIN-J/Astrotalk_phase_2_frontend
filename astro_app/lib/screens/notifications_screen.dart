import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await AstroApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marked all as read')),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    'No new notifications',
                    style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final title = item['title'] ?? 'Alert';
                      final message = item['message'] ?? '';
                      final type = item['type'] ?? 'info';
                      final time = item['timestamp'] ?? 'Just now';

                      return _buildNotificationCard(
                        title: title,
                        message: message,
                        type: type,
                        time: time,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String type,
    required String time,
    required bool isDark,
  }) {
    IconData icon;
    Color color;

    switch (type) {
      case 'transit':
        icon = Icons.auto_awesome_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'promo':
        icon = Icons.local_offer_rounded;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = const Color(0xFF4338CA);
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
