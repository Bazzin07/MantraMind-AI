import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/mood_service.dart';
import 'package:mantramind/models/mood_entry.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);

    // Request runtime permissions where required
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> scheduleDailyMotivation({
    int hour = 8,
    int minute = 0,
  }) async {
    await initialize();

    final user = SupabaseService.currentUser;
    if (user == null) return;

    final moods = await MoodService.listEntries(user.id);
    final String quote = _pickQuoteForTrend(_getMoodTrend(moods));

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_motivation_channel',
      'Daily Motivation',
      channelDescription: 'Daily motivational quote based on your mood trend',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel previous with same id to avoid duplicates
    const int notifId = 1001;
    await _plugin.cancel(notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        notifId,
        'Your Morning Motivation',
        quote,
        scheduled,
        details,
        // Use inexact scheduling to avoid SCHEDULE_EXACT_ALARM requirement on Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_motivation',
      );
    } catch (e) {
      // Swallow errors so app startup isn't blocked; logging is sufficient
      // If exact alarms are required, handle permission/manifest externally.
      // print('Notification schedule error: $e');
    }
  }

  // Demo helpers
  static Future<void> showTestNotification({
    String title = 'Hackathon Test',
    String body = 'This is a test notification',
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_motivation_channel',
      'Daily Motivation',
      channelDescription: 'Daily motivational quote based on your mood trend',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      2001,
      title,
      body,
      details,
      payload: 'test_immediate',
    );
  }

  static Future<void> scheduleTestInSeconds(
    int seconds, {
    String title = 'Scheduled Test',
    String? body,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_motivation_channel',
      'Daily Motivation',
      channelDescription: 'Daily motivational quote based on your mood trend',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduled =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _plugin.zonedSchedule(
      2002,
      title,
      body ?? 'This will fire in $seconds seconds',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test_scheduled_${seconds}s',
    );
  }

  // Simple mood trend: average score of last 7 entries and modal mood label
  static _MoodTrend _getMoodTrend(List<MoodEntry> entries) {
    if (entries.isEmpty) return _MoodTrend(category: 'neutral', avgScore: 0);
    final last = entries.take(7).toList();
    final avg = last.map((e) => e.moodScore).fold<int>(0, (a, b) => a + b) /
        last.length;

    final Map<String, int> counts = {};
    for (final e in last) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    String topMood = 'neutral';
    int topCount = 0;
    counts.forEach((m, c) {
      if (c > topCount) {
        topCount = c;
        topMood = m;
      }
    });

    // Map to a simplified category
    final moodCategory = _mapMood(topMood);
    return _MoodTrend(category: moodCategory, avgScore: avg);
  }

  static String _mapMood(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('happy') || m.contains('joy') || m.contains('calm'))
      return 'positive';
    if (m.contains('sad') || m.contains('tired') || m.contains('lonely'))
      return 'low';
    if (m.contains('anxious') || m.contains('stressed') || m.contains('angry'))
      return 'anxious';
    return 'neutral';
  }

  static String _pickQuoteForTrend(_MoodTrend trend) {
    final Map<String, List<String>> bank = {
      'positive': [
        'Keep the momentum going—one kind act for yourself today.',
        'Joy grows when you notice it. What’s one bright spot right now?',
        'Steady and calm—carry this ease into the day.',
      ],
      'low': [
        'You’ve made it this far. One small step is still progress.',
        'Gentle reminder: you don’t have to do it all today—just the next thing.',
        'Be kind to yourself. Clouds pass, and so will this feeling.',
      ],
      'anxious': [
        'Breathe in 4, hold 4, out 4, hold 4—repeat and proceed with care.',
        'Ground yourself: 5 things you see, 4 touch, 3 hear, 2 smell, 1 taste.',
        'You are safe in this moment. Take it one breath at a time.',
      ],
      'neutral': [
        'Small consistent steps build big change. Pick one helpful action.',
        'A steady day is great for planting a new habit.',
        'Check in with yourself—what would help you feel 5% better?',
      ],
    };
    final list = bank[trend.category] ?? bank['neutral']!;
    return list[Random().nextInt(list.length)];
  }
}

class _MoodTrend {
  final String category; // positive | low | anxious | neutral
  final double avgScore;
  _MoodTrend({required this.category, required this.avgScore});
}
