import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:astro_app/screens/name_analysis_screen.dart';

void main() {
  testWidgets('NameAnalysisScreen renders input form and system selectors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => const MaterialApp(
          home: NameAnalysisScreen(
            initialBirthName: 'John Ronald Reuel Tolkien',
            initialSystem: 'pythagorean',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Name Analysis'), findsOneWidget);
    expect(find.text('Pythagorean & Chaldean Vibrations'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Full Name at Birth *'), findsOneWidget);
    expect(find.text('Current / Commonly Used Name (Optional)'), findsOneWidget);
    expect(find.text('Calculation System'), findsOneWidget);
    expect(find.text('Pythagorean'), findsOneWidget);
    expect(find.text('Chaldean'), findsOneWidget);
    expect(find.text('Calculate Name Analysis'), findsOneWidget);
  });

  testWidgets('NameAnalysisScreen displays horizontal tab pills and switches views without deep scrolling', (WidgetTester tester) async {
    final mockReportData = {
      'status': 'success',
      'system': 'pythagorean',
      'analysis': {
        'original_name': 'jebin j',
        'clean_name': 'jebinj',
        'total_letters_count': 6,
        'core_numbers': {
          'expression': {
            'final_number': 5,
            'is_master_number': false,
            'reduction_steps': ['23 -> 2 + 3 = 5'],
            'label': 'Expression Number (Destiny)',
            'description': 'The vibrational frequency of your life mission and potential.',
          },
          'soul_urge': {
            'final_number': 5,
            'is_master_number': false,
            'reduction_steps': ['5'],
            'label': 'Soul Urge Number (Heart Desire)',
            'description': 'The inner driving motivation and secret emotional needs.',
          },
          'personality': {
            'final_number': 9,
            'is_master_number': false,
            'reduction_steps': ['18 -> 1 + 8 = 9'],
            'label': 'Personality Number (Outer Persona)',
            'description': 'The outer persona perceived by others.',
          },
        },
        'cornerstone': {
          'letter': 'J',
          'value': 1,
          'title': 'Initiative & Drive',
          'meaning': 'Approaches beginnings with pioneering zeal.',
        },
        'capstone': {
          'letter': 'J',
          'value': 1,
          'title': 'Completion & Tenacity',
          'meaning': 'Finishes endeavours with self-reliance.',
        },
        'first_vowel': {
          'letter': 'E',
          'value': 5,
          'title': 'Spontaneous Curiosity',
          'meaning': 'Instinctive visceral reflexes lean toward exploration.',
        },
        'words': [
          {
            'word': 'jebin',
            'letters': [
              {'letter': 'J', 'value': 1, 'type': 'consonant'},
              {'letter': 'E', 'value': 5, 'type': 'vowel'},
              {'letter': 'B', 'value': 2, 'type': 'consonant'},
              {'letter': 'I', 'value': 9, 'type': 'vowel'},
              {'letter': 'N', 'value': 5, 'type': 'consonant'},
            ],
            'expression_subtotal': 22,
            'expression_reduced': 4,
          },
        ],
      },
      'interpretations': {
        'expression': {
          'title': 'The Freedom Explorer & Catalyst',
          'core_theme': 'Dynamic Freedom, Adaptability & Expansion',
          'overview': 'You are driven to experience life in all its variety and multidimensional depth.',
          'strengths': ['Versatility', 'Quick-witted Communication', 'Magnetic Charisma'],
          'challenges': ['Restlessness', 'Impatience with routine'],
          'career': 'Excels in roles involving travel, communications, media, and innovation.',
          'relationships': 'Values intellectual stimulation, mutual freedom, and exciting adventures.',
          'guidance': 'Practice grounding routines to anchor your expansive intellectual curiosity.',
        },
        'soul_urge': {
          'title': 'The Seeker of Unbound Freedom',
          'core_theme': 'Inner Autonomy and Novel Horizons',
          'overview': 'At your core lies a deep longing for liberation from rigid constraints.',
          'strengths': ['Curiosity', 'Open-mindedness'],
          'challenges': ['Fearing commitment'],
          'career': 'Self-directed pathways and entrepreneurial exploration.',
          'relationships': 'Craves partners who respect personal independence.',
          'guidance': 'Inner peace arises from mindful presence rather than escaping obligations.',
        },
        'personality': {
          'title': 'The Compassionate Visionary',
          'core_theme': 'Universal Empathy & Magnetic Presence',
          'overview': 'You project worldly wisdom and magnetic approachability.',
          'strengths': ['Generosity', 'Broad perspective'],
          'challenges': ['Emotional exhaustion'],
          'career': 'Humanitarian service and artistic leadership.',
          'relationships': 'Warm and inclusive.',
          'guidance': 'Maintain healthy emotional boundaries.',
        },
      },
    };

    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: NameAnalysisScreen(
            initialBirthName: 'jebin j',
            initialSystem: 'pythagorean',
            initialReportData: mockReportData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Hero Banner & Name Blueprint header
    expect(find.text('jebin j'), findsOneWidget);
    expect(find.text('YOUR NAME BLUEPRINT'), findsOneWidget);

    // Verify 3 side-by-side core cards
    expect(find.text('Expression'), findsWidgets);
    expect(find.text('Soul Urge'), findsWidgets);
    expect(find.text('Personality'), findsWidgets);

    // Verify horizontal pill tab bar exists
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Strengths'), findsOneWidget);
    expect(find.text('Challenges'), findsOneWidget);
    expect(find.text('Pillars & Harmony'), findsOneWidget);
    expect(find.text('Calculation'), findsOneWidget);

    // In Overview tab by default:
    expect(find.text('The Freedom Explorer & Catalyst'), findsOneWidget);
    expect(find.text('Practical Life Guidance'), findsOneWidget);

    // Switch to Strengths tab
    await tester.ensureVisible(find.text('Strengths'));
    await tester.tap(find.text('Strengths'));
    await tester.pumpAndSettle();
    expect(find.text('Innate Talents & Core Strengths'), findsOneWidget);
    expect(find.text('Versatility'), findsOneWidget);
    expect(find.text('Magnetic Charisma'), findsOneWidget);

    // Switch to Challenges tab
    await tester.ensureVisible(find.text('Challenges'));
    await tester.tap(find.text('Challenges'));
    await tester.pumpAndSettle();
    expect(find.text('Growth Lessons & Potential Challenges'), findsOneWidget);
    expect(find.text('Restlessness'), findsOneWidget);

    // Switch to Pillars & Harmony tab
    await tester.ensureVisible(find.text('Pillars & Harmony'));
    await tester.tap(find.text('Pillars & Harmony'));
    await tester.pumpAndSettle();
    expect(find.text('Foundational Pillars of the Name'), findsOneWidget);
    expect(find.text('CORNERSTONE (Value 1)'), findsOneWidget);
    expect(find.text('CAPSTONE (Value 1)'), findsOneWidget);

    // Switch to Calculation tab
    await tester.ensureVisible(find.text('Calculation'));
    await tester.tap(find.text('Calculation'));
    await tester.pumpAndSettle();
    expect(find.text('Calculation Transparency'), findsOneWidget);
    expect(find.text('Subtotal: 22 (Reduced: 4)'), findsOneWidget);
  });
}
