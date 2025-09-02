import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SarvamService {
  static String? apiKey;
  static const String _baseUrl = 'https://api.sarvam.ai/translate';

  // Updated language code format with required -IN suffix
  static const Map<String, String> _languageToCode = {
    'English': 'en-IN',
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Bengali': 'bn-IN',
    'Marathi': 'mr-IN',
    'Gujarati': 'gu-IN',
    'Punjabi': 'pa-IN',
    'Odia': 'od-IN',
    'Assamese': 'as-IN',
    'Urdu': 'ur-IN',
    'auto': 'auto',
  };

  // Valid output script options according to API error message
  static const List<String> _validOutputScripts = [
    'roman',
    'fully-native',
    'spoken-form-in-native'
  ];

  static void initialize() {
    apiKey = dotenv.env['SARVAM_API_KEY'];
    print('Loaded Sarvam API key: ${apiKey?.substring(0, 5)}...');

    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('Sarvam API key not found in environment variables');
    }
  }

  static Future<String> translateText({
    required String inputText,
    required String sourceLanguage,
    required String targetLanguage,
    int retryCount = 2,
  }) async {
    // Check for same language - no need to translate
    if (sourceLanguage == targetLanguage) {
      return inputText;
    }

    // Check for empty text to prevent API errors
    if (inputText.trim().isEmpty) {
      print('Warning: Empty text provided for translation');
      return inputText;
    }

    // Convert language names to language codes expected by the API
    final sourceCode = _languageToCode[sourceLanguage] ?? 'auto';
    final targetCode = _languageToCode[targetLanguage] ?? 'en-IN';

    print('Translation request: $sourceLanguage ($sourceCode) -> $targetLanguage ($targetCode)');

    // Debug: Print first part of the text to be translated
    final previewText = inputText.length > 50 ? '${inputText.substring(0, 50)}...' : inputText;
    print('Text to translate (preview): $previewText');

    // Modified API payload with correct output_script options
    final payload = {
      "input": inputText,
      "source_language_code": sourceCode,
      "target_language_code": targetCode,
      "speaker_gender": "Female",
      "mode": "formal",
      "model": "mayura:v1",
      "enable_preprocessing": true,
      "output_script": "fully-native", // Using a valid option
      "numerals_format": "international"
    };

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        if (attempt > 0) {
          print('Retry attempt $attempt for translation');
          // Add a delay between retries
          await Future.delayed(Duration(milliseconds: 800 * attempt));
          
          // On retries, try different output script formats
          if (attempt <= _validOutputScripts.length) {
            payload["output_script"] = _validOutputScripts[attempt - 1];
            print('Trying with output_script: ${payload["output_script"]}');
          }
        }

        print('Sending translation request to API...');
        final headers = {
          'Content-Type': 'application/json',
          'API-Subscription-Key': apiKey!,
        };

        final url = Uri.parse(_baseUrl);
        
        // Print the exact payload being sent (for debugging)
        if (attempt == 0) {
          print('Sending payload: ${jsonEncode(payload)}');
        }
        
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(payload),
        );

        print('API response status: ${response.statusCode}');
        print('API response body: ${response.body}');

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final translated = result['output'] ?? inputText;

          // Debug: Print a preview of the translation result
          final translatedPreview = translated.length > 50 ? '${translated.substring(0, 50)}...' : translated;
          print('Translation result (preview): $translatedPreview');

          // Better validation of translation result
          if (translated.trim().isEmpty) {
            print('Warning: Translation returned empty text');
            if (attempt < retryCount) continue;
          } else if (translated == inputText) {
            // For languages with different scripts, this equality check might not be enough
            // Let's check if at least the characters are different
            bool sameScript = true;
            
            // Very basic check: if the first 10 characters contain at least one character different
            // from ASCII, we assume it's a different script
            for (int i = 0; i < min(translated.length, 10); i++) {
              if (translated.codeUnitAt(i) > 127) {
                sameScript = false;
                break;
              }
            }
            
            if (sameScript) {
              print('Warning: Translation appears to be unchanged from source');
              if (attempt < retryCount) {
                // Try with a different valid output script on retry
                int scriptIndex = (attempt + 1) % _validOutputScripts.length;
                payload["output_script"] = _validOutputScripts[scriptIndex];
                continue;
              }
            }
          }

          print('Translation successful');
          return translated;
        } else {
          print('Translation API error: ${response.statusCode} - ${response.body}');
          
          // For 400 errors, try to parse and print the detailed error
          if (response.statusCode == 400) {
            try {
              final errorBody = jsonDecode(response.body);
              print('Detailed error: ${errorBody['error']['message']}');
              
              // If the error is about output_script, fix it for the next attempt
              if (errorBody['error']['message'].toString().contains('output_script')) {
                // Use 'roman' as a fallback since it's mentioned in the error message
                payload["output_script"] = "roman";
                print('Changing output_script to "roman" for next attempt');
              }
              
              // If the error is about language codes, try to fix it
              if (errorBody['error']['message'].toString().contains('language_code')) {
                // If we get here on a retry, try auto detection for source
                if (attempt > 0 && sourceCode != 'auto') {
                  payload["source_language_code"] = "auto";
                  print('Changing source_language_code to "auto" for next attempt');
                }
              }
            } catch (e) {
              print('Could not parse error body: $e');
            }
          }
          
          if (attempt < retryCount) continue;
          return inputText;
        }
      } catch (e) {
        print('Translation error: $e');
        if (attempt < retryCount) continue;
        return inputText;
      }
    }

    return inputText; // Fallback
  }

  static Future<String> translateAIResponse({
    required String englishResponse,
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'English') {
      return englishResponse;
    }
    
    try {
      // For longer responses, break them into paragraphs and translate each
      if (englishResponse.length > 500) {
        print('Breaking long response into paragraphs for translation');
        
        // Split by paragraphs (double newline)
        final paragraphs = englishResponse.split('\n\n');
        final translatedParagraphs = <String>[];
        
        for (var i = 0; i < paragraphs.length; i++) {
          final paragraph = paragraphs[i].trim();
          if (paragraph.isEmpty) continue;
          
          print('Translating paragraph ${i+1}/${paragraphs.length}');
          final translatedParagraph = await translateText(
            inputText: paragraph,
            sourceLanguage: 'English',
            targetLanguage: targetLanguage,
          );
          
          translatedParagraphs.add(translatedParagraph);
          
          // Add a small delay between paragraph translations to avoid rate limiting
          if (i < paragraphs.length - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        
        return translatedParagraphs.join('\n\n');
      } else {
        // For shorter responses, translate directly
        return await translateText(
          inputText: englishResponse,
          sourceLanguage: 'English',
          targetLanguage: targetLanguage,
        );
      }
    } catch (e) {
      print("AI translation error: $e");
      return englishResponse; // Fallback to English on error
    }
  }

  // Helper function to get min of two integers
  static int min(int a, int b) => a < b ? a : b;
  
  // Enhanced API connection test with detailed logging
  static Future<bool> testApiConnection() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'API-Subscription-Key': apiKey!,
      };
      
      // Create a test payload with all valid output script options and correct language codes
      final payloads = _validOutputScripts.map((script) => {
        "input": "Hello, how are you?",
        "source_language_code": "en-IN",
        "target_language_code": "hi-IN",
        "speaker_gender": "Female",
        "mode": "formal",
        "model": "mayura:v1",
        "enable_preprocessing": true,
        "output_script": script,
        "numerals_format": "international"
      }).toList();
      
      print('Testing API connection with multiple output script options...');
      final url = Uri.parse(_baseUrl);
      
      bool anySuccess = false;
      Map<String, dynamic> successfulPayload = {};
      
      for (var payload in payloads) {
        print('Trying with output_script: ${payload["output_script"]}');
        
        final response = await http.post(
          url, 
          headers: headers,
          body: jsonEncode(payload),
        );
        
        print('Test API connection status: ${response.statusCode}');
        print('Test API response: ${response.body}');
        
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final translated = result['output'] ?? '';
          
          print('Translation result: $translated');
          
          if (translated != payload["input"] && translated.isNotEmpty) {
            print('Successful translation with output_script: ${payload["output_script"]}');
            anySuccess = true;
            successfulPayload = payload;
            break;
          }
        }
      }
      
      // If we found a working configuration, update our default
      if (anySuccess && successfulPayload.isNotEmpty) {
        print('Found working configuration: output_script=${successfulPayload["output_script"]}');
        // Here you would save this configuration for future use
      }
      
      return anySuccess;
    } catch (e) {
      print('API connection test error: $e');
      return false;
    }
  }
}