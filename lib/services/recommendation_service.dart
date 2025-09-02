import 'dart:convert';
import 'dart:math' as math;
import 'package:mantramind/models/recommendation_item.dart';
import 'package:mantramind/services/diary_service.dart';
import 'package:mantramind/services/mood_service.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/gemini_service.dart';

class RecommendationService {
  static const _emotionSet = [
    'happy',
    'sad',
    'angry',
    'anxious',
    'stressed',
    'calm',
    'joy',
    'neutral',
    'lonely',
    'tired'
  ];

  static Future<List<RecommendationItem>> getPersonalizedRecommendations({
    int lookbackDays = 14,
    int maxItems = 6,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    final diaries = await DiaryService.listRecent(user.id, days: lookbackDays);
    final moods = await MoodService.listEntries(user.id);

    // Prepare compact JSON context for Gemini
    final recentDiaries = diaries.take(15).map((d) {
      final previewLen = math.min(d.content.length, 120);
      return {
        'date': d.createdAt.toIso8601String(),
        'emotion': d.moodLabel,
        'sentiment': d.sentimentScore,
        'summary': d.aiSummary ?? d.content.substring(0, previewLen),
      };
    });

    final recentMoods = moods.take(15).map((m) => {
          'date': m.createdAt.toIso8601String(),
          'emotion': m.mood,
          'score': m.moodScore,
          'note': m.note,
          'triggers': m.triggers,
        });

    final prompt = '''
You are a supportive wellbeing assistant. Review the user's recent moods and diary summaries, then return concise personalized self-help resources.
Rules:
- Use emotion labels only from: ${_emotionSet.map((e) => '"$e"').join(', ')}
- Output STRICT JSON only: {"items": [{"title": string, "subtitle": string, "category": "article"|"tip"|"guide", "reason": string}]}
- Keep titles practical and positive; subtitles short.
- Ground recommendations in the patterns you see (use "reason").
- Limit to $maxItems items.

RecentDiaries: ${jsonEncode(recentDiaries.toList())}
RecentMoods: ${jsonEncode(recentMoods.toList())}
''';

    final resp = await GeminiService.getResponse(
        prompt, 'Personalized self-help recommendations JSON only');
    try {
      final cleaned =
          resp.trim().replaceAll('```json', '').replaceAll('```', '');
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      final items = (map['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return items.map((e) => RecommendationItem.fromJson(e)).toList();
    } catch (_) {
      // Fallback minimal suggestions
      return [
        RecommendationItem(
          title: '5-minute grounding routine',
          subtitle: 'Quick reset using senses when feeling anxious.',
          category: 'tip',
          reason: 'General support when anxiety or stress peaks.',
        ),
      ];
    }
  }
}
