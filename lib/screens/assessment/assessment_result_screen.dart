import 'package:flutter/material.dart';
import 'package:mantramind/models/assessment_result.dart';
import 'package:mantramind/services/sarvam_service.dart';
import 'package:mantramind/screens/home/dashboard_screen.dart'; // Import for navigation

class AssessmentResultScreen extends StatefulWidget {
  final AssessmentResult result;
  final String selectedLanguage;

  const AssessmentResultScreen({
    Key? key,
    required this.result,
    required this.selectedLanguage,
  }) : super(key: key);

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  late String _displayText;
  bool _isLoading = true;
  List<String> _translatedRecommendations = [];

  @override
  void initState() {
    super.initState();
    _prepareContent();
  }

  Future<void> _prepareContent() async {
    setState(() {
      _isLoading = true;
    });

    // Use the translated assessment if available, otherwise show the original
    _displayText =
        widget.result.translatedAssessment ?? widget.result.rawAssessment;

    // Translate recommendations if not in English
    if (widget.selectedLanguage != 'English') {
      try {
        _translatedRecommendations = await Future.wait(
          widget.result.recommendedActions.map((action) async {
            return await SarvamService.translateText(
              inputText: action,
              sourceLanguage: 'English',
              targetLanguage: widget.selectedLanguage,
            );
          }),
        );
      } catch (e) {
        print('Error translating recommendations: $e');
        _translatedRecommendations = widget.result.recommendedActions;
      }
    } else {
      _translatedRecommendations = widget.result.recommendedActions;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Assessment Results'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.selectedLanguage,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildAssessmentCard(),
                        const SizedBox(height: 16),
                        _buildRecommendationsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildDashboardButton(),
              ],
            ),
    );
  }

  Widget _buildDashboardButton() {
    // Get appropriate button color based on condition
    final buttonColor = _getColorForCondition(widget.result.mainCondition);
    
    // Translate button text based on selected language
    final buttonText = _getTranslatedString(
        'Go to Dashboard', widget.selectedLanguage);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to the disorder dashboard screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisorderDashboardScreen(
                disorder: widget.result.mainCondition,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForCondition(widget.result.mainCondition)),
            const SizedBox(width: 10),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedString(
                  'Assessment Summary', widget.selectedLanguage),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getIconForCondition(widget.result.mainCondition),
                  size: 32,
                  color: _getColorForCondition(widget.result.mainCondition),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslatedString(
                            'Main Findings', widget.selectedLanguage),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        widget.selectedLanguage == 'English'
                            ? widget.result.mainCondition
                            : _getTranslatedCondition(
                                widget.result.mainCondition,
                                widget.selectedLanguage),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getColorForCondition(
                                  widget.result.mainCondition),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedString(
                  'Detailed Assessment', widget.selectedLanguage),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(_displayText),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedString(
                  'Recommended Actions', widget.selectedLanguage),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _translatedRecommendations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_translatedRecommendations[index])),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCondition(String condition) {
    switch (condition) {
      case 'Anxiety':
        return Icons.psychology;
      case 'Depression':
        return Icons.mood_bad;
      case 'ADHD':
        return Icons.scatter_plot;
      case 'OCD':
        return Icons.repeat;
      case 'PTSD':
        return Icons.warning;
      case 'Bipolar Disorder':
        return Icons.sync_alt;
      case 'No significant mental health concerns':
        return Icons.check_circle;
      default:
        return Icons.question_mark;
    }
  }

  Color _getColorForCondition(String condition) {
    switch (condition) {
      case 'No significant mental health concerns':
        return Colors.green;
      case 'Anxiety':
      case 'Depression':
      case 'ADHD':
      case 'OCD':
      case 'PTSD':
      case 'Bipolar Disorder':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Basic string translations for common UI elements
  String _getTranslatedString(String text, String language) {
    if (language == 'English') return text;

    final translations = {
      'Assessment Summary': {
        'Hindi': 'मूल्यांकन सारांश',
        'Tamil': 'மதிப்பீட்டு சுருக்கம்',
        // Add more languages as needed
      },
      'Detailed Assessment': {
        'Hindi': 'विस्तृत मूल्यांकन',
        'Tamil': 'விரிவான மதிப்பீடு',
        // Add more languages as needed
      },
      'Recommended Actions': {
        'Hindi': 'अनुशंसित कार्रवाई',
        'Tamil': 'பரிந்துரைக்கப்பட்ட செயல்கள்',
        // Add more languages as needed
      },
      'Main Findings': {
        'Hindi': 'मुख्य निष्कर्ष',
        'Tamil': 'முக்கிய கண்டுபிடிப்புகள்',
        // Add more languages as needed
      },
      'Go to Dashboard': {
        'Hindi': 'डैशबोर्ड पर जाएं',
        'Tamil': 'டாஷ்போர்டுக்குச் செல்லவும்',
        // Add more languages as needed
      },
    };

    return translations[text]?[language] ?? text;
  }

  // Basic translations for conditions
  String _getTranslatedCondition(String condition, String language) {
    final translations = {
      'Anxiety': {
        'Hindi': 'चिंता',
        'Tamil': 'பதட்டம்',
        // Add more languages as needed
      },
      'Depression': {
        'Hindi': 'अवसाद',
        'Tamil': 'மன அழுத்தம்',
        // Add more languages as needed
      },
      'ADHD': {
        'Hindi': 'एडीएचडी',
        'Tamil': 'ஏடிஹெச்டி',
        // Add more languages as needed
      },
      'OCD': {
        'Hindi': 'ओसीडी',
        'Tamil': 'ஓசிடி',
        // Add more languages as needed
      },
      'PTSD': {
        'Hindi': 'पीटीएसडी',
        'Tamil': 'பிடிஎஸ்டி',
        // Add more languages as needed
      },
      'Bipolar Disorder': {
        'Hindi': 'द्विध्रुवी विकार',
        'Tamil': 'இருமுனை கோளாறு',
        // Add more languages as needed
      },
      'No significant mental health concerns': {
        'Hindi': 'कोई महत्वपूर्ण मानसिक स्वास्थ्य चिंता नहीं',
        'Tamil': 'குறிப்பிடத்தக்க மன நல கவலைகள் இல்லை',
        // Add more languages as needed
      },
      'Inconclusive': {
        'Hindi': 'अनिर्णीत',
        'Tamil': 'தீர்மானிக்க முடியாதது',
      },
    };

    return translations[condition]?[language] ?? condition;
  }
}