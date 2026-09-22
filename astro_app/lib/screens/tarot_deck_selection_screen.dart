import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tarot_service.dart';
import 'tarot_reading_screen.dart';

class TarotDeckSelectionScreen extends StatefulWidget {
  final String endpoint;
  final String title;
  final String question;
  final int requiredCards;

  const TarotDeckSelectionScreen({
    super.key,
    required this.endpoint,
    required this.title,
    required this.question,
    required this.requiredCards,
  });

  @override
  State<TarotDeckSelectionScreen> createState() => _TarotDeckSelectionScreenState();
}

class _TarotDeckSelectionScreenState extends State<TarotDeckSelectionScreen> with TickerProviderStateMixin {
  final int totalCards = 78;
  List<int> selectedIndices = [];
  bool isLoading = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleCard(int index) {
    if (selectedIndices.contains(index)) {
      setState(() {
        selectedIndices.remove(index);
      });
    } else {
      if (selectedIndices.length < widget.requiredCards) {
        setState(() {
          selectedIndices.add(index);
        });
      }
    }
  }

  void _confirmSelection() async {
    if (selectedIndices.length != widget.requiredCards) return;

    setState(() {
      isLoading = true;
    });

    try {
      final seed = selectedIndices.join(',');
      final reading = await TarotService().drawSpread(widget.endpoint, question: widget.question, seed: seed);
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TarotReadingScreen(spreadData: reading)
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildCardSpread(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = 55.w;
        final double cardHeight = cardWidth * 1.6;
        final int cardsPerRow = 26;
        final double availableWidth = constraints.maxWidth - 32.w; // 16 padding on each side
        final double spacing = (availableWidth - cardWidth) / (cardsPerRow - 1);
        
        // Calculate the total height needed for the 3 rows.
        // We add extra height for the arc droop at the edges.
        final double stackHeight = (cardHeight * 3) + 60.h + 50.h;

        return SizedBox(
          height: stackHeight,
          width: constraints.maxWidth,
          child: Stack(
            children: List.generate(totalCards, (index) {
              final rowIndex = index ~/ cardsPerRow;
              final indexInRow = index % cardsPerRow;

              final isSelected = selectedIndices.contains(index);
              final selectOrder = isSelected ? selectedIndices.indexOf(index) + 1 : null;

              // Arc Calculation
              final double centerIndex = (cardsPerRow - 1) / 2;
              final double distanceFromCenter = indexInRow - centerIndex; // negative to left, positive to right
              
              // The ends of the row will drop lower by this amount to create a beautiful fan arc
              final double arcDrop = (distanceFromCenter * distanceFromCenter) * 0.4.h;
              
              // The cards will tilt outwards for the fan effect
              final double rotationAngle = distanceFromCenter * 0.04; // radians

              // The final target position for this card
              final double targetLeft = 16.w + (indexInRow * spacing);
              final double targetTop = 10.h + (rowIndex * (cardHeight + 25.h)) + arcDrop;

              // Staggered animation values (each card starts a bit later)
              final double startDelay = (index / totalCards) * 0.7;
              final double endDelay = (startDelay + 0.3).clamp(0.0, 1.0);
              final Curve cardCurve = Interval(startDelay, endDelay, curve: Curves.easeOutBack);

              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final double animValue = cardCurve.transform(_animController.value);
                  
                  // Cards fly in from the bottom center of the screen
                  final double startLeft = (constraints.maxWidth / 2) - (cardWidth / 2);
                  final double startTop = constraints.maxHeight + 200.h;
                  
                  final currentLeft = startLeft + (targetLeft - startLeft) * animValue;
                  
                  // If selected, lift it up by 30 pixels AND remove the arc drop so it pops out straight
                  final selectionLift = isSelected ? (30.h + arcDrop) : 0.0;
                  final currentTop = (startTop + (targetTop - startTop) * animValue) - selectionLift;

                  // Selected cards face perfectly straight
                  final currentRotation = isSelected ? 0.0 : (rotationAngle * animValue);

                  return Positioned(
                    left: currentLeft,
                    top: currentTop,
                    child: Transform.rotate(
                      angle: currentRotation,
                      alignment: Alignment.bottomCenter,
                      child: Opacity(
                        opacity: animValue.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => _toggleCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/tarot/tarot_back.jpg'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? Colors.amber.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                          blurRadius: isSelected ? 12 : 5,
                          offset: Offset(0, isSelected ? 0 : 3),
                          spreadRadius: isSelected ? 2 : 0,
                        )
                      ],
                    ),
                    child: isSelected
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 5)],
                                ),
                                child: Text(
                                  '$selectOrder',
                                  style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF021B10), // Dark green
          image: DecorationImage(
            image: const AssetImage('assets/images/tarot/tarot_cosmic_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF021B10).withValues(alpha: 0.85), // Dark green tint to let cards pop
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.h),
                child: Text(
                  'Select ${widget.requiredCards} Card${widget.requiredCards > 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 28.sp, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.amber,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Focus on your question:\n"${widget.question}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp, 
                    color: const Color(0xFFFFD700).withValues(alpha: 0.8), 
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              
              // Spread Area
              Expanded(
                child: _buildCardSpread(context),
              ),
              
              Container(
                padding: EdgeInsets.all(24.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF021B10),
                      const Color(0xFF021B10).withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 5,
                        shadowColor: Colors.amber.withValues(alpha: 0.5),
                      ),
                      onPressed: selectedIndices.length == widget.requiredCards && !isLoading
                          ? _confirmSelection
                          : null,
                      child: isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                          : Text(
                              'Reveal Reading',
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp, 
                                fontWeight: FontWeight.bold, 
                                color: selectedIndices.length == widget.requiredCards ? Colors.black : Colors.white54
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

