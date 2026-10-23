import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veralume/data/repositories/bible_repository.dart';
import 'package:veralume/data/database/app_database.dart';
import 'package:veralume/domain/assistant/sam_sam_assistant.dart';
import 'package:veralume/domain/memory/verse_memory.dart';
import 'package:veralume/domain/assistant/sam_sam_companion.dart';

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
    await AppDatabase.instance.ensureUserSchema(database);
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
    'Sam-Sam Bible fact references resolve from the bundled database',
    () async {
      for (final fact in SamSamFacts.facts) {
        final match = RegExp(
          r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$',
        ).firstMatch(fact.reference);
        expect(match, isNotNull, reason: fact.reference);
        final verses = await repository.passageByReference(
          match!.group(1)!,
          int.parse(match.group(2)!),
          startVerse: int.tryParse(match.group(3) ?? ''),
          endVerse: int.tryParse(match.group(4) ?? ''),
          versionId: 1,
        );
        expect(verses, isNotEmpty, reason: fact.reference);
      }
    },
  );

  test(
    'Sam-Sam resolves references and answers about biblical events',
    () async {
      final assistant = SamSamAssistant(repository);
      final reference = await assistant.ask('Please show me John 3:16', 1);
      expect(reference.verses, hasLength(1));
      expect(reference.verses.single.reference, 'John 3:16');

      final event = await assistant.ask('Tell me about David and Goliath', 1);
      expect(event.message, contains('Goliath'));
      expect(event.verses, isNotEmpty);
      expect(event.verses.every((verse) => verse.versionId == 1), isTrue);
    },
  );

  test(
    'Sam-Sam handles conversation and grounded life questions offline',
    () async {
      final assistant = SamSamAssistant(repository);

      final greeting = await assistant.ask('Hi Sam-Sam!', 1);
      expect(greeting.message, contains('Hello'));
      expect(greeting.verses, isEmpty);

      final anxiety = await assistant.ask('I feel anxious and worried', 1);
      expect(anxiety.message, contains('worried'));
      expect(anxiety.verses, isNotEmpty);

      final topic = await assistant.ask('Find Scripture about kindness', 1);
      expect(topic.verses, isNotEmpty);
      expect(topic.verses.every((verse) => verse.versionId == 1), isTrue);

      final clothing = await assistant.ask('Wolf in sheeps clothing', 1);
      expect(clothing.verses, isNotEmpty);
      expect(clothing.verses.first.reference, 'Matthew 7:15');

      final exhausted = await assistant.ask('I feel tired and overwhelmed', 1);
      expect(exhausted.message, contains('tired'));
      expect(exhausted.verses, isNotEmpty);

      final guilty = await assistant.ask('I feel guilty and ashamed', 1);
      expect(guilty.message, contains('tell God the truth'));
      expect(guilty.verses, isNotEmpty);

      final grateful = await assistant.ask('I am thankful today', 1);
      expect(grateful.message, contains('thankful'));
      expect(grateful.verses, isNotEmpty);
    },
  );

  test(
    'offline assistant declines questions outside its local Bible guide',
    () async {
      final assistant = SamSamAssistant(repository);

      final reply = await assistant.ask('What is pi?', 1);

      expect(reply.verses, isEmpty);
      expect(
        reply.message,
        contains('can’t answer that from my offline Bible guide'),
      );
    },
  );

  test(
    'Sam-Sam understands typos, Tagalog, Bisaya, and short follow-ups offline',
    () async {
      final assistant = SamSamAssistant(repository);

      final typo = await assistant.ask('Tell me abot Goliat', 1);
      expect(typo.verses, isNotEmpty);
      expect(typo.verses.first.reference, '1 Samuel 17:45');

      final tagalog = await assistant.ask('Kinakabahan ako', 1);
      expect(tagalog.message, contains('Ikinalulungkot'));
      expect(tagalog.verses, isNotEmpty);

      final bisaya = await assistant.ask('Nabalaka ko', 1);
      expect(bisaya.message, contains('Pasayloa'));
      expect(bisaya.verses, isNotEmpty);

      final followUp = await assistant.ask(
        'ngano?',
        1,
        conversation: ['Nabalaka ko'],
      );
      expect(followUp.message, contains('Mahitungod sa imong pangutana'));
      expect(followUp.verses, isNotEmpty);

      final contextualFollowUp = await assistant.ask(
        'What does that mean?',
        1,
        conversation: ['I feel anxious'],
      );
      expect(
        contextualFollowUp.message,
        contains('About your earlier question'),
      );
      expect(contextualFollowUp.verses, isNotEmpty);

      final localizedReference = await assistant.ask('Juan 3:16', 1);
      expect(localizedReference.verses, hasLength(1));
      expect(localizedReference.verses.single.reference, 'John 3:16');
    },
  );

  test('combined topic search resolves terms in one query', () async {
    final results = await repository.searchAnyTerms(
      ['kindness', 'mercy', 'compassion'],
      versionId: 1,
      limit: 6,
    );
    expect(results, isNotEmpty);
    expect(results.length, lessThanOrEqualTo(6));
  });

  test(
    'bookmarks and multi-verse ranges persist after database reopen',
    () async {
      final verses = await repository.chapter(1, 1);
      await repository.toggleBookmarks(verses.take(3).map((verse) => verse.id));
      expect(await repository.bookmarks(), hasLength(3));
      final firstSaved = (await repository.bookmarks()).first;
      await repository.updateSermonDetails(
        verseId: firstSaved.verse.id,
        isHighlight: false,
        title: 'Hope',
        note: 'Use this in Sunday’s message.',
      );
      final updated = (await repository.bookmarks()).first;
      expect(updated.sermonTitle, 'Hope');
      expect(updated.sermonNote, 'Use this in Sunday’s message.');
      await database.close();
      await openRepository();
      expect(await repository.bookmarks(), hasLength(3));
      expect(await repository.bookmarks(query: 'light'), isNotEmpty);
      expect(
        (await repository.bookmarks(query: 'Sunday')).single.sermonTitle,
        'Hope',
      );
      await repository.removeBookmark(firstSaved.verse.id);
      expect(await repository.bookmarks(), hasLength(2));
    },
  );

  test('highlights can be created, listed, recolored, and removed', () async {
    final verses = await repository.chapter(1, 1);
    final ids = verses.take(2).map((verse) => verse.id).toList();
    await repository.setHighlights(ids, 'F6D365');
    expect(await repository.highlights(), hasLength(2));
    await repository.setHighlights(ids, '93B8F4');
    expect((await repository.highlights()).first.color, '93B8F4');
    final savedHighlight = (await repository.highlights()).first;
    await repository.updateSermonDetails(
      verseId: savedHighlight.verse.id,
      isHighlight: true,
      title: 'Creation',
      note: 'Connect this with the opening theme.',
    );
    final managedHighlight = (await repository.highlights()).first;
    expect(managedHighlight.sermonTitle, 'Creation');
    expect(managedHighlight.sermonNote, 'Connect this with the opening theme.');
    expect(
      (await repository.highlights(query: 'opening theme')).single.sermonTitle,
      'Creation',
    );
    await repository.setHighlights(ids, '93B8F4');
    final recolored = (await repository.highlights()).singleWhere(
      (saved) => saved.verse.id == savedHighlight.verse.id,
    );
    expect(recolored.sermonTitle, 'Creation');
    expect(recolored.sermonNote, 'Connect this with the opening theme.');
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

  test(
    'memory verses stay local, deduplicate, and record recall outcomes',
    () async {
      final verse = (await repository.chapter(1, 1)).first;
      await repository.saveMemoryVerse(verse.id);
      await repository.saveMemoryVerse(verse.id);
      expect(await repository.isMemoryVerse(verse.id), isTrue);
      expect(await repository.memoryVerses(), hasLength(1));
      await repository.recordMemoryPractice(verse.id, successful: true);
      await repository.recordMemoryPractice(verse.id, successful: false);
      final saved = (await repository.memoryVerses()).single;
      expect(saved.practiceCount, 2);
      expect(saved.successfulRecalls, 1);
      expect(saved.failedRecalls, 1);
      expect(saved.status.label, 'Practicing');
      await repository.removeMemoryVerse(verse.id);
      expect(await repository.memoryVerses(), isEmpty);
    },
  );

  test(
    'cloze normalization is forgiving and preserves multilingual tokens',
    () {
      final exercise = ClozeExercise("Ang Diyos's pag-ibig ay dakila!");
      expect(exercise.tokens, containsAll(["Diyos's", 'pag-ibig', 'dakila']));
      expect(exercise.correct('PAG-IBIG ', 'pag-ibig'), isTrue);
      expect(exercise.correct('mali', 'pag-ibig'), isFalse);
      expect(exercise.blanks(), isNotEmpty);
    },
  );

  test('Verse Lens context remains valid at chapter boundaries', () async {
    final verses = await repository.chapter(1, 1);
    final opening = await repository.contextFor(verses.first, 5);
    final closing = await repository.contextFor(verses.last, 5);

    expect(opening.map((verse) => verse.number), [1, 2, 3, 4, 5]);
    expect(closing.map((verse) => verse.number), [27, 28, 29, 30, 31]);
    expect(opening.every((verse) => verse.chapter == 1), isTrue);
    expect(closing.every((verse) => verse.chapter == 1), isTrue);
  });

  test('Verse Lens resolves references in the selected translation', () async {
    final verse = await repository.verseAt(
      versionId: 2,
      bookOrder: 43,
      chapter: 3,
      number: 16,
    );
    expect(verse, isNotNull);
    expect(verse!.versionId, 2);
    expect(verse.reference, 'John 3:16');
  });
}
