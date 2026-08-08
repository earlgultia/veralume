import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veralume/main.dart';
import 'package:veralume/presentation/providers/app_providers.dart';
import 'package:veralume/presentation/screens/app_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, opens Scripture, and persists a bookmark', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    await tester.pumpWidget(const ProviderScope(child: VeralumeApp()));
    await tester.pumpAndSettle();
    expect(find.text('VERALUME'), findsOneWidget);

    await tester.tap(find.text('Begin reading'));
    await tester.pumpAndSettle();
    expect(find.text('VERALUME'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    final repository = container.read(bibleRepositoryProvider);
    final firstVerse = (await repository.chapter(1, 1)).first;
    if (await repository.isBookmarked(firstVerse.id)) {
      await repository.toggleBookmark(firstVerse.id);
    }

    await tester.tap(find.text('Bible').last);
    await tester.pumpAndSettle();
    expect(find.text('English ASV (ASV)'), findsOneWidget);

    await tester.tap(find.text('Genesis').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-chapter-1')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a verse'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pick-verse-1')));
    await tester.pumpAndSettle();
    expect(find.text('Genesis 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('verse-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 verse selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toggle bookmark'));
    await tester.pumpAndSettle();
    expect(await repository.isBookmarked(firstVerse.id), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark_outline).last);
    await tester.pumpAndSettle();
    expect(find.text('Saved Scripture'), findsWidgets);
    expect(find.textContaining('Genesis 1:1'), findsOneWidget);
  });
}
