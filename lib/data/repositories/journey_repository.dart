import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../domain/journey/journey_catalog.dart';
import '../database/app_database.dart';
import '../models/bible_models.dart';
import '../models/journey_models.dart';
import 'bible_repository.dart';

class LocalReadingHistory {
  const LocalReadingHistory({
    required this.bookOrder,
    required this.bookName,
    required this.chapter,
    required this.readAt,
  });
  final int bookOrder, chapter;
  final String bookName;
  final DateTime readAt;
  String get reference => '$bookName $chapter';
}

class LocalSavedPassage {
  const LocalSavedPassage({
    required this.verse,
    required this.kind,
    this.content,
  });
  final BibleVerse verse;
  final String kind;
  final String? content;
}

class UserReadingContext {
  const UserReadingContext({
    required this.recentlyRead,
    required this.bookmarks,
    required this.highlights,
    required this.notes,
  });
  final List<LocalReadingHistory> recentlyRead;
  final List<LocalSavedPassage> bookmarks, highlights, notes;
  bool get isEmpty =>
      recentlyRead.isEmpty &&
      bookmarks.isEmpty &&
      highlights.isEmpty &&
      notes.isEmpty;
}

class JourneyRepository {
  JourneyRepository({AppDatabase? database, DateTime Function()? clock})
    : _database = database ?? AppDatabase.instance,
      _connection = null,
      _clock = clock ?? DateTime.now;

  JourneyRepository.withConnection(
    this._connection, {
    DateTime Function()? clock,
  }) : _database = AppDatabase.instance,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final Database? _connection;
  final DateTime Function() _clock;
  bool _schemaReady = false;

  Future<Database> get _db async {
    final db = _connection ?? await _database.database;
    if (!_schemaReady) {
      await _database.ensureUserSchema(db);
      _schemaReady = true;
    }
    return db;
  }

  Future<void> recordMeaningfulReading({
    required int bookId,
    required int chapter,
    required int versesRead,
    required DateTime startedAt,
    required Duration duration,
    bool completed = true,
  }) async {
    if (chapter < 1 || versesRead < 1 || duration.isNegative) return;
    final db = await _db;
    final bookRows = await db.query(
      'books',
      columns: ['book_order'],
      where: 'id=?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (bookRows.isEmpty) return;
    final bookOrder = bookRows.first['book_order'] as int;
    final verseCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT count(*) FROM verses WHERE book_id=? AND chapter_number=?',
            [bookId, chapter],
          ),
        ) ??
        0;
    if (verseCount == 0) return;
    final now = _clock();
    final localDate = _dateKey(now);
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'reading_progress',
        where: 'book_order=? AND chapter=?',
        whereArgs: [bookOrder, chapter],
        limit: 1,
      );
      final existing = existingRows.firstOrNull;
      final oldVerses = existing?['verses_read'] as int? ?? 0;
      final oldCompleted = (existing?['completed'] as int? ?? 0) == 1;
      final nextVerses = math.max(oldVerses, math.min(versesRead, verseCount));
      final nextCompleted = oldCompleted || completed;
      final firstReadAt =
          existing?['first_read_at'] as String? ??
          now.toUtc().toIso8601String();
      await txn.insert('reading_progress', {
        'book_order': bookOrder,
        'chapter': chapter,
        'verses_read': nextVerses,
        'completed': nextCompleted ? 1 : 0,
        'first_read_at': firstReadAt,
        'last_read_at': now.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('reading_sessions', {
        'book_order': bookOrder,
        'chapter': chapter,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': now.toUtc().toIso8601String(),
        'local_date': localDate,
        'duration_seconds': math.max(0, duration.inSeconds),
        'verses_read': versesRead,
      });
      final chapterDelta = !oldCompleted && nextCompleted ? 1 : 0;
      final verseDelta = nextVerses - oldVerses;
      await txn.rawInsert(
        '''INSERT INTO reading_days(local_date,chapters_read,verses_read,reading_seconds)
           VALUES(?,?,?,?) ON CONFLICT(local_date) DO UPDATE SET
           chapters_read=chapters_read+excluded.chapters_read,
           verses_read=verses_read+excluded.verses_read,
           reading_seconds=reading_seconds+excluded.reading_seconds''',
        [localDate, chapterDelta, verseDelta, math.max(0, duration.inSeconds)],
      );
    });
    await _unlockEligibleMilestones();
  }

  Future<Map<int, List<ReadingProgress>>> progressByBook() async {
    final rows = await (await _db).query(
      'reading_progress',
      orderBy: 'book_order,chapter',
    );
    final result = <int, List<ReadingProgress>>{};
    for (final row in rows) {
      final item = _progressFromRow(row);
      result.putIfAbsent(item.bookOrder, () => []).add(item);
    }
    return result;
  }

  Future<List<ReadingProgress>> progressForBook(int bookOrder) async =>
      (await (await _db).query(
        'reading_progress',
        where: 'book_order=?',
        whereArgs: [bookOrder],
        orderBy: 'chapter',
      )).map(_progressFromRow).toList();

  ReadingProgress _progressFromRow(Map<String, Object?> row) => ReadingProgress(
    bookOrder: row['book_order'] as int,
    chapter: row['chapter'] as int,
    versesRead: row['verses_read'] as int,
    completed: row['completed'] == 1,
    firstReadAt: DateTime.parse(row['first_read_at'] as String),
    lastReadAt: DateTime.parse(row['last_read_at'] as String),
  );

  Future<JourneyStats> stats() async {
    final db = await _db;
    final rows = await db.query('reading_progress');
    final chaptersRead = rows.where((row) => row['completed'] == 1).length;
    final versesRead = rows.fold<int>(
      0,
      (total, row) => total + (row['verses_read'] as int),
    );
    final exploredOrders = rows.map((row) => row['book_order'] as int).toSet();
    final canonicalCounts = <int, int>{
      for (final row in await db.rawQuery(
        '''SELECT b.book_order,count(c.id) chapter_count FROM books b
           JOIN chapters c ON c.book_id=b.id
           WHERE b.version_id=(SELECT min(id) FROM bible_versions)
           GROUP BY b.book_order''',
      ))
        row['book_order'] as int: row['chapter_count'] as int,
    };
    final completeByBook = <int, int>{};
    for (final row in rows.where((row) => row['completed'] == 1)) {
      final order = row['book_order'] as int;
      completeByBook[order] = (completeByBook[order] ?? 0) + 1;
    }
    final booksCompleted = completeByBook.entries
        .where((entry) => canonicalCounts[entry.key] == entry.value)
        .length;
    final dayRows = await db.query('reading_days', orderBy: 'local_date');
    final days = dayRows
        .where(
          (row) =>
              (row['chapters_read'] as int) > 0 ||
              (row['verses_read'] as int) > 0 ||
              (row['reading_seconds'] as int) >= 20,
        )
        .map((row) => row['local_date'] as String)
        .toList();
    final streaks = _streaks(days, _clock());
    final totalChapters = canonicalCounts.values.fold<int>(0, (a, b) => a + b);
    return JourneyStats(
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      chaptersRead: chaptersRead,
      booksExplored: exploredOrders.length,
      booksCompleted: booksCompleted,
      versesRead: versesRead,
      readingDays: days.length,
      scriptureProgress: totalChapters == 0 ? 0 : chaptersRead / totalChapters,
    );
  }

  (int, int) _streaks(List<String> keys, DateTime now) {
    final days = keys.map(_parseDateKey).whereType<DateTime>().toSet().toList()
      ..sort();
    if (days.isEmpty) return (0, 0);
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (_ordinal(days[i]) - _ordinal(days[i - 1]) == 1) {
        run++;
        longest = math.max(longest, run);
      } else {
        run = 1;
      }
    }
    final today = DateTime(now.year, now.month, now.day);
    final gap = _ordinal(today) - _ordinal(days.last);
    if (gap > 1 || gap < 0) return (0, longest);
    var current = 1;
    for (var i = days.length - 1; i > 0; i--) {
      if (_ordinal(days[i]) - _ordinal(days[i - 1]) != 1) break;
      current++;
    }
    return (current, longest);
  }

  static const _milestoneDefinitions =
      <({String key, String title, String description, String symbol})>[
        (
          key: 'first_step',
          title: 'First Step',
          description: 'Read your first Bible chapter.',
          symbol: '🌱',
        ),
        (
          key: 'getting_started',
          title: 'Getting Started',
          description: 'Read 10 Bible chapters.',
          symbol: '📖',
        ),
        (
          key: 'growing',
          title: 'Growing',
          description: 'Read 50 Bible chapters.',
          symbol: '🔥',
        ),
        (
          key: 'rooted',
          title: 'Rooted',
          description: 'Read 100 Bible chapters.',
          symbol: '🌿',
        ),
        (
          key: 'deeply_rooted',
          title: 'Deeply Rooted',
          description: 'Read 500 Bible chapters.',
          symbol: '🌳',
        ),
        (
          key: 'book_explorer',
          title: 'Book Explorer',
          description: 'Complete your first Bible book.',
          symbol: '📚',
        ),
        (
          key: 'scripture_seeker',
          title: 'Scripture Seeker',
          description: 'Explore 10 different Bible books.',
          symbol: '🕊️',
        ),
        (
          key: 'journey_begins',
          title: 'Journey Begins',
          description: 'Maintain a 7-day reading streak.',
          symbol: '✨',
        ),
        (
          key: 'faithful_reader',
          title: 'Faithful Reader',
          description: 'Maintain a 30-day reading streak.',
          symbol: '🔥',
        ),
        (
          key: 'word_dweller',
          title: 'Word Dweller',
          description: 'Maintain a 100-day reading streak.',
          symbol: '👑',
        ),
      ];

  Future<void> _unlockEligibleMilestones() async {
    final value = await stats();
    final eligible = <String>{
      if (value.chaptersRead >= 1) 'first_step',
      if (value.chaptersRead >= 10) 'getting_started',
      if (value.chaptersRead >= 50) 'growing',
      if (value.chaptersRead >= 100) 'rooted',
      if (value.chaptersRead >= 500) 'deeply_rooted',
      if (value.booksCompleted >= 1) 'book_explorer',
      if (value.booksExplored >= 10) 'scripture_seeker',
      if (value.currentStreak >= 7) 'journey_begins',
      if (value.currentStreak >= 30) 'faithful_reader',
      if (value.currentStreak >= 100) 'word_dweller',
    };
    final db = await _db;
    final unlockedAt = _clock().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final key in eligible) {
        await txn.insert('milestones', {
          'milestone_key': key,
          'unlocked_at': unlockedAt,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<List<JourneyMilestone>> milestones() async {
    await _unlockEligibleMilestones();
    final unlocked = {
      for (final row in await (await _db).query('milestones'))
        row['milestone_key'] as String: DateTime.parse(
          row['unlocked_at'] as String,
        ),
    };
    return [
      for (final definition in _milestoneDefinitions)
        JourneyMilestone(
          key: definition.key,
          title: definition.title,
          description: definition.description,
          symbol: definition.symbol,
          isUnlocked: unlocked.containsKey(definition.key),
          unlockedAt: unlocked[definition.key],
        ),
    ];
  }

  Future<PassageReference?> lastReadingPosition() async {
    final db = await _db;
    final sessions = await db.query(
      'reading_sessions',
      columns: ['book_order', 'chapter'],
      orderBy: 'ended_at DESC,id DESC',
      limit: 1,
    );
    if (sessions.isNotEmpty) {
      return PassageReference(
        sessions.first['book_order'] as int,
        sessions.first['chapter'] as int,
      );
    }
    final history = await db.rawQuery(
      '''SELECT b.book_order,v.chapter_number FROM reading_history h
         JOIN verses v ON v.id=h.verse_id JOIN books b ON b.id=v.book_id
         ORDER BY h.accessed_at DESC,h.id DESC LIMIT 1''',
    );
    return history.isEmpty
        ? null
        : PassageReference(
            history.first['book_order'] as int,
            history.first['chapter_number'] as int,
          );
  }

  Future<GuidedJourneyProgress> guidedProgress(String journeyId) async {
    final definition = guidedJourneys
        .where((journey) => journey.id == journeyId)
        .firstOrNull;
    if (definition == null) {
      return GuidedJourneyProgress(journeyId, const <int>{});
    }
    final rows = await (await _db).query(
      'journey_progress',
      where: 'journey_id=?',
      whereArgs: [journeyId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return GuidedJourneyProgress(journeyId, const <int>{});
    }
    final completed = (rows.first['completed_days'] as String)
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((day) => day >= 1 && day <= definition.days.length)
        .toSet();
    final completedAt = rows.first['completed_at'] as String?;
    return GuidedJourneyProgress(
      journeyId,
      completed,
      completedAt: completedAt == null ? null : DateTime.tryParse(completedAt),
    );
  }

  Future<void> completeGuidedDay(
    String journeyId,
    int day,
    int totalDays,
  ) async {
    final definition = guidedJourneys
        .where((journey) => journey.id == journeyId)
        .firstOrNull;
    if (definition == null ||
        totalDays != definition.days.length ||
        day < 1 ||
        day > definition.days.length) {
      return;
    }
    final existing = await guidedProgress(journeyId);
    if (day > 1 && !existing.completedDays.contains(day - 1)) return;
    final completed = {...existing.completedDays, day};
    final now = _clock().toUtc().toIso8601String();
    await (await _db).insert('journey_progress', {
      'journey_id': journeyId,
      'started_at': now,
      'completed_days': (completed.toList()..sort()).join(','),
      'completed_at': completed.length == definition.days.length
          ? existing.completedAt?.toUtc().toIso8601String() ?? now
          : existing.completedAt?.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  DailyLight dailyLight(DateTime date) => dailyLightForDate(date);

  Future<BibleBook?> bookForOrder(int bookOrder, int versionId) async =>
      BibleRepository.withConnection(
        await _db,
      ).bookByOrder(versionId, bookOrder);

  Future<List<BibleVerse>> resolvePassage(
    PassageReference passage,
    int versionId,
  ) async {
    if (passage.bookOrder < 1 ||
        passage.bookOrder > 66 ||
        passage.chapter < 1) {
      return [];
    }
    try {
      final bible = BibleRepository.withConnection(await _db);
      final book = await bible.bookByOrder(versionId, passage.bookOrder);
      if (book == null) return [];
      final verses = await bible.chapter(book.id, passage.chapter);
      if (passage.startVerse == null) return verses;
      final end = passage.endVerse ?? passage.startVerse!;
      return verses
          .where(
            (verse) =>
                verse.number >= passage.startVerse! && verse.number <= end,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VerseConnection>> connectionsFor(BibleVerse source) async {
    final rows = await (await _db).query(
      'books',
      columns: ['book_order'],
      where: 'id=?',
      whereArgs: [source.bookId],
      limit: 1,
    );
    if (rows.isEmpty) return [];
    final bookOrder = rows.first['book_order'] as int;
    return verseConnections
        .where(
          (connection) =>
              connection.source.bookOrder == bookOrder &&
              connection.source.chapter == source.chapter &&
              connection.source.startVerse == source.number,
        )
        .toList();
  }

  Future<List<LocalReadingHistory>> historyForLocalDate(
    DateTime date,
    int versionId,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''SELECT book_order,chapter,max(ended_at) read_at
         FROM reading_sessions WHERE local_date=?
         GROUP BY book_order,chapter ORDER BY read_at''',
      [_dateKey(date)],
    );
    final bible = BibleRepository.withConnection(db);
    final result = <LocalReadingHistory>[];
    for (final row in rows) {
      final order = row['book_order'] as int;
      final book = await bible.bookByOrder(versionId, order);
      if (book == null) continue;
      result.add(
        LocalReadingHistory(
          bookOrder: order,
          bookName: book.name,
          chapter: row['chapter'] as int,
          readAt: DateTime.tryParse(row['read_at'] as String? ?? '') ?? date,
        ),
      );
    }
    return result;
  }

  Future<List<LocalSavedPassage>> searchSaved(
    String query,
    int versionId, {
    int limit = 20,
  }) async {
    final results = <LocalSavedPassage>[];
    for (final kind in const ['bookmark', 'highlight', 'note']) {
      results.addAll(
        await _savedPassages(kind, versionId, query: query, limit: limit),
      );
    }
    return results.take(limit).toList();
  }

  Future<UserReadingContext> userReadingContext(
    int versionId, {
    int limit = 8,
  }) async {
    final db = await _db;
    final recentRows = await db.rawQuery(
      '''SELECT book_order,chapter,max(ended_at) read_at FROM reading_sessions
         GROUP BY book_order,chapter ORDER BY read_at DESC LIMIT ?''',
      [limit],
    );
    final bible = BibleRepository.withConnection(db);
    final recentlyRead = <LocalReadingHistory>[];
    for (final row in recentRows) {
      final order = row['book_order'] as int;
      final book = await bible.bookByOrder(versionId, order);
      if (book == null) continue;
      recentlyRead.add(
        LocalReadingHistory(
          bookOrder: order,
          bookName: book.name,
          chapter: row['chapter'] as int,
          readAt:
              DateTime.tryParse(row['read_at'] as String? ?? '') ?? _clock(),
        ),
      );
    }
    return UserReadingContext(
      recentlyRead: recentlyRead,
      bookmarks: await _savedPassages('bookmark', versionId, limit: limit),
      highlights: await _savedPassages('highlight', versionId, limit: limit),
      notes: await _savedPassages('note', versionId, limit: limit),
    );
  }

  Future<List<LocalSavedPassage>> _savedPassages(
    String kind,
    int versionId, {
    String query = '',
    int limit = 20,
  }) async {
    final table = switch (kind) {
      'bookmark' => 'bookmarks',
      'highlight' => 'highlights',
      'note' => 'notes',
      _ => throw ArgumentError.value(kind, 'kind'),
    };
    final alias = kind == 'bookmark'
        ? 'x'
        : kind == 'highlight'
        ? 'x'
        : 'x';
    final contentColumn = kind == 'note'
        ? 'x.content saved_content'
        : kind == 'highlight'
        ? 'x.color saved_content'
        : 'NULL saved_content';
    final term = query.trim();
    final where = term.isEmpty
        ? ''
        : "WHERE v.text LIKE ? OR b.name LIKE ? ${kind == 'note' ? 'OR x.content LIKE ?' : ''}";
    final args = <Object?>[
      if (term.isNotEmpty) '%$term%',
      if (term.isNotEmpty) '%$term%',
      if (term.isNotEmpty && kind == 'note') '%$term%',
      limit,
    ];
    final rows = await (await _db).rawQuery(
      '''SELECT v.*,b.name book_name,b.book_order,
         bv.abbreviation version_abbreviation,$contentColumn
         FROM $table $alias JOIN verses v ON v.id=x.verse_id
         JOIN books b ON b.id=v.book_id
         JOIN bible_versions bv ON bv.id=v.version_id
         $where ORDER BY ${kind == 'note' ? 'x.updated_at' : 'x.created_at'} DESC LIMIT ?''',
      args,
    );
    final result = <LocalSavedPassage>[];
    for (final row in rows) {
      var verse = BibleVerse.fromMap(row);
      if (verse.versionId != versionId) {
        final resolved = await resolvePassage(
          PassageReference(
            row['book_order'] as int,
            verse.chapter,
            startVerse: verse.number,
          ),
          versionId,
        );
        if (resolved.isNotEmpty) verse = resolved.first;
      }
      result.add(
        LocalSavedPassage(
          verse: verse,
          kind: kind,
          content: row['saved_content'] as String?,
        ),
      );
    }
    return result;
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  DateTime? _parseDateKey(String value) {
    final parts = value.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) return null;
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  }

  int _ordinal(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
