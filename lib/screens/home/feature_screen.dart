import 'package:flutter/material.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MantraMind Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Access tools and resources for your mental health journey',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Free features section
            _buildSectionHeader('Free Features', Colors.green),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Daily Diary',
              'Record your thoughts, feelings, and experiences',
              Icons.book,
              Colors.indigo,
              isLocked: false,
              onTap: () {
                // Navigate to Daily Diary feature
                // Navigator.push(context, MaterialPageRoute(builder: (context) => DailyDiaryScreen()));
              },
            ),
            _buildFeatureCard(
              'Mood Tracking',
              'Track your mood patterns over time',
              Icons.mood,
              Colors.amber,
              isLocked: false,
              onTap: () {},
            ),
            _buildFeatureCard(
              'Breathing Exercises',
              'Guided breathing techniques for relaxation',
              Icons.air,
              Colors.lightBlue,
              isLocked: false,
              onTap: () {},
            ),
            _buildFeatureCard(
              'Basic Meditation',
              'Simple guided meditation sessions',
              Icons.self_improvement,
              Colors.teal,
              isLocked: false,
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            
            // Premium features section
            _buildSectionHeader('Premium Features', Colors.purple),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'AI Face Analyzer',
              'Analyze facial expressions to detect emotional patterns',
              Icons.face,
              Colors.deepPurple,
              isLocked: true,
              onTap: () {
                _showPremiumDialog(context);
              },
            ),
            _buildFeatureCard(
              'Advanced Analytics',
              'Detailed insights and patterns from your data',
              Icons.analytics,
              Colors.blue,
              isLocked: true,
              onTap: () {
                _showPremiumDialog(context);
              },
            ),
            _buildFeatureCard(
              'Personalized Therapy Plans',
              'AI-generated therapy plans based on your needs',
              Icons.psychology,
              Colors.red,
              isLocked: true,
              onTap: () {
                _showPremiumDialog(context);
              },
            ),
            _buildFeatureCard(
              'Expert Video Sessions',
              'Access to video sessions with mental health experts',
              Icons.video_camera_front,
              Colors.orange,
              isLocked: true,
              onTap: () {
                _showPremiumDialog(context);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Upgrade button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to subscription page
                  _showPremiumDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.purple,
                ),
                child: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(title.contains('Premium') ? Icons.star : Icons.check_circle, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color, {
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              isLocked
                  ? Icon(Icons.lock, color: Colors.grey[400])
                  : Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This is a premium feature. Upgrade to MantraMind Premium to unlock all features and get personalized support for your mental health journey.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page
              // Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}