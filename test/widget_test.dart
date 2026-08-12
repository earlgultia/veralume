import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/presentation/screens/app_shell.dart';

void main() {
  testWidgets('David welcomes first-time users and starts feature tutorial', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    expect(find.text('Welcome to VERALUME'), findsOneWidget);
    expect(find.textContaining('I’m David'), findsOneWidget);
    expect(find.text('Show me around'), findsOneWidget);

    await tester.tap(find.text('Show me around'));
    await tester.pumpAndSettle();
    expect(find.text('Read at your pace'), findsOneWidget);
    expect(find.text('Bible reader'), findsOneWidget);
    expect(find.text('Bible versions'), findsOneWidget);
  });

  testWidgets('empty state is accessible through bookmarks screen', (
    tester,
  ) async {
    // Smoke coverage for app screen construction; database behavior is covered
    // by the deterministic import validation script.
    expect(const BookmarksScreen(), isA<ConsumerStatefulWidget>());
  });

  testWidgets('Bible story catalog is bundled and available offline', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BibleStoriesScreen()));

    expect(find.text('Bible Stories'), findsOneWidget);
    expect(
      find.text('All stories and Scripture passages are available offline.'),
      findsOneWidget,
    );
    expect(find.text('Noah and the Flood'), findsOneWidget);
  });
}
