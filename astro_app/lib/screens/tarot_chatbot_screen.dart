import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/celestial_animations.dart';
import '../services/astro_api_service.dart';
import 'tarot_card_details_screen.dart';
import 'tarot_deck_selection_screen.dart';

enum ChatStep {
  greeting,
  categorySelection,
  subCategorySelection,
  drawCardPrompt,
  completed,
}

class ChatMessage {
  final String text;
  final bool isBot;
  final Map<String, dynamic>? cardData;

  ChatMessage({
    required this.text,
    required this.isBot,
    this.cardData,
  });
}

class TarotChatbotScreen extends StatefulWidget {
  final AppColorPalette currentPalette;
  final bool isDark;

  const TarotChatbotScreen({
    super.key,
    this.currentPalette = AppColorPalette.midnightCosmic,
    this.isDark = false,
  });

  @override
  State<TarotChatbotScreen> createState() => _TarotChatbotScreenState();
}

class _TarotChatbotScreenState extends State<TarotChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  ChatStep _currentStep = ChatStep.greeting;
  List<String> _currentOptions = [];
  
  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _subCategories = {
    'About Love and marriage': [
      'Find out about your love life.',
      'Know all about your marriage.',
      'Sneak-peek inside your Dating Life'
    ],
    'Get quick answers from tarot': [
      'Is the answer Yes or No?',
      'Will my wish come true?'
    ],
    'About Dreams and Ambitions': [
      'What is my life\'s purpose?',
      'Will I achieve my goals?'
    ],
    'About Yourself': [
      'What are my hidden strengths?',
      'How can I improve myself?'
    ],
    'About Career': [
      'Will I get a promotion?',
      'Is it a good time for a job change?'
    ],
  };

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  void _startChat() async {
    // Initial delay for realism
    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage("Good Evening !");
    
    await Future.delayed(const Duration(milliseconds: 800));
    _addBotMessage("Are you ready for tarot reading?");
    
    setState(() {
      _currentStep = ChatStep.greeting;
      _currentOptions = ['Yes', 'No'];
    });
  }

  void _addBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isBot: true));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isBot: false));
    });
    _scrollToBottom();
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

  void _handleOptionSelected(String option) async {
    _addUserMessage(option);
    setState(() {
      _currentOptions = []; // Hide options while thinking
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    switch (_currentStep) {
      case ChatStep.greeting:
        if (option == 'Yes') {
          _addBotMessage("Which of these options would you like to find out about :");
          setState(() {
            _currentStep = ChatStep.categorySelection;
            _currentOptions = _subCategories.keys.toList();
          });
        } else {
          _addBotMessage("No worries. Let me know when you are ready.");
          setState(() {
            _currentStep = ChatStep.completed;
          });
        }
        break;
        
      case ChatStep.categorySelection:
        _selectedCategory = option;
        _addBotMessage("What would you like to know About $_selectedCategory");
        setState(() {
          _currentStep = ChatStep.subCategorySelection;
          _currentOptions = _subCategories[option] ?? ['Tell me more'];
        });
        break;
        
      case ChatStep.subCategorySelection:
        _selectedSubCategory = option;
        _addBotMessage("Alright! I shall tell you what's in store for you. Simply think of a question in your head and draw a card from the pack. Make sure the question is clear in your head!");
        setState(() {
          _currentStep = ChatStep.drawCardPrompt;
          _currentOptions = ['Draw Card', 'Wait'];
        });
        break;
        
      case ChatStep.drawCardPrompt:
        if (option == 'Draw Card') {
          _navigateToCardSelection();
        } else {
          _addBotMessage("Take your time. Tap 'Draw Card' when your mind is focused.");
          setState(() {
            _currentOptions = ['Draw Card'];
          });
        }
        break;
        
      case ChatStep.completed:
        break;
    }
  }

  void _navigateToCardSelection() async {
    String endpoint = 'single';
    int requiredCards = 1;
    
    if (_selectedCategory == 'About Love and marriage' || _selectedCategory == 'About Career') {
      endpoint = 'celtic-cross';
      requiredCards = 3;
    }

    final readingResult = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => TarotDeckSelectionScreen(
        endpoint: endpoint,
        title: _selectedSubCategory ?? 'Tarot Reading',
        question: 'Category: $_selectedCategory',
        requiredCards: requiredCards,
        currentPalette: widget.currentPalette,
        isDark: widget.isDark,
        returnDataInsteadOfNavigate: true,
      )
    ));

    if (readingResult != null && readingResult is Map<String, dynamic>) {
      _handleReadingResult(readingResult);
    } else {
      if (mounted) {
        setState(() {
          _currentOptions = ['Draw Card'];
        });
      }
    }
  }

  void _handleReadingResult(Map<String, dynamic> result) async {
    final positions = result['positions'] as List<dynamic>? ?? [];
    
    if (positions.isEmpty) return;

    for (var pos in positions) {
      final card = pos['card'];
      final cardName = card['name'];
      
      String meaning = card['meaning_up'] ?? card['desc'] ?? 'A mysterious force surrounds this card.';
      if (card['orientation'] == 'Reversed' && card['meaning_rev'] != null) {
        meaning = card['meaning_rev'];
      }
      
      _addUserMessage(cardName);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "",
            isBot: true,
            cardData: card,
          ));
        });
        _scrollToBottom();
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      
      _addBotMessage("${pos['position_name']}\n$meaning");
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    _addBotMessage("Would you like to know about anything else?");
    if (mounted) {
      setState(() {
        _currentStep = ChatStep.greeting; // Resets for next flow
        _currentOptions = ['Yes', 'No'];
      });
    }
  }

  Color get _primaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
    }
  }

  Color get _accentColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return const Color(0xFFFFB300); 
      case AppColorPalette.emeraldDivine: return const Color(0xFFD4AF37); 
      case AppColorPalette.royalIndigo: return const Color(0xFFE5C07B); 
      case AppColorPalette.midnightCosmic: default: return const Color(0xFFF5D67D); 
    }
  }

  Color get _surfaceColor {
    if (widget.isDark) {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return AppTheme.saffronCard;
        case AppColorPalette.emeraldDivine: return AppTheme.emeraldCard;
        case AppColorPalette.royalIndigo: return AppTheme.royalCard;
        case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicSurface;
      }
    } else {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return const Color(0xFFFFF7F0);
        case AppColorPalette.emeraldDivine: return const Color(0xFFF5FBF6);
        case AppColorPalette.royalIndigo: return const Color(0xFFF3F5FC);
        case AppColorPalette.midnightCosmic: default: return const Color(0xFFF4F7FB);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.getHeaderGradient(widget.currentPalette, widget.isDark),
            ),
            child: CosmicStarfieldBackground(
              isDark: widget.isDark,
              starCount: 20,
              child: CosmicDustBackground(
                particleCount: 30,
                primaryColor: _accentColor,
                accentColor: Colors.white,
              ),
            ),
          ),
        ),
        
        Positioned.fill(
          top: 110.h,
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor, 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  top: false, 
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildMessageBubble(msg);
                          },
                        ),
                      ),
                      if (_currentOptions.isNotEmpty)
                        _buildOptionsArea(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardMessageContent(ChatMessage msg) {
    final card = msg.cardData!;
    final cardName = card['name'];
    final imageUrl = '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/static/${card['image'] ?? 'assets/tarot/${cardName.toString().toLowerCase().replaceAll(' ', '_')}.webp'}?v=3';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "You have chosen",
          style: GoogleFonts.inter(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 14.sp),
        ),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            imageUrl,
            height: 150.h,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/tarot/tarot_back.jpg',
              height: 150.h,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          cardName.toString().toUpperCase(),
          style: GoogleFonts.inter(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TarotCardDetailsScreen(
                cardData: card,
                positionName: 'Card Details',
                currentPalette: widget.currentPalette,
                isDark: widget.isDark,
              )
            ));
          },
          child: Text(
            "Know more about this card>>",
            style: GoogleFonts.inter(
              color: const Color(0xFF8B93A5), 
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.isBot) ...[
            Container(
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor,
                border: Border.all(color: Colors.white, width: 2), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.smart_toy, color: Colors.black87, size: 20.sp), 
            ),
          ],
          
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: msg.isBot 
                    ? (widget.isDark ? const Color(0xFF2A2A40) : Colors.white) 
                    : _accentColor,
                borderRadius: BorderRadius.circular(18.r).copyWith( 
                  topLeft: msg.isBot ? Radius.zero : Radius.circular(18.r),
                  topRight: msg.isBot ? Radius.circular(18.r) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: msg.cardData != null 
                  ? _buildCardMessageContent(msg) 
                  : Text(
                      msg.text,
                      style: GoogleFonts.inter(
                        color: msg.isBot && widget.isDark ? Colors.white : Colors.black87,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4, 
                      ),
                    ),
            ),
          ),
          
          if (!msg.isBot) ...[
            Container(
              margin: EdgeInsets.only(left: 12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor, 
                border: Border.all(color: _accentColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(10.w),
              child: Text(
                "You",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOptionsArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E2E).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center, 
        children: _currentOptions.map((option) {
          return GestureDetector(
            onTap: () => _handleOptionSelected(option),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF2A2A40) : Colors.white,
                borderRadius: BorderRadius.circular(24.r), 
                border: Border.all(color: _accentColor.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                option,
                style: GoogleFonts.inter(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
