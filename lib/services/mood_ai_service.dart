import 'dart:convert';
import 'package:mantramind/services/gemini_service.dart';

class MoodAIService {
  static Future<Map<String, dynamic>> analyzeDiary(String text) async {
    final prompt = """
You are a supportive mental health assistant. Analyze the user's diary text for:
- sentiment_score from -1.0 (very negative) to 1.0 (very positive)
- mood_emotion from this set ONLY: ["happy","sad","angry","anxious","stressed","calm","joy","neutral","lonely","tired"]
- a short empathetic summary (max 2-3 sentences)
Return ONLY a JSON object with keys: sentiment_score, mood_emotion, summary.
Text:
$text
""";
    final res = await GeminiService.getResponse(
        prompt, "Analyze diary entry and return JSON only");

    try {
      final cleaned =
          res.trim().replaceAll("```json", "").replaceAll("```", "");
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return map;
    } catch (_) {
      return {
        'sentiment_score': 0.0,
        'mood_emotion': 'neutral',
        'summary': res,
      };
    }
  }

  static Future<String> generateMoodInsight({
    required String mood,
    required int moodScore,
    String? note,
    String? triggers,
  }) async {
    final prompt = """
You're a brief and compassionate coach. Given mood data, provide one short personalized insight and one actionable tip (max 2 sentences total).
Use emotion labels like happy, sad, anxious, calm—not high/low.
Data:
- emotion: $mood
- intensity: $moodScore (1-5)
- note: ${note ?? ""}
- triggers: ${triggers ?? ""}
""";
    final res = await GeminiService.getResponse(
        prompt, "Generate concise mood insight");
    return res.trim();
  }
}
