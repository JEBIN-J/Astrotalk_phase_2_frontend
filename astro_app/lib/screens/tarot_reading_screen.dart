import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'tarot_card_details_screen.dart';
import '../services/astro_api_service.dart';

class TarotReadingScreen extends StatefulWidget {
  final Map<String, dynamic> spreadData;

  const TarotReadingScreen({Key? key, required this.spreadData}) : super(key: key);

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final Set<int> _revealedIndices = {};

  @override
  Widget build(BuildContext context) {
    final positions = widget.spreadData['positions'] as List<dynamic>;
    
    final spreadType = widget.spreadData['spread_type'].toString().replaceAll('_', '/').toUpperCase();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '$spreadType READING', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            color: const Color(0xFFF5D67D),
            fontSize: 18.sp,
            letterSpacing: 1.2,
          )
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF5D67D),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF021B10), // Dark green background
          image: DecorationImage(
            image: const AssetImage('assets/images/tarot/tarot_cosmic_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF021B10).withValues(alpha: 0.85), // Dark green tint
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(positions.length, (index) {
              final pos = positions[index];
              final card = pos['card'];
              final isRevealed = _revealedIndices.contains(index);

              return Padding(
                padding: EdgeInsets.only(bottom: index == positions.length - 1 ? 0 : 20.h),
                child: GestureDetector(
                  onTap: () {
                    if (!isRevealed) {
                      setState(() {
                        _revealedIndices.add(index);
                      });
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TarotCardDetailsScreen(
                          cardData: card,
                          positionName: pos['position_name'],
                        )
                      ));
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final rotateAnim = Tween(begin: 3.14159, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotateAnim,
                        child: child,
                        builder: (context, child) {
                          final isUnder = (ValueKey(isRevealed) != child!.key);
                          var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                          tilt *= isUnder ? -1.0 : 1.0;
                          final value = isUnder ? min(rotateAnim.value, 3.14159 / 2) : rotateAnim.value;
                          return Transform(
                            transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                      );
                    },
                    child: isRevealed
                        ? _buildRevealedCard(pos, card, key: const ValueKey(true))
                        : _buildFaceDownCard(pos['position_name'], key: const ValueKey(false)),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      ),
      ),
    );
  }

  double min(double a, double b) => a < b ? a : b;

  Widget _buildFaceDownCard(String positionName, {Key? key}) {
    return Container(
      key: key,
      height: 400.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF021B10),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5D67D).withValues(alpha: 0.05), 
            blurRadius: 30, 
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3), width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/tarot/tarot_back.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              color: Colors.black.withValues(alpha: 0.4), // Darken the background image slightly so text is readable
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 36.h),
              Text(
                positionName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 22.sp,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5D67D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Tap to Reveal', 
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFF5D67D), 
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedCard(Map<String, dynamic> pos, Map<String, dynamic> card, {Key? key}) {
    final isReversed = card['orientation'] == 'Reversed';
    
    return Container(
      key: key,
      height: 400.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF021B10),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          ),
        ]
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF052B18),
                borderRadius: BorderRadius.vertical(top: Radius.circular(23.r)),
                border: Border(bottom: BorderSide(color: const Color(0xFFF5D67D).withValues(alpha: 0.2))),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://www.transparenttextures.com/patterns/stardust.png',
                    repeat: ImageRepeat.repeat,
                    color: Colors.white.withValues(alpha: 0.1),
                    colorBlendMode: BlendMode.modulate,
                  ),
                  if (card['image'] != null || card['name'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(23.r)),
                      child: Transform.rotate(
                        angle: isReversed ? 3.14159 : 0,
                        child: Image.network(
                          '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/static/${card['image'] ?? 'assets/tarot/${card['name'].toString().toLowerCase().replaceAll(' ', '_')}.webp'}?v=3',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/tarot/tarot_back.jpg',
                                fit: BoxFit.cover,
                                color: Colors.black.withValues(alpha: 0.5),
                                colorBlendMode: BlendMode.darken,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.style_outlined, size: 72.sp, color: const Color(0xFFF5D67D)),
                                  if (isReversed) ...[
                                    SizedBox(height: 12.h),
                                    Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFFEF4444), size: 28.sp),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/tarot/tarot_back.jpg',
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.5),
                          colorBlendMode: BlendMode.darken,
                        ),
                        Transform.rotate(
                          angle: isReversed ? 3.14159 : 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.style_outlined, size: 72.sp, color: const Color(0xFFF5D67D)),
                              if (isReversed) ...[
                                SizedBox(height: 12.h),
                                Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFFEF4444), size: 28.sp),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pos['position_name'].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500, 
                      fontSize: 12.sp, 
                      color: const Color(0xFFF5D67D),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (card['yes_no_meaning'] != null && widget.spreadData['spread_type'] == 'yes_no') ...[
                    Text(
                      '${card['yes_no_meaning']}'.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.sp,
                        color: '${card['yes_no_meaning']}'.toLowerCase().contains('yes') 
                            ? const Color(0xFF4ADE80) 
                            : ('${card['yes_no_meaning']}'.toLowerCase().contains('no') 
                                ? const Color(0xFFF87171) 
                                : Colors.amber),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                  Text(
                    '${card['name']}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, 
                      fontSize: 22.sp, 
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    isReversed ? 'Reversed' : 'Upright',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp, 
                      color: Colors.white60, 
                      fontStyle: FontStyle.italic
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5D67D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp, 
                            color: const Color(0xFFF5D67D), 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.arrow_forward_rounded, size: 14.sp, color: const Color(0xFFF5D67D)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
