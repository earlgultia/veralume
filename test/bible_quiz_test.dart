import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/data/models/bible_models.dart';
import 'package:veralume/domain/quiz/bible_quiz.dart';

BibleVerse verse(int id, String book, int chapter, int number, String text) =>
    BibleVerse(
      id: id,
      versionId: 1,
      bookId: id,
      bookName: book,
      versionAbbreviation: 'TEST',
      chapter: chapter,
      number: number,
      text: text,
    );

void main() {
  final verses = [
    verse(1, 'Genesis', 1, 1, 'In the beginning God created heaven and earth.'),
    verse(2, 'Exodus', 2, 3, 'Moses faithfully carried the people onward.'),
    verse(3, 'Psalms', 23, 1, 'The Lord is my shepherd and provider.'),
    verse(4, 'Matthew', 5, 9, 'Blessed are the peacemakers and faithful.'),
    verse(5, 'John', 3, 16, 'God loved the world and gave his Son.'),
    verse(6, 'Romans', 8, 28, 'All things work together for good.'),
  ];

  test('easy quiz creates four unique book choices with one answer', () {
    final questions = BibleQuizFactory(
      random: Random(1),
    ).create(verses, QuizDifficulty.easy, count: 4);
    expect(questions, hasLength(4));
    for (final question in questions) {
      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
      expect(
        question.options.where((value) => value == question.answer),
        hasLength(1),
      );
    }
  });

  test('medium quiz uses exact Scripture references', () {
    final question = BibleQuizFactory(
      random: Random(2),
    ).create(verses, QuizDifficulty.medium, count: 1).single;
    expect(question.options, contains(question.reference));
    expect(question.answer, question.reference);
  });

  test('hard quiz masks exactly one answer from the verse', () {
    final question = BibleQuizFactory(
      random: Random(3),
    ).create(verses, QuizDifficulty.hard, count: 1).single;
    expect(question.passage, contains('_____'));
    expect(question.options, contains(question.answer));
    expect(question.passage, isNot(contains(question.answer)));
  });
}
