import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mantramind/services/gemini_service.dart';
import 'package:mantramind/services/speech_to_text_service.dart';
import 'package:mantramind/models/assessment_result.dart';
import 'package:mantramind/screens/assessment/assessment_result_screen.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIAssessmentScreen extends StatefulWidget {
  const AIAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AIAssessmentScreen> createState() => _AIAssessmentScreenState();
}

class _AIAssessmentScreenState extends State<AIAssessmentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _userInputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SpeechToTextService _speechService = SpeechToTextService();
  
  // UI state variables
  bool _isTyping = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _assessmentInProgress = false;
  bool _showLanguageSelector = false;
  bool _isSpeaking = false;
  int? _speakingMessageIndex;
  double _soundLevel = 0.0;
  Timer? _soundLevelTimer;
  int _assessmentStep = 0;
  late AnimationController _pulseController;
  
  // Language support
  String _selectedLanguage = 'English';
  final Map<String, String> _languageCodes = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Bengali': 'bn-IN',
    'Marathi': 'mr-IN',
    'Gujarati': 'gu-IN',
    'Punjabi': 'pa-IN',
    'Odia': 'or-IN',
    'Assamese': 'as-IN',
    'Urdu': 'ur-IN',
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Initialize speech recognition
    _initializeSpeech();
    
    // Start assessment with welcome message
    _startAssessment();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechService.initialize();
    
    // Listen for recognized text
    _speechService.textStream.listen((text) {
      setState(() {
        _userInputController.text = text;
      });
      
      // Submit text if it's a final result (not ending with ...)
      if (!text.endsWith('...') && text.isNotEmpty) {
        _handleUserInput(text);
      }
    });
    
    // Listen for listening state changes
    _speechService.listeningStream.listen((isListening) {
      setState(() {
        _isListening = isListening;
      });
    });
    
    // Listen for errors
    _speechService.errorStream.listen((error) {
      _showSnackBar("Speech recognition error: $error");
    });
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _userInputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _speechService.dispose();
    _cancelSoundLevelSimulation();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _startAssessment() async {
    setState(() {
      _isTyping = true;
      _assessmentInProgress = true;
      _assessmentStep = 1;
    });

    try {
      // Get initial prompt for assessment with explicit language instruction
      String prompt;
      
      if (_selectedLanguage == 'English') {
        prompt = """
You are MantraMind's AI mental health assessment assistant. I'd like you to conduct a brief mental health assessment by asking me a series of questions.

Please begin by introducing yourself and asking how I've been feeling emotionally over the past two weeks. Keep your responses conversational, empathetic, and concise (1-3 sentences).

As we progress, ask questions to assess common mental health conditions like anxiety, depression, ADHD, etc. Ask one question at a time.

After 8-10 questions, you will have gathered enough information to provide a preliminary, non-diagnostic assessment. When ready with your assessment, start your response with "ASSESSMENT_COMPLETE:" followed by your analysis.
""";
      } else {
        // For non-English languages, add explicit instructions to respond in that language
        prompt = """
You are MantraMind's AI mental health assessment assistant. I'd like you to conduct a brief mental health assessment by asking me a series of questions.

IMPORTANT: Please respond ONLY in ${_selectedLanguage} language throughout our entire conversation. Do NOT use English at all.

Please begin by introducing yourself in ${_selectedLanguage} and asking how I've been feeling emotionally over the past two weeks. Keep your responses conversational, empathetic, and concise (1-3 sentences).

As we progress, ask questions to assess common mental health conditions like anxiety, depression, ADHD, etc. Ask one question at a time.

After 8-10 questions, you will have gathered enough information to provide a preliminary, non-diagnostic assessment. When ready with your assessment, start your response with "ASSESSMENT_COMPLETE:" followed by your analysis.

Remember to use ONLY ${_selectedLanguage} language in all your responses.
""";
      }

      // Get response from Gemini, using improved language parameter
      final languageCode = _languageCodes[_selectedLanguage] ?? 'en-US';
      print("Starting assessment in $_selectedLanguage (language code: $languageCode)");
      
      final response = await GeminiService.getResponse(
        prompt, 
        "You are a mental health assessment assistant responding in $_selectedLanguage",
        language: _selectedLanguage != 'English' ? languageCode.split('-')[0] : 'en',
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            step: 1,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error starting assessment: $e");
      _handleError("Couldn't start assessment. Please check your internet connection and try again.");
    }
  }

  Future<void> _handleUserInput(String input) async {
    if (input.trim().isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        text: input,
        isUser: true,
      ));
      _isTyping = true;
      _userInputController.clear();
      _assessmentStep++;
    });
    _scrollToBottom();

    try {
      // Build context from conversation history with explicit language instruction
      String conversationContext = "You are conducting a mental health assessment. ";
      
      if (_selectedLanguage != 'English') {
        conversationContext += "RESPOND ONLY IN ${_selectedLanguage.toUpperCase()} LANGUAGE. ";
      }
      
      conversationContext += "The conversation so far:\n\n";
      
      for (final message in _messages) {
        final role = message.isUser ? "User" : "Assistant";
        conversationContext += "$role: ${message.text}\n\n";
      }
      
      conversationContext += """
Continue the assessment by responding to the user's last message. Be empathetic and conversational.
${_selectedLanguage != 'English' ? 'IMPORTANT: Respond ONLY in $_selectedLanguage language.' : ''}

Ask one follow-up question at a time to gather more information about their mental health. Make your questions specific and relevant to what they've shared.

After you've asked about 8-10 questions total (we're currently on question ${_assessmentStep}), provide your assessment by starting your response with "ASSESSMENT_COMPLETE:" followed by a summary of potential mental health concerns.

Your assessment should:
1. Mention possible conditions their symptoms might align with
2. Emphasize this is not a clinical diagnosis
3. Recommend they consult a professional for proper evaluation
4. Suggest 2-3 self-care strategies that might help

${_selectedLanguage != 'English' ? 'Remember to use ONLY $_selectedLanguage language in your response.' : ''}
Keep your response concise and clear.
""";
      
      // Get response from Gemini with language parameter
      final response = await GeminiService.getResponse(
        input,
        conversationContext,
        language: _selectedLanguage != 'English' 
          ? (_languageCodes[_selectedLanguage] ?? 'en-US').split('-')[0] 
          : 'en',
      );

      // Check if assessment is complete
      if (_isAssessmentComplete(response)) {
        await _processAssessmentResult(response);
        return;
      }

      // Add AI response to chat (properly in requested language)
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            step: _assessmentStep,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error processing response: $e");
      _handleError("I couldn't process your response. Please try again.");
    }
  }

  bool _isAssessmentComplete(String response) {
    return response.contains('ASSESSMENT_COMPLETE:') || 
           response.contains('ASSESSMENT COMPLETE:') ||
           response.contains('Assessment complete:');
  }

  Future<void> _processAssessmentResult(String response) async {
    String assessmentText;
    
    // Extract assessment content
    if (response.contains('ASSESSMENT_COMPLETE:')) {
      assessmentText = response.split('ASSESSMENT_COMPLETE:')[1].trim();
    } else if (response.contains('ASSESSMENT COMPLETE:')) {
      assessmentText = response.split('ASSESSMENT COMPLETE:')[1].trim();
    } else if (response.contains('Assessment complete:')) {
      assessmentText = response.split('Assessment complete:')[1].trim();
    } else {
      assessmentText = response;
    }
    
    // Create assessment result object
    final result = AssessmentResult(
      rawAssessment: assessmentText,
      translatedAssessment: _selectedLanguage != 'English' ? assessmentText : null,
      mainCondition: _parseMainCondition(assessmentText),
      recommendedActions: _parseRecommendedActions(assessmentText),
      date: DateTime.now(),
    );

    // Save result to database
    try {
      await _saveAssessmentResult(result);
    } catch (e) {
      print("Error saving assessment: $e");
      // Continue even if saving fails
    }

    // Show completion message
    setState(() {
      _messages.add(ChatMessage(
        text: "Thank you for completing the assessment! I'm preparing your results...",
        isUser: false,
        isHighlighted: true,
      ));
      _isTyping = false;
    });
    _scrollToBottom();
    
    // Navigate to results screen after brief delay
    await Future.delayed(const Duration(seconds: 2));
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
    final conditions = [
      'Anxiety', 'Depression', 'ADHD', 'OCD', 'PTSD', 
      'Bipolar Disorder', 'Generalized Anxiety Disorder',
      'Social Anxiety', 'Panic Disorder', 'No significant mental health concerns'
    ];
    
    for (final condition in conditions) {
      if (assessmentText.contains(condition)) {
        return condition;
      }
    }
    
    return 'Inconclusive';
  }

  List<String> _parseRecommendedActions(String assessmentText) {
    final List<String> recommendations = [];
    
    // Look for recommendations phrases
    final recommendationPatterns = [
      RegExp(r'recommend[s]?\s+([\w\s\.,]+)\.', caseSensitive: false),
      RegExp(r'suggest[s]?\s+([\w\s\.,]+)\.', caseSensitive: false),
    ];
    
    for (final pattern in recommendationPatterns) {
      final matches = pattern.allMatches(assessmentText);
      for (final match in matches) {
        if (match.group(1) != null && match.group(1)!.length > 10) {
          recommendations.add(match.group(1)!.trim());
        }
      }
    }
    
    // If no specific recommendations found, provide general ones
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Consider consulting with a mental health professional',
        'Practice regular self-care and stress management techniques',
        'Maintain a journal to track symptoms and mood changes',
      ]);
    }
    
    return recommendations;
  }

  Future<void> _saveAssessmentResult(AssessmentResult result) async {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null) {
      await SupabaseService.client.from('assessment_results').insert({
        'user_id': currentUser.id,
        'main_condition': result.mainCondition,
        'raw_assessment': result.rawAssessment,
        'translated_assessment': result.translatedAssessment,
        'recommended_actions': result.recommendedActions,
        'language': _selectedLanguage,
        'date': result.date.toIso8601String(),
      });
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: message,
          isUser: false,
          isError: true,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _toggleLanguageSelector() {
    setState(() {
      _showLanguageSelector = !_showLanguageSelector;
    });
  }

  void _changeLanguage(String language) {
    if (_selectedLanguage != language) {
      setState(() {
        _selectedLanguage = language;
        _showLanguageSelector = false;
        
        // Show loading indicator while changing language
        _isTyping = true;
      });
      
      // Show language change notification with loading state
      _showSnackBar("Switching to $language...");
      
      // Clear existing messages and restart assessment with a slight delay
      // This gives time for the loading state to be visible
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _messages.clear();
            _assessmentInProgress = true;
            _assessmentStep = 0;
          });
          
          // Start a fresh assessment in the new language
          _startAssessment();
        }
      });
    } else {
      setState(() {
        _showLanguageSelector = false;
      });
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _speechService.stopListening();
      _cancelSoundLevelSimulation();
    } else {
      // Request permissions first
      bool hasPermission = await _speechService.requestPermissions();
      if (!hasPermission) {
        _showSnackBar("Microphone permission is required for speech recognition");
        return;
      }
      
      await _speechService.startListening(
        selectedLanguage: _selectedLanguage,
        onListeningStarted: () {
          setState(() {
            _isListening = true;
            _userInputController.text = '';
          });
          _startSoundLevelSimulation();
        },
        onListeningFinished: () {
          setState(() {
            _isListening = false;
          });
          _cancelSoundLevelSimulation();
        },
      );
    }
  }

  void _startSoundLevelSimulation() {
    _soundLevelTimer?.cancel();
    _soundLevelTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Create a realistic microphone sound level simulation
          _soundLevel = 0.3 + (math.Random().nextDouble() * 0.7);
        });
      }
    });
  }

  void _cancelSoundLevelSimulation() {
    _soundLevelTimer?.cancel();
    _soundLevelTimer = null;
    if (mounted) {
      setState(() {
        _soundLevel = 0.0;
      });
    }
  }

  void _speakMessage(int index) async {
    final message = _messages[index];
    
    // Don't speak if it's a user message
    if (message.isUser) return;
    
    // If already speaking this message, stop it
    if (_isSpeaking && _speakingMessageIndex == index) {
      await _speechService.stopSpeaking();
      setState(() {
        _isSpeaking = false;
        _speakingMessageIndex = null;
      });
      return;
    }
    
    // Stop any ongoing speech
    if (_isSpeaking) {
      await _speechService.stopSpeaking();
    }
    
    // Start speaking the message
    setState(() {
      _isSpeaking = true;
      _speakingMessageIndex = index;
    });
    
    await _speechService.speak(message.text, _selectedLanguage);
    
    // Update state when speaking finishes
    setState(() {
      _isSpeaking = false;
      _speakingMessageIndex = null;
    });
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
      body: Stack(
        children: [
          // Main gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildCustomAppBar(),
                
                // Progress indicator
                _buildProgressIndicator(),
                
                // Messages area
                Expanded(
                  child: _messages.isEmpty
                    ? _buildWelcomeScreen()
                    : _buildMessageList(),
                ),
                
                // AI typing indicator
                if (_isTyping) _buildTypingIndicator(),
                
                // Input area
                _buildInputArea(),
              ],
            ),
          ),
          
          // Language selector overlay (if visible)
          if (_showLanguageSelector) _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo or icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.psychology,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Text(
              "Mental Health Assessment",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Language selector button
          IconButton(
            onPressed: _toggleLanguageSelector,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  _selectedLanguage,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            tooltip: "Change language",
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Show progress indicator only during assessment
    if (!_assessmentInProgress || _messages.isEmpty) return SizedBox();
    
    final int totalSteps = 10;  // Typical assessment takes about 10 steps
    final double progress = _assessmentStep / totalSteps;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Assessment Progress",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "${(_assessmentStep / totalSteps * 100).round()}%",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replace the Lottie animation with a Flutter built-in animation
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  color: Theme.of(context).primaryColor,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ).animate().fade(duration: 600.ms).scale(
            begin: Offset(0.8, 0.8),
            end: Offset(1.0, 1.0),
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          SizedBox(height: 24),
          Text(
            "Starting your assessment...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 16),
          if (_isTyping)
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final bool isCurrentlySpeaking = !message.isUser && _isSpeaking && _messages.indexOf(message) == _speakingMessageIndex;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!message.isUser && message.step != null)
              Padding(
                padding: EdgeInsets.only(left: 54, bottom: 4),
                child: Text(
                  "Question ${message.step}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for AI
                if (!message.isUser)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.psychology,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
                
                // Message bubble
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).primaryColor
                          : message.isError
                              ? Colors.red.shade50
                              : message.isHighlighted
                                  ? Colors.green.shade50
                                  : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : message.isError
                                ? Colors.red.shade800
                                : message.isHighlighted
                                    ? Colors.green.shade800
                                    : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                // Add a speak button for AI messages
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => _speakMessage(_messages.indexOf(message)),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCurrentlySpeaking 
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentlySpeaking ? Icons.stop : Icons.volume_up,
                          color: isCurrentlySpeaking
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                
                // User avatar 
                if (message.isUser)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
              ],
            ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.psychology,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          _buildPulsingDots(),
        ],
      ),
    ).animate().fade(duration: 200.ms);
  }

  Widget _buildPulsingDots() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double delay = index / 3;
            final double value = (((_pulseController.value + delay) % 1.0) < 0.5) ? 1.0 : 0.5;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(value),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Speech recognition indicator
          if (_isListening)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  _buildPulsingMic(),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Listening in $_selectedLanguage...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      if (_userInputController.text.isNotEmpty)
                        Text(
                          _userInputController.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.stop_circle, color: Colors.red),
                    onPressed: _toggleListening,
                    tooltip: 'Stop listening',
                  ),
                ],
              ),
            ),
            
          // Input row
          Row(
            children: [
              // Mic button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.red.shade100
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                  onPressed: _speechEnabled ? _toggleListening : null,
                  tooltip: _speechEnabled
                      ? 'Start speaking'
                      : 'Speech recognition unavailable',
                ),
              ),
              SizedBox(width: 8),
              
              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isTyping
                          ? Colors.grey.shade300
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _userInputController,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening...'
                          : 'Type your response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    enabled: !_isTyping && !_isListening,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _handleUserInput,
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
              SizedBox(width: 8),
              
              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withBlue(
                            (Theme.of(context).primaryColor.blue + 40).clamp(0, 255),
                          ),
                    ],
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
        ],
      ),
    );
  }

  Widget _buildPulsingMic() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Use the simulated sound level to determine the size of the inner circle
        final double innerSize = _soundLevel > 0 
            ? 20 + (_soundLevel * 16) 
            : 20 + 8 * _pulseController.value;
            
        // Also use the sound level for the opacity
        final double opacity = _soundLevel > 0
            ? 0.8 - (_soundLevel * 0.3)
            : 0.8 - 0.4 * _pulseController.value;
        
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave circle - subtle animation
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3 * _pulseController.value),
                    width: 2,
                  ),
                ),
              ),
              
              // Inner active circle
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(opacity),
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 14 + 3 * (_soundLevel > 0 ? _soundLevel : _pulseController.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return GestureDetector(
      onTap: _toggleLanguageSelector, // Close by tapping outside
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Select Language",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: _toggleLanguageSelector,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Language list (scrollable)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _languageCodes.keys.map((language) {
                        final isSelected = _selectedLanguage == language;
                        return InkWell(
                          onTap: () => _changeLanguage(language),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                                        : Colors.grey.shade100,
                                  ),
                                  child: Center(
                                    child: Text(
                                      language.substring(0, 2),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  language,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                                Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _toggleLanguageSelector,
                        child: Text("Cancel"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _changeLanguage(_selectedLanguage),
                        child: Text("Confirm"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().scale(
                begin: Offset(0.8, 0.8),
                end: Offset(1.0, 1.0),
                duration: 200.ms,
                curve: Curves.easeOut,
              ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final bool isHighlighted;
  final int? step;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.isHighlighted = false,
    this.step,
  });
}