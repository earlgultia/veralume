import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veralume/data/repositories/bible_repository.dart';

void main() {
  sqfliteFfiInit();
  late Directory tempDirectory;
  late String databasePath;
  late Database database;
  late BibleRepository repository;

  Future<void> openRepository() async {
    database = await databaseFactoryFfi.openDatabase(databasePath);
    await database.execute('PRAGMA foreign_keys=ON');
    await database.execute(
      'CREATE TABLE IF NOT EXISTS bookmarks(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL UNIQUE REFERENCES verses(id), created_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS highlights(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL UNIQUE REFERENCES verses(id), color TEXT NOT NULL, created_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL REFERENCES verses(id), content TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS reading_history(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL REFERENCES verses(id), accessed_at TEXT NOT NULL)',
    );
    repository = BibleRepository.withConnection(database);
  }

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('veralume_test_');
    databasePath = '${tempDirectory.path}${Platform.pathSeparator}veralume.db';
    await File('assets/data/veralume.db').copy(databasePath);
    await openRepository();
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'loads all versions and canonical books without loading all verses',
    () async {
      final versions = await repository.versions();
      expect(versions.map((version) => version.abbreviation), [
        'ASV',
        'KJV',
        'ADB',
        'ASND',
        'APD',
        'BNB',
        'MBB-CEB',
        'CEBBUGNA',
      ]);
      expect(await repository.books(versions.first.id), hasLength(66));
      expect(await repository.chapterCount(1), 50);
    },
  );

  test('search supports global, version, and book filters', () async {
    final global = await repository.search('beginning');
    final version = await repository.search('beginning', versionId: 1);
    final book = await repository.search('beginning', versionId: 1, bookId: 1);
    expect(global, isNotEmpty);
    expect(version.every((verse) => verse.versionId == 1), isTrue);
    expect(book.every((verse) => verse.bookId == 1), isTrue);
  });

  test(
    'bookmarks and multi-verse ranges persist after database reopen',
    () async {
      final verses = await repository.chapter(1, 1);
      await repository.toggleBookmarks(verses.take(3).map((verse) => verse.id));
      expect(await repository.bookmarks(), hasLength(3));
      await database.close();
      await openRepository();
      expect(await repository.bookmarks(), hasLength(3));
      expect(await repository.bookmarks(query: 'light'), isNotEmpty);
    },
  );

  test('highlights can be created, listed, recolored, and removed', () async {
    final verses = await repository.chapter(1, 1);
    final ids = verses.take(2).map((verse) => verse.id).toList();
    await repository.setHighlights(ids, 'F6D365');
    expect(await repository.highlights(), hasLength(2));
    await repository.setHighlights(ids, '93B8F4');
    expect((await repository.highlights()).first.color, '93B8F4');
    await repository.setHighlights(ids, null);
    expect(await repository.highlights(), isEmpty);
  });

  test('notes create, search, edit, delete, and persist', () async {
    final verse = (await repository.chapter(1, 1)).first;
    await repository.saveNote(verse.id, 'Creation reflection');
    var notes = await repository.notes(query: 'reflection');
    expect(notes.single.content, 'Creation reflection');
    await repository.saveNote(
      verse.id,
      'Updated reflection',
      id: notes.single.id,
    );
    notes = await repository.notes();
    expect(notes.single.content, 'Updated reflection');
    await repository.deleteNote(notes.single.id);
    expect(await repository.notes(), isEmpty);
  });

  test('history and version switching preserve passage location', () async {
    final verse = (await repository.chapter(1, 1)).first;
    await repository.addHistory(verse.id);
    expect((await repository.history()).single.id, verse.id);
    final equivalent = await repository.equivalentBook(verse.bookId, 2);
    expect(equivalent, isNotNull);
    expect(
      (await repository.chapter(equivalent!, 1)).first.number,
      verse.number,
    );
    await repository.clearHistory();
    expect(await repository.history(), isEmpty);
  });

  test('daily verse is deterministic for a calendar date', () async {
    final date = DateTime(2026, 8, 8);
    expect(
      (await repository.dailyVerse(date)).id,
      (await repository.dailyVerse(date)).id,
    );
  });
}
