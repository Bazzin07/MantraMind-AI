class RecommendationItem {
  final String title;
  final String subtitle;
  final String category; // 'article' | 'tip' | 'guide'
  final String? reason;

  RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.category,
    this.reason,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? 'article',
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'reason': reason,
      };
}
