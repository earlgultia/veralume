import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/domain/assistant/sam_sam_companion.dart';
import 'package:veralume/presentation/screens/app_shell.dart';
import 'package:veralume/presentation/widgets/sam_sam_animated_character.dart';
import 'package:veralume/presentation/widgets/sam_sam_pop_out.dart';

void main() {
  test('Sam-Sam facts include a readable passage prompt', () {
    expect(SamSamFacts.facts, isNotEmpty);
    for (final fact in SamSamFacts.facts) {
      expect(fact.message, isNotEmpty);
      expect(fact.reference, startsWith('Psalm '));
      expect(fact.question, contains(fact.reference));
    }
  });

  test('Sam-Sam has offline Bible story moments to share', () {
    expect(SamSamFacts.stories.length, greaterThanOrEqualTo(8));
    for (final story in SamSamFacts.stories) {
      expect(story.title, isNotEmpty);
      expect(story.message, isNotEmpty);
      expect(story.reference, isNotEmpty);
      expect(story.question, contains(story.title));
    }
  });

  testWidgets('Bible Facts lists offline facts and conversation prompts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BibleFactsScreen()));
    expect(find.text('Bible Facts'), findsOneWidget);
    expect(
      find.text('The book of Psalms is a collection of 150 songs and prayers.'),
      findsOneWidget,
    );
    expect(find.text('Explore with Sam-Sam'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sam-Sam stays still and reacts when tapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SamSamAnimatedCharacter(height: 140, onTap: () => tapped++),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SamSamAnimatedCharacter), findsOneWidget);
    final initialRect = tester.getRect(find.byType(Image));

    await tester.pump(const Duration(seconds: 13));
    expect(find.byType(SamSamAnimatedCharacter), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.getRect(find.byType(Image)), initialRect);
    expect(
      find.byKey(const ValueKey('sam-sam-animated-character')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('sam-sam-animated-character')));
    await tester.pump();
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinching Sam-Sam reports a bounded size adjustment', (
    tester,
  ) async {
    final scales = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SamSamAnimatedCharacter(
              height: 180,
              onScaleChanged: scales.add,
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(Image));
    final first = await tester.startGesture(
      Offset(rect.center.dx - 10, rect.center.dy),
      pointer: 1,
    );
    final second = await tester.startGesture(
      Offset(rect.center.dx + 10, rect.center.dy),
      pointer: 2,
    );
    await tester.pump();
    await second.moveTo(Offset(rect.center.dx + 100, rect.center.dy));
    await tester.pump();

    expect(scales, isNotEmpty);
    expect(scales.last, greaterThan(1));
    expect(scales.last, lessThanOrEqualTo(1.5));

    await first.up();
    await second.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sam-Sam starts small and accepts the saved size', (
    tester,
  ) async {
    final firstKey = GlobalKey<SamSamPopOutState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SamSamPopOut(key: firstKey, onAsk: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(firstKey.currentState!.characterScale, .4);
    firstKey.currentState!.updateCharacterScale(1.3);
    await tester.pump();

    expect(firstKey.currentState!.characterScale, 1.3);

    final restoredKey = GlobalKey<SamSamPopOutState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SamSamPopOut(
            key: restoredKey,
            initialScale: 1.3,
            onAsk: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(restoredKey.currentState!.characterScale, 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sam-Sam stays visible, checks in, and shares Bible facts', (
    tester,
  ) async {
    final key = GlobalKey<SamSamPopOutState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [SamSamPopOut(key: key, onAsk: (_) {})],
          ),
        ),
      ),
    );
    expect(key.currentState!.isVisible, isTrue);
    expect(key.currentState!.isBubbleVisible, isTrue);
    expect(find.textContaining('I’m Sam-Sam'), findsOneWidget);
    expect(find.text('Sam-Sam is thinking...'), findsOneWidget);
    final characterRect = tester.getRect(
      find.byKey(const ValueKey('sam-sam-animated-character')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('sam-sam-thought-bubble')),
    );
    expect(characterRect.overlaps(bubbleRect), isFalse);

    await tester.tap(find.byKey(const ValueKey('sam-sam-pop-out-character')));
    await tester.pump();
    expect(find.text('Checking in'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(key.currentState!.isBubbleVisible, isFalse);
    await tester.pump(const Duration(seconds: 49));
    expect(key.currentState!.isBubbleVisible, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(key.currentState!.isBubbleVisible, isTrue);
    expect(find.text('A gentle reminder'), findsOneWidget);

    await tester.tap(find.text('Another'));
    await tester.pump();
    expect(find.text('Bible fact'), findsOneWidget);
    expect(find.text(SamSamFacts.facts.first.message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double-tapping elsewhere does not hide Sam-Sam', (tester) async {
    final key = GlobalKey<SamSamPopOutState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Center(child: Text('Tap anywhere')),
              SamSamPopOut(key: key, onAsk: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(key.currentState!.isVisible, isTrue);

    await tester.tapAt(const Offset(30, 30));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(30, 30));
    await tester.pump();
    expect(key.currentState!.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });
}
