import 'package:flutter/material.dart';
import 'package:mantramind/services/sarvam_service.dart';

class TranslationDebugScreen extends StatefulWidget {
  const TranslationDebugScreen({super.key});

  @override
  State<TranslationDebugScreen> createState() => _TranslationDebugScreenState();
}

class _TranslationDebugScreenState extends State<TranslationDebugScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translationResult = '';
  String _apiResponse = '';
  bool _isLoading = false;
  String _selectedSourceLanguage = 'English';
  String _selectedTargetLanguage = 'Hindi';
  
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

  @override
  void initState() {
    super.initState();
    _inputController.text = 'Hello, how are you?';
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _testTranslation() async {
    setState(() {
      _isLoading = true;
      _translationResult = '';
      _apiResponse = '';
    });

    try {
      // Test API connection first
      final isConnected = await SarvamService.testApiConnection();
      _apiResponse = 'API Connection Test: ${isConnected ? 'SUCCESS' : 'FAILED'}';
      
      if (isConnected) {
        // Attempt translation
        final result = await SarvamService.translateText(
          inputText: _inputController.text,
          sourceLanguage: _selectedSourceLanguage,
          targetLanguage: _selectedTargetLanguage,
        );
        
        setState(() {
          _translationResult = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _translationResult = 'API Connection Failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _apiResponse += '\nError: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Debug Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source Language', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedSourceLanguage,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSourceLanguage = newValue;
                    });
                  }
                },
                items: _availableLanguages
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              const Text('Target Language', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedTargetLanguage,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTargetLanguage = newValue;
                    });
                  }
                },
                items: _availableLanguages
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              const Text('Text to Translate', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _inputController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter text to translate',
                ),
              ),
              const SizedBox(height: 16),
              
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testTranslation,
                  child: _isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Testing...'),
                          ],
                        )
                      : const Text('Test Translation'),
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_apiResponse.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('API Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_apiResponse),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              if (_translationResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Translation Result:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_translationResult),
                      const SizedBox(height: 16),
                      Text('Is Different from Input: ${_translationResult != _inputController.text}', 
                           style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}