import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  /// Ensures additive user-data tables exist without replacing Scripture data.
  /// Exposed for deterministic migrations and database-backed tests.
  Future<void> ensureUserSchema(Database db) => _createUserTables(db);

  Future<Database> _open() async {
    final databaseDirectory = await getDatabasesPath();
    final target = p.join(databaseDirectory, 'veralume_v2.db');
    final previous = p.join(databaseDirectory, 'veralume_v1.db');
    final isNewInstall = !await File(target).exists();
    if (isNewInstall) {
      final bytes = await rootBundle.load('assets/data/veralume.db');
      await File(target).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    final db = await openDatabase(
      target,
      version: 1,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys=ON');
        await _createUserTables(db);
      },
    );
    if (isNewInstall && await File(previous).exists()) {
      await _migrateUserData(previous, db);
    }
    return db;
  }

  Future<void> _migrateUserData(String previousPath, Database target) async {
    Database? previous;
    try {
      previous = await openDatabase(previousPath, readOnly: true);
      for (final table in const [
        'bookmarks',
        'highlights',
        'notes',
        'reading_history',
      ]) {
        try {
          final rows = await previous.rawQuery(
            '''SELECT x.*,bv.code legacy_version_code,b.book_order legacy_book_order,
               v.chapter_number legacy_chapter,v.verse_number legacy_verse
               FROM $table x JOIN verses v ON v.id=x.verse_id
               JOIN books b ON b.id=v.book_id
               JOIN bible_versions bv ON bv.id=v.version_id''',
          );
          await target.transaction((transaction) async {
            for (final row in rows) {
              final matches = await transaction.rawQuery(
                '''SELECT v.id FROM verses v JOIN books b ON b.id=v.book_id
                 JOIN bible_versions bv ON bv.id=v.version_id
                 WHERE bv.code=? AND b.book_order=? AND v.chapter_number=?
                 AND v.verse_number=? LIMIT 1''',
                [
                  row['legacy_version_code'],
                  row['legacy_book_order'],
                  row['legacy_chapter'],
                  row['legacy_verse'],
                ],
              );
              if (matches.isEmpty) continue;
              final migrated = Map<String, Object?>.from(row)
                ..remove('legacy_version_code')
                ..remove('legacy_book_order')
                ..remove('legacy_chapter')
                ..remove('legacy_verse')
                ..['verse_id'] = matches.first['id'];
              await transaction.insert(
                table,
                migrated,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          });
        } catch (_) {
          // Recover every healthy table even if one legacy table is missing.
        }
      }
    } catch (_) {
      // A damaged legacy database must not prevent the new Bible from opening.
    } finally {
      await previous?.close();
    }
  }

  Future<void> _createUserTables(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS bookmarks(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL UNIQUE REFERENCES verses(id), created_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS highlights(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL UNIQUE REFERENCES verses(id), color TEXT NOT NULL, created_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL REFERENCES verses(id), content TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_history(id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL REFERENCES verses(id), accessed_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS history_recent ON reading_history(accessed_at DESC)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_progress(book_order INTEGER NOT NULL, chapter INTEGER NOT NULL, verses_read INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0, first_read_at TEXT NOT NULL, last_read_at TEXT NOT NULL, PRIMARY KEY(book_order, chapter))',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, book_order INTEGER NOT NULL, chapter INTEGER NOT NULL, started_at TEXT NOT NULL, ended_at TEXT NOT NULL, local_date TEXT NOT NULL, duration_seconds INTEGER NOT NULL, verses_read INTEGER NOT NULL DEFAULT 0)',
    );
    final sessionColumns = await db.rawQuery(
      'PRAGMA table_info(reading_sessions)',
    );
    if (!sessionColumns.any((column) => column['name'] == 'local_date')) {
      await db.execute(
        'ALTER TABLE reading_sessions ADD COLUMN local_date TEXT',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS sessions_started ON reading_sessions(started_at DESC)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_days(local_date TEXT PRIMARY KEY, chapters_read INTEGER NOT NULL DEFAULT 0, verses_read INTEGER NOT NULL DEFAULT 0, reading_seconds INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS milestones(milestone_key TEXT PRIMARY KEY, unlocked_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS journey_progress(journey_id TEXT PRIMARY KEY, started_at TEXT NOT NULL, completed_days TEXT NOT NULL DEFAULT \'\', completed_at TEXT)',
    );
  }
}
