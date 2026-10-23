import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veralume/data/models/faith_calendar_event.dart';
import 'package:veralume/data/repositories/faith_calendar_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calendar events persist, update, and delete locally', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = FaithCalendarRepository();
    final event = FaithCalendarEvent(
      id: 'devotional-1',
      title: 'Morning devotional',
      startsAt: DateTime(2026, 10, 21, 8),
      category: FaithCalendarCategory.devotional,
      repeat: FaithCalendarRepeat.daily,
    );

    await repository.save(event);
    final saved = await repository.events();
    expect(saved.single.id, event.id);
    expect(saved.single.startsAt, event.startsAt);

    await repository.save(event.copyWith(title: 'Quiet morning devotional'));
    expect((await repository.events()).single.title, 'Quiet morning devotional');

    await repository.delete(event.id);
    expect(await repository.events(), isEmpty);
  });

  test('calendar events repeat on the selected days from their start date', () {
    final weeklyPrayer = FaithCalendarEvent(
      id: 'weekly-prayer',
      title: 'Prayer time',
      startsAt: DateTime(2026, 10, 19, 19),
      category: FaithCalendarCategory.prayer,
      repeat: FaithCalendarRepeat.weekly,
    );

    expect(weeklyPrayer.occursOn(DateTime(2026, 10, 19)), isTrue);
    expect(weeklyPrayer.occursOn(DateTime(2026, 10, 26)), isTrue);
    expect(weeklyPrayer.occursOn(DateTime(2026, 10, 27)), isFalse);
    expect(weeklyPrayer.occursOn(DateTime(2026, 10, 12)), isFalse);
  });
}
