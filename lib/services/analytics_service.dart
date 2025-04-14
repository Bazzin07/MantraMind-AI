import 'package:mantramind/models/chat_message.dart';
import 'package:mantramind/services/supabase_service.dart';

class AnalyticsService {
  // Save chat message to database
  static Future<void> saveChatMessage(ChatMessage message, String userId, String disorder) async {
    try {
      await SupabaseService.client.from('chat_history').insert({  // Changed from supabase to client
        'user_id': userId,
        'is_user': message.isUser,
        'message': message.text,
        'timestamp': message.timestamp.toIso8601String(),
        'disorder': disorder,
      });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }
  
  // Analyze sentiment from messages
  static Future<Map<String, dynamic>> analyzeSentiment(List<ChatMessage> userMessages) async {
    // In a real implementation, you'd use an ML model or API for this
    // For now, we'll use a simple keyword-based approach
    
    final positiveKeywords = ['good', 'better', 'happy', 'positive', 'hopeful'];
    final negativeKeywords = ['bad', 'worse', 'sad', 'negative', 'hopeless'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (var message in userMessages) {
      if (!message.isUser) continue;
      
      final lowerText = message.text.toLowerCase();
      
      for (var keyword in positiveKeywords) {
        if (lowerText.contains(keyword)) positiveCount++;
      }
      
      for (var keyword in negativeKeywords) {
        if (lowerText.contains(keyword)) negativeCount++;
      }
    }
    
    double sentimentScore = 0;
    if (positiveCount + negativeCount > 0) {
      sentimentScore = (positiveCount - negativeCount) / (positiveCount + negativeCount);
    }
    
    return {
      'sentiment_score': sentimentScore,
      'positive_count': positiveCount,
      'negative_count': negativeCount,
    };
  }
  
  // Track topics discussed
  static List<String> extractTopics(List<ChatMessage> messages) {
    // Simple implementation for now
    final mentalHealthTopics = {
      'anxiety': ['anxiety', 'anxious', 'panic', 'worry'],
      'depression': ['depression', 'depressed', 'sad', 'hopeless'],
      'sleep': ['sleep', 'insomnia', 'tired', 'rest'],
      'stress': ['stress', 'stressed', 'overwhelmed', 'pressure'],
      'mindfulness': ['mindful', 'meditation', 'breathing', 'present'],
    };
    
    final topicsDiscussed = <String>{};
    
    for (var message in messages) {
      final lowerText = message.text.toLowerCase();
      
      mentalHealthTopics.forEach((topic, keywords) {
        for (var keyword in keywords) {
          if (lowerText.contains(keyword)) {
            topicsDiscussed.add(topic);
            break;
          }
        }
      });
    }
    
    return topicsDiscussed.toList();
  }
}