import 'package:flutter/material.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _userDisorders = [];
  List<Map<String, dynamic>> _userReports = [];
  
  // Static premium subscription data for demo
  final bool _isPremium = true;
  final String _subscriptionTier = 'Premium Plus';
  final String _subscriptionExpiry = '2025-05-15';
  final List<String> _premiumFeatures = [
    'Unlimited disorder tracking',
    'Weekly detailed reports',
    'Therapy session reminders',
    'Exclusive content & resources',
    'Priority support'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get basic user info from Supabase auth
      final user = SupabaseService.currentUser;
      
      if (user != null) {
        print('Found current user: ${user.id}');
        print('User email: ${user.email}');
        print('User metadata: ${user.userMetadata}');
        
        // Get user profile data from the users table
        final userData = await SupabaseService.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        print('User data from DB: $userData');
        
        // Get user disorders
        final disorders = await SupabaseService.getUserDisorder();
        print('User disorders: $disorders');
        
        // If no disorders yet, provide sample data for testing
        List<Map<String, dynamic>> finalDisorders = disorders.isNotEmpty 
            ? disorders 
            : [
                {'disorder': 'Anxiety', 'added_date': '2025-03-01'},
                {'disorder': 'Depression', 'added_date': '2025-02-15'}
              ];
        
        // Get user reports or use sample data if none exist
        List<Map<String, dynamic>> reports;
        try {
          reports = await SupabaseService.client
              .from('user_reports')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false);
          print('User reports from DB: $reports');
        } catch (e) {
          print('Error fetching reports: $e');
          reports = [];
        }
        
        // If no reports, provide sample data
        List<Map<String, dynamic>> finalReports = reports.isNotEmpty 
            ? reports 
            : [
                {
                  'title': 'Monthly Progress Report',
                  'created_at': '2025-03-15',
                  'report_type': 'monthly',
                  'status': 'completed'
                },
                {
                  'title': 'Anxiety Management Report',
                  'created_at': '2025-02-28',
                  'report_type': 'disorder',
                  'status': 'completed'
                },
                {
                  'title': 'Weekly Mood Summary',
                  'created_at': '2025-03-30',
                  'report_type': 'weekly',
                  'status': 'in_progress'
                },
              ];
        
        setState(() {
          // Set user name based on available data, with fallbacks
          _userName = userData?['name']?.toString() ?? 
                      user.userMetadata?['name']?.toString() ?? 
                      user.email?.split('@')[0] ?? 
                      'User';
                      
          _userEmail = user.email ?? 'No email available';
          _userDisorders = finalDisorders;
          _userReports = finalReports;
          _isLoading = false;
          
          // In a real app, you would uncomment these to fetch from DB
          // _isPremium = userData?['is_premium'] ?? false; 
          // _subscriptionTier = userData?['subscription_tier'] ?? 'Free';
          // _subscriptionExpiry = userData?['subscription_expiry'] ?? DateTime.now().add(const Duration(days: 30)).toString();
        });
      } else {
        print('No user found - redirecting to login');
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Even if there's an error, populate with fallback data to show UI
      setState(() {
        _userName = 'Demo User';
        _userEmail = 'demo@example.com';
        _userDisorders = [
          {'disorder': 'Anxiety', 'added_date': '2025-03-01'},
          {'disorder': 'Depression', 'added_date': '2025-02-15'}
        ];
        _userReports = [
          {
            'title': 'Monthly Progress Report',
            'created_at': '2025-03-15',
            'report_type': 'monthly',
            'status': 'completed'
          },
        ];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Premium Status Section
                    _buildPremiumStatusSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Subscription Section
                    _buildSubscriptionSection(),
                    
                    const SizedBox(height: 24),
                    
                    // My Disorders Section
                    _buildDisordersSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Reports Section
                    _buildReportsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.purple.shade200,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isPremium)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _subscriptionTier,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to edit profile screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile coming soon!')),
                      );
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatusSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isPremium ? Colors.amber.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPremium ? Icons.verified_user : Icons.no_accounts,
                  color: _isPremium ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'SUBSCRIPTION STATUS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _isPremium ? Colors.amber.shade800 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.amber.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _isPremium ? 'PREMIUM USER' : 'FREE USER',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isPremium ? Colors.amber.shade900 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isPremium)
                    Text(
                      'Expires: ${_formatDate(_subscriptionExpiry)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _isPremium
                ? ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to subscription management page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subscription management coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Manage Subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to upgrade page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upgrade page coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Upgrade to Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Card(
      elevation: 3,
      color: _isPremium ? Colors.amber.shade50 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPremium ? Icons.workspace_premium : Icons.star_border,
                  color: _isPremium ? Colors.amber : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Subscription Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isPremium ? Colors.amber.shade800 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.amber.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isPremium ? _subscriptionTier : 'Free Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isPremium ? Colors.amber.shade900 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _isPremium
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your subscription expires on: ${_formatDate(_subscriptionExpiry)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Premium Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        _premiumFeatures.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(_premiumFeatures[index]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Premium for additional features:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to subscription page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upgrade page coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Upgrade Now'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisordersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _userDisorders.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No conditions added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userDisorders.length,
                itemBuilder: (context, index) {
                  final disorder = _userDisorders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getDisorderIcon(disorder['disorder']),
                      title: Text(disorder['disorder']),
                      subtitle: disorder['added_date'] != null
                          ? Text('Added: ${_formatDate(disorder['added_date'])}')
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to disorder dashboard
                        // Using a SnackBar for now
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing details for ${disorder['disorder']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to add disorder screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add condition feature coming soon!')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Condition'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        if (!_isPremium && _userDisorders.length >= 2) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free users can track up to 2 conditions. Upgrade to Premium for unlimited tracking!',
                    style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _userReports.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No reports generated yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userReports.length,
                itemBuilder: (context, index) {
                  final report = _userReports[index];
                  
                  IconData iconData;
                  Color iconColor;
                  
                  // Determine icon based on report type
                  switch (report['report_type']) {
                    case 'monthly':
                      iconData = Icons.calendar_month;
                      iconColor = Colors.blue;
                      break;
                    case 'weekly':
                      iconData = Icons.date_range;
                      iconColor = Colors.green;
                      break;
                    case 'disorder':
                      iconData = Icons.psychology;
                      iconColor = Colors.purple;
                      break;
                    default:
                      iconData = Icons.description;
                      iconColor = Colors.grey;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.2),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(report['title'] ?? 'Report'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Generated: ${_formatDate(report['created_at'])}'),
                          if (report['status'] == 'in_progress')
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'In Progress',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      trailing: report['status'] == 'completed'
                          ? IconButton(
                              icon: const Icon(Icons.download, color: Colors.blue),
                              onPressed: () {
                                // Download report logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Downloading report...'),
                                  ),
                                );
                              },
                            )
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                      onTap: () {
                        // View report details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing report: ${report['title']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Generate new report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generating new report...'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_chart),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (!_isPremium) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free users can generate basic monthly reports. Upgrade to Premium for detailed weekly reports and more insights!',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _getDisorderIcon(String disorder) {
    final Map<String, IconData> disorderIcons = {
      'Depression': Icons.cloud,
      'Anxiety': Icons.vibration,
      'Bipolar Disorder': Icons.swap_vert,
      'PTSD': Icons.flash_on,
      'OCD': Icons.replay,
      'ADHD': Icons.blur_on,
      'Schizophrenia': Icons.psychology,
      'Eating Disorders': Icons.restaurant,
      'BPD': Icons.waves,
      'Addiction': Icons.link,
    };

    final IconData icon = disorderIcons[disorder] ?? Icons.health_and_safety;
    final Color color = _getDisorderColor(disorder);

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  Color _getDisorderColor(String disorder) {
    final Map<String, Color> disorderColors = {
      'Depression': Colors.indigo,
      'Anxiety': Colors.orange,
      'Bipolar Disorder': Colors.purple,
      'PTSD': Colors.red,
      'OCD': Colors.teal,
      'ADHD': Colors.blue,
      'Schizophrenia': Colors.deepPurple,
      'Eating Disorders': Colors.pink,
      'BPD': Colors.amber,
      'Addiction': Colors.brown,
    };

    return disorderColors[disorder] ?? Colors.deepPurple;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      print('Error formatting date $dateString: $e');
      return 'Unknown';
    }
  }
}

// This is a placeholder for the DisorderDashboardScreen
// Replace it with your actual implementation
class DisorderDashboardScreen extends StatelessWidget {
  final String disorder;

  const DisorderDashboardScreen({super.key, required this.disorder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(disorder),
      ),
      body: Center(
        child: Text('$disorder Dashboard Coming Soon'),
      ),
    );
  }
}