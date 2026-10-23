import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../repositories/bible_repository.dart';

class DailyWordNotificationService {
  DailyWordNotificationService._();

  static final instance = DailyWordNotificationService._();
  static const _notificationIdBase = 7400;
  static const _daysToSchedule = 30;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    if (_initialized) return;

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) {
      throw StateError('Daily Word notifications could not initialize.');
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> scheduleDailyWords({
    required BibleRepository repository,
    required int versionId,
    DateTime? now,
  }) async {
    await initialize();
    final permissionGranted = await requestPermission();
    if (!permissionGranted) {
      throw StateError('Notification permission has not been granted.');
    }
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final notifications = <({int id, DateTime date, String body})>[];

    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final scheduledDate = timezone.TZDateTime(
        timezone.local,
        date.year,
        date.month,
        date.day,
        8,
      );
      if (!scheduledDate.isAfter(current)) continue;
      final verse = await repository.dailyVerse(date, versionId: versionId);
      final excerpt = verse.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final body =
          '“$excerpt” — ${verse.reference} · ${verse.versionAbbreviation}';
      notifications.add((
        id: _notificationIdBase + dayOffset,
        date: date,
        body: body.length <= 240 ? body : '${body.substring(0, 237)}…',
      ));
    }

    for (var index = 0; index < _daysToSchedule; index++) {
      await _plugin.cancel(id: _notificationIdBase + index);
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_word',
        'Today’s Word',
        channelDescription: 'Daily Scripture reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
    for (final notification in notifications) {
      final scheduledDate = timezone.TZDateTime(
        timezone.local,
        notification.date.year,
        notification.date.month,
        notification.date.day,
        8,
      );
      await _plugin.zonedSchedule(
        id: notification.id,
        title: 'Today’s Word',
        body: notification.body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelDailyWords() async {
    await initialize();
    for (var index = 0; index < _daysToSchedule; index++) {
      await _plugin.cancel(id: _notificationIdBase + index);
    }
  }
}
