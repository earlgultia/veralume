import 'dart:math';

import '../../data/models/bible_models.dart';

enum QuizDifficulty { easy, medium, hard }

class BibleQuizQuestion {
  const BibleQuizQuestion({
    required this.prompt,
    required this.passage,
    required this.options,
    required this.answer,
    required this.reference,
  });

  final String prompt;
  final String passage;
  final List<String> options;
  final String answer;
  final String reference;
}

class BibleQuizFactory {
  BibleQuizFactory({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<BibleQuizQuestion> create(
    List<BibleVerse> verses,
    QuizDifficulty difficulty, {
    int count = 10,
  }) {
    if (verses.length < 4) return const [];
    final shuffled = [...verses]..shuffle(_random);
    final questions = <BibleQuizQuestion>[];
    for (final verse in shuffled) {
      final question = switch (difficulty) {
        QuizDifficulty.easy => _referenceQuestion(
          verse,
          verses,
          bookOnly: true,
        ),
        QuizDifficulty.medium => _referenceQuestion(verse, verses),
        QuizDifficulty.hard => _completionQuestion(verse, verses),
      };
      if (question != null) questions.add(question);
      if (questions.length == count) break;
    }
    return questions;
  }

  BibleQuizQuestion? _referenceQuestion(
    BibleVerse verse,
    List<BibleVerse> pool, {
    bool bookOnly = false,
  }) {
    String choice(BibleVerse value) =>
        bookOnly ? value.bookName : value.reference;
    final answer = choice(verse);
    final distractors =
        pool.map(choice).where((value) => value != answer).toSet().toList()
          ..shuffle(_random);
    if (distractors.length < 3) return null;
    final options = [answer, ...distractors.take(3)]..shuffle(_random);
    return BibleQuizQuestion(
      prompt: bookOnly
          ? 'Which book contains this verse?'
          : 'Which reference matches this verse?',
      passage: verse.text,
      options: options,
      answer: answer,
      reference: verse.reference,
    );
  }

  BibleQuizQuestion? _completionQuestion(
    BibleVerse verse,
    List<BibleVerse> pool,
  ) {
    final words = _words(verse.text).where((word) => word.length >= 5).toList();
    if (words.isEmpty) return null;
    final answer = words[_random.nextInt(words.length)];
    final distractors =
        pool
            .expand((item) => _words(item.text))
            .where(
              (word) =>
                  word.length >= 5 &&
                  word.toLowerCase() != answer.toLowerCase(),
            )
            .toSet()
            .toList()
          ..shuffle(_random);
    if (distractors.length < 3) return null;
    final pattern = RegExp(r'\b' + RegExp.escape(answer) + r'\b');
    final passage = verse.text.replaceFirst(pattern, '_____');
    if (passage == verse.text) return null;
    final options = [answer, ...distractors.take(3)]..shuffle(_random);
    return BibleQuizQuestion(
      prompt: 'Which word completes the verse?',
      passage: passage,
      options: options,
      answer: answer,
      reference: verse.reference,
    );
  }

  Iterable<String> _words(String text) => RegExp(
    r"[A-Za-zÀ-ÖØ-öø-ÿ]+(?:['’][A-Za-zÀ-ÖØ-öø-ÿ]+)?",
  ).allMatches(text).map((match) => match.group(0)!);
}
