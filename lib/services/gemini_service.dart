import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Fixed: Using the most recent and correct endpoint
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  static Future<String> getResponse(String userInput, String context) async {

     final therapistContext = """
You are MantraMind AI, a compassionate mental health assistant trained to provide supportive, evidence-based guidance. Your goal is to help users manage their mental health conditions through empathetic conversation and practical advice. Focus on:
  
1. Providing emotional support and validation
2. Suggesting evidence-based coping strategies
3. Encouraging healthy habits and routines
4. Reminding users of their strengths and progress
5. Suggesting when professional help may be beneficial
  
$context
  
Be concise and warm in your responses. Do not diagnose conditions or replace professional mental healthcare. If the user mentions serious issues like self-harm or suicide, urgently but calmly recommend seeking immediate professional help.
""";

    final url = '$_baseUrl?key=$_apiKey';
    
    final payload = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": "$context\n\nUser's latest response: $userInput\n\nYour next response:"
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
        "stopSequences": []
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_ONLY_HIGH"
        }
      ]
    };
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? 'No response from AI';
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get response from Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      throw Exception('Failed to communicate with Gemini: $e');
    }
  }
  
  // Method to list available models - useful for debugging
  static Future<List<String>> listModels() async {
    final url = 'https://generativelanguage.googleapis.com/v1/models?key=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final models = (jsonResponse['models'] as List)
            .map((model) => model['name'] as String)
            .toList();
        return models;
      } else {
        print('Error listing models: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error listing models: $e');
      return [];
    }
  }
}