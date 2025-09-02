import 'package:mantramind/models/mood_entry.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class MoodService {
  static const _uuid = Uuid();

  static Future<List<MoodEntry>> listEntries(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => MoodEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching mood entries: $e');
      return [];
    }
  }

  static Future<MoodEntry?> createEntry({
    required String userId,
    required String mood,
    required int moodScore,
    String? note,
    String? triggers,
    String? aiInsight,
  }) async {
    try {
      final id = _uuid.v4();
      final payload = {
        'id': id,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'mood': mood,
        'mood_score': moodScore,
        'note': note,
        'triggers': triggers,
        'ai_insight': aiInsight,
      };
      final response = await SupabaseService.client
          .from('mood_entries')
          .insert(payload)
          .select()
          .single();
      return MoodEntry.fromJson(response);
    } catch (e) {
      print('Error creating mood entry: $e');
      return null;
    }
  }
}
