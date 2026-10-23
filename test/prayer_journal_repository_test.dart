import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veralume/data/database/app_database.dart';
import 'package:veralume/data/repositories/prayer_journal_repository.dart';

void main() {
  sqfliteFfiInit();
  late Directory tempDirectory;
  late Database database;
  late PrayerJournalRepository repository;
  var now = DateTime(2026, 10, 16, 9);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'veralume_prayer_journal_',
    );
    final path = '${tempDirectory.path}${Platform.pathSeparator}veralume.db';
    await File('assets/data/veralume.db').copy(path);
    database = await databaseFactoryFfi.openDatabase(path);
    await database.execute('PRAGMA foreign_keys=ON');
    await AppDatabase.instance.ensureUserSchema(database);
    repository = PrayerJournalRepository.withConnection(
      database,
      clock: () => now,
    );
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test('saves dated prayers locally and marks them answered', () async {
    final prayerId = await repository.save(
      title: 'For patience',
      content: 'Help me listen carefully today.',
    );
    final saved = (await repository.entries()).single;
    expect(saved.id, prayerId);
    expect(saved.title, 'For patience');
    expect(saved.content, 'Help me listen carefully today.');
    expect(saved.createdAt, now.toUtc());
    expect(saved.answered, isFalse);

    now = now.add(const Duration(days: 2));
    await repository.setAnswered(prayerId, true);
    final answered = (await repository.entries()).single;
    expect(answered.answered, isTrue);
    expect(answered.answeredAt, now.toUtc());
    expect(answered.createdAt, DateTime(2026, 10, 16, 9).toUtc());

    await repository.setAnswered(prayerId, false);
    final reopened = (await repository.entries()).single;
    expect(reopened.answered, isFalse);
    expect(reopened.answeredAt, isNull);
  });

  test(
    'edits and deletes entries without changing their original date',
    () async {
      final id = await repository.save(title: 'First', content: 'A prayer.');
      final createdAt = (await repository.entries()).single.createdAt;
      now = now.add(const Duration(days: 1));

      await repository.save(
        id: id,
        title: 'Updated title',
        content: 'An updated prayer.',
      );
      final updated = (await repository.entries()).single;
      expect(updated.title, 'Updated title');
      expect(updated.content, 'An updated prayer.');
      expect(updated.createdAt, createdAt);

      await repository.delete(id);
      expect(await repository.entries(), isEmpty);
    },
  );

  test('rejects empty prayer title or content', () async {
    await expectLater(
      repository.save(title: '  ', content: 'Prayer'),
      throwsArgumentError,
    );
    await expectLater(
      repository.save(title: 'Title', content: '  '),
      throwsArgumentError,
    );
    expect(await repository.entries(), isEmpty);
  });
}
