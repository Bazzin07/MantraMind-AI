import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:mantramind/screens/home/profile_screen.dart';
import 'package:mantramind/screens/home/ai_chat_screen.dart';
import 'package:mantramind/screens/home/feature_screen.dart';

class DisorderDashboardScreen extends StatefulWidget {
  final String disorder;
  
  const DisorderDashboardScreen({
    required this.disorder,
    super.key,
  });

  @override
  State<DisorderDashboardScreen> createState() => _DisorderDashboardScreenState();
}

class _DisorderDashboardScreenState extends State<DisorderDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  int streakCount = 0;
  double progressPercentage = 0.0;
  List<Map<String, dynamic>> recommendedTasks = [];
  Map<String, dynamic>? aiInsight;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    // This would be replaced with actual data fetching from your backend
    setState(() => _isLoading = true);
    
    try {
      // Simulating API calls with a delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Here you would actually fetch data from Supabase
      // final userData = await SupabaseService.getUserDashboardData(widget.disorder);
      
      // For demo purposes, we'll use mock data
      setState(() {
        recommendedTasks = _getAIRecommendedTasksForDisorder(widget.disorder);
        aiInsight = _getAIInsightForDisorder(widget.disorder);
        
        // Calculate streak count and progress based on activity completion
        _calculateProgress();
        
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }
  
  void _calculateProgress() {
    // Calculate streaks
    streakCount = _calculateStreakCount();
    
    // Calculate progress percentage based on completed activities
    int totalActivities = recommendedTasks.length;
    int completedActivities = recommendedTasks.where((task) => 
      task['isCompleted'] == true).length;
    
    progressPercentage = totalActivities > 0 ? completedActivities / totalActivities : 0.0;
  }
  
  int _calculateStreakCount() {
    // Count consecutive days with at least one completed activity
    int streak = 0;
    
    if (recommendedTasks.isEmpty) return 0;
    
    // Get the number of days tracked (assuming all tasks have the same length of progress array)
    int days = recommendedTasks.first['progress'].length;
    
    // Count backwards from the most recent day
    for (int i = days - 1; i >= 0; i--) {
      bool anyActivityCompleted = recommendedTasks.any((task) {
        List<bool> progress = List<bool>.from(task['progress']);
        return i < progress.length && progress[i];
      });
      
      if (anyActivityCompleted) {
        streak++;
      } else {
        break; // Streak is broken
      }
    }
    
    return streak;
  }
  
  Map<String, dynamic> _getAIInsightForDisorder(String disorder) {
    // This would come from your backend with actual AI analysis in a real app
    final Map<String, Map<String, dynamic>> disorderInsights = {
      'Depression': {
        'summary': 'Based on your activity patterns, your mood tends to improve after morning sunlight exposure and social connections.',
        'recommendation': 'Consider increasing outdoor morning activities and scheduling more social interactions this week.',
        'progress': 'You\'ve been consistent with your morning sunlight routine, which is excellent progress.',
      },
      'Anxiety': {
        'summary': 'Your anxiety symptoms appear to decrease significantly after deep breathing exercises.',
        'recommendation': 'Try incorporating more breathing exercises throughout your day, especially before stressful situations.',
        'progress': 'Your consistency with deep breathing practice shows strong commitment to managing your anxiety.',
      },
      'ADHD': {
        'summary': 'The Pomodoro technique has significantly improved your focus duration based on your tracking data.',
        'recommendation': 'Consider gradually increasing your focused work sessions from 25 to 30 minutes.',
        'progress': 'Your environment organization habits have improved 40% over the last month.',
      },
      'OCD': {
        'summary': 'Your ERP practice shows a pattern of decreasing distress levels over time.',
        'recommendation': 'Consider gradually increasing the difficulty of your exposure exercises this week.',
        'progress': 'You\'ve maintained consistent practice with your ERP exercises for 7 consecutive days.',
      },
      'Bipolar Disorder': {
        'summary': 'Your sleep tracking data shows improved stability when you maintain a consistent sleep schedule.',
        'recommendation': 'Focus on keeping your bedtime consistent, even on weekends.',
        'progress': 'Your mood tracking shows more stable patterns compared to last month.',
      },
      'PTSD': {
        'summary': 'Grounding techniques appear to be most effective for you during trigger situations.',
        'recommendation': 'Consider practicing the 5-4-3-2-1 technique more regularly as preventative care.',
        'progress': 'Your ability to identify triggers has improved significantly over the past two weeks.',
      },
      'Schizophrenia': {
        'summary': 'Reality testing exercises show positive correlation with reduced hallucination intensity.',
        'recommendation': 'Continue with your medication regimen and daily reality-testing practices.',
        'progress': 'Your consistent reporting of symptoms is helping establish effective patterns.',
      },
      'Eating Disorders': {
        'summary': 'Mindful eating practices correlate with reduced anxiety around mealtimes.',
        'recommendation': 'Continue practicing mindful eating and consider adding body positivity exercises.',
        'progress': 'You\'ve consistently completed your meal plan for 5 consecutive days.',
      },
      'BPD': {
        'summary': 'DBT skills practice shows correlation with improved emotional regulation.',
        'recommendation': 'Focus more on distress tolerance skills during the upcoming week.',
        'progress': 'Your use of the STOP skill has increased by 60% in challenging situations.',
      },
      'Addiction': {
        'summary': 'Urge surfing techniques appear most effective during your high-risk times (evenings).',
        'recommendation': 'Plan additional coping activities for evening hours when cravings tend to intensify.',
        'progress': 'You\'ve successfully used urge surfing techniques 12 times this week.',
      },
    };
    
    // Default insight if disorder not found in our map
    if (!disorderInsights.containsKey(disorder)) {
      return {
        'summary': 'Regular tracking shows you\'re making steady progress in managing your symptoms.',
        'recommendation': 'Continue with your current regimen and consider adding more mindfulness practices.',
        'progress': 'Your consistency with daily check-ins is excellent.',
      };
    }
    
    return disorderInsights[disorder]!;
  }
  
  List<Map<String, dynamic>> _getAIRecommendedTasksForDisorder(String disorder) {
    // This would come from your backend with actual AI recommendations in a real app
    final Map<String, List<Map<String, dynamic>>> disorderTasks = {
      'Depression': [
        {
          'title': 'Morning Sunlight',
          'description': 'Spend 10 minutes in natural sunlight',
          'icon': Icons.wb_sunny,
          'color': Colors.amber,
          'isCompleted': true,
          'aiReason': 'Natural light exposure helps regulate serotonin levels',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Physical Activity',
          'description': 'Go for a 20-minute walk',
          'icon': Icons.directions_walk,
          'color': Colors.green,
          'isCompleted': false,
          'aiReason': 'Exercise releases endorphins that improve mood',
          'effectiveness': 0.78,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Gratitude Journal',
          'description': 'Write down 3 things you are grateful for',
          'icon': Icons.book,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Shifts focus from negative to positive aspects of life',
          'effectiveness': 0.72,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, false, false, true, false, false], // Last 7 days
        },
        {
          'title': 'Social Connection',
          'description': 'Call or meet a friend',
          'icon': Icons.people,
          'color': Colors.purple,
          'isCompleted': true,
          'aiReason': 'Social support reduces isolation and improves mood',
          'effectiveness': 0.90,
          'recommendedFrequency': '3-4 times per week',
          'adaptiveDifficulty': 'Moderate',
          'progress': [false, true, false, true, false, true, true], // Last 7 days
        },
        {
          'title': 'Pleasant Activity',
          'description': 'Engage in an activity you enjoy for 30 minutes',
          'icon': Icons.favorite,
          'color': Colors.red,
          'isCompleted': false,
          'aiReason': 'Positive reinforcement helps combat anhedonia',
          'effectiveness': 0.81,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy to Moderate',
          'progress': [true, false, true, false, false, true, false], // Last 7 days
        },
      ],
      'Anxiety': [
        {
          'title': 'Deep Breathing',
          'description': '5 minutes of diaphragmatic breathing',
          'icon': Icons.air,
          'color': Colors.lightBlue,
          'isCompleted': true,
          'aiReason': 'Activates parasympathetic nervous system to reduce stress response',
          'effectiveness': 0.88,
          'recommendedFrequency': '2-3 times daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, true, false, true, true], // Last 7 days
        },
        {
          'title': 'Worry Journal',
          'description': 'Write down your worries and challenge them',
          'icon': Icons.edit_note,
          'color': Colors.teal,
          'isCompleted': false,
          'aiReason': 'Helps identify cognitive distortions and promotes realistic thinking',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, false, true, false, true, false], // Last 7 days
        },
        {
          'title': 'Progressive Muscle Relaxation',
          'description': '10 minutes of tensing and relaxing muscle groups',
          'icon': Icons.spa,
          'color': Colors.indigo,
          'isCompleted': false,
          'aiReason': 'Reduces physical tension associated with anxiety',
          'effectiveness': 0.82,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [false, true, false, false, true, false, false], // Last 7 days
        },
        {
          'title': 'Mindful Walking',
          'description': 'Take a 15-minute mindful walk',
          'icon': Icons.directions_walk,
          'color': Colors.green,
          'isCompleted': true,
          'aiReason': 'Combines physical activity with mindfulness for dual benefit',
          'effectiveness': 0.79,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [false, true, true, false, true, false, true], // Last 7 days
        },
        {
          'title': 'Worry Time',
          'description': 'Schedule 15 minutes dedicated to worrying',
          'icon': Icons.schedule,
          'color': Colors.amber,
          'isCompleted': false,
          'aiReason': 'Limits worry to specific time to free up mental resources',
          'effectiveness': 0.70,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, false, false, false, false], // Last 7 days
        },
      ],
      'ADHD': [
        {
          'title': 'Pomodoro Focus Session',
          'description': '25 minutes of focused work, then 5-minute break',
          'icon': Icons.timer,
          'color': Colors.red,
          'isCompleted': true,
          'aiReason': 'Structured time blocks improve focus and task completion',
          'effectiveness': 0.92,
          'recommendedFrequency': 'During work/study periods',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Task Prioritization',
          'description': 'Create a prioritized to-do list for tomorrow',
          'icon': Icons.format_list_numbered,
          'color': Colors.orange,
          'isCompleted': false,
          'aiReason': 'Reduces decision fatigue and improves executive functioning',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily (evening)',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Environment Organization',
          'description': 'Organize your workspace for 10 minutes',
          'icon': Icons.cleaning_services,
          'color': Colors.cyan,
          'isCompleted': true,
          'aiReason': 'Reduces visual distractions and improves focus',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Mindfulness Meditation',
          'description': '10 minutes of focused attention meditation',
          'icon': Icons.self_improvement,
          'color': Colors.deepPurple,
          'isCompleted': false,
          'aiReason': 'Strengthens attention networks in the brain',
          'effectiveness': 0.78,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Challenging',
          'progress': [false, false, true, false, true, false, false], // Last 7 days
        },
        {
          'title': 'Body Doubling',
          'description': 'Work alongside someone else (in person or virtually)',
          'icon': Icons.people_alt,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Social accountability improves task initiation and completion',
          'effectiveness': 0.88,
          'recommendedFrequency': '3-5 times per week',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, false, true, false, true, false], // Last 7 days
        },
      ],
      'OCD': [
        {
          'title': 'ERP Practice',
          'description': 'Exposure and response prevention exercise',
          'icon': Icons.psychology,
          'color': Colors.teal,
          'isCompleted': true,
          'aiReason': 'Gold standard treatment to reduce obsessions and compulsions',
          'effectiveness': 0.90,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Challenging (adaptive)',
          'progress': [true, true, true, true, true, true, true], // Last 7 days
        },
        {
          'title': 'Mindfulness of Thoughts',
          'description': 'Practice observing thoughts without engaging',
          'icon': Icons.cloud,
          'color': Colors.blueGrey,
          'isCompleted': false,
          'aiReason': 'Reduces reactivity to intrusive thoughts',
          'effectiveness': 0.82,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Cognitive Restructuring',
          'description': 'Challenge and reframe obsessive thoughts',
          'icon': Icons.swap_horiz,
          'color': Colors.indigo,
          'isCompleted': false,
          'aiReason': 'Helps identify and challenge OCD-related cognitive distortions',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate to Challenging',
          'progress': [false, true, false, true, false, true, false], // Last 7 days
        },
        {
          'title': 'Relaxation Techniques',
          'description': '15 minutes of progressive muscle relaxation',
          'icon': Icons.spa,
          'color': Colors.lightBlue,
          'isCompleted': true,
          'aiReason': 'Reduces physical tension associated with anxiety and obsessions',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Uncertainty Training',
          'description': 'Practice tolerating uncertainty in low-risk situations',
          'icon': Icons.help_outline,
          'color': Colors.orange,
          'isCompleted': false,
          'aiReason': 'Builds tolerance for uncertainty which is often difficult in OCD',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate to Challenging',
          'progress': [false, true, false, false, true, false, false], // Last 7 days
        },
      ],
      'Bipolar Disorder': [
        {
          'title': 'Mood Tracking',
          'description': 'Record your mood, energy, and sleep patterns',
          'icon': Icons.mood,
          'color': Colors.amber,
          'isCompleted': true,
          'aiReason': 'Helps identify early warning signs of mood episodes',
          'effectiveness': 0.90,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Sleep Hygiene',
          'description': 'Maintain consistent sleep and wake times',
          'icon': Icons.bedtime,
          'color': Colors.indigo,
          'isCompleted': false,
          'aiReason': 'Sleep disruption can trigger mood episodes',
          'effectiveness': 0.95,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, false, false, true, false, false], // Last 7 days
        },
        {
          'title': 'Stress Management',
          'description': 'Practice a stress reduction technique for 15 minutes',
          'icon': Icons.spa,
          'color': Colors.teal,
          'isCompleted': true,
          'aiReason': 'Stress can trigger or worsen mood episodes',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, false, true, true, false, true, true], // Last 7 days
        },
        {
          'title': 'Medication Adherence',
          'description': 'Take medications as prescribed',
          'icon': Icons.medication,
          'color': Colors.red,
          'isCompleted': true,
          'aiReason': 'Medication is a cornerstone of bipolar disorder management',
          'effectiveness': 0.98,
          'recommendedFrequency': 'As prescribed',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, true, true, true, true], // Last 7 days
        },
        {
          'title': 'Activity Moderation',
          'description': 'Balance activities to avoid overcommitment',
          'icon': Icons.balance,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Helps prevent overstimulation that could trigger mania',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [false, true, false, true, false, false, false], // Last 7 days
        },
      ],
      'PTSD': [
        {
          'title': 'Grounding Techniques',
          'description': 'Practice 5-4-3-2-1 sensory grounding',
          'icon': Icons.spa,
          'color': Colors.green,
          'isCompleted': true,
          'aiReason': 'Helps manage flashbacks and dissociation',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily and during triggers',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Progressive Exposure',
          'description': 'Gradual exposure to trauma-related triggers',
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'isCompleted': false,
          'aiReason': 'Reduces avoidance and helps process traumatic memories',
          'effectiveness': 0.90,
          'recommendedFrequency': '2-3 times per week',
          'adaptiveDifficulty': 'Challenging (adaptive)',
          'progress': [true, false, true, false, false, true, false], // Last 7 days
        },
        {
          'title': 'Deep Breathing',
          'description': '10 cycles of deep breathing',
          'icon': Icons.air,
          'color': Colors.lightBlue,
          'isCompleted': true,
          'aiReason': 'Activates parasympathetic nervous system to reduce hyperarousal',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Safe Place Visualization',
          'description': 'Visualize your safe place for 5 minutes',
          'icon': Icons.security,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Provides mental refuge during distress',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily and as needed',
          'adaptiveDifficulty': 'Easy',
          'progress': [false, true, false, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Trigger Identification',
          'description': 'Record triggers and response patterns',
          'icon': Icons.find_in_page,
          'color': Colors.purple,
          'isCompleted': true,
          'aiReason': 'Helps identify and prepare for trauma triggers',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, true, false, true], // Last 7 days
        },
      ],
      'Schizophrenia': [
        {
          'title': 'Reality Testing',
          'description': 'Practice checking evidence for thoughts and perceptions',
          'icon': Icons.check_circle,
          'color': Colors.blue,
          'isCompleted': true,
          'aiReason': 'Helps distinguish real from hallucinations or delusions',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily and as needed',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Medication Adherence',
          'description': 'Take medications as prescribed',
          'icon': Icons.medication,
          'color': Colors.red,
          'isCompleted': true,
          'aiReason': 'Foundation of symptom management',
          'effectiveness': 0.95,
          'recommendedFrequency': 'As prescribed',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, true, true, true, true, true, true], // Last 7 days
        },
        {
          'title': 'Social Skills Practice',
          'description': 'Engage in a planned social interaction',
          'icon': Icons.people,
          'color': Colors.green,
          'isCompleted': false,
          'aiReason': 'Helps maintain social functioning and reality connections',
          'effectiveness': 0.80,
          'recommendedFrequency': '2-3 times per week',
          'adaptiveDifficulty': 'Moderate to Challenging',
          'progress': [false, true, false, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Stress Management',
          'description': 'Practice a relaxation technique for 15 minutes',
          'icon': Icons.spa,
          'color': Colors.teal,
          'isCompleted': false,
          'aiReason': 'Stress can worsen psychotic symptoms',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, false, true, false, false, true, false], // Last 7 days
        },
        {
          'title': 'Cognitive Enhancement',
          'description': 'Complete 15 minutes of cognitive exercises',
          'icon': Icons.psychology,
          'color': Colors.purple,
          'isCompleted': true,
          'aiReason': 'Helps maintain cognitive functioning',
          'effectiveness': 0.70,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
      ],
      'Eating Disorders': [
        {
          'title': 'Regular Meal Plan',
          'description': 'Follow structured meal plan with all meals and snacks',
          'icon': Icons.restaurant,
          'color': Colors.orange,
          'isCompleted': true,
          'aiReason': 'Establishes regular eating patterns and nutritional intake',
          'effectiveness': 0.95,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Challenging',
          'progress': [true, true, false, true, true, true, true], // Last 7 days
        },
        {
          'title': 'Mindful Eating',
          'description': 'Practice mindful eating for one meal',
          'icon': Icons.restaurant_menu,
          'color': Colors.teal,
          'isCompleted': false,
          'aiReason': 'Builds healthy relationship with food and reduces anxiety',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, false, false, true, false], // Last 7 days
        },
        {
          'title': 'Body Neutrality',
          'description': 'Practice body neutrality affirmations',
          'icon': Icons.favorite,
          'color': Colors.pink,
          'isCompleted': true,
          'aiReason': 'Reduces body image distress',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Challenging',
          'progress': [true, true, true, false, true, false, true], // Last 7 days
        },
        {
          'title': 'Emotion Regulation',
          'description': 'Identify emotions before and after eating',
          'icon': Icons.mood,
          'color': Colors.purple,
          'isCompleted': false,
          'aiReason': 'Helps separate emotions from eating behaviors',
          'effectiveness': 0.85,
          'recommendedFrequency': 'With each meal',
          'adaptiveDifficulty': 'Moderate',
          'progress': [false, true, false, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Food Challenge',
          'description': 'Include one challenging food in your meal',
          'icon': Icons.sports_score,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Gradually reduces food-related fear and avoidance',
          'effectiveness': 0.90,
          'recommendedFrequency': '2-3 times per week',
          'adaptiveDifficulty': 'Challenging (adaptive)',
          'progress': [true, false, true, false, false, false, false], // Last 7 days
        },
      ],
      'BPD': [
        {
          'title': 'Emotion Regulation',
          'description': 'Practice DBT emotion regulation skill',
          'icon': Icons.psychology,
          'color': Colors.purple,
          'isCompleted': true,
          'aiReason': 'Core skill for managing emotional intensity',
          'effectiveness': 0.90,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Distress Tolerance',
          'description': 'Use TIPP or STOP skill during distress',
          'icon': Icons.healing,
          'color': Colors.red,
          'isCompleted': false,
          'aiReason': 'Helps manage crisis without making situation worse',
          'effectiveness': 0.85,
          'recommendedFrequency': 'As needed',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Interpersonal Effectiveness',
          'description': 'Practice DEAR MAN skill in a conversation',
          'icon': Icons.people,
          'color': Colors.green,
          'isCompleted': true,
          'aiReason': 'Improves interpersonal communication and boundary-setting',
          'effectiveness': 0.80,
          'recommendedFrequency': '2-3 times per week',
          'adaptiveDifficulty': 'Challenging',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Mindfulness',
          'description': '10 minutes of mindfulness practice',
          'icon': Icons.self_improvement,
          'color': Colors.blue,
          'isCompleted': false,
          'aiReason': 'Foundation skill for DBT and emotional regulation',
          'effectiveness': 0.75,
          'adaptiveDifficulty' : 'Medium',
          'progress': [true,true,false,true,true,true,false],

        },
        {
          'title': 'Splitting Awareness',
          'description': 'Notice black and white thinking and find middle ground',
          'icon': Icons.compare_arrows,
          'color': Colors.teal,
          'isCompleted': true,
          'aiReason': 'Reduces cognitive distortions common in BPD',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Challenging',
          'progress': [true, false, true, false, true, true, true], // Last 7 days
        },
      ],
      'Addiction': [
        {
          'title': 'Urge Surfing',
          'description': 'Practice mindfully observing cravings without acting',
          'icon': Icons.waves,
          'color': Colors.blue,
          'isCompleted': true,
          'aiReason': 'Builds tolerance for discomfort without relapse',
          'effectiveness': 0.88,
          'recommendedFrequency': 'As needed during cravings',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'HALT Check-in',
          'description': 'Monitor if you\'re Hungry, Angry, Lonely, or Tired',
          'icon': Icons.check_circle_outline,
          'color': Colors.amber,
          'isCompleted': false,
          'aiReason': 'Addresses common relapse triggers',
          'effectiveness': 0.85,
          'recommendedFrequency': '3 times daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Trigger Avoidance Plan',
          'description': 'Review and update trigger avoidance strategies',
          'icon': Icons.do_not_disturb,
          'color': Colors.red,
          'isCompleted': true,
          'aiReason': 'Proactive planning reduces relapse risk',
          'effectiveness': 0.92,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
        {
          'title': 'Replacement Activity',
          'description': 'Engage in healthy rewarding alternative activity',
          'icon': Icons.swap_horiz,
          'color': Colors.green,
          'isCompleted': false,
          'aiReason': 'Builds new reward pathways in the brain',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [false, true, false, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Support Meeting',
          'description': 'Attend recovery support group',
          'icon': Icons.people,
          'color': Colors.purple,
          'isCompleted': true,
          'aiReason': 'Social support significantly improves recovery outcomes',
          'effectiveness': 0.95,
          'recommendedFrequency': '2-3 times per week',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, false, true, true, true, false, true], // Last 7 days
        },
      ],
    };
    if (!disorderTasks.containsKey(disorder)) {
      return [
        {
          'title': 'Mindfulness Practice',
          'description': '10 minutes of mindfulness meditation',
          'icon': Icons.self_improvement,
          'color': Colors.blue,
          'isCompleted': true,
          'aiReason': 'Improves awareness of thoughts and emotions',
          'effectiveness': 0.80,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, true, false, true, true, true], // Last 7 days
        },
        {
          'title': 'Journaling',
          'description': 'Write about your thoughts and feelings',
          'icon': Icons.book,
          'color': Colors.teal,
          'isCompleted': false,
          'aiReason': 'Helps process emotions and identify patterns',
          'effectiveness': 0.75,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Easy',
          'progress': [true, false, true, true, false, false, false], // Last 7 days
        },
        {
          'title': 'Physical Activity',
          'description': '20 minutes of moderate exercise',
          'icon': Icons.directions_run,
          'color': Colors.green,
          'isCompleted': true,
          'aiReason': 'Improves mood and reduces stress',
          'effectiveness': 0.85,
          'recommendedFrequency': 'Daily',
          'adaptiveDifficulty': 'Moderate',
          'progress': [true, true, false, true, true, false, true], // Last 7 days
        },
      ];
    }
    
    return disorderTasks[disorder]!;
  }

  Widget _buildRecommendedTasks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insight card with personalized recommendations
          _buildAIInsightCard(),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Recommended Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          // Show AI effectiveness metrics
          _buildEffectivenessOverview(),
          
          const SizedBox(height: 16),
          
          ...recommendedTasks.map((task) => _buildEnhancedTaskItem(task)),
        ],
      ),
    );
  }
  
  Widget _buildAIInsightCard() {
    if (aiInsight == null) return const SizedBox.shrink();
    
    final Color disorderColor = _getDisorderColor(widget.disorder);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            disorderColor.withOpacity(0.9),
            disorderColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: disorderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Assistant Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Text(
            aiInsight!['summary'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Recommendation:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            aiInsight!['recommendation'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aiInsight!['progress'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEffectivenessOverview() {
    // Calculate average effectiveness
    double averageEffectiveness = 0;
    if (recommendedTasks.isNotEmpty) {
      averageEffectiveness = recommendedTasks.fold(
          0.0, (sum, task) => sum + (task['effectiveness'] as double)) / 
          recommendedTasks.length;
    }
    
    // Calculate completed tasks percentage for this week
    int completedTasks = recommendedTasks
        .where((task) => task['isCompleted'] == true)
        .length;
    
    double completionRate = recommendedTasks.isNotEmpty 
        ? completedTasks / recommendedTasks.length 
        : 0;
        
    // Calculate consistency based on progress array
    double consistency = 0;
    if (recommendedTasks.isNotEmpty) {
      int totalDays = 0;
      int completedDays = 0;
      
      for (var task in recommendedTasks) {
        List<bool> progress = List<bool>.from(task['progress']);
        totalDays += progress.length;
        completedDays += progress.where((day) => day).length;
      }
      
      consistency = totalDays > 0 ? completedDays / totalDays : 0;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Activity Tracking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEffectivenessMetric(
                'Activity Effectiveness',
                averageEffectiveness,
                Icons.auto_graph,
                Colors.blue,
                suffix: '%',
                multiplier: 100,
              ),
              _buildEffectivenessMetric(
                'Current Completion',
                completionRate,
                Icons.check_circle_outline,
                Colors.green,
                suffix: '%',
                multiplier: 100,
              ),
              _buildEffectivenessMetric(
                'Weekly Consistency',
                consistency,
                Icons.calendar_today,
                Colors.orange,
                suffix: '%',
                multiplier: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEffectivenessMetric(
    String label, 
    double value, 
    IconData icon, 
    Color color, {
    String suffix = '', 
    double multiplier = 1,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * multiplier).toInt()}$suffix',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildEnhancedTaskItem(Map<String, dynamic> task) {
    final List<bool> progress = List<bool>.from(task['progress']);
    final int completedDays = progress.where((day) => day).length;
    
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: task['isCompleted'] 
              ? task['color'].withOpacity(0.5) 
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: task['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            task['icon'],
            color: task['color'],
            size: 28,
          ),
        ),
        title: Text(
          task['title'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(7, (index) => 
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < progress.length && progress[index]
                          ? task['color']
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedDays/7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Checkbox(
          value: task['isCompleted'],
          onChanged: (value) {
            setState(() {
              task['isCompleted'] = value;
              // Update progress array
              List<bool> updatedProgress = List<bool>.from(task['progress']);
              if (updatedProgress.isNotEmpty) {
                updatedProgress[updatedProgress.length - 1] = value ?? false;
                task['progress'] = updatedProgress;
              }
              // Recalculate progress percentage
              _calculateProgress();
            });
          },
          activeColor: task['color'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // AI Reasoning
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.psychology, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Recommendation Reason:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['aiReason'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Effectiveness and Frequency
                Row(
                  children: [
                    // Effectiveness
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Effectiveness',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearPercentIndicator(
                            percent: task['effectiveness'] as double,
                            lineHeight: 8,
                            animation: true,
                            animationDuration: 1000,
                            backgroundColor: Colors.grey[200],
                            progressColor: task['color'],
                            barRadius: const Radius.circular(8),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${((task['effectiveness'] as double) * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Frequency
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended Frequency',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: task['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task['recommendedFrequency'],
                              style: TextStyle(
                                fontSize: 12,
                                color: task['color'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Difficulty level
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Difficulty Level:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task['adaptiveDifficulty'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _getDifficultyColor(task['adaptiveDifficulty']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    if (difficulty.contains('Easy')) return Colors.green;
    if (difficulty.contains('Moderate')) return Colors.orange;
    if (difficulty.contains('Challenging')) return Colors.red;
    return Colors.grey;
  }
  
  Color _getDisorderColor(String disorder) {
    switch (disorder) {
      case 'Depression':
        return Colors.blue.shade700;
      case 'Anxiety':
        return Colors.teal.shade600;
      case 'ADHD':
        return Colors.orange.shade700;
      case 'OCD':
        return Colors.indigo.shade600;
      case 'Bipolar Disorder':
        return Colors.purple.shade600;
      case 'PTSD':
        return Colors.red.shade700;
      case 'Schizophrenia':
        return Colors.deepPurple.shade700;
      case 'Eating Disorders':
        return Colors.pink.shade600;
      case 'BPD':
        return Colors.amber.shade800;
      case 'Addiction':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade600; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.disorder} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  _buildRecommendedTasks(),
                ],
              ),
            ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          primaryColor: Theme.of(context).primaryColor,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          iconSize: 22,
          elevation: 8,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            // Handle navigation based on bottom nav selection
            if (index == 1) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AIChatScreen()),
              );
            } else if (index == 2) {
              // Navigate to Analytics or Progress screen
            } else if (index == 3) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const FeaturesScreen()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
              tooltip: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'AI Chat',
              tooltip: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Progress',
              tooltip: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Features',
              tooltip: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Calculate completion percentage for the progress bar
    int totalActivities = recommendedTasks.length;
    int completedActivities = recommendedTasks.where((task) => 
      task['isCompleted'] == true).length;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Streak Card
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0), // Even padding
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department, 
                                color: Colors.orange,
                                size: 22),
                            SizedBox(width: 4), // Reduced spacing
                            Text(
                              'Streak',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Progress Card
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0), // Even padding
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, 
                                color: Colors.green,
                                size: 22),
                            SizedBox(width: 4),
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CircularPercentIndicator(
                          radius: 33.0, // Slightly smaller for better fit
                          lineWidth: 6.0,
                          percent: progressPercentage,
                          center: Text(
                            '${(progressPercentage * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13
                            ),
                          ),
                          progressColor: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 800,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Weekly Activity Progress Bar
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Activity Completion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(progressPercentage * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearPercentIndicator(
                  percent: progressPercentage,
                  lineHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  progressColor: Colors.green,
                  barRadius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 800,
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                  ),
                  trailing: Text(
                    '$completedActivities/$totalActivities tasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}