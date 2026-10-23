class PrayerJournalEntry {
  const PrayerJournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.answered,
    this.answeredAt,
  });

  final int id;
  final String title, content;
  final DateTime createdAt;
  final bool answered;
  final DateTime? answeredAt;

  factory PrayerJournalEntry.fromMap(Map<String, Object?> map) =>
      PrayerJournalEntry(
        id: map['id'] as int,
        title: map['title'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        answered: map['answered'] == 1,
        answeredAt: map['answered_at'] == null
            ? null
            : DateTime.parse(map['answered_at'] as String),
      );
}
