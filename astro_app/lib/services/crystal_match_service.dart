/// Data models and structured definitions for the Crystal Match Numerology feature.
///
/// Note: All actual records, calculations, rule evaluations, and recommendations
/// are authoritatively computed and returned by the backend engine backed by SQLite.
class CrystalRecord {
  final String id;
  final String name;
  final List<String> alternativeNames;
  final String mineralFamily;
  final String chemicalFormula;
  final String mohsHardness;
  final String colourDescription;
  final String geologicalDescription;
  final String traditionalAssociations;
  final List<int> pythagoreanNumbers;
  final List<int> chaldeanNumbers;
  final List<String> supportedIntentions;
  final String suggestedUse;
  final String careInstructions;
  final String safetyNotes;
  final String limitations;
  final String publicationStatus;
  final String contentVersion;

  const CrystalRecord({
    required this.id,
    required this.name,
    required this.alternativeNames,
    required this.mineralFamily,
    required this.chemicalFormula,
    required this.mohsHardness,
    required this.colourDescription,
    required this.geologicalDescription,
    required this.traditionalAssociations,
    required this.pythagoreanNumbers,
    required this.chaldeanNumbers,
    required this.supportedIntentions,
    required this.suggestedUse,
    required this.careInstructions,
    required this.safetyNotes,
    this.limitations =
        'Complementary symbolic and mindfulness practice. Not a medical treatment or guaranteed outcome.',
    this.publicationStatus = 'published',
    this.contentVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'alternative_names': alternativeNames,
        'mineral_family': mineralFamily,
        'chemical_formula': chemicalFormula,
        'mohs_hardness': mohsHardness,
        'colour_description': colourDescription,
        'geological_description': geologicalDescription,
        'traditional_associations': traditionalAssociations,
        'pythagorean_numbers': pythagoreanNumbers,
        'chaldean_numbers': chaldeanNumbers,
        'supported_intentions': supportedIntentions,
        'suggested_use': suggestedUse,
        'care_instructions': careInstructions,
        'safety_notes': safetyNotes,
        'limitations': limitations,
        'publication_status': publicationStatus,
        'content_version': contentVersion,
      };

  factory CrystalRecord.fromJson(Map<String, dynamic> json) => CrystalRecord(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        alternativeNames: (json['alternative_names'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        mineralFamily: json['mineral_family'] as String? ?? 'Silicate',
        chemicalFormula: json['chemical_formula'] as String? ?? 'N/A',
        mohsHardness: json['mohs_hardness'] as String? ?? '7.0',
        colourDescription: json['colour_description'] as String? ?? '',
        geologicalDescription:
            json['geological_description'] as String? ?? '',
        traditionalAssociations:
            json['traditional_associations'] as String? ?? '',
        pythagoreanNumbers: (json['pythagorean_numbers'] as List<dynamic>?)
                ?.map((e) => int.tryParse(e.toString()) ?? 0)
                .toList() ??
            [],
        chaldeanNumbers: (json['chaldean_numbers'] as List<dynamic>?)
                ?.map((e) => int.tryParse(e.toString()) ?? 0)
                .toList() ??
            [],
        supportedIntentions: (json['supported_intentions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        suggestedUse: json['suggested_use'] as String? ?? '',
        careInstructions: json['care_instructions'] as String? ?? '',
        safetyNotes: json['safety_notes'] as String? ?? '',
        limitations: json['limitations'] as String? ?? '',
        publicationStatus: json['publication_status'] as String? ?? 'published',
        contentVersion: json['content_version'] as String? ?? '1.0.0',
      );
}

/// A matched crystal recommendation produced by evaluated backend rules.
class CrystalRecommendation {
  final CrystalRecord crystal;
  final int matchScore;
  final String primaryRuleCode;
  final String primaryRuleTitle;
  final String matchExplanation;
  final List<String> contributingFactors;
  final int matchingNumber;
  final String numberRole;
  final bool isIntentionMatch;

  const CrystalRecommendation({
    required this.crystal,
    required this.matchScore,
    required this.primaryRuleCode,
    required this.primaryRuleTitle,
    required this.matchExplanation,
    required this.contributingFactors,
    required this.matchingNumber,
    required this.numberRole,
    required this.isIntentionMatch,
  });

  Map<String, dynamic> toJson() => {
        'crystal': crystal.toJson(),
        'match_score': matchScore,
        'primary_rule_code': primaryRuleCode,
        'primary_rule_title': primaryRuleTitle,
        'match_explanation': matchExplanation,
        'contributing_factors': contributingFactors,
        'matching_number': matchingNumber,
        'number_role': numberRole,
        'is_intention_match': isIntentionMatch,
      };

  factory CrystalRecommendation.fromJson(Map<String, dynamic> json) =>
      CrystalRecommendation(
        crystal: CrystalRecord.fromJson(
            json['crystal'] as Map<String, dynamic>? ?? {}),
        matchScore: json['match_score'] as int? ?? 0,
        primaryRuleCode: json['primary_rule_code'] as String? ?? '',
        primaryRuleTitle: json['primary_rule_title'] as String? ?? '',
        matchExplanation: json['match_explanation'] as String? ?? '',
        contributingFactors: (json['contributing_factors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        matchingNumber: json['matching_number'] as int? ?? 0,
        numberRole: json['number_role'] as String? ?? '',
        isIntentionMatch: json['is_intention_match'] as bool? ?? false,
      );
}

/// Metadata and default definitions for Crystal Match features.
class CrystalMatchService {
  static const String engineVersion = '2.1.0';
  static const String contentVersion = '2026.1';

  /// Default intention categories (can also be loaded dynamically from backend).
  static const List<Map<String, String>> defaultIntentions = [
    {'code': 'all', 'title': 'All Intentions'},
    {'code': 'calm', 'title': 'Calm & Peace'},
    {'code': 'focus', 'title': 'Focus & Discipline'},
    {'code': 'confidence', 'title': 'Confidence & Courage'},
    {'code': 'creativity', 'title': 'Creativity & Joy'},
    {'code': 'protection', 'title': 'Protection & Boundaries'},
    {'code': 'growth', 'title': 'Heart & Growth'},
    {'code': 'motivation', 'title': 'Vitality & Drive'},
    {'code': 'reflection', 'title': 'Intuition & Reflection'},
  ];
}
