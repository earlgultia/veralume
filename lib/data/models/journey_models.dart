class ReadingProgress {
  const ReadingProgress({
    required this.bookOrder,
    required this.chapter,
    required this.versesRead,
    required this.completed,
    required this.firstReadAt,
    required this.lastReadAt,
  });
  final int bookOrder, chapter, versesRead;
  final bool completed;
  final DateTime firstReadAt, lastReadAt;
}

class JourneyStats {
  const JourneyStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.chaptersRead,
    required this.booksExplored,
    required this.booksCompleted,
    required this.versesRead,
    required this.readingDays,
    required this.scriptureProgress,
  });
  final int currentStreak, longestStreak, chaptersRead, booksExplored;
  final int booksCompleted, versesRead, readingDays;
  final double scriptureProgress;
}

class JourneyMilestone {
  const JourneyMilestone({
    required this.key,
    required this.title,
    required this.description,
    required this.symbol,
    required this.isUnlocked,
    this.unlockedAt,
  });
  final String key, title, description, symbol;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}

class PassageReference {
  const PassageReference(
    this.bookOrder,
    this.chapter, {
    this.startVerse,
    this.endVerse,
  });
  final int bookOrder, chapter;
  final int? startVerse, endVerse;
}

class DailyLight {
  const DailyLight(this.passage, this.reflection);
  final PassageReference passage;
  final String reflection;
}

class VerseConnection {
  const VerseConnection(this.source, this.target, this.type);
  final PassageReference source, target;
  final String type;
}

class GuidedJourneyDay {
  const GuidedJourneyDay(this.day, this.passage, this.reflection);
  final int day;
  final PassageReference passage;
  final String reflection;
}

class GuidedJourney {
  const GuidedJourney({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.days,
  });
  final String id, title, description, theme;
  final List<GuidedJourneyDay> days;
}

class GuidedJourneyProgress {
  const GuidedJourneyProgress(
    this.journeyId,
    this.completedDays, {
    this.completedAt,
  });
  final String journeyId;
  final Set<int> completedDays;
  final DateTime? completedAt;
}
