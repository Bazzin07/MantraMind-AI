import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Streaming controllers
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController = StreamController<String>.broadcast();
  
  // Language mapping for speech recognition
  final Map<String, String> _languageCodes = {
    'English': 'en_US',
    'Hindi': 'hi_IN',
    'Tamil': 'ta_IN',
    'Telugu': 'te_IN',
    'Kannada': 'kn_IN',
    'Malayalam': 'ml_IN',
    'Bengali': 'bn_IN',
    'Marathi': 'mr_IN',
    'Gujarati': 'gu_IN',
    'Punjabi': 'pa_IN',
    'Odia': 'or_IN',
    'Assamese': 'as_IN',
    'Urdu': 'ur_IN',
  };
  
  // Expose streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<bool> get listeningStream => _listeningStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          _errorStreamController.add(error.errorMsg);
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _listeningStreamController.add(false);
          }
        },
        debugLogging: true,
      );
      
      // Initialize TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech service: $e');
      _errorStreamController.add("Speech initialization error: $e");
      return false;
    }
  }
  
  Future<void> startListening({
    required String selectedLanguage,
    VoidCallback? onListeningStarted,
    VoidCallback? onListeningFinished,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _errorStreamController.add("Failed to initialize speech recognition");
        return;
      }
    }
    
    // Stop any ongoing listening
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(Duration(milliseconds: 200)); // Short delay to ensure proper reset
    }
    
    try {
      final localeId = _languageCodes[selectedLanguage] ?? 'en_US';
      print('Starting speech recognition in language: $selectedLanguage (locale: $localeId)');
      
      await _speech.listen(
        onResult: (result) {
          print('Recognition result: ${result.recognizedWords} (final: ${result.finalResult})');
          if (result.finalResult) {
            _textStreamController.add(result.recognizedWords);
            if (onListeningFinished != null) onListeningFinished();
          } else {
            _textStreamController.add(result.recognizedWords + " ...");
          }
        },
        localeId: localeId,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          // Sound level can be used for visualizing microphone activity
          // Level ranges from 0 (silence) to 1 (maximum volume)
          print('Sound level: $level');
        },
        cancelOnError: true,
      );
      
      _listeningStreamController.add(true);
      if (onListeningStarted != null) onListeningStarted();
    } catch (e) {
      print('Error starting speech recognition: $e');
      _errorStreamController.add("Error starting speech recognition: $e");
    }
  }
  
  void stopListening() {
    if (_speech.isListening) {
      print('Stopping speech recognition');
      _speech.stop();
      _listeningStreamController.add(false);
    }
  }
  
  Future<void> speak(String text, String language) async {
    if (_isSpeaking) {
      await stopSpeaking();
      await Future.delayed(Duration(milliseconds: 300));
    }
    
    try {
      _isSpeaking = true;
      
      // Convert language name to language code for TTS
      String langCode;
      switch (language) {
        case 'Hindi': langCode = 'hi-IN'; break;
        case 'Tamil': langCode = 'ta-IN'; break;
        case 'Telugu': langCode = 'te-IN'; break;
        case 'Kannada': langCode = 'kn-IN'; break;
        case 'Malayalam': langCode = 'ml-IN'; break;
        case 'Bengali': langCode = 'bn-IN'; break;
        case 'Marathi': langCode = 'mr-IN'; break;
        case 'Gujarati': langCode = 'gu-IN'; break;
        case 'Punjabi': langCode = 'pa-IN'; break;
        case 'Odia': langCode = 'or-IN'; break;
        case 'Urdu': langCode = 'ur-PK'; break;
        default: langCode = 'en-US';
      }
      
      print('Speaking text in $language (code: $langCode)');
      
      await _flutterTts.setLanguage(langCode);
      final result = await _flutterTts.speak(text);
      
      if (result != 1) {
        _errorStreamController.add("Failed to start text-to-speech");
        _isSpeaking = false;
      }
    } catch (e) {
      print('Error in text-to-speech: $e');
      _errorStreamController.add("Text-to-speech error: $e");
      _isSpeaking = false;
    }
  }
  
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }
  
  void dispose() {
    stopListening();
    stopSpeaking();
    _textStreamController.close();
    _listeningStreamController.close();
    _errorStreamController.close();
  }
  
  bool get isListening => _speech.isListening;
  bool get isSpeaking => _isSpeaking;
  
  Future<bool> requestPermissions() async {
    final hasPermission = await _speech.hasPermission;
    print('Speech recognition permission status: $hasPermission');
    return hasPermission;
  }
  
  // Get available languages (useful for debugging)
  Future<List<String>> getAvailableLanguages() async {
    final locales = await _speech.locales();
    List<String> languages = locales.map((locale) => '${locale.name} (${locale.localeId})').toList();
    print('Available languages: $languages');
    return languages;
  }
}