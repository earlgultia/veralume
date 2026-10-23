import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/domain/journey/journey_catalog.dart';

void main() {
  test(
    'every daily devotional includes Scripture, reflection, lesson, prayer',
    () {
      expect(dailyLights, isNotEmpty);
      for (final devotional in dailyLights) {
        expect(devotional.passage.bookOrder, greaterThan(0));
        expect(devotional.passage.chapter, greaterThan(0));
        expect(devotional.reflection.trim(), isNotEmpty);
        expect(devotional.practicalLesson.trim(), isNotEmpty);
        expect(devotional.prayer.trim(), isNotEmpty);
      }
    },
  );

  test('daily devotional selection is stable for a local calendar day', () {
    final first = dailyLightForDate(DateTime(2026, 10, 16, 1));
    final later = dailyLightForDate(DateTime(2026, 10, 16, 23));
    expect(later.passage.bookOrder, first.passage.bookOrder);
    expect(later.passage.chapter, first.passage.chapter);
    expect(later.reflection, first.reflection);
  });
}
