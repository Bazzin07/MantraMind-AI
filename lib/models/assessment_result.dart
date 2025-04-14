class AssessmentResult {
  final String rawAssessment;
  final String? translatedAssessment;
  final String mainCondition;
  final List<String> recommendedActions;
  final DateTime date;

  AssessmentResult({
    required this.rawAssessment,
    this.translatedAssessment,
    required this.mainCondition,
    required this.recommendedActions,
    required this.date,
  });

  // Create from JSON (useful when retrieving from Supabase)
  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      rawAssessment: json['raw_assessment'] ?? '',
      mainCondition: json['main_condition'] ?? 'Unknown',
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to JSON (useful when storing to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'raw_assessment': rawAssessment,
      'main_condition': mainCondition,
      'recommended_actions': recommendedActions,
      'date': date.toIso8601String(),
    };
  }
}