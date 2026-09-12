import 'bible_models.dart';

class LivingWordSession {
  const LivingWordSession({required this.id, required this.localDate, required this.verse, required this.currentStage, required this.completed, required this.stages});
  final int id, currentStage;
  final String localDate;
  final BibleVerse verse;
  final bool completed;
  final List<bool> stages;
}

class ApplicationEntry {
  const ApplicationEntry({required this.id, required this.verse, required this.content, required this.createdAt});
  final int id;
  final BibleVerse verse;
  final String content;
  final DateTime createdAt;
}
