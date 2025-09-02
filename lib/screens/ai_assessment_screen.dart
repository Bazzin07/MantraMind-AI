import 'package:flutter/material.dart';
import 'package:mantramind/services/sarvam_service.dart';

class AIAssessmentScreen extends StatefulWidget {
  const AIAssessmentScreen({super.key});

  @override
  State<AIAssessmentScreen> createState() => _AIAssessmentScreenState();
}

class _AIAssessmentScreenState extends State<AIAssessmentScreen> {
  String selectedLanguage = 'English';
  List<String> languages = [
    'English', 'Hindi', 'Tamil', 'Telugu', 'Kannada',
    'Malayalam', 'Bengali', 'Marathi', 'Gujarati',
    'Punjabi', 'Odia', 'Assamese', 'Urdu'
  ];
  
  // Original questions in English
  final List<String> originalQuestions = [
    "How have you been feeling lately?",
    "Are you experiencing any stress or anxiety?",
    "How would you rate your sleep quality?",
    "Have you been able to focus on daily tasks?",
    // Add more questions as needed
  ];
  
  // Translated questions will be stored here
  List<String> translatedQuestions = [];
  bool isLoading = false;
  int currentQuestionIndex = 0;
  TextEditingController answerController = TextEditingController();
  List<String> answers = [];

  @override
  void initState() {
    super.initState();
    // Initialize with English questions
    translatedQuestions = List.from(originalQuestions);
  }

  Future<void> translateQuestions() async {
    if (selectedLanguage == 'English') {
      setState(() {
        translatedQuestions = List.from(originalQuestions);
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<String> newTranslatedQuestions = [];
      for (String question in originalQuestions) {
        String translatedQuestion = await SarvamService.translateText(
          inputText : question,
          sourceLanguage: 'English',
          targetLanguage: selectedLanguage,
        );
        newTranslatedQuestions.add(translatedQuestion);
      }

      setState(() {
        translatedQuestions = newTranslatedQuestions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: $e')),
      );
    }
  }

  void onLanguageChanged(String? newLanguage) {
    if (newLanguage != null && newLanguage != selectedLanguage) {
      setState(() {
        selectedLanguage = newLanguage;
      });
      translateQuestions();
    }
  }

  void submitAnswer() {
    if (answerController.text.trim().isNotEmpty) {
      setState(() {
        answers.add(answerController.text);
        answerController.clear();
        
        if (currentQuestionIndex < translatedQuestions.length - 1) {
          currentQuestionIndex++;
        } else {
          // Handle assessment completion
          // This could navigate to a results page or show a summary
          _showCompletionDialog();
        }
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Complete'),
        content: const Text('Thank you for completing the assessment.'),
        actions: [
          TextButton(
            child: const Text('View Results'),
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to results page or show results
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Assessment'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Language',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: languages.map((String language) {
                            return DropdownMenuItem<String>(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                          onChanged: onLanguageChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${currentQuestionIndex + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Question ${currentQuestionIndex + 1} of ${translatedQuestions.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              translatedQuestions[currentQuestionIndex],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: TextField(
                                controller: answerController,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Type your answer here...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitAnswer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Next',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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