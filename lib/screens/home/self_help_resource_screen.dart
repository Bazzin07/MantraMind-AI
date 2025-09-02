import 'package:flutter/material.dart';
import 'package:mantramind/models/recommendation_item.dart';
import 'package:mantramind/services/recommendation_service.dart';

class SelfHelpResourceScreen extends StatefulWidget {
  const SelfHelpResourceScreen({super.key});

  @override
  State<SelfHelpResourceScreen> createState() => _SelfHelpResourceScreenState();
}

class _SelfHelpResourceScreenState extends State<SelfHelpResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';
  bool _loadingRecs = false;
  List<RecommendationItem> _recs = [];

  // Added rich content for each static item
  final List<Map<String, String>> _articles = const [
    {
      'title': 'Understanding Anxiety: What It Is and How It Feels',
      'subtitle': 'Learn symptoms, common triggers, and when to seek help.',
      'content': '''
Anxiety is a natural response to stress. It becomes a concern when it feels constant, overwhelming, or interferes with life.

Common signs:
- Restlessness, racing thoughts, difficulty concentrating
- Muscle tension, rapid heartbeat, shallow breathing
- Irritability, trouble sleeping, avoidance of situations

Common triggers:
- Work or academic pressure
- Health worries or uncertainty
- Social situations and performance

Quick relief strategies:
1) Box breathing: inhale 4s, hold 4s, exhale 4s, hold 4s (x4)
2) Grounding (5-4-3-2-1): 5 see, 4 touch, 3 hear, 2 smell, 1 taste
3) Gentle movement: walk, stretch, shake out tension

When to seek help:
- Anxiety persists for weeks and limits activities
- Panic attacks or intense physical symptoms
- You’re avoiding responsibilities or relationships

You’re not alone. Anxiety is common and treatable. Small steps help.
''',
    },
    {
      'title': 'The Science of Sleep and Mental Health',
      'subtitle': 'How better sleep hygiene supports mood and focus.',
      'content': '''
Sleep supports memory, attention, and emotional balance. Poor sleep can raise stress hormones and amplify anxiety or low mood.

Sleep hygiene essentials:
- Consistent schedule: same sleep/wake time daily
- Wind-down: dim lights, light reading, gentle stretches
- Cut stimulants: caffeine after noon, heavy meals before bed
- Bedroom: cool, dark, quiet; bed for sleep only

If you wake at night:
- Try a calm reset: slow breathing or read a page
- Avoid doomscrolling; low light helps melatonin

Aim for 7–9 hours. Prioritize rhythm over perfection.
''',
    },
    {
      'title': 'Self-Compassion Basics',
      'subtitle': 'Treat yourself like a friend—practical ways to begin.',
      'content': '''
Self-compassion means meeting your struggles with kindness, understanding, and support—like you would a friend.

Try this:
1) Mindfulness: Name what you’re feeling without judgment
2) Common humanity: Struggle is part of being human
3) Kind action: Hand to heart; say, “This is hard—and I can be kind to myself.”

Small daily practices build a supportive inner voice.
''',
    },
  ];

  final List<Map<String, String>> _tips = const [
    {
      'title': 'Box Breathing (4-4-4-4)',
      'subtitle': 'Inhale 4, hold 4, exhale 4, hold 4. Repeat x4.',
      'content': '''
How:
- Sit comfortably, relax shoulders
- Inhale through nose 4s
- Hold 4s
- Exhale through mouth 4s
- Hold 4s
Repeat 4–6 cycles. Notice your body calming.

Use before meetings, during anxiety, or to reset.
''',
    },
    {
      'title': '2-Minute Grounding',
      'subtitle': 'Name 5 things you see, 4 touch, 3 hear, 2 smell, 1 taste.',
      'content': '''
A quick 5–4–3–2–1 reset:
- 5 see
- 4 touch
- 3 hear
- 2 smell
- 1 taste

This re-anchors you in the present.
''',
    },
    {
      'title': 'Worry Window',
      'subtitle': 'Schedule 10 mins/day to write worries, then move on.',
      'content': '''
Give worry a dedicated slot:
1) Pick a daily 10-minute window
2) Collect worries during the day; set them aside
3) In your window, write them and plan next steps if useful
4) After time is up, gently redirect attention

This reduces rumination and builds control.
''',
    },
  ];

  final List<Map<String, String>> _guides = const [
    {
      'title': 'CBT Thought Record',
      'subtitle': 'Catch thoughts, challenge them, choose a balanced view.',
      'content': '''
A simple 5-step worksheet:
1) Situation: What happened?
2) Thought: What went through your mind?
3) Evidence: For and against the thought
4) Balanced view: A more helpful alternative
5) Outcome: How do you feel now?

Keep it short and practical. Repetition builds skill.
''',
    },
    {
      'title': 'Beginner Meditation (5 mins)',
      'subtitle': 'Gentle breath focus with a reset phrase.',
      'content': '''
Quick guide:
- Sit upright but relaxed; soften gaze or close eyes
- Inhale naturally; on exhale, silently say “Here” or “Soft”
- When the mind wanders, gently return to breath
- Use a 5-minute timer; end with one kind thought to yourself

Consistency over length—start small, return often.
''',
    },
    {
      'title': 'Creating a Coping Plan',
      'subtitle': 'Identify triggers, early signs, supports, and actions.',
      'content': '''
Build your plan:
- Triggers: Situations or patterns that set you off
- Early signs: First body or thought cues
- Supports: People, places, routines
- Actions: What you’ll try first, second, third
- Safety: Emergency contacts or crisis steps if needed

Keep it handy. Update as you learn what works.
''',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRecs();
  }

  Future<void> _fetchRecs() async {
    setState(() => _loadingRecs = true);
    try {
      final items =
          await RecommendationService.getPersonalizedRecommendations();
      if (!mounted) return;
      setState(() => _recs = items);
    } finally {
      if (mounted) setState(() => _loadingRecs = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Help Resource'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Tips'),
            Tab(text: 'Guides'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadingRecs ? null : _fetchRecs,
            icon: _loadingRecs
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Refresh recommendations',
          )
        ],
      ),
      body: Column(
        children: [
          if (_recs.isNotEmpty) _recommendationsBar(theme),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search resources...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(theme, _articles, 'article'),
                _buildList(theme, _tips, 'tip'),
                _buildList(theme, _guides, 'guide'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationsBar(ThemeData theme) {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Text('Recommended for you', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (_loadingRecs)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, i) {
                final r = _recs[i];
                final icon = r.category == 'tip'
                    ? Icons.lightbulb
                    : r.category == 'guide'
                        ? Icons.integration_instructions
                        : Icons.menu_book;
                return SizedBox(
                  width: 260,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openRecommendationDetail(r),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(r.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.subtitle,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (r.reason != null) ...[
                              const SizedBox(height: 8),
                              Text('Why: ${r.reason!}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _recs.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      ThemeData theme, List<Map<String, String>> items, String category) {
    final filtered = _query.isEmpty
        ? items
        : items
            .where((e) =>
                e['title']!.toLowerCase().contains(_query) ||
                e['subtitle']!.toLowerCase().contains(_query) ||
                (e['content']?.toLowerCase().contains(_query) ?? false))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('No results', style: TextStyle(color: Colors.grey[600])),
      );
    }

    final icon = category == 'tip'
        ? Icons.lightbulb
        : category == 'guide'
            ? Icons.integration_instructions
            : Icons.menu_book;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = filtered[i];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(item['title']!),
            subtitle: Text(item['subtitle']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDetail(
              context,
              title: item['title']!,
              subtitle: item['subtitle']!,
              content: item['content'] ?? '',
              category: category,
            ),
          ),
        );
      },
    );
  }

  void _openRecommendationDetail(RecommendationItem r) {
    // Try match static content by title; otherwise build a generated fallback.
    List<Map<String, String>> source;
    if (r.category == 'tip') {
      source = _tips;
    } else if (r.category == 'guide') {
      source = _guides;
    } else {
      source = _articles;
    }
    final match = source.firstWhere(
      (e) => e['title']!.toLowerCase() == r.title.toLowerCase(),
      orElse: () => const <String, String>{},
    );

    final content = (match['content'] != null && match['content']!.isNotEmpty)
        ? match['content']!
        : _buildGeneratedContent(r);

    _showDetail(
      context,
      title: r.title,
      subtitle: r.subtitle,
      content: content,
      category: r.category,
      reason: r.reason,
    );
  }

  String _buildGeneratedContent(RecommendationItem r) {
    final intro = r.reason != null && r.reason!.trim().isNotEmpty
        ? 'Why this may help: ${r.reason!.trim()}\n\n'
        : '';
    switch (r.category) {
      case 'tip':
        return intro +
            'Try this quick tip:\n\n- ${r.title}.\n- ${r.subtitle}.\n\nTake a gentle breath and give it a 2-minute try.';
      case 'guide':
        return intro +
            'Step-by-step guide:\n\n1) ${r.title}\n2) Read the steps slowly\n3) Practice for 3–5 minutes\n\nSave what works for you.';
      default:
        return intro +
            '${r.title}\n\n${r.subtitle}\n\nReflect on what stands out and note one action you can take today.';
    }
  }

  void _showDetail(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String content,
    required String category,
    String? reason,
  }) {
    final icon = category == 'tip'
        ? Icons.lightbulb
        : category == 'guide'
            ? Icons.integration_instructions
            : Icons.menu_book;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(subtitle,
                                style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (reason != null && reason.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Why you see this: $reason'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
