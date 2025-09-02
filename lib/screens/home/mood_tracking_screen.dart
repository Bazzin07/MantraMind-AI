import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mantramind/models/mood_entry.dart';
import 'package:mantramind/services/mood_service.dart';
import 'package:mantramind/services/mood_ai_service.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/notification_service.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _score = 3; // 1-5
  String _mood = 'neutral';
  final _noteCtrl = TextEditingController();
  final _triggersCtrl = TextEditingController();
  bool _saving = false;
  String? _aiInsight;

  // New: recent entries and emotions list (consistent with Daily Diary)
  List<MoodEntry> _entries = [];
  final emotions = const [
    'happy',
    'sad',
    'angry',
    'anxious',
    'stressed',
    'calm',
    'joy',
    'neutral',
    'lonely',
    'tired'
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final list = await MoodService.listEntries(user.id);
    setState(() => _entries = list);
  }

  Future<void> _save() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final insight = await MoodAIService.generateMoodInsight(
        mood: _mood,
        moodScore: _score,
        note: _noteCtrl.text.trim(),
        triggers: _triggersCtrl.text.trim(),
      );
      _aiInsight = insight;

      await MoodService.createEntry(
        userId: user.id,
        mood: _mood,
        moodScore: _score,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        triggers: _triggersCtrl.text.trim().isEmpty
            ? null
            : _triggersCtrl.text.trim(),
        aiInsight: _aiInsight,
      );

      await _loadEntries();

      // Refresh tomorrow morning's motivational quote based on the latest trend
      await NotificationService.scheduleDailyMotivation(hour: 8, minute: 0);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mood saved')));
      _noteCtrl.clear();
      _triggersCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save mood: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- Demo/Test notification actions ---
  Future<void> _sendTestNow() async {
    try {
      await NotificationService.showTestNotification(
        title: 'MantraMind',
        body: 'Mental health is not a destination, but a process. Its about how you drive, not where you\'re going.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent test notification')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send test notification: $e')),
      );
    }
  }

  Future<void> _scheduleTestIn10s() async {
    try {
      await NotificationService.scheduleTestInSeconds(10,
          title: 'MantraMind Test', body: 'Scheduled in 10 seconds');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled test in 10s')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule test: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracking')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _headerCard(theme),
            const SizedBox(height: 12),
            _editorCard(theme),
            const SizedBox(height: 12),
            // Demo/Test notifications section
            _demoNotificationCard(theme),
            const SizedBox(height: 12),
            if (_aiInsight != null) _insightCard(theme),
            const SizedBox(height: 16),
            if (_entries.isNotEmpty) _trendCard(theme),
            const SizedBox(height: 16),
            Text('Recent moods', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              Text('No entries yet', style: TextStyle(color: Colors.grey[600]))
            else
              ..._entries.map(_entryTile),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log your mood with a quick emotion and score. We’ll show trends and a short insight to help you reflect.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s mood', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: emotions
                  .map((e) => ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_emotionEmoji(e)),
                            const SizedBox(width: 6),
                            Text(e),
                          ],
                        ),
                        selected: _mood == e,
                        onSelected: (_) => setState(() => _mood = e),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Intensity'),
                Expanded(
                  child: Slider(
                    value: _score.toDouble(),
                    onChanged: (v) => setState(() => _score = v.round()),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _score.toString(),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Optional note', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggersCtrl,
              decoration: const InputDecoration(
                labelText: 'Triggers (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoNotificationCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 20),
                const SizedBox(width: 8),
                Text('Demo notifications', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Trigger test notifications for the demo. These do not affect your schedule.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendTestNow,
                    child: const Text('Send test now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _scheduleTestIn10s,
                    child: const Text('Schedule in 10s'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI insight', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_aiInsight ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _trendCard(ThemeData theme) {
    // Prepare chart data (last up to 14 entries, newest last)
    final recent = _entries.take(14).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].moodScore.toDouble()));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mood trend (last ${recent.length} entries)',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 5,
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (recent.length / 3).clamp(1, 4).toDouble(),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= recent.length) {
                            return const SizedBox.shrink();
                          }
                          final d = recent[idx].createdAt;
                          return Text(DateFormat('MM/dd').format(d),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryTile(MoodEntry e) {
    final date = DateFormat('MMM d, h:mm a').format(e.createdAt);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      leading: CircleAvatar(child: Text(_emotionEmoji(e.mood))),
      title: Text('${e.mood} • ${e.moodScore}/5'),
      subtitle: Text(date),
      trailing:
          e.aiInsight != null ? const Icon(Icons.auto_awesome, size: 18) : null,
    );
  }

  String _emotionEmoji(String? emotion) {
    switch (emotion) {
      case 'happy':
      case 'joy':
        return '😊';
      case 'sad':
        return '😔';
      case 'angry':
        return '😠';
      case 'anxious':
        return '😟';
      case 'stressed':
        return '😣';
      case 'calm':
        return '😌';
      case 'lonely':
        return '😞';
      case 'tired':
        return '🥱';
      default:
        return '😐';
    }
  }
}
