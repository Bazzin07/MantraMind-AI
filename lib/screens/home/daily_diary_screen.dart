import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mantramind/services/mood_ai_service.dart';
import 'package:mantramind/services/diary_service.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/models/diary_entry.dart';

class DailyDiaryScreen extends StatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  State<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends State<DailyDiaryScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _aiSummary;
  double? _sentiment;
  String? _emotion; // emotion label
  List<DiaryEntry> _entries = [];
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
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _loadEntries() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final list = await DiaryService.listRecent(user.id, days: 14);
    setState(() => _entries = list);
  }

  Future<void> _save() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);

    try {
      final analysis = await MoodAIService.analyzeDiary(text);
      _sentiment = (analysis['sentiment_score'] as num?)?.toDouble();
      _emotion = analysis['mood_emotion'] as String?;
      _aiSummary = analysis['summary'] as String?;

      await DiaryService.createEntry(
        userId: user.id,
        content: text,
        sentimentScore: _sentiment,
        moodLabel: _emotion,
        aiSummary: _aiSummary,
      );

      await _loadEntries();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary saved')),
      );
      _controller.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save diary: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Diary')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _headerCard(theme),
            const SizedBox(height: 12),
            _editorCard(theme),
            const SizedBox(height: 12),
            if (_aiSummary != null) _insightCard(theme),
            const SizedBox(height: 12),
            if (_entries.isNotEmpty) _trendCard(theme),
            const SizedBox(height: 16),
            Text('Recent entries', style: theme.textTheme.titleMedium),
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
            label: Text(_saving ? 'Saving...' : 'Save Entry'),
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
            child: const Icon(Icons.book, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Capture a few sentences about your day. We’ll keep it private and reflect it back with a short, gentle summary.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorCard(ThemeData theme) {
    final count = _controller.text.length;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s entry', style: theme.textTheme.titleMedium),
                Text('$count/1000', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLength: 1000,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'How did today feel? Any moments that stood out? ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: emotions
                  .map((e) => ChoiceChip(
                        label: Text(e),
                        selected: _emotion == e,
                        onSelected: (_) => setState(() => _emotion = e),
                      ))
                  .toList(),
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
            Text('AI reflection', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_aiSummary ?? ''),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (_emotion != null)
                  Chip(label: Text('Emotion: ${_emotion!}')),
                if (_sentiment != null)
                  Chip(
                      label:
                          Text('Sentiment: ${_sentiment!.toStringAsFixed(2)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendCard(ThemeData theme) {
    // Prepare chart data: last up to 14 entries with non-null sentiment
    final recent = _entries
        .where((e) => e.sentimentScore != null)
        .take(14)
        .toList()
        .reversed
        .toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (var i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].sentimentScore!.toDouble()));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentiment trend (last ${recent.length} entries)',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: -1,
                  maxY: 1,
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.5,
                        getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (recent.length / 3).clamp(1, 6).toDouble(),
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

  Widget _entryTile(DiaryEntry e) {
    final date = DateFormat('MMM d, h:mm a').format(e.createdAt);
    final emoji = _emotionEmoji(e.moodLabel);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      leading: CircleAvatar(child: Text(emoji)),
      title: Text(e.aiSummary ?? e.content,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('$date • ${e.moodLabel ?? 'unknown'}'),
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
