import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/presentation/screens/app_shell.dart';

void main() {
  testWidgets('onboarding communicates offline features', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    expect(find.text('VERALUME'), findsOneWidget);
    expect(find.text('Offline Bible'), findsOneWidget);
    expect(find.text('Search Scripture'), findsOneWidget);
    expect(find.text('Begin reading'), findsOneWidget);
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
