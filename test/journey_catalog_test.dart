import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/domain/journey/journey_catalog.dart';

void main() {
  test('guided Journey catalog is complete, ordered, and unique', () {
    expect(guidedJourneys, hasLength(14));
    expect(
      guidedJourneys.map((journey) => journey.id).toSet(),
      hasLength(guidedJourneys.length),
    );
    for (final journey in guidedJourneys) {
      expect(journey.title.trim(), isNotEmpty);
      expect(journey.description.trim(), isNotEmpty);
      expect(journey.theme.trim(), isNotEmpty);
      expect(journey.days, hasLength(7));
      expect(
        journey.days.map((day) => day.day),
        orderedEquals(List.generate(journey.days.length, (index) => index + 1)),
      );
      for (final day in journey.days) {
        expect(day.passage.bookOrder, inInclusiveRange(1, 66));
        expect(day.passage.chapter, greaterThan(0));
        expect(day.reflection.trim(), isNotEmpty);
      }
    }
  });

  test('daily light selection is deterministic for the local calendar day', () {
    final first = dailyLightForDate(DateTime(2026, 8, 12, 1));
    final later = dailyLightForDate(DateTime(2026, 8, 12, 23, 59));
    expect(identical(first, later), isTrue);
    expect(first.reflection.trim(), isNotEmpty);
  });

  test('verse connections use supported categories without duplicates', () {
    const types = {
      'Cross Reference',
      'Similar Theme',
      'Related Passage',
      'Same Topic',
      'Old Testament Connection',
      'New Testament Connection',
      'Prophecy / Fulfillment',
    };
    final identities = <String>{};
    for (final connection in verseConnections) {
      expect(types, contains(connection.type));
      expect(
        identities.add(
          '${connection.source.bookOrder}:${connection.source.chapter}:${connection.source.startVerse}'
          '>${connection.target.bookOrder}:${connection.target.chapter}:${connection.target.startVerse}:${connection.type}',
        ),
        isTrue,
      );
    }
  });
}
