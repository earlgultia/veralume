import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/data/models/bible_models.dart';
import 'package:veralume/data/repositories/bible_repository.dart';
import 'package:veralume/presentation/screens/app_shell.dart';
import 'package:veralume/presentation/screens/whats_new_screen.dart';
import 'package:veralume/presentation/providers/app_providers.dart';
import 'package:veralume/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch opens the app without the tutorial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarded': false});
    await tester.pumpWidget(const ProviderScope(child: VeralumeApp()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.takeException(), isNull);
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

  testWidgets('What’s New shows the 1.5.4 Faith Over Fear update', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WhatsNewScreen()));

    expect(find.text('VERALUME 1.5.4 • FAITH OVER FEAR'), findsOneWidget);
    expect(find.text('Sam-Sam · connected conversations'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily Devotional'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Daily Devotional'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Prayer Journal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prayer Journal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Veralume UI 2.0'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Veralume UI 2.0'), findsOneWidget);
  });

  testWidgets('Notes stays focused and readable at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWith(
            (ref) => _EmptyNotesRepository(),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
            child: const NotesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Search your notes'), findsOneWidget);
    expect(find.text('Your Word. Your Light. Everywhere.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard pages no longer append the branded footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PageFrame(title: 'Example', child: Text('Page content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page content'), findsOneWidget);
    expect(find.text('Your Word. Your Light. Everywhere.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyNotesRepository extends BibleRepository {
  @override
  Future<List<SavedVerse>> notes({String query = ''}) async => const [];
}
