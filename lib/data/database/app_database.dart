import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

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
      final validVerseIds = <int>{
        for (final row in await target.query('verses', columns: ['id']))
          row['id'] as int,
      };
      await target.transaction((transaction) async {
        for (final table in const [
          'bookmarks',
          'highlights',
          'notes',
          'reading_history',
        ]) {
          final rows = await previous!.query(table);
          for (final row in rows) {
            if (!validVerseIds.contains(row['verse_id'])) continue;
            await transaction.insert(
              table,
              Map<String, Object?>.from(row),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      });
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
  }
}
