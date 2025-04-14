import 'package:flutter/material.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/gemini_service.dart';
import 'package:mantramind/services/sarvam_service.dart';
import 'package:mantramind/services/speech_to_text_service.dart';
import 'package:mantramind/models/assessment_result.dart';
import 'package:mantramind/screens/assessment/assessment_result_screen.dart';

class AIAssessmentScreen extends StatefulWidget {
  const AIAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AIAssessmentScreen> createState() => _AIAssessmentScreenState();
}

class _AIAssessmentScreenState extends State<AIAssessmentScreen> {
  final TextEditingController _userInputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _selectedLanguage = 'English'; // Default language
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  bool _speechEnabled = false;
  bool _assessmentInProgress = false;
  final ScrollController _scrollController = ScrollController();
  
  final List<String> _availableLanguages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Marathi',
    'Gujarati',
    'Punjabi',
    'Odia',
    'Assamese',
    'Urdu'
  ];

  // UI strings that will change based on language
  Map<String, String> _uiStrings = {
    'typingHint': 'Type your response...',
    'listeningHint': 'Listening...',
    'sendButton': 'Send',
    'changeLanguage': 'Change Language',
    'selectLanguage': 'Select Language',
    'aiTyping': 'AI is typing...',
    'errorMessage': 'Sorry, there was an error. Please try again.'
  };

  @override
  void initState() {
    super.initState();
    _initSpeechRecognition();
    _updateUIStrings();
    
    // Test translation functionality
    _testTranslation().then((_) {
      // Start assessment after testing
      _startAssessment();
    });
    
    // Listen for speech recognition results
    _speechToTextService.textStream.listen((recognizedText) {
      if (recognizedText.isNotEmpty) {
        _userInputController.text = recognizedText;
        // Auto submit after receiving speech input
        _handleUserInput(recognizedText);
      }
    });
  }

  Future<void> _testTranslation() async {
    if (_selectedLanguage == 'English') {
      // No translation needed for English
      return;
    }
    
    try {
      // Test a simple translation to verify the service is working
      final testResult = await SarvamService.translateText(
        inputText: 'Hello, how are you?',
        sourceLanguage: 'English',
        targetLanguage: _selectedLanguage,
      );
      
      print('Translation test result: $testResult');
      
      if (testResult.isEmpty) {
        print('WARNING: Translation test returned empty result');
      }
    } catch (e) {
      print('Translation service test failed: $e');
      // Don't throw the error, just log it - we'll still try to start the assessment
    }
  }

  void _updateUIStrings() async {
    if (_selectedLanguage == 'English') {
      setState(() {
        _uiStrings = {
          'typingHint': 'Type your response...',
          'listeningHint': 'Listening...',
          'sendButton': 'Send',
          'changeLanguage': 'Change Language',
          'selectLanguage': 'Select Language',
          'aiTyping': 'AI is typing...',
          'errorMessage': 'Sorry, there was an error. Please try again.'
        };
      });
      return;
    }
    
    // Translate UI strings to selected language
    try {
      Map<String, String> translatedStrings = Map.from(_uiStrings);
      
      for (var key in _uiStrings.keys) {
        translatedStrings[key] = await SarvamService.translateText(
         inputText:  _uiStrings[key]!,
         sourceLanguage:  'English',
         targetLanguage:  _selectedLanguage,
        );
      }
      
      if (mounted) {
        setState(() {
          _uiStrings = translatedStrings;
        });
      }
    } catch (e) {
      print('Error translating UI strings: $e');
    }
  }

  Future<void> _initSpeechRecognition() async {
    _speechEnabled = await _speechToTextService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _userInputController.dispose();
    _speechToTextService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startAssessment() async {
    setState(() {
      _isTyping = true;
      _assessmentInProgress = true;
    });

    try {
      final initialPrompt = await _getInitialPrompt();
      print("Original prompt: $initialPrompt"); // Debug
      
      // For English, use the prompt directly
      if (_selectedLanguage == 'English') {
        setState(() {
          _messages.add(ChatMessage(
            text: initialPrompt,
            isUser: false,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        return;
      }
      
      print("Translating to: $_selectedLanguage"); // Debug
      
      // Translate prompt to user's selected language
      final translatedPrompt = await SarvamService.translateText(
        inputText: initialPrompt,
        sourceLanguage: 'English',
        targetLanguage: _selectedLanguage,
      );
      
      print("Translated prompt: $translatedPrompt"); // Debug
      
      // Verify that the translated text is different from the original
      if (translatedPrompt == initialPrompt) {
        print("WARNING: Translation returned same text as original!"); // Debug
      }

      setState(() {
        _messages.add(ChatMessage(
          text: translatedPrompt,
          isUser: false,
          originalText: initialPrompt, // Store original English text for context building
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      print("Translation error details: $e"); // Debug
      _handleError('Failed to start assessment: $e');
    }
  }

  Future<String> _getInitialPrompt() async {
    return """
I'm going to ask you a series of questions to assess your mental health. 
Please answer honestly as this will help me understand your symptoms better.

Let's start with a general question:
How have you been feeling emotionally over the past two weeks?
    """;
  }

Future<void> _handleUserInput(String userInput) async {
  if (userInput.trim().isEmpty) return;

  // Add user message to chat
  setState(() {
    _messages.add(ChatMessage(
      text: userInput,
      isUser: true,
    ));
    _isTyping = true;
    _userInputController.clear();
  });
  _scrollToBottom();

  try {
    // Step 1: Translate user input to English for processing (if needed)
    String translatedUserInput = userInput;
    if (_selectedLanguage != 'English') {
      print("Translating user input from $_selectedLanguage to English");
      translatedUserInput = await SarvamService.translateText(
        inputText: userInput,
        sourceLanguage: _selectedLanguage,
        targetLanguage: 'English',
      );
      print("Translated user input: $translatedUserInput");
    }

    // Step 2: Process with Gemini (in English)
    final assessmentContext = _buildAssessmentContext();
    print("Sending to Gemini: $translatedUserInput");
    String aiResponse = await GeminiService.getResponse(
      translatedUserInput, 
      assessmentContext,
    );
    print("Received from Gemini: ${aiResponse.substring(0, min(50, aiResponse.length))}...");

    // Check if assessment is complete
    if (_isAssessmentComplete(aiResponse)) {
      await _showAssessmentResult(aiResponse);
      return;
    }

    // Step 3: Store original response and prepare for translation
    final originalAiResponse = aiResponse;
    String displayResponse = aiResponse;
    
    // Step 4: Translate AI response to user's language if needed
    if (_selectedLanguage != 'English') {
      print("Translating AI response to $_selectedLanguage");
      displayResponse = await SarvamService.translateAIResponse(
        englishResponse: originalAiResponse,
        targetLanguage: _selectedLanguage,
      );
      
      print("Original AI response (first 50 chars): ${originalAiResponse.substring(0, min(50, originalAiResponse.length))}...");
      print("Translated AI response (first 50 chars): ${displayResponse.substring(0, min(50, displayResponse.length))}...");
      
      // Verify translation actually happened
      if (displayResponse == originalAiResponse) {
        print("WARNING: Translation failed - response unchanged");
      }
    }

    // Step 5: Add the (translated) AI response to chat
    setState(() {
      _messages.add(ChatMessage(
        text: displayResponse,
        isUser: false,
        originalText: originalAiResponse, // Store original English text for context
      ));
      _isTyping = false;
    });
    _scrollToBottom();
  } catch (e) {
    print("Error in handleUserInput: $e");
    _handleError('Error processing your response: $e');
  }
}

// Add this helper function
int min(int a, int b) => a < b ? a : b;

  String _buildAssessmentContext() {
    // Build the conversation history for context
    String conversationHistory = '';
    
    // Include all messages in their ORIGINAL ENGLISH form for Gemini to process
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final role = message.isUser ? 'USER' : 'ASSISTANT';
      
      // For accurate context, we MUST use the original English content
      // This is critical - we need to use the original English text, not the translated version
      String messageText = message.originalText ?? message.text;
      conversationHistory += '$role: $messageText\n';
    }

    // Additional hint about the language
    String languageContext = _selectedLanguage != 'English' 
        ? "NOTE: The user is communicating in $_selectedLanguage and their messages have been translated to English for you. Your responses will be translated to $_selectedLanguage before being shown to the user. Please phrase your questions and responses in a way that will translate naturally to $_selectedLanguage.\n\n"
        : "";

    // Instructions for the AI model
    return '''
You are an AI mental health assessment assistant. Your task is to conduct a diagnostic assessment to determine if the user might have symptoms related to common mental health disorders like anxiety, depression, ADHD, OCD, PTSD, or bipolar disorder.

$languageContext
Ask questions one at a time, and analyze the user's responses to guide the conversation. Be empathetic and professional. Don't provide a diagnosis until you've asked at least 8-10 comprehensive questions.

If the user's responses indicate no significant mental health concerns, you should acknowledge that. Never jump to conclusions or diagnose someone based on limited information.

Conversation history so far:
$conversationHistory

After gathering sufficient information, provide a summary of potential conditions the user's symptoms might align with, emphasizing that this is not a clinical diagnosis and they should consult a mental health professional for a proper evaluation.

When you have gathered enough information and are ready to provide a preliminary assessment, begin your final response with "ASSESSMENT_COMPLETE:" followed by your analysis.
''';
  }

  bool _isAssessmentComplete(String response) {
    return response.contains('ASSESSMENT_COMPLETE:');
  }

  Future<void> _showAssessmentResult(String response) async {
  // Extract the assessment part
  final assessmentText = response.split('ASSESSMENT_COMPLETE:')[1].trim();
  
  String translatedAssessment = assessmentText;
  
  // Translate the assessment if not in English
  if (_selectedLanguage != 'English') {
    print("Translating final assessment to $_selectedLanguage");
    translatedAssessment = await SarvamService.translateAIResponse(
      englishResponse: assessmentText,
      targetLanguage: _selectedLanguage,
    );
    
    print("Original assessment (first 50 chars): ${assessmentText.substring(0, min(50, assessmentText.length))}...");
    print("Translated assessment (first 50 chars): ${translatedAssessment.substring(0, min(50, translatedAssessment.length))}...");
  }
  
  // Parse the assessment to determine main potential condition
  final result = AssessmentResult(
    rawAssessment: assessmentText,
    translatedAssessment: _selectedLanguage != 'English' ? translatedAssessment : null,
    mainCondition: _parseMainCondition(assessmentText),
    recommendedActions: _parseRecommendedActions(assessmentText),
    date: DateTime.now(),
  );

  // Save the assessment result to Supabase
  await _saveAssessmentResult(result);

  // Navigate to result screen
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentResultScreen(
          result: result,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
  }
}

  String _parseMainCondition(String assessmentText) {
    // This is a simplified approach - you would want more sophisticated parsing
    // based on the structure of Gemini's responses
    final conditions = [
      'Anxiety',
      'Depression',
      'ADHD',
      'OCD',
      'PTSD',
      'Bipolar Disorder',
      'No significant mental health concerns'
    ];
    
    for (var condition in conditions) {
      if (assessmentText.contains(condition)) {
        return condition;
      }
    }
    
    return 'Inconclusive';
  }

  List<String> _parseRecommendedActions(String assessmentText) {
    // Default recommendations - in a real app, you'd parse these from the AI response
    return [
      'Consult with a mental health professional for a proper diagnosis',
      'Practice self-care and stress management techniques',
      'Track your symptoms and mood over time'
    ];
  }

  Future<void> _saveAssessmentResult(AssessmentResult result) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        await SupabaseService.client.from('assessment_results').insert({
          'user_id': currentUser.id,
          'main_condition': result.mainCondition,
          'raw_assessment': result.rawAssessment,
          'translated_assessment': result.translatedAssessment,
          'language': _selectedLanguage,
          'date': result.date.toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving assessment result: $e');
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: _uiStrings['errorMessage'] ?? 'Sorry, there was an error. Please try again.',
        isUser: false,
      ));
    });
    _scrollToBottom();
    print(errorMessage);
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_uiStrings['selectLanguage'] ?? 'Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableLanguages.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedLanguage == _availableLanguages[index];
              return Card(
                elevation: isSelected ? 3 : 1,
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: ListTile(
                  leading: isSelected 
                    ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                    : Icon(Icons.language),
                  title: Text(_availableLanguages[index]),
                  onTap: () {
                    Navigator.pop(context);
                    
                    // Only restart if language changed
                    if (_selectedLanguage != _availableLanguages[index]) {
                      setState(() {
                        _selectedLanguage = _availableLanguages[index];
                        _messages.clear();
                      });
                      _updateUIStrings();
                      _startAssessment();
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleListening() async {
    if (_speechToTextService.isListening) {
      _speechToTextService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      await _speechToTextService.startListening(
        selectedLanguage: _selectedLanguage,
        onListeningStarted: () {
          setState(() {
            _isListening = true;
          });
        },
        onListeningFinished: () {
          setState(() {
            _isListening = false;
          });
        },
      );
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Mental Health Assessment'),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Enhanced Language selector banner
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.translate, 
                        color: Theme.of(context).primaryColor),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Language', 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SizedBox(height: 2),
                          Text(_selectedLanguage, 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: _changeLanguage,
                        icon: Icon(Icons.language, size: 18),
                        label: Text('Change'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rest of your UI (chat messages, etc.)
                Expanded(
                  child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 64, color: Colors.blue.shade300),
                          SizedBox(height: 16),
                          Text('Starting assessment...', style: TextStyle(fontSize: 16)),
                          if (_isTyping)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                ),
                
                // AI typing indicator
                if (_isTyping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          _uiStrings['aiTyping'] ?? 'AI is typing...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Input area
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Microphone button for speech input
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening 
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening 
                  ? Colors.red 
                  : (_speechEnabled ? Theme.of(context).primaryColor : Colors.grey),
                size: 28,
              ),
              onPressed: _speechEnabled ? _toggleListening : null,
              tooltip: _speechEnabled 
                  ? (_isListening ? 'Stop listening' : 'Start speaking') 
                  : 'Speech recognition unavailable',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                color: Colors.grey[100],
                border: Border.all(
                  color: _isListening ? Colors.red.withOpacity(0.5) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _userInputController,
                decoration: InputDecoration(
                  hintText: _isListening 
                      ? '${_uiStrings['listeningHint'] ?? 'Listening...'} ($_selectedLanguage)' 
                      : _uiStrings['typingHint'] ?? 'Type your response...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  suffixIcon: _userInputController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _userInputController.clear();
                          });
                        },
                      )
                    : null,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _handleUserInput,
                enabled: !_isListening && !_isTyping, // Disable while listening or AI is typing
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withBlue(255)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: (_userInputController.text.isNotEmpty && !_isTyping) 
                ? () => _handleUserInput(_userInputController.text)
                : null,
              disabledColor: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? originalText; // Store original English text for translation context

  ChatMessage({
    required this.text, 
    required this.isUser, 
    this.originalText,
  });
}