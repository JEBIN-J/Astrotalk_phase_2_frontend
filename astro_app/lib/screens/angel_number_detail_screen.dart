import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';

class AngelNumberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lookupData;
  final String? initialSequence;

  const AngelNumberDetailScreen({
    super.key,
    required this.lookupData,
    this.initialSequence,
  });

  @override
  State<AngelNumberDetailScreen> createState() => _AngelNumberDetailScreenState();
}

class _AngelNumberDetailScreenState extends State<AngelNumberDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  // Exact Theme Palette from the Angel Numbers Explore Card
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color darkIndigo = Color(0xFF4F46E5);
  static const Color softCardBg = Color(0xFFF5F3FF);
  static const Color cardBorder = Color(0xFFEDE9FE);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF64748B);
  static const Color badgeBg = Color(0xFFEDE9FE);
  static const Color badgeText = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    _data = widget.lookupData;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshSequence(String seq) async {
    setState(() => _isLoading = true);
    try {
      final res = await AstroApiService.lookupAngelNumber(seq);
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sequence: $e')),
        );
      }
    }
  }

  void _showRecordSightingModal(BuildContext context, String seq) {
    final noteController = TextEditingController();
    String selectedCategory = 'Clock / Watch';
    String selectedMood = 'Inspired';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_add_rounded, color: primaryIndigo, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Record Sighting: $seq',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Where did you notice it?',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children: ['Clock / Watch', 'Receipt / Bill', 'License Plate', 'Phone / Screen', 'Other'].map((cat) {
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat, style: GoogleFonts.outfit(fontSize: 12.sp, color: isSelected ? Colors.white : darkText)),
                    selected: isSelected,
                    selectedColor: primaryIndigo,
                    backgroundColor: softCardBg,
                    side: BorderSide(color: isSelected ? primaryIndigo : cardBorder),
                    onSelected: (val) {
                      if (val) setModalState(() => selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 14.h),
              Text(
                'Personal Reflection / Note (Optional)',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What were you thinking or feeling at that moment?',
                  hintStyle: GoogleFonts.outfit(fontSize: 13.sp, color: mutedText),
                  filled: true,
                  fillColor: softCardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: primaryIndigo),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    try {
                      await AstroApiService.addAngelSighting(
                        observedSequence: seq,
                        contextCategory: selectedCategory,
                        personalNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                        mood: selectedMood,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sighting of $seq saved to your personal journal!'),
                            backgroundColor: darkIndigo,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not save sighting: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'Save to Journal',
                    style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normSeq = _data['normalized_sequence']?.toString() ?? widget.initialSequence ?? '';
    final hasReviewed = _data['has_reviewed_interpretation'] == true;
    final interp = _data['interpretation'] as Map<String, dynamic>?;
    final reduction = _data['reduction'] as Map<String, dynamic>? ?? {};
    final patterns = (_data['detected_patterns'] as List<dynamic>?) ?? [];
    final primaryPattern = _data['primary_pattern'] as String? ?? 'general_sequence';
    final rootInfo = _data['root_number_info'] as Map<String, dynamic>?;
    final related = (_data['related_sequences'] as List<dynamic>?) ?? [];
    final calcSteps = (reduction['calculation_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: softCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: cardBorder),
              ),
              child: Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: darkText, size: 15.sp),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(color: primaryIndigo, shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 11.sp),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                'Angel Sequence: $normSeq',
                style: GoogleFonts.outfit(
                  fontSize: 17.5.sp,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => _showRecordSightingModal(context, normSeq),
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: softCardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder),
                  ),
                  child: Center(
                    child: Icon(Icons.bookmark_add_outlined, color: primaryIndigo, size: 18.sp),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryIndigo))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HERO BANNER ---
                  _buildHeroBanner(normSeq, interp, patterns, primaryPattern),
                  SizedBox(height: 16.h),

                  // --- REDUCTION CALCULATION CARD ---
                  _buildReductionCard(normSeq, reduction, calcSteps),
                  SizedBox(height: 16.h),

                  // --- STATUS OR REVIEWED CONTENT ---
                  if (!hasReviewed) ...[
                    _buildHonestUnavailableCard(normSeq),
                    SizedBox(height: 16.h),
                  ] else ...[
                    // Symbolic Themes
                    if (interp?['traditional_symbolic_themes'] != null)
                      _buildThemesWrap((interp!['traditional_symbolic_themes'] as List<dynamic>).map((e) => e.toString()).toList()),
                    SizedBox(height: 16.h),

                    // Tabbed Deep Meanings
                    _buildInterpretationTabs(interp!),
                    SizedBox(height: 16.h),

                    // Practical & Reflection Guidance
                    _buildReflectionGuidanceCard(interp),
                    SizedBox(height: 16.h),
                  ],

                  // --- ROOT NUMBER ARCHETYPE SNIPPET ---
                  if (rootInfo != null) ...[
                    _buildRootNumberCard(rootInfo),
                    SizedBox(height: 16.h),
                  ],

                  // --- RELATED NUMBER PATTERNS ---
                  if (related.isNotEmpty) ...[
                    _buildRelatedSequencesSection(related),
                    SizedBox(height: 24.h),
                  ],

                  // --- ACTION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecordSightingModal(context, normSeq),
                      icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                      label: Text(
                        'Record This Sighting in Journal',
                        style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryIndigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(
    String seq,
    Map<String, dynamic>? interp,
    List<dynamic> patterns,
    String primaryPattern,
  ) {
    final title = interp?['title'] ?? 'Number Sequence: $seq';
    final shortMeaning = interp?['short_meaning'] ??
        'A deterministic numeric sequence analyzed using standard Pythagorean numerology digit reduction.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: softCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      seq,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (patterns.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Text(
                    patterns.first['name']?.toString() ?? 'Pattern Detected',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: badgeText,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: darkText,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            shortMeaning,
            style: GoogleFonts.outfit(
              fontSize: 13.5.sp,
              color: mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReductionCard(
    String seq,
    Map<String, dynamic> reduction,
    List<String> calcSteps,
  ) {
    final compTotal = reduction['compound_total'] ?? 0;
    final rootNum = reduction['root_number'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.calculate_rounded, color: primaryIndigo, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numerological Reduction',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Step-by-step digit sum to single root (1-9)',
                      style: GoogleFonts.outfit(fontSize: 11.5.sp, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: softCardBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in calcSteps)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_right_rounded, color: primaryIndigo, size: 18.sp),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            step,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Compound Total', style: GoogleFonts.outfit(fontSize: 11.sp, color: mutedText)),
                      Text(
                        '$compTotal',
                        style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Root Number', style: GoogleFonts.outfit(fontSize: 11.sp, color: badgeText)),
                      Text(
                        '$rootNum',
                        style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: darkIndigo),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHonestUnavailableCard(String seq) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: const Color(0xFFD97706), size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Reviewed Interpretation Available',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'We never fabricate or substitute unrelated interpretations. The digit reduction and pattern analysis above are mathematically computed for $seq. As new approved editorial interpretations are added to the library, they will appear here.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5.sp,
                    color: const Color(0xFFB45309),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesWrap(List<String> themes) {
    if (themes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRADITIONAL SYMBOLIC THEMES',
          style: GoogleFonts.outfit(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: mutedText,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: themes.map((theme) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: softCardBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: primaryIndigo, size: 14.sp),
                  SizedBox(width: 5.w),
                  Text(
                    theme,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterpretationTabs(Map<String, dynamic> interp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryIndigo,
            unselectedLabelColor: mutedText,
            indicatorColor: primaryIndigo,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Detailed Meaning'),
              Tab(text: 'Love & Relation'),
              Tab(text: 'Career & Work'),
              Tab(text: 'Personal Growth'),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              height: 180.h,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _tabContent(interp['detailed_meaning'] ?? 'No detailed meaning provided.'),
                  _tabContent(interp['love_and_relationships'] ?? 'No love & relationship interpretation published.'),
                  _tabContent(interp['career_and_work'] ?? 'No career interpretation published.'),
                  _tabContent(interp['personal_growth'] ?? interp['spiritual_reflection'] ?? 'No growth notes published.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent(String text) {
    return SingleChildScrollView(
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13.5.sp,
          color: darkText,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildReflectionGuidanceCard(Map<String, dynamic> interp) {
    final questions = (interp['reflection_questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final guidance = interp['practical_guidance'];
    List<String> guidanceList = [];
    if (guidance is List) {
      guidanceList = guidance.map((e) => e.toString()).toList();
    } else if (guidance is String && guidance.isNotEmpty) {
      guidanceList = [guidance];
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: softCardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: primaryIndigo, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Reflection & Practical Guidance',
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ),
            ],
          ),
          if (questions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Questions to Ask Yourself:',
              style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: darkIndigo),
            ),
            SizedBox(height: 6.h),
            for (final q in questions)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: primaryIndigo, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(q, style: GoogleFonts.outfit(fontSize: 13.sp, color: darkText, height: 1.3)),
                    ),
                  ],
                ),
              ),
          ],
          if (guidanceList.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Practical Next Steps:',
              style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: darkIndigo),
            ),
            SizedBox(height: 6.h),
            for (final g in guidanceList)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: primaryIndigo, size: 15.sp),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(g, style: GoogleFonts.outfit(fontSize: 13.sp, color: darkText, height: 1.3)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRootNumberCard(Map<String, dynamic> rootInfo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${rootInfo['number']}',
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: darkIndigo,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anchored in Root Number ${rootInfo['number']}',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  rootInfo['title'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: primaryIndigo),
                ),
                SizedBox(height: 4.h),
                Text(
                  rootInfo['short_meaning'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 12.5.sp, color: mutedText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSequencesSection(List<dynamic> related) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATED NUMBER PATTERNS',
          style: GoogleFonts.outfit(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: mutedText,
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 110.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (ctx, idx) {
              final item = related[idx] as Map<String, dynamic>;
              final rSeq = item['sequence']?.toString() ?? '';
              return InkWell(
                onTap: () => _refreshSequence(rSeq),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 160.w,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: softCardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rSeq,
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: darkIndigo,
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, size: 14.sp, color: primaryIndigo),
                        ],
                      ),
                      Text(
                        item['title']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
