import 'package:mantramind/models/diary_entry.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class DiaryService {
  static const _uuid = Uuid();

  static Future<List<DiaryEntry>> listEntries(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching diary entries: $e');
      return [];
    }
  }

  static Future<List<DiaryEntry>> listRecent(String userId,
      {int days = 14}) async {
    try {
      final response = await SupabaseService.client
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .gte('created_at',
              DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('created_at', ascending: false);
      return (response as List).map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching recent diary entries: $e');
      return [];
    }
  }

  static Future<DiaryEntry?> createEntry({
    required String userId,
    required String content,
    double? sentimentScore,
    String? moodLabel,
    String? aiSummary,
  }) async {
    try {
      final id = _uuid.v4();
      final payload = {
        'id': id,
        'user_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'sentiment_score': sentimentScore,
        'mood_label': moodLabel, // store emotion like "happy", "sad"
        'ai_summary': aiSummary,
      };
      final response = await SupabaseService.client
          .from('diary_entries')
          .insert(payload)
          .select()
          .single();
      return DiaryEntry.fromJson(response);
    } catch (e) {
      print('Error creating diary entry: $e');
      return null;
    }
  }
}
