enum FaithCalendarCategory { devotional, prayer, bibleStudy, church, personal }

enum FaithCalendarRepeat { once, daily, weekly }

class FaithCalendarEvent {
  const FaithCalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.category,
    required this.repeat,
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final FaithCalendarCategory category;
  final FaithCalendarRepeat repeat;
  final String notes;

  bool occursOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(startsAt.year, startsAt.month, startsAt.day);
    if (day.isBefore(startDay)) return false;
    return switch (repeat) {
      FaithCalendarRepeat.once => day == startDay,
      FaithCalendarRepeat.daily => true,
      FaithCalendarRepeat.weekly => day.weekday == startDay.weekday,
    };
  }

  FaithCalendarEvent copyWith({
    String? title,
    DateTime? startsAt,
    FaithCalendarCategory? category,
    FaithCalendarRepeat? repeat,
    String? notes,
  }) => FaithCalendarEvent(
    id: id,
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    category: category ?? this.category,
    repeat: repeat ?? this.repeat,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'startsAt': startsAt.toIso8601String(),
    'category': category.name,
    'repeat': repeat.name,
    'notes': notes,
  };

  factory FaithCalendarEvent.fromJson(Map<String, Object?> json) =>
      FaithCalendarEvent(
        id: json['id']! as String,
        title: json['title']! as String,
        startsAt: DateTime.parse(json['startsAt']! as String),
        category: FaithCalendarCategory.values.byName(
          json['category']! as String,
        ),
        repeat: FaithCalendarRepeat.values.byName(json['repeat']! as String),
        notes: json['notes'] as String? ?? '',
      );
}
