import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String> getResponse(
    String userInput, 
    String systemContext,
    {String language = 'en'}
  ) async {
    try {
      // Correctly format the URL with the API key
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      // Add language instruction if not English
      String languageInstruction = "";
      if (language != "en") {
        languageInstruction = "Respond in language code: $language. ";
      }
      
      final payload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": "$systemContext\n\n${languageInstruction}User input: $userInput"
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 32,
          "topP": 0.95,
          "maxOutputTokens": 800,
        }
      };
      
      // Print the URL for debugging (remove in production)
      print("Calling Gemini API at: ${url.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN')}");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to get response: ${response.body}');
      }
    } catch (e) {
      // Fallback for testing when API fails
      print('Error calling API: $e');
      return "This is a fallback response as the API call failed. Error: $e";
    }
  }
}