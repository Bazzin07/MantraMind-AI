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
  
  // Add streaming controllers
  final StreamController<String> _textStreamController = StreamController.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController.broadcast();
  
  Stream<String> get textStream => _textStreamController.stream;
  Stream<bool> get listeningStream => _listeningStreamController.stream;

  // Add error stream
  final StreamController<String> _errorStreamController = StreamController.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;
  
  // Add partial results support
  String _currentPartialText = '';
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        _errorStreamController.add(error.errorMsg);
        _listeningStreamController.add(false);
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        // Update listening status based on speech status
        if (status == 'notListening' || status == 'done') {
          _listeningStreamController.add(false);
          
          // If we have partial text when stopping, send it as final
          if (_currentPartialText.isNotEmpty) {
            _textStreamController.add(_currentPartialText);
          }
        } else if (status == 'listening') {
          _listeningStreamController.add(true);
        }
      },
    );

    // Also initialize TTS
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    
    return _isInitialized;
  }

  Future<void> startListening({
    required String selectedLanguage,
    VoidCallback? onListeningStarted,
    VoidCallback? onListeningFinished,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Could not initialize speech recognition');
        _errorStreamController.add('Failed to initialize speech recognition');
        return;
      }
    }

    // Reset current partial text
    _currentPartialText = '';
    
    // Map language names to BCP-47 language codes
    final String languageCode = _getLanguageCode(selectedLanguage);
    
    if (await _speech.hasPermission && _isInitialized) {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          print('Speech result: ${result.recognizedWords}, final: ${result.finalResult}');
          
          // Handle both partial and final results
          if (result.finalResult) {
            // Final result - clean any trailing ellipsis that might have been added
            final cleanText = result.recognizedWords.replaceAll(' ...', '');
            _textStreamController.add(cleanText);
            _currentPartialText = ''; // Clear partial text
            
            if (onListeningFinished != null) {
              onListeningFinished();
            }
          } else {
            // Update partial text - store without ellipsis
            _currentPartialText = result.recognizedWords;
            // Send with ellipsis for UI display
            _textStreamController.add('${result.recognizedWords} ...');
          }
        },
        localeId: languageCode,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true, // Enable partial results
        listenFor: const Duration(seconds: 60), // Increased from 30 seconds
        pauseFor: const Duration(seconds: 5), // Increased from 3 seconds
      );
      
      _listeningStreamController.add(true);
      
      if (onListeningStarted != null) {
        onListeningStarted();
      }
    } else {
      print('Speech recognition permissions denied or not initialized');
      _errorStreamController.add('Speech recognition permission denied');
    }
  }

  void stopListening() {
    if (_isInitialized && _speech.isListening) {
      // If we have partial text when stopping manually, ensure it's sent as final
      if (_currentPartialText.isNotEmpty) {
        _textStreamController.add(_currentPartialText);
      }
      
      _speech.stop();
      _listeningStreamController.add(false);
    }
  }

  Future<void> speak(String text, String language) async {
    if (text.isEmpty) return;
    await _flutterTts.setLanguage(_getLanguageCode(language));
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

  // Helper method to convert language names to BCP-47 language codes
  String _getLanguageCode(String language) {
    final langMap = {
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
      // Add more languages as needed
    };
    return langMap[language] ?? 'en-US';
  }
}