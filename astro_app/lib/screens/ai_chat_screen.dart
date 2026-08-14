import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Namaste! I am your AI Vedic Astrologer. How can I guide your path today?",
      isUser: false,
      timestamp: DateTime.now(),
    )
  ];
  
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await AstroApiService.chatAiAstrologer(question: text);
      final replyText = response['response'] ?? 'The stars are clouded at the moment. Please try again.';
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: replyText, isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: 'Error connecting to the cosmos: $e', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 8),
                ],
              ),
              child: Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Astrologer',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
                ),
                Text(
                  'Online • Ready to help',
                  style: GoogleFonts.outfit(fontSize: 12.sp, color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(isDark);
                }
                
                final msg = _messages[index];
                return _buildChatBubble(msg, isDark);
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.outfit(fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'Ask about career, marriage, doshas...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Color(0xFF0D9488),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
            ),
            
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF4338CA) 
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20.r).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                  bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isUser ? [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.outfit(
                  color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  fontSize: 15.sp,
                  height: 1.4.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            padding: EdgeInsets.all(6.w),
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20.r).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(),
                SizedBox(width: 4.w),
                _buildDot(),
                SizedBox(width: 4.w),
                _buildDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDot() {
    return Container(
      width: 6.w,
      height: 6.h,
      decoration: const BoxDecoration(
        color: Color(0xFF94A3B8),
        shape: BoxShape.circle,
      ),
    );
  }
}
