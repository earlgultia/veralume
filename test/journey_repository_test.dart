import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veralume/data/database/app_database.dart';
import 'package:veralume/data/models/journey_models.dart';
import 'package:veralume/data/repositories/bible_repository.dart';
import 'package:veralume/data/repositories/journey_repository.dart';
import 'package:veralume/domain/assistant/david_assistant.dart';

void main() {
  sqfliteFfiInit();
  late Directory tempDirectory;
  late Database database;
  late BibleRepository bible;
  late JourneyRepository journey;
  late DateTime now;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('veralume_journey_');
    final path = '${tempDirectory.path}${Platform.pathSeparator}veralume.db';
    await File('assets/data/veralume.db').copy(path);
    database = await databaseFactoryFfi.openDatabase(path);
    await database.execute('PRAGMA foreign_keys=ON');
    await AppDatabase.instance.ensureUserSchema(database);
    bible = BibleRepository.withConnection(database);
    now = DateTime(2026, 8, 12, 12);
    journey = JourneyRepository.withConnection(database, clock: () => now);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'schema creation is idempotent and contains every Journey table',
    () async {
      await AppDatabase.instance.ensureUserSchema(database);
      await AppDatabase.instance.ensureUserSchema(database);
      final tables = {
        for (final row in await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        ))
          row['name'],
      };
      expect(
        tables,
        containsAll({
          'reading_progress',
          'reading_sessions',
          'reading_days',
          'milestones',
          'journey_progress',
        }),
      );
    },
  );

  test('progress is canonical and idempotent across Bible versions', () async {
    final asvJohn = await bible.bookByOrder(1, 43);
    final kjvJohn = await bible.bookByOrder(2, 43);
    expect(asvJohn, isNotNull);
    expect(kjvJohn, isNotNull);

    await journey.recordMeaningfulReading(
      bookId: asvJohn!.id,
      chapter: 3,
      versesRead: 36,
      startedAt: now.subtract(const Duration(seconds: 20)),
      duration: const Duration(seconds: 20),
    );
    now = now.add(const Duration(hours: 1));
    await journey.recordMeaningfulReading(
      bookId: kjvJohn!.id,
      chapter: 3,
      versesRead: 36,
      startedAt: now.subtract(const Duration(seconds: 20)),
      duration: const Duration(seconds: 20),
    );

    final progress = await journey.progressForBook(43);
    expect(progress, hasLength(1));
    expect(progress.single.chapter, 3);
    expect(progress.single.completed, isTrue);
    final stats = await journey.stats();
    expect(stats.chaptersRead, 1);
    expect(stats.booksExplored, 1);
    expect(stats.scriptureProgress, closeTo(1 / 1189, 0.000001));
  });

  test('partial reading upgrades without double-counting verses', () async {
    final john = (await bible.bookByOrder(1, 43))!;
    await journey.recordMeaningfulReading(
      bookId: john.id,
      chapter: 3,
      versesRead: 1,
      startedAt: now.subtract(const Duration(seconds: 20)),
      duration: const Duration(seconds: 20),
      completed: false,
    );
    await journey.recordMeaningfulReading(
      bookId: john.id,
      chapter: 3,
      versesRead: 36,
      startedAt: now.subtract(const Duration(seconds: 20)),
      duration: const Duration(seconds: 20),
    );
    final progress = (await journey.progressForBook(43)).single;
    expect(progress.completed, isTrue);
    expect(progress.versesRead, 36);
    expect((await journey.stats()).versesRead, 36);
  });

  test('passages and connections respect the selected Bible version', () async {
    final apd = await journey.resolvePassage(
      const PassageReference(43, 3, startVerse: 16),
      5,
    );
    expect(apd.single.versionId, 5);
    expect(apd.single.bookName, 'Juan');
    final asv = await journey.resolvePassage(
      const PassageReference(43, 3, startVerse: 16),
      1,
    );
    final connections = await journey.connectionsFor(asv.single);
    expect(connections, hasLength(3));
    for (final connection in connections) {
      expect(await journey.resolvePassage(connection.target, 5), isNotEmpty);
    }
  });

  test('guided journey completion is ordered and persists', () async {
    await journey.completeGuidedDay('hope', 2, 7);
    expect((await journey.guidedProgress('hope')).completedDays, isEmpty);
    await journey.completeGuidedDay('hope', 1, 7);
    await journey.completeGuidedDay('hope', 2, 7);
    expect(
      (await journey.guidedProgress('hope')).completedDays,
      orderedEquals({1, 2}),
    );
  });

  test('David answers local reading and saved-passage questions', () async {
    now = DateTime.now().subtract(const Duration(days: 1));
    for (final chapter in [5, 6, 7]) {
      final matthew = (await bible.bookByOrder(1, 40))!;
      await journey.recordMeaningfulReading(
        bookId: matthew.id,
        chapter: chapter,
        versesRead: (await bible.chapter(matthew.id, chapter)).length,
        startedAt: now.subtract(const Duration(seconds: 20)),
        duration: const Duration(seconds: 20),
      );
    }
    final john316 = (await journey.resolvePassage(
      const PassageReference(43, 3, startVerse: 16),
      1,
    )).single;
    await bible.toggleBookmark(john316.id);
    final david = DavidAssistant(bible, journeyRepository: journey);
    final history = await david.ask('David, what did I read yesterday?', 1);
    expect(history.message, contains('Matthew 5–7'));
    final saved = await david.ask('What verses did I save?', 1);
    expect(saved.verses.map((verse) => verse.id), contains(john316.id));
  });
}
