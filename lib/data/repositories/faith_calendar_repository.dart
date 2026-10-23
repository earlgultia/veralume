import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/faith_calendar_event.dart';

class FaithCalendarRepository {
  static const _storageKey = 'faithCalendarEvents';

  Future<List<FaithCalendarEvent>> events() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_storageKey);
    if (saved == null || saved.isEmpty) return const [];

    final decoded = jsonDecode(saved);
    if (decoded is! List) {
      throw const FormatException('Saved calendar data is not a list.');
    }
    return decoded
        .whereType<Map>()
        .map(
          (event) => FaithCalendarEvent.fromJson(
            Map<String, Object?>.from(event),
          ),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  Future<void> save(FaithCalendarEvent event) async {
    final current = await events();
    final updated = [
      for (final existing in current)
        if (existing.id != event.id) existing,
      event,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    await _write(updated);
  }

  Future<void> delete(String id) async {
    final current = await events();
    await _write(current.where((event) => event.id != id).toList());
  }

  Future<void> _write(List<FaithCalendarEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(events.map((event) => event.toJson()).toList());
    if (!await preferences.setString(_storageKey, encoded)) {
      throw StateError('Calendar changes could not be saved on this device.');
    }
  }
}
