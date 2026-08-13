import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/bible_models.dart';

class BibleRepository {
  BibleRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance,
      _connection = null;
  BibleRepository.withConnection(this._connection)
    : _database = AppDatabase.instance;
  final AppDatabase _database;
  final Database? _connection;
  Future<Database> get _db async => _connection ?? await _database.database;

  Future<List<BibleVersion>> versions() async => (await (await _db).query(
    'bible_versions',
    orderBy: 'id',
  )).map(BibleVersion.fromMap).toList();
  Future<List<BibleBook>> books(int versionId) async =>
      (await (await _db).query(
        'books',
        where: 'version_id=?',
        whereArgs: [versionId],
        orderBy: 'book_order',
      )).map(BibleBook.fromMap).toList();
  Future<BibleBook?> book(int bookId) async {
    final rows = await (await _db).query(
      'books',
      where: 'id=?',
      whereArgs: [bookId],
      limit: 1,
    );
    return rows.isEmpty ? null : BibleBook.fromMap(rows.first);
  }

  Future<BibleBook?> bookByOrder(int versionId, int bookOrder) async {
    final rows = await (await _db).query(
      'books',
      where: 'version_id=? AND book_order=?',
      whereArgs: [versionId, bookOrder],
      limit: 1,
    );
    return rows.isEmpty ? null : BibleBook.fromMap(rows.first);
  }

  Future<int> chapterCount(int bookId) async =>
      Sqflite.firstIntValue(
        await (await _db).rawQuery(
          'SELECT count(*) FROM chapters WHERE book_id=?',
          [bookId],
        ),
      ) ??
      0;

  Future<Map<int, int>> chapterCounts(int versionId) async => {
    for (final row in await (await _db).rawQuery(
      'SELECT b.book_order,count(c.id) chapter_count FROM books b LEFT JOIN chapters c ON c.book_id=b.id WHERE b.version_id=? GROUP BY b.id,b.book_order',
      [versionId],
    ))
      row['book_order'] as int: row['chapter_count'] as int,
  };

  Future<int?> equivalentBook(int bookId, int targetVersionId) async {
    final rows = await (await _db).rawQuery(
      'SELECT target.id FROM books source JOIN books target ON target.book_order=source.book_order WHERE source.id=? AND target.version_id=? LIMIT 1',
      [bookId, targetVersionId],
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  static const _select =
      '''SELECT v.*, b.name book_name, bv.abbreviation version_abbreviation FROM verses v JOIN books b ON b.id=v.book_id JOIN bible_versions bv ON bv.id=v.version_id''';
  Future<List<BibleVerse>> chapter(
    int bookId,
    int chapter,
  ) async => (await (await _db).rawQuery(
    '$_select WHERE v.book_id=? AND v.chapter_number=? ORDER BY v.verse_number',
    [bookId, chapter],
  )).map(BibleVerse.fromMap).toList();
  Future<BibleVerse?> verse(int id) async {
    final rows = await (await _db).rawQuery('$_select WHERE v.id=?', [id]);
    return rows.isEmpty ? null : BibleVerse.fromMap(rows.first);
  }

  /// Returns one verse by its stable Bible coordinates. This keeps features
  /// such as Verse Lens and Give Me a Verse independent of database ids,
  /// which differ between translations.
  Future<BibleVerse?> verseAt({
    required int versionId,
    required int bookOrder,
    required int chapter,
    required int number,
  }) async {
    final rows = await (await _db).rawQuery(
      '$_select WHERE v.version_id=? AND b.book_order=? AND v.chapter_number=? AND v.verse_number=? LIMIT 1',
      [versionId, bookOrder, chapter, number],
    );
    return rows.isEmpty ? null : BibleVerse.fromMap(rows.first);
  }

  /// Context deliberately remains in the current chapter. It is predictable,
  /// avoids invalid boundary references, and keeps the reader lightweight.
  Future<List<BibleVerse>> contextFor(BibleVerse selected, int count) async {
    final verses = await chapter(selected.bookId, selected.chapter);
    if (verses.isEmpty) return [];
    final selectedIndex = verses.indexWhere((verse) => verse.id == selected.id);
    if (selectedIndex < 0) return [];
    final wanted = count.clamp(1, 10);
    var start = selectedIndex - ((wanted - 1) ~/ 2);
    var end = start + wanted;
    if (start < 0) {
      end = (end - start).clamp(0, verses.length);
      start = 0;
    }
    if (end > verses.length) {
      start = (start - (end - verses.length)).clamp(0, verses.length);
      end = verses.length;
    }
    return verses.sublist(start, end);
  }

  Future<FocusEntry?> reflectionForVerse(int verseId) async {
    final rows = await (await _db).rawQuery(
      '''SELECT n.id entry_id,n.content,n.created_at,n.updated_at,v.*,b.name book_name,bv.abbreviation version_abbreviation
      FROM notes n JOIN verses v ON v.id=n.verse_id JOIN books b ON b.id=v.book_id JOIN bible_versions bv ON bv.id=v.version_id
      WHERE n.verse_id=? AND n.type='reflection' ORDER BY n.updated_at DESC LIMIT 1''',
      [verseId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return FocusEntry(
      id: row['entry_id'] as int,
      verse: BibleVerse.fromMap(row),
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<BibleVerse?> adjacentVerse(BibleVerse verse, int direction) async {
    final comparator = direction < 0 ? '<' : '>';
    final order = direction < 0 ? 'DESC' : 'ASC';
    final rows = await (await _db).rawQuery(
      '$_select WHERE v.book_id=? AND v.chapter_number=? AND v.verse_number $comparator ? ORDER BY v.verse_number $order LIMIT 1',
      [verse.bookId, verse.chapter, verse.number],
    );
    return rows.isEmpty ? null : BibleVerse.fromMap(rows.first);
  }

  Future<List<BibleVerse>> passageByReference(
    String bookName,
    int chapter, {
    int? startVerse,
    int? endVerse,
    required int versionId,
  }) async {
    final normalized = bookName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final versionBooks = await books(versionId);
    BibleBook? match;
    for (final book in versionBooks) {
      final name = book.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final abbreviation = book.abbreviation.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      if (name == normalized ||
          abbreviation == normalized ||
          name == '${normalized}s') {
        match = book;
        break;
      }
    }
    if (match == null) return [];
    final verses = await this.chapter(match.id, chapter);
    if (startVerse == null) return verses;
    final last = endVerse ?? startVerse;
    return verses
        .where((verse) => verse.number >= startVerse && verse.number <= last)
        .toList();
  }

  Future<List<BibleVerse>> randomVerses(
    int versionId, {
    int limit = 80,
  }) async => (await (await _db).rawQuery(
    '$_select WHERE v.version_id=? ORDER BY random() LIMIT ?',
    [versionId, limit],
  )).map(BibleVerse.fromMap).toList();

  Future<List<BibleVerse>> search(
    String query, {
    int? versionId,
    int? bookId,
  }) async {
    final term = query.trim().replaceAll('"', ' ');
    if (term.isEmpty) return [];
    final filters = <String>['verses_fts MATCH ?'];
    final args = <Object?>['"$term"'];
    if (versionId != null) {
      filters.add('v.version_id=?');
      args.add(versionId);
    }
    if (bookId != null) {
      filters.add('v.book_id=?');
      args.add(bookId);
    }
    return (await (await _db).rawQuery(
      '$_select JOIN verses_fts ON verses_fts.rowid=v.id WHERE ${filters.join(' AND ')} ORDER BY bm25(verses_fts) LIMIT 200',
      args,
    )).map(BibleVerse.fromMap).toList();
  }

  Future<List<BibleVerse>> searchAnyTerms(
    Iterable<String> terms, {
    required int versionId,
    int limit = 12,
  }) async {
    final cleanTerms = terms
        .map((term) => term.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((term) => term.length > 2)
        .toSet()
        .take(6)
        .toList();
    if (cleanTerms.isEmpty) return [];
    final match = cleanTerms.map((term) => '"$term"').join(' OR ');
    return (await (await _db).rawQuery(
      '$_select JOIN verses_fts ON verses_fts.rowid=v.id WHERE verses_fts MATCH ? AND v.version_id=? ORDER BY bm25(verses_fts) LIMIT ?',
      [match, versionId, limit],
    )).map(BibleVerse.fromMap).toList();
  }

  Future<BibleVerse> dailyVerse(DateTime date, {int versionId = 1}) async {
    final count = Sqflite.firstIntValue(
      await (await _db).rawQuery(
        'SELECT count(*) FROM verses WHERE version_id=?',
        [versionId],
      ),
    )!;
    final offset = (date.year * 372 + date.month * 31 + date.day) % count;
    return BibleVerse.fromMap(
      (await (await _db).rawQuery(
        '$_select WHERE v.version_id=? ORDER BY v.id LIMIT 1 OFFSET ?',
        [versionId, offset],
      )).first,
    );
  }

  Future<void> addHistory(int verseId) async =>
      (await _db).insert('reading_history', {
        'verse_id': verseId,
        'accessed_at': DateTime.now().toUtc().toIso8601String(),
      });
  Future<List<BibleVerse>> history() async => (await (await _db).rawQuery(
    '$_select JOIN (SELECT verse_id,max(accessed_at) last FROM reading_history GROUP BY verse_id ORDER BY last DESC LIMIT 20) h ON h.verse_id=v.id ORDER BY h.last DESC',
  )).map(BibleVerse.fromMap).toList();
  Future<void> clearHistory() async => (await _db).delete('reading_history');

  Future<bool> isMemoryVerse(int verseId) async => (await (await _db).query(
    'memory_verses', where: 'verse_id=?', whereArgs: [verseId], limit: 1,
  )).isNotEmpty;

  Future<void> saveMemoryVerse(int verseId) async {
    await (await _db).insert('memory_verses', {
      'verse_id': verseId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeMemoryVerse(int verseId) async =>
      (await _db).delete('memory_verses', where: 'verse_id=?', whereArgs: [verseId]);

  Future<List<MemoryVerse>> memoryVerses({String query = ''}) async {
    final term = query.trim();
    final where = term.isEmpty ? '' : ' WHERE v.text LIKE ? OR b.name LIKE ? OR bv.abbreviation LIKE ?';
    final args = term.isEmpty ? <Object?>[] : ['%$term%', '%$term%', '%$term%'];
    final rows = await (await _db).rawQuery(
      '''SELECT m.id memory_id,m.created_at,m.practice_count,m.successful_recalls,m.failed_recalls,m.last_practiced_at,m.last_successful_recall_at,v.*,b.name book_name,bv.abbreviation version_abbreviation
      FROM memory_verses m JOIN verses v ON v.id=m.verse_id JOIN books b ON b.id=v.book_id JOIN bible_versions bv ON bv.id=v.version_id$where
      ORDER BY COALESCE(m.last_practiced_at,m.created_at) ASC''', args);
    return rows.map((row) => MemoryVerse(
      id: row['memory_id'] as int, verse: BibleVerse.fromMap(row),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      practiceCount: row['practice_count'] as int,
      successfulRecalls: row['successful_recalls'] as int,
      failedRecalls: row['failed_recalls'] as int,
      lastPracticedAt: row['last_practiced_at'] == null ? null : DateTime.parse(row['last_practiced_at'] as String).toLocal(),
      lastSuccessfulRecallAt: row['last_successful_recall_at'] == null ? null : DateTime.parse(row['last_successful_recall_at'] as String).toLocal(),
    )).toList();
  }

  Future<void> recordMemoryPractice(int verseId, {required bool successful}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    // Use a parameterized update so the counters remain correct offline.
    await (await _db).rawUpdate(
      successful
          ? 'UPDATE memory_verses SET practice_count=practice_count+1,successful_recalls=successful_recalls+1,last_practiced_at=?,last_successful_recall_at=? WHERE verse_id=?'
          : 'UPDATE memory_verses SET practice_count=practice_count+1,failed_recalls=failed_recalls+1,last_practiced_at=? WHERE verse_id=?',
      successful ? [now, now, verseId] : [now, verseId],
    );
  }
  Future<LastLight?> lastLight() async {
    final rows = await (await _db).rawQuery(
      '$_select JOIN last_light l ON l.verse_id=v.id WHERE l.id=1',
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    try {
      return LastLight(
        verse: BibleVerse.fromMap(row),
        savedAt: DateTime.parse(row['saved_at'] as String).toLocal(),
        localDate: row['local_date'] as String,
      );
    } catch (_) {
      await (await _db).delete('last_light', where: 'id=1');
      return null;
    }
  }

  Future<void> saveLastLight(BibleVerse verse) async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await (await _db).insert('last_light', {
      'id': 1,
      'verse_id': verse.id,
      'saved_at': now.toUtc().toIso8601String(),
      'local_date': date,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> toggleBookmark(int verseId) async {
    final db = await _db;
    final n = await db.delete(
      'bookmarks',
      where: 'verse_id=?',
      whereArgs: [verseId],
    );
    if (n == 0) {
      await db.insert('bookmarks', {
        'verse_id': verseId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<void> toggleBookmarks(Iterable<int> verseIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      for (final verseId in verseIds) {
        final removed = await txn.delete(
          'bookmarks',
          where: 'verse_id=?',
          whereArgs: [verseId],
        );
        if (removed == 0) {
          await txn.insert('bookmarks', {
            'verse_id': verseId,
            'created_at': now,
          });
        }
      }
    });
  }

  Future<bool> isBookmarked(int verseId) async => (await (await _db).query(
    'bookmarks',
    where: 'verse_id=?',
    whereArgs: [verseId],
    limit: 1,
  )).isNotEmpty;
  Future<List<BibleVerse>> bookmarks({String query = ''}) async {
    final term = query.trim();
    final where = term.isEmpty ? '' : ' WHERE v.text LIKE ? OR b.name LIKE ?';
    final args = term.isEmpty ? <Object?>[] : ['%$term%', '%$term%'];
    return (await (await _db).rawQuery(
      '$_select JOIN bookmarks x ON x.verse_id=v.id$where ORDER BY x.created_at DESC',
      args,
    )).map(BibleVerse.fromMap).toList();
  }

  Future<void> setHighlight(int verseId, String? color) async {
    final db = await _db;
    if (color == null) {
      await db.delete('highlights', where: 'verse_id=?', whereArgs: [verseId]);
    } else {
      await db.insert('highlights', {
        'verse_id': verseId,
        'color': color,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> setHighlights(Iterable<int> verseIds, String? color) async {
    final db = await _db;
    await db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      for (final verseId in verseIds) {
        if (color == null) {
          await txn.delete(
            'highlights',
            where: 'verse_id=?',
            whereArgs: [verseId],
          );
        } else {
          await txn.insert('highlights', {
            'verse_id': verseId,
            'color': color,
            'created_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<List<SavedVerse>> highlights() async {
    final rows = await (await _db).rawQuery(
      '''SELECT h.id saved_id,h.color,h.created_at,v.*,
         b.name book_name,bv.abbreviation version_abbreviation
         FROM highlights h JOIN verses v ON v.id=h.verse_id
         JOIN books b ON b.id=v.book_id
         JOIN bible_versions bv ON bv.id=v.version_id
         ORDER BY h.created_at DESC''',
    );
    return rows
        .map(
          (m) => SavedVerse(
            id: m['saved_id'] as int,
            verse: BibleVerse.fromMap(m),
            color: m['color'] as String,
            createdAt: DateTime.parse(m['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<Map<int, String>> highlightsForChapter(
    int bookId,
    int chapter,
  ) async => {
    for (final r in await (await _db).rawQuery(
      'SELECT h.verse_id,h.color FROM highlights h JOIN verses v ON v.id=h.verse_id WHERE v.book_id=? AND v.chapter_number=?',
      [bookId, chapter],
    ))
      r['verse_id'] as int: r['color'] as String,
  };
  Future<void> saveNote(
    int verseId,
    String content, {
    int? id,
    String type = 'note',
  }) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    if (id == null) {
      await db.insert('notes', {
        'verse_id': verseId,
        'content': content,
        'created_at': now,
        'updated_at': now,
        'type': type,
      });
    } else {
      await db.update(
        'notes',
        {'content': content, 'updated_at': now, 'type': type},
        where: 'id=?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteNote(int id) async =>
      (await _db).delete('notes', where: 'id=?', whereArgs: [id]);
  Future<List<SavedVerse>> notes({String query = ''}) async {
    final term = query.trim();
    final where = term.isEmpty
        ? " WHERE n.type='note'"
        : " WHERE n.type='note' AND (n.content LIKE ? OR v.text LIKE ? OR b.name LIKE ?)";
    final args = term.isEmpty ? <Object?>[] : ['%$term%', '%$term%', '%$term%'];
    return (await (await _db).rawQuery(
          '''SELECT n.id note_id,n.content,n.created_at,v.*,
             b.name book_name,bv.abbreviation version_abbreviation
             FROM notes n JOIN verses v ON v.id=n.verse_id
             JOIN books b ON b.id=v.book_id
             JOIN bible_versions bv ON bv.id=v.version_id
             $where ORDER BY n.updated_at DESC''',
          args,
        ))
        .map(
          (m) => SavedVerse(
            id: m['note_id'] as int,
            verse: BibleVerse.fromMap(m),
            content: m['content'] as String,
            createdAt: DateTime.parse(m['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> savePrayer(int verseId, String content, {int? id}) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    if (id == null) {
      await db.insert('prayers', {
        'verse_id': verseId,
        'content': content,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.update(
        'prayers',
        {'content': content, 'updated_at': now},
        where: 'id=?',
        whereArgs: [id],
      );
    }
  }

  Future<List<FocusEntry>> focusEntries(String table) async {
    final typeFilter = table == 'notes' ? "WHERE n.type='reflection'" : '';
    final alias = table == 'notes' ? 'n' : 'p';
    final rows = await (await _db).rawQuery(
      '''SELECT $alias.id entry_id,$alias.content,$alias.created_at,$alias.updated_at,v.*,b.name book_name,bv.abbreviation version_abbreviation
      FROM $table $alias JOIN verses v ON v.id=$alias.verse_id JOIN books b ON b.id=v.book_id JOIN bible_versions bv ON bv.id=v.version_id
      $typeFilter ORDER BY $alias.updated_at DESC''',
    );
    return rows
        .map(
          (row) => FocusEntry(
            id: row['entry_id'] as int,
            verse: BibleVerse.fromMap(row),
            content: row['content'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
          ),
        )
        .toList();
  }

  Future<FocusSession> startFocusSession(int verseId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await (await _db).insert('focus_sessions', {
      'verse_id': verseId,
      'created_at': now,
    });
    return FocusSession(
      id: id,
      verseId: verseId,
      readCompleted: false,
      reflectionCompleted: false,
      respondCompleted: false,
      prayerCompleted: false,
      createdAt: DateTime.parse(now),
    );
  }

  Future<void> updateFocusSession(
    int id, {
    bool? read,
    bool? reflection,
    bool? respond,
    bool? prayer,
    bool completed = false,
  }) async {
    final values = <String, Object?>{};
    if (read != null) {
      values['read_completed'] = read ? 1 : 0;
    }
    if (reflection != null) {
      values['reflection_completed'] = reflection ? 1 : 0;
    }
    if (respond != null) {
      values['respond_completed'] = respond ? 1 : 0;
    }
    if (prayer != null) {
      values['prayer_completed'] = prayer ? 1 : 0;
    }
    if (completed) {
      values['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (values.isNotEmpty) {
      await (await _db).update(
        'focus_sessions',
        values,
        where: 'id=?',
        whereArgs: [id],
      );
    }
  }
}
