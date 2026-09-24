import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tarot_service.dart';
import 'tarot_reading_screen.dart';

import '../theme/app_theme.dart';

class TarotDeckSelectionScreen extends StatefulWidget {
  final String endpoint;
  final String title;
  final String question;
  final int requiredCards;
  final AppColorPalette currentPalette;
  final bool isDark;
  final bool returnDataInsteadOfNavigate;

  const TarotDeckSelectionScreen({
    super.key,
    required this.endpoint,
    required this.title,
    required this.question,
    required this.requiredCards,
    this.currentPalette = AppColorPalette.emeraldDivine,
    this.isDark = false,
    this.returnDataInsteadOfNavigate = false,
  });

  @override
  State<TarotDeckSelectionScreen> createState() => _TarotDeckSelectionScreenState();
}

class _TarotDeckSelectionScreenState extends State<TarotDeckSelectionScreen> with TickerProviderStateMixin {
  final int totalCards = 78;
  List<int> selectedIndices = [];
  bool isLoading = false;
  late AnimationController _animController;

  Color get _primaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
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
    if (selectedIndices.contains(index) || selectedIndices.length >= widget.requiredCards) return;

    setState(() {
      selectedIndices.add(index);
    });

    if (selectedIndices.length == widget.requiredCards) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !isLoading) {
          _confirmSelection();
        }
      });
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
        if (widget.returnDataInsteadOfNavigate) {
          Navigator.pop(context, reading);
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => TarotReadingScreen(
              spreadData: reading,
              currentPalette: widget.currentPalette,
              isDark: widget.isDark,
            )
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to connect to the divine realm. Please check your connection and try again.'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  Widget _buildCardSpread(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = 45.w; // Smaller cards so they don't merge
        final double cardHeight = cardWidth * 1.6;
        final int cardsPerRow = 20; 
        final int numRows = (totalCards / cardsPerRow).ceil();
        final double availableWidth = constraints.maxWidth - 32.w; 
        
        // Calculate the total height needed for the rows
        final double stackHeight = (cardHeight * numRows) + (35.h * numRows) + 30.h;

        // Sort indices so selected cards are rendered last (on top) in the order they were selected
        List<int> sortedIndices = List.generate(totalCards, (i) => i);
        sortedIndices.sort((a, b) {
          bool aSelected = selectedIndices.contains(a);
          bool bSelected = selectedIndices.contains(b);
          if (aSelected && bSelected) {
            return selectedIndices.indexOf(a).compareTo(selectedIndices.indexOf(b));
          } else if (aSelected) {
            return 1; // a is selected, put it after b
          } else if (bSelected) {
            return -1; // b is selected, put it after a
          }
          return a.compareTo(b); // maintain original order for unselected
        });

        return SizedBox(
          height: stackHeight,
          width: constraints.maxWidth,
          child: Stack(
            children: sortedIndices.map((index) {
              final rowIndex = index ~/ cardsPerRow;
                final indexInRow = index % cardsPerRow;
                
                final int cardsInThisRow = (rowIndex == numRows - 1) ? (totalCards % cardsPerRow == 0 ? cardsPerRow : totalCards % cardsPerRow) : cardsPerRow;
                
                // Use fixed spacing based on the max cards per row, but center each row
                final double spacing = (availableWidth - cardWidth) / (cardsPerRow - 1);
                final double rowTotalWidth = cardWidth + (cardsInThisRow - 1) * spacing;
                final double rowLeftOffset = (constraints.maxWidth - rowTotalWidth) / 2;

                final isSelected = selectedIndices.contains(index);
                final selectOrder = isSelected ? selectedIndices.indexOf(index) + 1 : null;

                // Arc Calculation
                final double centerIndex = (cardsInThisRow - 1) / 2;
                final double distanceFromCenter = indexInRow - centerIndex; 
                
                // Gentler arc and rotation
                final double arcDrop = (distanceFromCenter * distanceFromCenter) * 0.25.h;
                final double rotationAngle = distanceFromCenter * 0.035; 

                final double targetLeft = rowLeftOffset + (indexInRow * spacing);
                final double targetTop = 10.h + (rowIndex * (cardHeight + 35.h)) + arcDrop;

                // Staggered animation values (each card starts a bit later)
                final double startDelay = (index / totalCards) * 0.7;
                final double endDelay = (startDelay + 0.3).clamp(0.0, 1.0);
                final Curve cardCurve = Interval(startDelay, endDelay, curve: Curves.easeOutBack);

                return AnimatedBuilder(
                  key: ValueKey(index), // Key ensures AnimatedPositioned tracks the exact card when list order changes
                  animation: _animController,
                  builder: (context, child) {
                    final double animValue = cardCurve.transform(_animController.value);
                    
                    // Cards fly in from the bottom center of the screen
                    final double startLeft = (constraints.maxWidth / 2) - (cardWidth / 2);
                    final double startTop = constraints.maxHeight + 200.h;
                    
                    final double unselectedLeft = startLeft + (targetLeft - startLeft) * animValue;
                    final double unselectedTop = (startTop + (targetTop - startTop) * animValue);

                    // Button position roughly (adjusted to go fully down into the button)
                    double buttonTargetLeft = (constraints.maxWidth / 2) - (cardWidth / 2);
                    double buttonTargetTop = constraints.maxHeight - 40.h; 

                    if (isSelected && selectOrder != null) {
                      // Fan out the collected cards slightly so they form a visible stacked deck
                      buttonTargetLeft += ((selectOrder - 1) * 8.w) - 20.w; 
                      buttonTargetTop -= ((selectOrder - 1) * 1.5.h);
                    }

                    final bool shouldAnimateFlight = _animController.isCompleted;

                    return AnimatedPositioned(
                      duration: shouldAnimateFlight ? const Duration(milliseconds: 800) : Duration.zero,
                      curve: Curves.easeInOutBack, // Jumps up high before swooshing down!
                      left: isSelected ? buttonTargetLeft : unselectedLeft,
                      top: isSelected ? buttonTargetTop : unselectedTop,
                      child: AnimatedRotation(
                        turns: (isSelected && selectOrder != null) 
                            ? (((selectOrder - 1) * 0.015) - 0.04) // Slight rotation fan for collected cards
                            : (rotationAngle * animValue) / (2 * 3.14159265),
                        duration: shouldAnimateFlight ? const Duration(milliseconds: 800) : Duration.zero,
                        curve: Curves.easeInOut,
                        alignment: Alignment.bottomCenter,
                        child: AnimatedScale(
                          scale: isSelected ? 0.22 : 1.0, // Made slightly larger so the stack is visible
                          duration: shouldAnimateFlight ? const Duration(milliseconds: 800) : Duration.zero,
                          curve: Curves.easeInBack, // Grows larger before shrinking!
                        child: AnimatedOpacity(
                          opacity: animValue.clamp(0.0, 1.0), // Keeps it solid, no ghosting
                          duration: Duration.zero,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => _toggleCard(index),
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      image: DecorationImage(
                        image: const AssetImage('assets/images/tarot/tarot_back.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: widget.currentPalette == AppColorPalette.emeraldDivine 
                            ? null
                            : ColorFilter.mode(_primaryColor, BlendMode.hue),
                      ),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.9), // Elegant gold border
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4), 
                          blurRadius: 4,
                          offset: const Offset(-2, 2), // Subtle shadow to the left
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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
        title: Text(widget.title, style: GoogleFonts.outfit(color: _primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _surfaceColor,
              widget.isDark ? _surfaceColor : const Color(0xFFFFFCED),
              _surfaceColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle gold background designs
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Icon(Icons.star_outline_rounded, size: 250.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            Positioned(
              top: 200.h,
              left: -40.w,
              child: Icon(Icons.auto_awesome, size: 150.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: 150.h,
              right: -30.w,
              child: Icon(Icons.brightness_4_outlined, size: 180.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                    child: Text(
                      (widget.requiredCards - selectedIndices.length) > 0 
                          ? 'Select ${widget.requiredCards - selectedIndices.length} More Card${(widget.requiredCards - selectedIndices.length) > 1 ? 's' : ''}'
                          : 'Revealing Cards...',
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp, 
                        fontWeight: FontWeight.bold, 
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'Focus on your question:\n"${widget.question}"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp, 
                        color: const Color(0xFFB8860B), 
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),
              
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
                      _surfaceColor,
                      _surfaceColor.withValues(alpha: 0.8),
                      _surfaceColor.withValues(alpha: 0.0),
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
                        backgroundColor: _primaryColor,
                        disabledBackgroundColor: _primaryColor.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 5,
                        shadowColor: _primaryColor.withValues(alpha: 0.3),
                      ),
                      onPressed: selectedIndices.length == widget.requiredCards && !isLoading
                          ? _confirmSelection
                          : null,
                      child: isLoading 
                          ? SizedBox(height: 24.h, width: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              'Reveal Reading',
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp, 
                                fontWeight: FontWeight.bold, 
                                color: selectedIndices.length == widget.requiredCards ? const Color(0xFFFFD700) : Colors.white70
                              ),
                            ),
                    ),
                  ),
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
}

