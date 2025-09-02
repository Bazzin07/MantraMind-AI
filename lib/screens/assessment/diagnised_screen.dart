import 'package:flutter/material.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/screens/assessment/disorder_selection_screen.dart';
import 'package:mantramind/screens/assessment/ai_assessment_screen.dart'; // Import your AI assessment scree

class DiagnosedPage extends StatefulWidget {
  const DiagnosedPage({super.key}); // Removed userName parameter

  @override
  State<DiagnosedPage> createState() => _DiagnosedPageState();
}

class _DiagnosedPageState extends State<DiagnosedPage> {
  String userName = 'User'; // Default value
  bool isLoading = true; // To show a loading indicator while fetching the name

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        final response = await SupabaseService.client
            .from('users')
            .select('name')
            .eq('id', currentUser.id)
            .single();
        setState(() {
          userName = response['name'] ?? 'User';
          isLoading = false;
        });
      } else {
        print('No current user found');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Assessment'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello, $userName', // Use state variable userName
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How would you like to proceed?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildOptionCard(
                    context,
                    icon: Icons.psychology_alt,
                    title: 'Self Diagnosis',
                    subtitle:
                        'Get assessed using our AI-powered mental health evaluation',
                    onTap: () => _navigateToAIAssessment(context),
                  ),
                  const SizedBox(height: 30),
                  _buildOptionCard(
                    context,
                    icon: Icons.assignment_turned_in,
                    title: 'Already Diagnosed',
                    subtitle: 'Select your pre-existing mental health condition',
                    onTap: () => _showDisorderSelection(context),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 50, color: Theme.of(context).primaryColor),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAIAssessment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIAssessmentScreen(), // Replace with your AI assessment screen
      ),
    );
  }

  void _showDisorderSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DisorderSelectionScreen(),
      ),
    );
  }
}