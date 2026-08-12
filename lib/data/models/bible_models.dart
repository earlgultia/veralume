class BibleVersion {
  const BibleVersion(
    this.id,
    this.code,
    this.name,
    this.abbreviation,
    this.language,
  );
  final int id;
  final String code, name, abbreviation, language;
  factory BibleVersion.fromMap(Map<String, Object?> m) => BibleVersion(
    m['id'] as int,
    m['code'] as String,
    (m['name'] as String).toUpperCase(),
    (m['abbreviation'] as String).toUpperCase(),
    m['language'] as String,
  );
}

class BibleBook {
  const BibleBook(
    this.id,
    this.versionId,
    this.name,
    this.abbreviation,
    this.testament,
    this.order,
  );
  final int id, versionId, order;
  final String name, abbreviation, testament;
  factory BibleBook.fromMap(Map<String, Object?> m) => BibleBook(
    m['id'] as int,
    m['version_id'] as int,
    m['name'] as String,
    m['abbreviation'] as String,
    m['testament'] as String,
    m['book_order'] as int,
  );
}

class BibleVerse {
  const BibleVerse({
    required this.id,
    required this.versionId,
    required this.bookId,
    required this.bookName,
    required this.versionAbbreviation,
    required this.chapter,
    required this.number,
    required this.text,
  });
  final int id, versionId, bookId, chapter, number;
  final String bookName, versionAbbreviation, text;
  String get reference => '$bookName $chapter:$number';
  factory BibleVerse.fromMap(Map<String, Object?> m) => BibleVerse(
    id: m['id'] as int,
    versionId: m['version_id'] as int,
    bookId: m['book_id'] as int,
    bookName: m['book_name'] as String,
    versionAbbreviation: (m['version_abbreviation'] as String).toUpperCase(),
    chapter: m['chapter_number'] as int,
    number: m['verse_number'] as int,
    text: m['text'] as String,
  );
}

class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.verse,
    this.content,
    this.color,
    required this.createdAt,
  });
  final int id;
  final BibleVerse verse;
  final String? content, color;
  final DateTime createdAt;
}

class LastLight {
  const LastLight({
    required this.verse,
    required this.savedAt,
    required this.localDate,
  });
  final BibleVerse verse;
  final DateTime savedAt;
  final String localDate;
}

class FocusEntry {
  const FocusEntry({
    required this.id,
    required this.verse,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });
  final int id;
  final BibleVerse verse;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.verseId,
    required this.readCompleted,
    required this.reflectionCompleted,
    required this.respondCompleted,
    required this.prayerCompleted,
    required this.createdAt,
    this.completedAt,
  });
  final int id, verseId;
  final bool readCompleted,
      reflectionCompleted,
      respondCompleted,
      prayerCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
}
