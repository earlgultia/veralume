import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/prayer_journal_entry.dart';

class PrayerJournalRepository {
  PrayerJournalRepository({AppDatabase? database, DateTime Function()? clock})
    : _database = database ?? AppDatabase.instance,
      _connection = null,
      _clock = clock ?? DateTime.now;

  PrayerJournalRepository.withConnection(
    this._connection, {
    DateTime Function()? clock,
  }) : _database = AppDatabase.instance,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final Database? _connection;
  final DateTime Function() _clock;

  Future<Database> get _db async {
    final db = _connection ?? await _database.database;
    await _database.ensureUserSchema(db);
    return db;
  }

  Future<List<PrayerJournalEntry>> entries() async => (await (await _db).query(
    'prayer_journal',
    orderBy: 'created_at DESC',
  )).map(PrayerJournalEntry.fromMap).toList();

  Future<int> save({
    required String title,
    required String content,
    int? id,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'A prayer title is required.');
    }
    if (cleanContent.isEmpty) {
      throw ArgumentError.value(
        content,
        'content',
        'Prayer content cannot be empty.',
      );
    }
    final db = await _db;
    if (id == null) {
      return db.insert('prayer_journal', {
        'title': cleanTitle,
        'content': cleanContent,
        'created_at': _clock().toUtc().toIso8601String(),
      });
    }
    await db.update(
      'prayer_journal',
      {'title': cleanTitle, 'content': cleanContent},
      where: 'id=?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> setAnswered(int id, bool answered) async {
    final now = answered ? _clock().toUtc().toIso8601String() : null;
    await (await _db).update(
      'prayer_journal',
      {'answered': answered ? 1 : 0, 'answered_at': now},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await (await _db).delete('prayer_journal', where: 'id=?', whereArgs: [id]);
  }
}
