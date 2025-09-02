import 'package:mantramind/models/user_task.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TaskService {
  static const _uuid = Uuid();
  
  static Future<List<UserTask>> getUserTasks(String userId, String disorder) async {
    try {
      final response = await SupabaseService.client  // Changed from supabase to client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('disorder_type', disorder)
          .order('created_at', ascending: false);
      
      return (response as List).map((task) => UserTask.fromJson(task)).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }
  
  static Future<void> createTask(String userId, String title, String description, String category, String disorder) async {
    try {
      final taskId = _uuid.v4();
      
      await SupabaseService.client.from('tasks').insert({  // Changed from supabase to client
        'id': taskId,
        'user_id': userId,
        'title': title,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': null,
        'category': category,
        'disorder_type': disorder,
      });
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }
  
  static Future<void> completeTask(String taskId) async {
    try {
      await SupabaseService.client.from('tasks').update({  // Changed from supabase to client
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (e) {
      print('Error completing task: $e');
      rethrow;
    }
  }
  
  // Extract tasks from AI responses
  static List<Map<String, String>> extractTaskSuggestions(String aiResponse) {
    // This is a simple implementation - in a real app, you might use 
    // structured outputs from the AI or more sophisticated NLP
    final suggestions = <Map<String, String>>[];
    
    // Look for tasks framed as suggestions
    final lines = aiResponse.split('\n');
    for (var line in lines) {
      if (line.contains('try to') || 
          line.contains('consider') || 
          line.contains('could') || 
          line.startsWith('- ')) {
        
        // Basic task extraction
        final title = line.replaceAll(RegExp(r'^- |^\d+\. '), '').trim();
        if (title.isNotEmpty) {
          suggestions.add({
            'title': title,
            'description': '',
          });
        }
      }
    }
    
    return suggestions;
  }
}