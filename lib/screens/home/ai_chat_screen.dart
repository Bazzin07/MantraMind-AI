import 'package:flutter/material.dart';
import 'package:mantramind/services/gemini_service.dart';
import 'package:mantramind/services/task_service.dart';
import 'package:mantramind/models/chat_message.dart';
import 'package:mantramind/services/speech_to_text_service.dart';
import 'package:mantramind/services/speech_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AIChatScreen extends StatefulWidget {
  final String disorder;

  const AIChatScreen({
    this.disorder = '',
    super.key,
  });

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  String _selectedLanguage = 'English';
  String _recognizedText = '';

  // Added for task suggestions
  final Set<int> _selectedTasks = {};

  final List<String> _supportedLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Marathi',
    'Kannada',
    'Gujarati'
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage(_getWelcomeMessage());
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    final speechService = SpeechService(); // Use the singleton instance
    await speechService.initialize();

    // Listen for recognized text
    speechService.textStream.listen((text) {
      if (text.isNotEmpty) {
        setState(() {
          _recognizedText = text;
          // Update the text controller with the recognized text
          // Remove '...' if it's a partial result
          _textController.text = text.replaceAll(' ...', '');
        });

        // Debug output
        print('Recognized text: $text');
      }
    });

    // Listen for listening state changes
    speechService.listeningStream.listen((isListening) {
      setState(() {
        _isListening = isListening;
        // When we stop listening, make sure the text is in the controller
        if (!isListening && _recognizedText.isNotEmpty) {
          _textController.text = _recognizedText.replaceAll(' ...', '');
          print('Stopped listening, final text: ${_textController.text}');
        }
      });
    });

    // Listen for errors
    speechService.errorStream.listen((errorMsg) {
      print('Speech error received: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition error: $errorMsg')),
      );
    });
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  String _getWelcomeMessage() {
    if (widget.disorder.isNotEmpty) {
      return "Hello! I'm your AI mental health assistant. I see you're managing ${widget.disorder}. How can I help you today?";
    }
    return "Hello! I'm your AI mental health assistant. How can I help you today?";
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _recognizedText = '';
    });

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });

    // Build context for Gemini based on user history and disorder
    String context =
        "You are a compassionate mental health assistant helping someone";
    if (widget.disorder.isNotEmpty) {
      context += " who is managing ${widget.disorder}";
    }
    context +=
        ". Provide supportive, evidence-based advice. Focus on self-care practices.";

    try {
      final response = await GeminiService.getResponse(text, context);
      _processBotResponse(response);
    } catch (e) {
      _addBotMessage(
          "I'm having trouble connecting right now. Please try again later.");
    }
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
      ));
      _isLoading = false;
    });
  }

  void _processBotResponse(String response) {
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
      ));
      _isLoading = false;
    });

    // Extract potential tasks from the AI response
    final taskSuggestions = TaskService.extractTaskSuggestions(response);

    if (taskSuggestions.isNotEmpty) {
      _showTaskSuggestionsDialog(taskSuggestions);
    }
  }

  void _showTaskSuggestionsDialog(List<Map<String, String>> suggestions) {
    if (suggestions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Suggested Tasks?'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(suggestions[index]['title']!),
                    value: _selectedTasks.contains(index),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedTasks.add(index);
                        } else {
                          _selectedTasks.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectedTasks.clear();
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Add the selected tasks
                  for (var index in _selectedTasks) {
                    await TaskService.createTask(
                      'current_user_id', // Replace with actual user ID
                      suggestions[index]['title']!,
                      suggestions[index]['description'] ?? '',
                      'AI Suggestion',
                      widget.disorder,
                    );
                  }
                  Navigator.of(context).pop();
                  _selectedTasks.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tasks added to your list')),
                  );
                },
                child: const Text('Add Tasks'),
              ),
            ],
          );
        });
      },
    );
  }

  void _startListening() {
    final speechService = SpeechService();
    speechService.startListening(
      language: _selectedLanguage,
      onListeningStarted: () {
        setState(() {
          _isListening = true;
          _recognizedText = '';
          // Clear any previous text
          _textController.clear();
        });
        print('Started listening');
      },
      onListeningFinished: () {
        setState(() {
          _isListening = false;
          // Ensure the recognized text is in the text field
          if (_recognizedText.isNotEmpty) {
            _textController.text = _recognizedText.replaceAll(' ...', '');
            print('Finished listening, final text: ${_textController.text}');
          }
        });
      },
    );
  }

  void _stopListening() {
    if (_isListening) {
      final speechService = SpeechService();
      speechService.stopListening();
      setState(() {
        _isListening = false;
        // Make sure we have the latest recognized text
        if (_recognizedText.isNotEmpty) {
          _textController.text = _recognizedText.replaceAll(' ...', '');
          print(
              'Manually stopped listening, final text: ${_textController.text}');
        }
      });
    }
  }

  Future<void> _speakMessage(String message) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mental Health Assistant'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String language) {
              setState(() {
                _selectedLanguage = language;
              });
            },
            itemBuilder: (BuildContext context) {
              return _supportedLanguages.map((String language) {
                return PopupMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final message = _messages[_messages.length - index - 1];
                  return ChatBubble(
                    message: message,
                    onLongPress: !message.isUser
                        ? () => _speakMessage(message.text)
                        : null,
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            // Add speech recognition feedback when active
            if (_isListening)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Listening...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon:
                              const Icon(Icons.stop_circle, color: Colors.red),
                          onPressed: _stopListening,
                          tooltip: 'Stop listening',
                        ),
                      ],
                    ),
                    if (_recognizedText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _recognizedText,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
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
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _isListening ? Colors.red.shade50 : Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.blue,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ),
              onSubmitted: _handleSubmitted,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    SpeechService().dispose(); // Use the singleton
    super.dispose();
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;

  const ChatBubble({
    required this.message,
    this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: InkWell(
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              if (!message.isUser)
                const Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Long press to hear this message',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
