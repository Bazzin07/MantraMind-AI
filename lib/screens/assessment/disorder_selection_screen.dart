import 'package:flutter/material.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/screens/home/dashboard_screen.dart';

class DisorderSelectionScreen extends StatefulWidget {
  const DisorderSelectionScreen({super.key});

  @override
  State<DisorderSelectionScreen> createState() =>
      _DisorderSelectionScreenState();
}

class _DisorderSelectionScreenState extends State<DisorderSelectionScreen> {
  String? selectedDisorder;

  final List<Map<String, dynamic>> disorders = [
    {'name': 'Depression', 'description': 'Persistent sadness', 'icon': Icons.cloud, 'color': Colors.indigo},
    {'name': 'Anxiety', 'description': 'Excessive worry', 'icon': Icons.vibration, 'color': Colors.orange},
    {'name': 'Bipolar Disorder', 'description': 'Mood swings', 'icon': Icons.swap_vert, 'color': Colors.purple},
    {'name': 'PTSD', 'description': 'Trauma response', 'icon': Icons.flash_on, 'color': Colors.red},
    {'name': 'OCD', 'description': 'Repetitive behaviors', 'icon': Icons.replay, 'color': Colors.teal},
    {'name': 'ADHD', 'description': 'Inattention & hyperactivity', 'icon': Icons.blur_on, 'color': Colors.blue},
    {'name': 'Schizophrenia', 'description': 'Distorted perception', 'icon': Icons.psychology, 'color': Colors.deepPurple},
    {'name': 'Eating Disorders', 'description': 'Abnormal eating habits', 'icon': Icons.restaurant, 'color': Colors.pink},
    {'name': 'BPD', 'description': 'Unstable behavior', 'icon': Icons.waves, 'color': Colors.amber},
    {'name': 'Addiction', 'description': 'Substance dependence', 'icon': Icons.link, 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Condition'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildDisorderGrid()),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.15),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Disorder Selection', 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.5,
            )
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Select a condition you have been diagnosed with', 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 16, 
                color: Colors.grey[700],
                height: 1.3,
              )
            ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selectedDisorder == null 
                ? Colors.grey[100] 
                : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selectedDisorder == null 
                  ? Colors.grey[300]! 
                  : Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            child: Text(
              selectedDisorder == null ? 'No condition selected' : 'Selected: $selectedDisorder',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: selectedDisorder == null 
                  ? Colors.grey[600] 
                  : Theme.of(context).primaryColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisorderGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: disorders.length,
      itemBuilder: (context, index) {
        final disorder = disorders[index];
        final isSelected = selectedDisorder == disorder['name'];

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDisorder = disorder['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected ? disorder['color'].withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? disorder['color'] : Colors.grey[200]!,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                    ? disorder['color'].withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.15),
                  spreadRadius: isSelected ? 2 : 1,
                  blurRadius: isSelected ? 8 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: disorder['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    disorder['icon'], 
                    size: 38, 
                    color: disorder['color'],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  disorder['name'], 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: isSelected ? disorder['color'] : Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    disorder['description'], 
                    style: TextStyle(
                      fontSize: 13, 
                      color: Colors.grey[600]
                    ), 
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                if (isSelected) 
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: disorder['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle, 
                          color: disorder['color'], 
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: disorder['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: selectedDisorder == null ? null : () async {
          await SupabaseService.saveUserDisorder(selectedDisorder!);
           Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisorderDashboardScreen(disorder: selectedDisorder!),
      ),
    );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue to Dashboard', 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}