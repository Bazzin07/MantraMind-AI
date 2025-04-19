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
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      // Enhanced language handling 
      String languageInstruction = "";
      if (language != "en") {
        // Much stronger instruction to ensure proper language output
        languageInstruction = "IMPORTANT: You MUST respond in '$language' language ONLY. DO NOT use English.\n\n";
      }
      
      final payload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": "$languageInstruction$systemContext\n\nUser input: $userInput"
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 32,
          "topP": 0.95,
          "maxOutputTokens": 800,
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      };
      
      // Print URL for debugging (hide API key)
      print("Calling Gemini API with language: $language");
      
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
          
          // If non-English requested, verify it's not returning English
          if (language != "en" && _containsTooMuchEnglish(generatedText)) {
            if (retryCount < maxRetries) {
              print("Detected English in non-English response. Retrying...");
              retryCount++;
              
              // Strengthen the language instruction for retry
              languageInstruction = """
CRITICAL INSTRUCTION: You MUST respond ONLY in the '$language' language.
DO NOT respond in English under any circumstances.
If you respond in English, it will be rejected.

""";
              
              // Update the payload with stronger instruction
              (payload["contents"] as List)[0]["parts"][0]["text"] = 
                  "$languageInstruction$systemContext\n\nUser input: $userInput";
                  
              // Add short delay before retry
              await Future.delayed(Duration(milliseconds: 500));
              continue;
            } else {
              // If still getting English after retries, try one last approach - explicit translation
              print("Still receiving English after $maxRetries retries. Attempting translation approach.");
              
              final translationPrompt = """
TRANSLATE THE FOLLOWING TEXT TO $language LANGUAGE:

$generatedText
""";
              
              // Create a new payload for translation
              final translationPayload = {
                "contents": [
                  {
                    "role": "user",
                    "parts": [
                      {
                        "text": translationPrompt
                      }
                    ]
                  }
                ],
                "generationConfig": {
                  "temperature": 0.2,  // Lower temperature for translation
                  "maxOutputTokens": 800,
                }
              };
              
              final translationResponse = await http.post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(translationPayload),
              );
              
              if (translationResponse.statusCode == 200) {
                final translationData = jsonDecode(translationResponse.body);
                return translationData['candidates'][0]['content']['parts'][0]['text'];
              } else {
                // If translation fails, return original with a note
                return generatedText + "\n\n(Note: Apologies, but I had difficulty responding in your selected language)";
              }
            }
          }
          
          return generatedText;
        } else if (response.statusCode == 429 && retryCount < maxRetries) {
          // Handle rate limiting
          print("Rate limited (429). Retrying in 1 second...");
          retryCount++;
          await Future.delayed(Duration(seconds: 1));
          continue;
        } else {
          print("API Error: ${response.statusCode} - ${response.body}");
          throw Exception('Failed to get response: ${response.body}');
        }
      }
      
      throw Exception('Failed after multiple retry attempts');
    } catch (e) {
      print('Error calling API: $e');
      if (language != 'en') {
        // For non-English requests, provide error message in both English and likely translation
        return "There was an error processing your request. Please try again.\n\n(If you're seeing this message, there was a problem with the language service)";
      }
      return "There was an error processing your request. Please try again.";
    }
  }

  // Helper method to detect if response contains too much English when it shouldn't
  static bool _containsTooMuchEnglish(String text) {
    // Common English words/phrases that shouldn't appear in non-English text
    final englishIndicators = [
      ' the ', ' and ', ' is ', ' are ', ' to ', ' you ', ' for ', ' have ',
      ' this ', ' with ', ' your ', 'mental health', ' feel ', ' what ',
      'how are you', 'I understand', 'please tell me'
    ];
    
    // Count matches
    int matches = 0;
    for (final indicator in englishIndicators) {
      if (text.toLowerCase().contains(indicator.toLowerCase())) {
        matches++;
      }
    }
    
    // If many English indicators are found, it's likely still in English
    return matches > 3;
  }
}