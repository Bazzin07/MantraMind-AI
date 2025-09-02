class DiaryEntry {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final double? sentimentScore; // 0.0 - 1.0
  final String?
      moodLabel; // e.g., very_low/low/neutral/high/very_high or sad/happy, etc.
  final String? aiSummary;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.sentimentScore,
    this.moodLabel,
    this.aiSummary,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      moodLabel: json['mood_label'] as String?,
      aiSummary: json['ai_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sentiment_score': sentimentScore,
      'mood_label': moodLabel,
      'ai_summary': aiSummary,
    };
  }
}
