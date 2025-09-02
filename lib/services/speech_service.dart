import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  // Singleton implementation
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // Core functionality
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  
  // Stream controllers for communicating with UI
  final StreamController<String> _textStreamController = StreamController.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController.broadcast();
  final StreamController<String> _errorStreamController = StreamController.broadcast();
  
  // Public streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<bool> get listeningStream => _listeningStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  
  // Language mapping
  static final Map<String, String> _languageCodes = {
    'English': 'en-IN',
    'Hindi': 'hi-IN',
    'Bengali': 'bn-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Marathi': 'mr-IN',
    'Kannada': 'kn-IN',
    'Gujarati': 'gu-IN',
  };
  
  Future<bool> initialize() async {
    if (_initialized) return true;
    
    try {
      _initialized = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          _errorStreamController.add(error.errorMsg);
          _listeningStreamController.add(false);
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening' || status == 'done') {
            _listeningStreamController.add(false);
          } else if (status == 'listening') {
            _listeningStreamController.add(true);
          }
        },
      );
      
      // Initialize TTS
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      
      return _initialized;
    } catch (e) {
      print('Speech initialization error: $e');
      _errorStreamController.add('Failed to initialize: $e');
      return false;
    }
  }
  
  Future<void> startListening({
    required String language,
    VoidCallback? onListeningStarted,
    VoidCallback? onListeningFinished,
  }) async {
    // Initialize if needed
    if (!_initialized) {
      final initialized = await initialize();
      if (!initialized) {
        _errorStreamController.add('Could not initialize speech recognition');
        return;
      }
    }
    
    // Check permissions
    if (!await _speech.hasPermission) {
      _errorStreamController.add('Speech recognition permission denied');
      return;
    }
    
    try {
      // Start listening
      await _speech.listen(
        onResult: (result) {
          // Debug
          print('Speech result: ${result.recognizedWords}, final: ${result.finalResult}');
          
          // Handle both partial and final results
          if (result.finalResult) {
            _textStreamController.add(result.recognizedWords);
            if (onListeningFinished != null) {
              onListeningFinished();
            }
          } else {
            _textStreamController.add('${result.recognizedWords} ...');
          }
        },
        localeId: _languageCodes[language] ?? 'en-IN',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
      
      _listeningStreamController.add(true);
      if (onListeningStarted != null) {
        onListeningStarted();
      }
    } catch (e) {
      print('Error starting speech recognition: $e');
      _errorStreamController.add('Error starting speech: $e');
      _listeningStreamController.add(false);
    }
  }
  
  void stopListening() {
    if (_initialized && _speech.isListening) {
      _speech.stop();
      _listeningStreamController.add(false);
    }
  }
  
  Future<void> speak(String text, String language) async {
    if (text.isEmpty) return;
    
    await _flutterTts.setLanguage(_languageCodes[language] ?? 'en-IN');
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
  
  void dispose() {
    stopListening();
    _flutterTts.stop();
    _textStreamController.close();
    _listeningStreamController.close();
    _errorStreamController.close();
  }
  
  bool get isListening => _speech.isListening;
}