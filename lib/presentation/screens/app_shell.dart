import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../data/models/journey_models.dart';
import '../../data/models/living_word_models.dart';
import '../../data/services/daily_word_notification_service.dart';
import '../../data/services/online_sam_sam_service.dart';
import '../../domain/assistant/sam_sam_assistant.dart';
import '../../domain/assistant/sam_sam_companion.dart';
import '../../domain/journey/journey_catalog.dart';
import '../../domain/quiz/bible_quiz.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'journey_screens.dart';
import 'focus_screen.dart';
import 'whats_new_screen.dart';
import 'verse_lens_screen.dart';
import 'memory_verses_screen.dart';
import 'living_word_screen.dart';
import '../widgets/sam_sam_animated_character.dart';
import '../widgets/sam_sam_pop_out.dart';
import 'prayer_journal_screen.dart';
import 'faith_calendar_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

String _onlineFailureMessage(SamSamOnlineException error) {
  final explanation = switch (error.kind) {
    SamSamOnlineFailure.rateLimited =>
      'The online service is busy right now. Please try again shortly.',
    SamSamOnlineFailure.timeout =>
      'Sam-Sam’s online reply took too long. Please try again.',
    SamSamOnlineFailure.unconfigured =>
      'Online Sam-Sam is not connected to its service yet.',
    SamSamOnlineFailure.offline =>
      'There is no internet connection. Please connect and try again.',
    SamSamOnlineFailure.invalidConfiguration =>
      'Online Sam-Sam could not authenticate with its service. Please check the app configuration.',
    SamSamOnlineFailure.providerKeyInvalid =>
      'Sam-Sam’s OpenRouter key is missing or rejected. Update OPENROUTER_API_KEY in Supabase Edge Function Secrets.',
    SamSamOnlineFailure.providerCredits =>
      'OpenRouter requires account credits for this request. Check the provider account or choose an available free model.',
    SamSamOnlineFailure.modelsUnavailable =>
      'The configured free AI models are unavailable right now. Please try again later.',
    SamSamOnlineFailure.providerUnavailable =>
      'Sam-Sam could not connect to OpenRouter. Please try again when the service is available.',
    SamSamOnlineFailure.unavailable =>
      'The online service could not be reached. Please try again.',
    SamSamOnlineFailure.server =>
      'The online service returned an error. Please try again.',
  };
  return explanation;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _features =
      <
        ({
          String title,
          String subtitle,
          IconData icon,
          List<(IconData, String, String)> items,
        })
      >[
        (
          title: 'Read at your pace',
          subtitle: 'Your complete Bible library works without internet.',
          icon: Icons.auto_stories_rounded,
          items: [
            (
              Icons.menu_book_rounded,
              'Bible reader',
              'Choose a book and chapter, then adjust the font and reading layout.',
            ),
            (
              Icons.translate_rounded,
              'Bible versions',
              'Pick your preferred translation once; it stays selected until you change it.',
            ),
            (
              Icons.history_rounded,
              'Continue reading',
              'Return quickly to passages you opened recently.',
            ),
          ],
        ),
        (
          title: 'Find the Word',
          subtitle: 'Move from a thought to the right passage quickly.',
          icon: Icons.manage_search_rounded,
          items: [
            (
              Icons.search_rounded,
              'Scripture search',
              'Search words and phrases across all versions or within one book.',
            ),
            (
              Icons.bookmark_add_rounded,
              'Bookmarks',
              'Save verses you want to revisit.',
            ),
            (
              Icons.format_color_fill_rounded,
              'Highlights',
              'Color important verses and passages as you read.',
            ),
          ],
        ),
        (
          title: 'Make it personal',
          subtitle: 'Keep your study and reflections organized on your device.',
          icon: Icons.edit_note_rounded,
          items: [
            (
              Icons.note_add_rounded,
              'Personal notes',
              'Attach your own reflection to a verse and search it later.',
            ),
            (
              Icons.share_rounded,
              'Share Scripture',
              'Send a verse or selected passage to family and friends.',
            ),
            (
              Icons.lock_outline_rounded,
              'Private by design',
              'Your notes, bookmarks, and history remain stored locally.',
            ),
          ],
        ),
        (
          title: 'Meet Sam-Sam',
          subtitle:
              'A friendly Bible companion inspired by the book of Psalms.',
          icon: Icons.chat_bubble_rounded,
          items: [
            (
              Icons.question_answer_rounded,
              'Ask naturally',
              'Say hello, ask about Bible people and events, or request help for a life topic.',
            ),
            (
              Icons.travel_explore_rounded,
              'Find passages',
              'Type “John 3:16” or ask for verses about hope, prayer, love, and more.',
            ),
            (
              Icons.touch_app_rounded,
              'Open every result',
              'Tap a verse in Sam-Sam’s reply to read it in its full chapter.',
            ),
          ],
        ),
        (
          title: 'Explore and grow',
          subtitle:
              'Learn through stories, challenges, and a reading experience made for you.',
          icon: Icons.lightbulb_rounded,
          items: [
            (
              Icons.menu_book_rounded,
              'Bible Stories',
              'Explore 22 guided stories with their Scripture passages.',
            ),
            (
              Icons.quiz_rounded,
              'Offline Bible Quiz',
              'Test your knowledge at easy, medium, or hard difficulty.',
            ),
            (
              Icons.tune_rounded,
              'Settings',
              'Choose theme, text size, line spacing, verse numbers, and full-screen reading.',
            ),
          ],
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _features.length) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(onboarded: true));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF24213E), Color(0xFF6B5730)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  const _SamSamWelcomeTutorial(),
                  for (final feature in _features)
                    _FeatureTutorial(feature: feature),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i <= _features.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: i == _page ? AppTheme.gold : Colors.white38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.navy,
                    ),
                    icon: Icon(
                      _page == _features.length
                          ? Icons.auto_stories_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _page == _features.length
                          ? 'Begin reading'
                          : _page == 0
                          ? 'Show me around'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SamSamWelcomeTutorial extends ConsumerWidget {
  const _SamSamWelcomeTutorial();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _SamSamAvatar(size: 132),
        const SizedBox(height: 24),
        const Text(
          'Welcome to VERALUME',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hi, I’m Sam-Sam! My name is inspired by the Psalms. I can help you explore the Bible and talk through your questions.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFEFE4C7), fontSize: 18, height: 1.4),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<BibleVerse>>(
          future: ref
              .read(bibleRepositoryProvider)
              .passageByReference(
                'Psalm',
                119,
                startVerse: 105,
                versionId: ref.read(settingsProvider).defaultVersionId,
              ),
          builder: (context, snapshot) {
            final verse = snapshot.data?.firstOrNull;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .1),
                border: Border.all(color: AppTheme.gold.withValues(alpha: .65)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: verse == null
                  ? const SizedBox(
                      height: 30,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        Text(
                          '“${verse.text}”',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '${verse.reference} · ${verse.versionAbbreviation}',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    ),
  );
}

class _FeatureTutorial extends StatelessWidget {
  const _FeatureTutorial({required this.feature});
  final ({
    String title,
    String subtitle,
    IconData icon,
    List<(IconData, String, String)> items,
  })
  feature;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(28, 36, 28, 12),
    child: Column(
      children: [
        Icon(feature.icon, color: AppTheme.gold, size: 68),
        const SizedBox(height: 18),
        Text(
          feature.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          feature.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEFE4C7),
            fontSize: 17,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        for (final item in feature.items)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.$1, color: AppTheme.gold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          color: Color(0xFFD9DCE3),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDailyWordReminders(ref.read(settingsProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDailyWordReminders(ref.read(settingsProvider));
    }
  }

  Future<void> _syncDailyWordReminders(ReadingSettings settings) async {
    if (!settings.dailyWordReminder) return;
    try {
      await DailyWordNotificationService.instance.scheduleDailyWords(
        repository: ref.read(bibleRepositoryProvider),
        versionId: settings.defaultVersionId,
      );
    } catch (error) {
      debugPrint('Could not refresh Daily Word reminders: $error');
    }
  }

  Future<void> _openJourneyPassage(PassageReference passage) async {
    final bible = ref.read(bibleRepositoryProvider);
    final versionId = ref.read(settingsProvider).defaultVersionId;
    try {
      final book = await bible.bookByOrder(versionId, passage.bookOrder);
      if (book == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This book is unavailable in the selected Bible version.',
              ),
            ),
          );
        }
        return;
      }
      final verses = await bible.chapter(book.id, passage.chapter);
      if (verses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This passage is unavailable in the selected Bible version.',
              ),
            ),
          );
        }
        return;
      }
      final focus =
          passage.startVerse != null &&
              verses.any((verse) => verse.number == passage.startVerse)
          ? passage.startVerse
          : null;
      if (!mounted) return;
      await openReader(
        context,
        ref,
        book.id,
        passage.chapter,
        focusVerse: focus,
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The passage could not be opened.')),
        );
      }
    }
  }

  Future<void> _openVerse(BibleVerse verse) async {
    await openReader(
      context,
      ref,
      verse.bookId,
      verse.chapter,
      focusVerse: verse.number,
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQuietVerse(BibleVerse verse) async {
    await openReader(
      context,
      ref,
      verse.bookId,
      verse.chapter,
      focusVerse: verse.number,
      quiet: true,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsProvider.select(
        (settings) => (settings.defaultVersionId, settings.dailyWordReminder),
      ),
      (previous, next) {
        if (next.$2 && previous?.$2 == true && previous?.$1 != next.$1) {
          _syncDailyWordReminders(ref.read(settingsProvider));
        }
      },
    );
    const primaryTabs = [0, 1, 3, 4, 5];
    final screens = [
      HomeScreen(
        onNavigate: (i) => setState(() => index = i),
        openPassage: _openJourneyPassage,
        openVerse: _openVerse,
        openQuietVerse: _openQuietVerse,
      ),
      const BibleScreen(),
      JourneyScreen(
        openPassage: _openJourneyPassage,
        openBible: () => setState(() => index = 1),
      ),
      const SearchScreen(),
      BookmarksScreen(refreshToken: index),
      const SettingsScreen(),
    ];
    final samSamSettings = ref.watch(
      settingsProvider.select(
        (settings) => (settings.samSamEnabled, settings.samSamScale),
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: index, children: screens),
          if (samSamSettings.$1)
            SamSamPopOut(
              initialScale: samSamSettings.$2,
              onScaleChanged: (scale) => ref
                  .read(settingsProvider.notifier)
                  .update(
                    ref.read(settingsProvider).copyWith(samSamScale: scale),
                  ),
              onAsk: (question) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SamSamScreen(initialQuestion: question),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _RadiantNavigationBar(
          selectedIndex: primaryTabs.contains(index)
              ? primaryTabs.indexOf(index)
              : 0,
          onSelected: (i) => setState(() => index = primaryTabs[i]),
        ),
      ),
    );
  }
}

class _RadiantNavigationBar extends StatelessWidget {
  const _RadiantNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Bible'),
    (Icons.search_rounded, Icons.manage_search_rounded, 'Search'),
    (Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Saved'),
    (Icons.tune_rounded, Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Material(
        color: palette.navigation.withValues(alpha: .98),
        elevation: 8,
        shadowColor: palette.primary.withValues(alpha: .18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: palette.border.withValues(alpha: .7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _RadiantNavigationItem(
                    icon: _items[index].$1,
                    selectedIcon: _items[index].$2,
                    label: _items[index].$3,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiantNavigationItem extends StatelessWidget {
  const _RadiantNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon, selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 42 : 34,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: .14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey(selected),
                    size: selected ? 24 : 22,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.highlightTitle = false,
    this.bottomPadding = 100,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool highlightTitle;
  final double bottomPadding;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(
            title,
            style: highlightTitle
                ? const TextStyle(
                    color: AppTheme.gold,
                    fontFamily: 'serif',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5.2,
                  )
                : null,
          ),
          actions: actions,
          backgroundColor: Colors.transparent,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPadding),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.openPassage,
    required this.openVerse,
    required this.openQuietVerse,
  });
  final ValueChanged<int> onNavigate;
  final OpenJourneyPassage openPassage;
  final Future<void> Function(BibleVerse verse) openVerse;
  final Future<void> Function(BibleVerse verse) openQuietVerse;

  Future<void> _openLivingWord(
    BuildContext context,
    WidgetRef ref, {
    LivingWordSession? session,
  }) async {
    final active =
        session ??
        await ref
            .read(bibleRepositoryProvider)
            .beginLivingWord(
              DateTime.now(),
              ref.read(settingsProvider).defaultVersionId,
            );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LivingWordScreen(
          session: active,
          openVerse: openVerse,
          askSamSam: (verse) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SamSamScreen(
                initialQuestion:
                    'Help me understand ${verse.reference}.\n\n${verse.text}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    final journey = ref.read(journeyRepositoryProvider);
    final versionId = ref.watch(
      settingsProvider.select((value) => value.defaultVersionId),
    );
    final now = DateTime.now();
    final light = journey.dailyLight(now);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return PageFrame(
      title: 'VERALUME',
      highlightTitle: true,
      child: FutureBuilder(
        future: Future.wait<Object?>([
          journey.resolvePassage(light.passage, versionId),
          repo.history(),
          journey.stats(),
          repo.lastLight(),
        ]),
        builder: (context, snapshot) {
          final dailyPassage = snapshot.hasData
              ? snapshot.data![0] as List<BibleVerse>
              : <BibleVerse>[];
          final daily = dailyPassage.firstOrNull;
          final history = snapshot.hasData
              ? snapshot.data![1] as List<BibleVerse>
              : <BibleVerse>[];
          final stats = snapshot.hasData
              ? snapshot.data![2] as JourneyStats
              : null;
          final lastLight = snapshot.hasData
              ? snapshot.data![3] as LastLight?
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHero(greeting: greeting),
              const SizedBox(height: 16),
              GlassCard(
                onTap: () => _openLivingWord(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY\'S WORD',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      daily?.reference ?? 'Scripture',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      daily == null
                          ? 'A deeper moment with Scripture.'
                          : '“${daily.text}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'serif', height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Read · Understand · Reflect · Remember · Apply · Pray',
                    ),
                    const SizedBox(height: 12),
                    const FilledButton(
                      onPressed: null,
                      child: Text('Begin Today\'s Word'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _HomeJourneyCard(stats: stats, onTap: () => onNavigate(2)),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ContinueReading(
                  verse: history.first,
                  onTap: () => openVerse(history.first),
                ),
              ],
              if (lastLight != null) ...[
                const SizedBox(height: 16),
                _LastLightCard(
                  lastLight: lastLight,
                  onTap: () => openQuietVerse(lastLight.verse),
                ),
              ],
              const SizedBox(height: 28),
              const _HomeHeading(
                'Daily Devotional',
                'Verse, reflection, practical lesson, and prayer',
              ),
              const SizedBox(height: 12),
              _DailyVerseCard(
                verse: daily,
                reflection: light.reflection,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyLightScreen(openPassage: openPassage),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _HomeHeading(
                'Plan Your Time With God',
                'Build a devotional rhythm and keep faith events in one place',
              ),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FaithCalendarScreen(),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppTheme.gold),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faith Calendar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Schedule devotionals, prayer, study, and church',
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Walk With Me',
                'A gentle journey through Scripture',
              ),
              const SizedBox(height: 12),
              _HomeWalkCard(
                journey: guidedJourneys.firstWhere((item) => item.id == 'hope'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuidedJourneyScreen(
                      journey: guidedJourneys.firstWhere(
                        (item) => item.id == 'hope',
                      ),
                      openPassage: openPassage,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Give Me a Verse',
                'A little Scripture for what you need today',
              ),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GiveMeAVerseScreen(
                      openVerse: openVerse,
                      askSamSam: (verse) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SamSamScreen(
                            initialQuestion:
                                'Let’s talk about ${verse.reference}.\n\n${verse.text}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppTheme.gold,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I need…',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text('Hope, peace, strength, wisdom, and more.'),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Explore',
                'Everything works completely offline',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final half = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _HomeAction(
                        half,
                        'Read Bible',
                        'Books & chapters',
                        Icons.auto_stories_rounded,
                        () => onNavigate(1),
                      ),
                      _HomeAction(
                        half,
                        'Search',
                        'Find Scripture',
                        Icons.manage_search_rounded,
                        () => onNavigate(3),
                      ),
                      _HomeAction(
                        half,
                        'Saved',
                        'Bookmarks & highlights',
                        Icons.bookmarks_rounded,
                        () => onNavigate(4),
                      ),
                      _HomeAction(
                        half,
                        'Notes',
                        'Personal reflections',
                        Icons.edit_note_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotesScreen(),
                          ),
                        ),
                      ),
                      _HomeAction(
                        half,
                        'Prayer Journal',
                        'Write and revisit prayers',
                        Icons.volunteer_activism_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrayerJournalScreen(),
                          ),
                        ),
                      ),
                      _HomeAction(
                        half,
                        'Memory Verses',
                        'Practice Scripture',
                        Icons.psychology_alt_outlined,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MemoryVersesScreen(openVerse: openVerse),
                          ),
                        ),
                      ),
                      _HomeAction(
                        half,
                        'My Living Word',
                        'Private reflections and actions',
                        Icons.checklist_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LivingWordHistoryScreen(
                              open: (session) => _openLivingWord(
                                context,
                                ref,
                                session: session,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _HomeAction(
                        constraints.maxWidth,
                        'Bible Facts',
                        'Quick facts from Scripture',
                        Icons.lightbulb_outline_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BibleFactsScreen(),
                          ),
                        ),
                        featured: true,
                      ),
                      _HomeAction(
                        constraints.maxWidth,
                        'Bible Stories',
                        '22 Scripture stories · completely offline',
                        Icons.history_edu_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BibleStoriesScreen(),
                          ),
                        ),
                        featured: true,
                      ),
                      _HomeAction(
                        constraints.maxWidth,
                        'Offline Bible Quiz',
                        'Easy, medium, or hard · 10 questions',
                        Icons.quiz_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BibleQuizScreen(),
                          ),
                        ),
                        featured: true,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Recently read',
                'Return to your latest passages',
              ),
              const SizedBox(height: 8),
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (history.isEmpty)
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: AppTheme.gold),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Your opened passages will appear here.'),
                      ),
                      IconButton(
                        tooltip: 'Read Bible',
                        onPressed: () => onNavigate(1),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                )
              else
                for (final verse in history.take(4))
                  _RecentPassage(verse: verse, onTap: () => openVerse(verse)),
            ],
          );
        },
      ),
    );
  }
}

class _StoryPassage {
  const _StoryPassage(
    this.bookOrder,
    this.chapter,
    this.startVerse,
    this.label,
  );
  final int bookOrder, chapter, startVerse;
  final String label;
}

class _BibleStory {
  const _BibleStory(
    this.title,
    this.subtitle,
    this.summary,
    this.icon,
    this.passages, {
    this.people = const [],
    this.lessons = const [],
    this.related = const [],
  });
  final String title, subtitle, summary;
  final IconData icon;
  final List<_StoryPassage> passages;
  final List<String> people, lessons, related;
}

const _bibleStories = <_BibleStory>[
  _BibleStory(
    'Noah and the Flood',
    'Faith, judgment, and God’s covenant',
    'When violence filled the earth, Noah trusted God and built the ark. God preserved Noah’s family and the animals through the flood, then placed the rainbow in the sky as the sign of his covenant with every living creature.',
    Icons.water_rounded,
    [
      _StoryPassage(1, 6, 9, 'Genesis 6:9–22 · The ark is commanded'),
      _StoryPassage(1, 7, 1, 'Genesis 7 · The flood comes'),
      _StoryPassage(1, 8, 1, 'Genesis 8 · The waters recede'),
      _StoryPassage(1, 9, 1, 'Genesis 9:1–17 · God’s covenant'),
    ],
  ),
  _BibleStory(
    'David and Goliath',
    'Courage rooted in trust in God',
    'The Philistine champion Goliath terrified Israel’s army, but young David faced him without armor. Trusting in the Lord rather than weapons or size, David defeated Goliath with a sling and a stone.',
    Icons.shield_rounded,
    [_StoryPassage(9, 17, 1, '1 Samuel 17 · David faces Goliath')],
  ),
  _BibleStory(
    'Daniel in the Lions’ Den',
    'Faithfulness under pressure',
    'Daniel continued praying to God even after a royal decree made it illegal. He was thrown into a den of lions, but God sent an angel to keep him safe, showing the king that the living God delivers those who trust him.',
    Icons.pets_rounded,
    [_StoryPassage(27, 6, 1, 'Daniel 6 · God rescues Daniel')],
  ),
  _BibleStory(
    'The Birth of Jesus',
    'The promised Savior is born',
    'Mary and Joseph traveled to Bethlehem, where Jesus was born and laid in a manger. Angels announced good news of great joy to nearby shepherds: the promised Savior and Lord had come.',
    Icons.nightlight_round,
    [
      _StoryPassage(40, 1, 18, 'Matthew 1:18–25 · Joseph’s obedience'),
      _StoryPassage(42, 2, 1, 'Luke 2:1–20 · Jesus is born'),
    ],
  ),
  _BibleStory(
    'Jesus Calms the Storm',
    'Peace in the middle of fear',
    'A violent storm overwhelmed the disciples’ boat while Jesus slept. When they cried out, Jesus rebuked the wind and waves, and the sea became calm. The disciples marveled that even nature obeyed him.',
    Icons.storm_rounded,
    [_StoryPassage(41, 4, 35, 'Mark 4:35–41 · The storm is stilled')],
  ),
  _BibleStory(
    'The Good Samaritan',
    'What it means to love your neighbor',
    'Jesus told of a wounded traveler ignored by respected passersby but helped generously by a Samaritan. The story teaches that mercy crosses social boundaries and that loving a neighbor is something we actively do.',
    Icons.volunteer_activism_rounded,
    [_StoryPassage(42, 10, 25, 'Luke 10:25–37 · A neighbor shows mercy')],
  ),
  _BibleStory(
    'The Prodigal Son',
    'The Father’s welcoming grace',
    'A younger son wasted his inheritance and returned home expecting to be treated as a servant. His father ran to welcome him and celebrated his return, revealing God’s joy when the lost repent and come home.',
    Icons.home_rounded,
    [_StoryPassage(42, 15, 11, 'Luke 15:11–32 · The lost son returns')],
  ),
  _BibleStory(
    'The Resurrection of Jesus',
    'The empty tomb and risen Lord',
    'On the first day of the week, Jesus’ followers found the tomb empty. Jesus rose from the dead as he had promised, appeared to his disciples, and turned their grief into hope and a mission to share the good news.',
    Icons.wb_sunny_rounded,
    [_StoryPassage(43, 20, 1, 'John 20 · Jesus rises and appears')],
  ),
  _BibleStory(
    'The Creation',
    'God creates the heavens and the earth',
    'God brought light, order, and life into being, forming the world and every living creature. Humanity was made in God’s image and entrusted with caring for creation, and God rested after completing his work.',
    Icons.public_rounded,
    [
      _StoryPassage(1, 1, 1, 'Genesis 1 · God creates the world'),
      _StoryPassage(1, 2, 1, 'Genesis 2 · Life in the garden'),
    ],
  ),
  _BibleStory(
    'Abraham Trusts God',
    'A promise, a journey, and tested faith',
    'God called Abram to leave his homeland and promised to make him a blessing to all nations. Years later, Abraham’s trust was tested on Mount Moriah, where God provided a ram in place of Isaac.',
    Icons.route_rounded,
    [
      _StoryPassage(1, 12, 1, 'Genesis 12:1–9 · Abram is called'),
      _StoryPassage(1, 22, 1, 'Genesis 22:1–19 · Abraham is tested'),
    ],
  ),
  _BibleStory(
    'Joseph Forgives His Brothers',
    'God brings good through hardship',
    'Joseph’s jealous brothers sold him into slavery, but God remained with him and raised him to authority in Egypt. During famine, Joseph revealed himself to his brothers and chose forgiveness, recognizing that God had used his suffering to save many lives.',
    Icons.handshake_rounded,
    [
      _StoryPassage(1, 37, 1, 'Genesis 37 · Joseph is sold'),
      _StoryPassage(1, 45, 1, 'Genesis 45 · Joseph reveals himself'),
    ],
  ),
  _BibleStory(
    'Moses and the Red Sea',
    'God delivers Israel from Egypt',
    'Trapped between Pharaoh’s army and the sea, the Israelites were afraid. God opened a path through the waters, led his people safely across on dry ground, and delivered them from their pursuers.',
    Icons.waves_rounded,
    [_StoryPassage(2, 14, 1, 'Exodus 14 · Israel crosses the sea')],
  ),
  _BibleStory(
    'The Walls of Jericho',
    'Obedience before an impossible city',
    'Israel followed God’s unusual instructions by marching around Jericho for seven days. When the priests sounded their trumpets and the people shouted, the walls fell and the city was opened before them.',
    Icons.location_city_rounded,
    [_StoryPassage(6, 6, 1, 'Joshua 6 · The walls fall')],
  ),
  _BibleStory(
    'Gideon’s Small Army',
    'God’s strength, not human numbers',
    'God called the hesitant Gideon to rescue Israel from Midian, then reduced his army to only three hundred men. Their surprising victory made clear that Israel had been delivered by God rather than by military strength.',
    Icons.groups_rounded,
    [
      _StoryPassage(7, 6, 11, 'Judges 6:11–40 · Gideon is called'),
      _StoryPassage(7, 7, 1, 'Judges 7 · Three hundred men'),
    ],
  ),
  _BibleStory(
    'Elijah on Mount Carmel',
    'The Lord answers by fire',
    'Elijah challenged the prophets of Baal before the people of Israel. After their altar remained silent, Elijah prayed and the Lord consumed his water-soaked sacrifice with fire, turning the people’s hearts back to God.',
    Icons.local_fire_department_rounded,
    [_StoryPassage(11, 18, 17, '1 Kings 18:17–40 · God answers Elijah')],
  ),
  _BibleStory(
    'Queen Esther’s Courage',
    'Risking everything to save her people',
    'When a plot threatened the Jewish people, Esther chose to approach the king even though doing so could cost her life. Through courage, wisdom, and fasting, she exposed the plot and helped bring deliverance to her people.',
    Icons.workspace_premium_rounded,
    [
      _StoryPassage(17, 4, 1, 'Esther 4 · Esther chooses courage'),
      _StoryPassage(17, 7, 1, 'Esther 7 · The plot is exposed'),
    ],
  ),
  _BibleStory(
    'The Fiery Furnace',
    'Faith that would not bow',
    'Shadrach, Meshach, and Abednego refused to worship the king’s golden image. They were thrown into a blazing furnace, but God preserved them, and the king saw a fourth figure walking with them in the fire.',
    Icons.whatshot_rounded,
    [_StoryPassage(27, 3, 1, 'Daniel 3 · God protects his servants')],
  ),
  _BibleStory(
    'Jonah and the Great Fish',
    'Running from God and learning mercy',
    'Jonah fled from God’s call to warn Nineveh, but a storm and a great fish turned him back. Nineveh repented when Jonah preached, and God used the prophet’s anger to teach him about compassion and mercy.',
    Icons.sailing_rounded,
    [
      _StoryPassage(32, 1, 1, 'Jonah 1 · Jonah runs away'),
      _StoryPassage(32, 2, 1, 'Jonah 2 · Jonah prays'),
      _StoryPassage(32, 3, 1, 'Jonah 3 · Nineveh repents'),
      _StoryPassage(32, 4, 1, 'Jonah 4 · God teaches mercy'),
    ],
  ),
  _BibleStory(
    'Jesus Feeds Five Thousand',
    'A small offering becomes enough',
    'A large crowd followed Jesus into a remote place. With five loaves and two fish, Jesus gave thanks and fed everyone until they were satisfied, with twelve baskets of pieces left over.',
    Icons.restaurant_rounded,
    [_StoryPassage(41, 6, 30, 'Mark 6:30–44 · Jesus feeds the crowd')],
  ),
  _BibleStory(
    'Jesus and Zacchaeus',
    'A changed life welcomes salvation',
    'Zacchaeus climbed a tree to see Jesus above the crowd. Jesus called him down and entered his home, and the tax collector responded with repentance, generosity, and a promise to repay those he had cheated.',
    Icons.park_rounded,
    [_StoryPassage(42, 19, 1, 'Luke 19:1–10 · Jesus seeks the lost')],
  ),
  _BibleStory(
    'The Day of Pentecost',
    'The Holy Spirit empowers the church',
    'As the disciples gathered in Jerusalem, the Holy Spirit came with the sound of a rushing wind and tongues like fire. They spoke in other languages, Peter proclaimed Jesus, and thousands received the message and were baptized.',
    Icons.air_rounded,
    [_StoryPassage(44, 2, 1, 'Acts 2 · The Holy Spirit is given')],
  ),
  _BibleStory(
    'Saul Meets Jesus',
    'A persecutor becomes a witness',
    'While traveling to arrest believers in Damascus, Saul was stopped by a light from heaven and encountered the risen Jesus. After Ananias prayed for him, Saul regained his sight, was baptized, and began proclaiming Jesus.',
    Icons.flash_on_rounded,
    [_StoryPassage(44, 9, 1, 'Acts 9:1–31 · Saul’s life is changed')],
  ),
  _BibleStory(
    'Ruth and Naomi',
    'Loyal love and redemption',
    'Ruth remained faithfully beside Naomi, gathered grain in Bethlehem, and found kindness in Boaz. Their story traces God’s quiet provision through loyalty and redemption.',
    Icons.spa_rounded,
    [
      _StoryPassage(8, 1, 1, 'Ruth 1 • Ruth stays with Naomi'),
      _StoryPassage(8, 4, 1, 'Ruth 4 • Boaz redeems'),
    ],
    people: ['Ruth', 'Naomi', 'Boaz'],
    lessons: ['Faithfulness matters', 'God works through ordinary kindness'],
    related: ['The Birth of Jesus'],
  ),
  _BibleStory(
    'Samson',
    'Strength and surrender',
    'God gave Samson extraordinary strength, yet his impulsive choices brought loss. In his final prayer he turned again to God.',
    Icons.fitness_center_rounded,
    [
      _StoryPassage(7, 13, 1, 'Judges 13 • Samson’s birth'),
      _StoryPassage(7, 16, 1, 'Judges 16 • Samson’s final stand'),
    ],
    people: ['Samson', 'Delilah'],
    lessons: ['Gifts need faithful character', 'God hears honest repentance'],
  ),
  _BibleStory(
    'Jesus Is Baptized',
    'The beloved Son begins his ministry',
    'Jesus came to John at the Jordan and was baptized. The Spirit descended like a dove and the Father declared his delight in his Son.',
    Icons.water_rounded,
    [_StoryPassage(40, 3, 13, 'Matthew 3:13–17 • Jesus is baptized')],
    people: ['Jesus', 'John the Baptist'],
    lessons: ['Jesus identifies with humanity', 'God delights in his Son'],
  ),
  _BibleStory(
    'Jesus Is Tempted',
    'Faithful in the wilderness',
    'After fasting forty days, Jesus resisted the tempter by trusting and speaking God’s Word.',
    Icons.landscape_rounded,
    [_StoryPassage(40, 4, 1, 'Matthew 4:1–11 • Jesus resists temptation')],
    people: ['Jesus'],
    lessons: [
      'Scripture strengthens resistance',
      'Faithfulness matters in private',
    ],
  ),
  _BibleStory(
    'Calling the Disciples',
    'Ordinary people follow Jesus',
    'Jesus called fishermen and others to leave their old lives, learn from him, and become fishers of people.',
    Icons.group_add_rounded,
    [_StoryPassage(42, 5, 1, 'Luke 5:1–11 • The first disciples')],
    people: ['Jesus', 'Peter', 'James', 'John'],
    lessons: ['Jesus calls ordinary people', 'Discipleship is active trust'],
  ),
  _BibleStory(
    'The Sermon on the Mount',
    'Life in God’s kingdom',
    'Jesus taught about blessing, prayer, love of enemies, trust, and building life upon his words.',
    Icons.record_voice_over_rounded,
    [_StoryPassage(40, 5, 1, 'Matthew 5–7 • Jesus teaches')],
    people: ['Jesus', 'The disciples', 'The crowds'],
    lessons: ['Kingdom life begins in the heart', 'Practice Jesus’ words'],
  ),
  _BibleStory(
    'Jesus Walks on Water',
    'Take courage; do not be afraid',
    'During a stormy night Jesus came to his disciples walking on the sea. Peter faltered in fear and was immediately rescued.',
    Icons.directions_walk_rounded,
    [_StoryPassage(40, 14, 22, 'Matthew 14:22–33 • Jesus walks on the sea')],
    people: ['Jesus', 'Peter', 'The disciples'],
    lessons: ['Look to Jesus in fear', 'Jesus is ready to rescue'],
  ),
  _BibleStory(
    'The Transfiguration',
    'The glory of Jesus revealed',
    'Jesus shone with glory as Moses and Elijah appeared. The Father told the disciples to listen to his beloved Son.',
    Icons.brightness_7_rounded,
    [_StoryPassage(40, 17, 1, 'Matthew 17:1–13 • Jesus is transfigured')],
    people: ['Jesus', 'Peter', 'James', 'John'],
    lessons: ['Jesus fulfills Scripture', 'Listen to Jesus'],
  ),
  _BibleStory(
    'Jesus Raises Lazarus',
    'The resurrection and the life',
    'Jesus wept with Martha and Mary, then called Lazarus out of the tomb, revealing compassion and authority over death.',
    Icons.favorite_rounded,
    [_StoryPassage(43, 11, 1, 'John 11 • Lazarus is raised')],
    people: ['Jesus', 'Lazarus', 'Martha', 'Mary'],
    lessons: [
      'Jesus meets grief with compassion',
      'Death does not have the final word',
    ],
  ),
  _BibleStory(
    'The Last Supper',
    'Remembering Jesus’ covenant',
    'Jesus washed his disciples’ feet and shared bread and the cup, teaching them to remember him and love one another.',
    Icons.dinner_dining_rounded,
    [
      _StoryPassage(42, 22, 7, 'Luke 22:7–23 • Bread and the cup'),
      _StoryPassage(43, 13, 1, 'John 13 • Jesus serves'),
    ],
    people: ['Jesus', 'The disciples'],
    lessons: ['Jesus leads through service', 'Remember his love'],
  ),
  _BibleStory(
    'The Crucifixion',
    'Love displayed at the cross',
    'Jesus was crucified at Golgotha, forgave his enemies, and entrusted himself to the Father.',
    Icons.church_rounded,
    [_StoryPassage(42, 23, 26, 'Luke 23:26–49 • Jesus is crucified')],
    people: ['Jesus', 'Mary', 'The disciples'],
    lessons: ['God’s love is costly', 'Jesus offers forgiveness'],
  ),
  _BibleStory(
    'Paul’s Missionary Journeys',
    'The good news crosses borders',
    'Led by the Spirit, Paul and his companions carried the message of Jesus through cities and cultures.',
    Icons.map_rounded,
    [
      _StoryPassage(44, 13, 1, 'Acts 13 • The journey begins'),
      _StoryPassage(44, 16, 1, 'Acts 16 • Philippi'),
      _StoryPassage(44, 19, 1, 'Acts 19 • Ephesus'),
    ],
    people: ['Paul', 'Barnabas', 'Silas', 'Timothy'],
    lessons: ['The gospel is for every people', 'Faithfulness perseveres'],
  ),
];

class BibleStoriesScreen extends StatelessWidget {
  const BibleStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bible Stories')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_bibleStories.length} stories to explore',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Read the story, meet its people, and explore Scripture.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.offline_bolt_rounded, color: AppTheme.gold),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All stories and Scripture passages are available offline.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < _bibleStories.length; index++) ...[
          Builder(
            builder: (context) {
              final story = _bibleStories[index];
              return GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _BibleStoryScreen(story: story),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.gold.withValues(alpha: .26),
                            AppTheme.gold.withValues(alpha: .08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(story.icon, color: AppTheme.gold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            story.passages.first.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              );
            },
          ),
          if (index != _bibleStories.length - 1) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class BibleFactsScreen extends StatelessWidget {
  const BibleFactsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bible Facts')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A little Scripture knowledge',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse these quick facts offline, or tap Sam-Sam whenever he pops up to explore one together.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final fact in SamSamFacts.facts) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fact.reference,
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SamSamScreen(initialQuestion: fact.question),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Explore with Sam-Sam'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _BibleStoryScreen extends ConsumerWidget {
  const _BibleStoryScreen({required this.story});
  final _BibleStory story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    final books = repo.books(ref.watch(settingsProvider).defaultVersionId);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Story')),
      body: FutureBuilder<List<BibleBook>>(
        future: books,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
          children: [
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(story.icon, size: 36, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    story.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    story.subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Text(
                story.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.65,
                  fontFamily: 'serif',
                ),
              ),
            ),
            if (story.people.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'People involved',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final person in story.people) Chip(label: Text(person)),
                ],
              ),
            ],
            if (story.lessons.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Key lessons',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              for (final lesson in story.lessons)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text(lesson),
                ),
            ],
            if (story.related.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Related stories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(story.related.join(' • ')),
            ],
            const SizedBox(height: 28),
            Text(
              'Read the event in Scripture',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              const Text('The Scripture passages could not be loaded.')
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else
              for (final passage in story.passages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      final matches = snapshot.data!.where(
                        (book) => book.order == passage.bookOrder,
                      );
                      if (matches.isNotEmpty) {
                        openReader(
                          context,
                          ref,
                          matches.first.id,
                          passage.chapter,
                          focusVerse: passage.startVerse,
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: Text(passage.label),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.greeting});
  final String greeting;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.gold.withValues(alpha: .30),
          Theme.of(context).colorScheme.primary.withValues(alpha: .14),
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -12,
          top: -18,
          child: Icon(
            Icons.light_mode_rounded,
            size: 118,
            color: AppTheme.gold.withValues(alpha: .12),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  greeting.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Let His Word\nbe your light.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Scripture, reflection, and growth—wherever you are.'),
          ],
        ),
      ],
    ),
  );
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard({required this.verse, this.reflection, this.onTap});
  final BibleVerse? verse;
  final String? reflection;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: verse == null
        ? const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, color: AppTheme.gold),
              const SizedBox(height: 8),
              Text(
                verse!.text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.48,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(width: 24, height: 2, color: AppTheme.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${verse!.reference} · ${verse!.versionAbbreviation}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (reflection != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                const Text(
                  'REFLECTION',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(reflection!, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Read passage'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ],
            ],
          ),
  );
}

class _HomeJourneyCard extends StatelessWidget {
  const _HomeJourneyCard({required this.stats, required this.onTap});
  final JourneyStats? stats;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .17),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.route_rounded, color: AppTheme.gold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR JOURNEY',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stats == null
                    ? 'Loading your journey…'
                    : '${stats!.currentStreak} day streak · ${stats!.chaptersRead} chapters',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Text('Walk through the Word, one passage at a time.'),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _HomeWalkCard extends StatelessWidget {
  const _HomeWalkCard({required this.journey, required this.onTap});
  final GuidedJourney journey;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Row(
      children: [
        const Icon(
          Icons.directions_walk_rounded,
          color: AppTheme.gold,
          size: 34,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('${journey.days.length} days · ${journey.theme}'),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded),
      ],
    ),
  );
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading({required this.verse, required this.onTap});
  final BibleVerse verse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: AppTheme.gold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTINUE YOUR JOURNEY',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                verse.reference,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(verse.versionAbbreviation),
              const Text('Return to this passage and continue reading.'),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ],
    ),
  );
}

class _LastLightCard extends StatelessWidget {
  const _LastLightCard({required this.lastLight, required this.onTap});
  final LastLight lastLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final saved = lastLight.savedAt;
    final wasLastNight =
        saved.year == yesterday.year &&
        saved.month == yesterday.month &&
        saved.day == yesterday.day;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: AppTheme.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LAST LIGHT',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastLight.verse.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  wasLastNight
                      ? 'You ended your reading here last night.'
                      : 'You ended your quiet reading here.',
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction(
    this.width,
    this.title,
    this.subtitle,
    this.icon,
    this.onTap, {
    this.featured = false,
  });
  final double width;
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $subtitle',
    child: SizedBox(
      width: width,
      child: GlassCard(
        padding: const EdgeInsets.all(15),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: featured
                    ? AppTheme.gold.withValues(alpha: .22)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: featured ? AppTheme.gold : null),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentPassage extends StatelessWidget {
  const _RecentPassage({required this.verse, required this.onTap});
  final BibleVerse verse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${verse.chapter}',
        style: const TextStyle(
          color: AppTheme.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    title: Text(
      verse.reference,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(verse.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class LegacyHomeScreen extends ConsumerWidget {
  const LegacyHomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    return PageFrame(
      title: 'Veralume',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let His Word be your light.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 22),
          FutureBuilder(
            future: repo.dailyVerse(DateTime.now()),
            builder: (c, s) => GlassCard(
              child: s.hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VERSE OF THE DAY',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“${s.data!.text}”',
                          style: Theme.of(c).textTheme.titleLarge?.copyWith(
                            height: 1.45,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${s.data!.reference} · ${s.data!.versionAbbreviation}',
                        ),
                      ],
                    )
                  : const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          const SizedBox(height: 26),
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Quick('Read Bible', Icons.auto_stories, () => onNavigate(1)),
              _Quick('Search', Icons.search, () => onNavigate(2)),
              _Quick('Bookmarks', Icons.bookmark, () => onNavigate(3)),
              _Quick('Notes', Icons.edit_note, () => onNavigate(4)),
              _Quick(
                'Bible Quiz',
                Icons.quiz_outlined,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BibleQuizScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Recently read', style: Theme.of(context).textTheme.titleLarge),
          FutureBuilder(
            future: repo.history(),
            builder: (c, s) => Column(
              children: (s.data ?? [])
                  .take(5)
                  .map(
                    (v) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(v.reference),
                      subtitle: Text(
                        v.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => openReader(
                        c,
                        ref,
                        v.bookId,
                        v.chapter,
                        focusVerse: v.number,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.label, this.icon, this.tap);
  final String label;
  final IconData icon;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon),
    label: Text(label),
    onPressed: tap,
    padding: const EdgeInsets.all(10),
  );
}

class _BibleVersionSelector extends StatelessWidget {
  const _BibleVersionSelector({
    required this.selectedVersion,
    required this.onTap,
  });

  final BibleVersion selectedVersion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.translate_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bible version',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${selectedVersion.name} (${selectedVersion.abbreviation})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      selectedVersion.language,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BibleVersionPicker extends StatefulWidget {
  const _BibleVersionPicker({
    required this.versions,
    required this.selectedVersionId,
  });

  final List<BibleVersion> versions;
  final int selectedVersionId;

  @override
  State<_BibleVersionPicker> createState() => _BibleVersionPickerState();
}

class _BibleVersionPickerState extends State<_BibleVersionPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final versions = widget.versions.where((version) {
      if (query.isEmpty) return true;
      return version.name.toLowerCase().contains(query) ||
          version.abbreviation.toLowerCase().contains(query) ||
          version.language.toLowerCase().contains(query);
    }).toList();
    final maxHeight = MediaQuery.sizeOf(context).height * .82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose a Bible version', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Select the translation you want to read.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search name or language',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: versions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No Bible versions match “${_query.trim()}”.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: versions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final version = versions[index];
                        final isSelected =
                            version.id == widget.selectedVersionId;
                        return Material(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: .65,
                                )
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.menu_book_outlined,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              version.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${version.abbreviation} · ${version.language}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? Text(
                                    'Selected',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(version),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BibleVersionLoadState extends StatelessWidget {
  const _BibleVersionLoadState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 34,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ],
    ),
  );
}

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(bibleRepositoryProvider);
    final preferredVersionId = ref.watch(
      settingsProvider.select((settings) => settings.defaultVersionId),
    );
    return PageFrame(
      title: 'Bible',
      child: FutureBuilder(
        future: repo.versions(),
        builder: (c, vs) {
          if (vs.hasError) {
            return _BibleVersionLoadState(
              message: 'Bible versions couldn’t be loaded.',
              onRetry: () => setState(() {}),
            );
          }
          if (vs.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final versions = vs.data ?? <BibleVersion>[];
          if (versions.isEmpty) {
            return const _BibleVersionLoadState(
              message: 'No Bible versions are available.',
            );
          }
          final selectedVersion = versions.firstWhere(
            (version) => version.id == preferredVersionId,
            orElse: () => versions.first,
          );
          return Column(
            children: [
              _BibleVersionSelector(
                selectedVersion: selectedVersion,
                onTap: () => _chooseVersion(versions, selectedVersion.id),
              ),
              const SizedBox(height: 16),
              FutureBuilder(
                future: repo.books(selectedVersion.id),
                builder: (c, bs) {
                  if (bs.hasError) {
                    return _BibleVersionLoadState(
                      message:
                          'Books couldn’t be loaded for '
                          '${selectedVersion.abbreviation}.',
                      onRetry: () => setState(() {}),
                    );
                  }
                  if (bs.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final books = bs.data ?? <BibleBook>[];
                  if (books.isEmpty) {
                    return const _BibleVersionLoadState(
                      message: 'This Bible version has no available books.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final testament in ['OT', 'NT']) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            testament == 'OT'
                                ? 'Old Testament'
                                : 'New Testament',
                            style: Theme.of(c).textTheme.titleLarge,
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: books
                              .where((b) => b.testament == testament)
                              .length,
                          itemBuilder: (c, i) {
                            final b = books
                                .where((x) => x.testament == testament)
                                .elementAt(i);
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _chapters(c, b),
                                child: Center(
                                  child: Text(
                                    b.name,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _chooseVersion(
    List<BibleVersion> versions,
    int selectedVersionId,
  ) async {
    final selected = await showModalBottomSheet<BibleVersion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BibleVersionPicker(
        versions: versions,
        selectedVersionId: selectedVersionId,
      ),
    );
    if (selected == null || !mounted) return;
    await ref.read(settingsProvider.notifier).setDefaultVersion(selected.id);
  }

  Future<void> _chapters(BuildContext context, BibleBook b) async {
    final count = await ref.read(bibleRepositoryProvider).chapterCount(b.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.name, style: Theme.of(c).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: count,
                  itemBuilder: (c, i) => _NumberButton(
                    key: ValueKey('pick-chapter-${i + 1}'),
                    label: '${i + 1}',
                    onPressed: () {
                      Navigator.pop(c);
                      _verses(context, b, i + 1);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verses(
    BuildContext context,
    BibleBook book,
    int chapter,
  ) async {
    final verses = await ref
        .read(bibleRepositoryProvider)
        .chapter(book.id, chapter);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${book.name} $chapter',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a verse',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('read-whole-chapter'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openReader(context, ref, book.id, chapter);
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Read whole chapter'),
              ),
              const SizedBox(height: 16),
              if (verses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No verses found in this chapter.'),
                  ),
                )
              else
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: verses.length,
                    itemBuilder: (gridContext, index) {
                      final verse = verses[index];
                      return _NumberButton(
                        key: ValueKey('pick-verse-${verse.number}'),
                        label: '${verse.number}',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          openReader(
                            context,
                            ref,
                            book.id,
                            chapter,
                            focusVerse: verse.number,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openReader(
  BuildContext context,
  WidgetRef ref,
  int bookId,
  int chapter, {
  int? focusVerse,
  bool quiet = false,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ReaderScreen(
      bookId: bookId,
      chapter: chapter,
      focusVerse: focusVerse,
      initialQuiet: quiet,
    ),
  ),
);

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.focusVerse,
    this.initialQuiet = false,
  });
  final int bookId, chapter;
  final int? focusVerse;
  final bool initialQuiet;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late int chapter = widget.chapter;
  late int bookId = widget.bookId;
  final Set<int> selected = {};
  bool? _lastFullScreen;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _recordedPassages = {};
  bool _focusApplied = false;
  bool _quiet = false;
  bool _controlsVisible = true;
  bool _switchingVersion = false;
  Timer? _controlsTimer;
  Timer? _meaningfulReadTimer;
  String? _pendingReadingKey;
  DateTime? _readingStartedAt;
  int _pendingVerseCount = 0;
  int _pendingBookId = 0;
  int _pendingChapter = 0;
  double _horizontalDrag = 0;
  bool _pendingCompletion = false;
  final Set<String> _recordedMeaningfulReads = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = ref.read(settingsProvider);
    _quiet = widget.initialQuiet || settings.quietReading;
    if (_quiet && settings.keepScreenAwake) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _setScreenAwake(true),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _meaningfulReadTimer?.cancel();
    _controlsTimer?.cancel();
    _setScreenAwake(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    super.dispose();
  }

  static const _quietChannel = MethodChannel('veralume/quiet_reading');
  Future<void> _setScreenAwake(bool enabled) async {
    try {
      await _quietChannel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
    } catch (_) {}
  }

  void _setQuiet(bool enabled, ReadingSettings settings) {
    setState(() {
      _quiet = enabled;
      _controlsVisible = true;
    });
    _setScreenAwake(enabled && settings.keepScreenAwake);
    if (enabled) _scheduleControlsHide(settings);
  }

  void _scheduleControlsHide(ReadingSettings settings) {
    _controlsTimer?.cancel();
    if (!_quiet || settings.quietControls == 'always') return;
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && selected.isEmpty) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls(ReadingSettings settings) {
    if (!_quiet || settings.quietControls == 'always') return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleControlsHide(settings);
  }

  Future<void> _switchBibleVersion() async {
    if (_switchingVersion) return;
    setState(() => _switchingVersion = true);
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final versions = await repo.versions();
      if (!mounted) return;
      if (versions.isEmpty) {
        _showVersionMessage('No Bible versions are available.');
        return;
      }
      final currentVersionId = ref.read(settingsProvider).defaultVersionId;
      final selectedVersion = await showModalBottomSheet<BibleVersion>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _BibleVersionPicker(
          versions: versions,
          selectedVersionId: currentVersionId,
        ),
      );
      if (selectedVersion == null || !mounted) return;
      if (selectedVersion.id == currentVersionId) return;

      final targetBookId = await repo.equivalentBook(
        bookId,
        selectedVersion.id,
      );
      if (!mounted) return;
      if (targetBookId == null) {
        _showVersionMessage(
          'This book is not available in ${selectedVersion.abbreviation}.',
        );
        return;
      }

      final chapterCount = await repo.chapterCount(targetBookId);
      if (!mounted) return;
      if (chapterCount == 0) {
        _showVersionMessage(
          'This book has no chapters in ${selectedVersion.abbreviation}.',
        );
        return;
      }
      final targetChapter = chapter.clamp(1, chapterCount);
      await ref
          .read(settingsProvider.notifier)
          .setDefaultVersion(selectedVersion.id);
      if (!mounted) return;
      setState(() {
        bookId = targetBookId;
        chapter = targetChapter;
        selected.clear();
      });
    } catch (error) {
      if (mounted) {
        _showVersionMessage('Could not switch Bible version: $error');
      }
    } finally {
      if (mounted) setState(() => _switchingVersion = false);
    }
  }

  void _showVersionMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartMeaningfulTimer();
    } else {
      _meaningfulReadTimer?.cancel();
    }
  }

  void _scheduleMeaningfulReading(List<BibleVerse> verses) {
    if (verses.isEmpty) return;
    final key = '$bookId:$chapter';
    if (_pendingReadingKey == key || _recordedMeaningfulReads.contains(key)) {
      return;
    }
    _meaningfulReadTimer?.cancel();
    _pendingReadingKey = key;
    _readingStartedAt = DateTime.now();
    _pendingBookId = bookId;
    _pendingChapter = chapter;
    final isTargetedOpening =
        bookId == widget.bookId &&
        chapter == widget.chapter &&
        widget.focusVerse != null;
    _pendingVerseCount = isTargetedOpening ? 1 : verses.length;
    _pendingCompletion = !isTargetedOpening;
    _restartMeaningfulTimer();
  }

  void _restartMeaningfulTimer() {
    final key = _pendingReadingKey;
    if (key == null || _recordedMeaningfulReads.contains(key)) return;
    _meaningfulReadTimer?.cancel();
    _readingStartedAt = DateTime.now();
    _meaningfulReadTimer = Timer(const Duration(seconds: 20), () {
      final startedAt = _readingStartedAt;
      if (startedAt == null || !mounted) return;
      _recordedMeaningfulReads.add(key);
      unawaited(
        ref
            .read(journeyRepositoryProvider)
            .recordMeaningfulReading(
              bookId: _pendingBookId,
              chapter: _pendingChapter,
              versesRead: _pendingVerseCount,
              startedAt: startedAt,
              duration: DateTime.now().difference(startedAt),
              completed: _pendingCompletion,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(bibleRepositoryProvider),
        settings = ref.watch(settingsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_lastFullScreen != settings.fullScreen) {
      _lastFullScreen = settings.fullScreen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setEnabledSystemUIMode(
          settings.fullScreen
              ? SystemUiMode.immersiveSticky
              : SystemUiMode.edgeToEdge,
        );
      });
    }
    return FutureBuilder(
      future: Future.wait([
        repo.chapter(bookId, chapter),
        repo.highlightsForChapter(bookId, chapter),
      ]),
      builder: (c, s) {
        if (s.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('This chapter could not be opened.\n${s.error}'),
            ),
          );
        }
        if (!s.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final verses = s.data![0] as List<BibleVerse>,
            highlights = s.data![1] as Map<int, String>;
        if (verses.isNotEmpty && _recordedPassages.add('$bookId:$chapter')) {
          repo.addHistory(verses.first.id);
        }
        _scheduleMeaningfulReading(verses);
        if (!_focusApplied && widget.focusVerse != null && verses.isNotEmpty) {
          _focusApplied = true;
          final index = verses.indexWhere(
            (verse) => verse.number == widget.focusVerse,
          );
          if (index >= 0) {
            selected.add(verses[index].id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && verses.length > 1) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent *
                      index /
                      (verses.length - 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }
        final quietSurface = settings.quietTone == 'system'
            ? Theme.of(context).scaffoldBackgroundColor
            : settings.quietTone == 'warm'
            ? const Color(0xFF19140F)
            : const Color(0xFF0E1420);
        final quietInk = settings.quietTone == 'system'
            ? Theme.of(context).textTheme.bodyLarge?.color
            : settings.quietTone == 'warm'
            ? const Color(0xFFF2E7D3)
            : const Color(0xFFE8E9E6);
        if (_quiet && _controlsVisible) _scheduleControlsHide(settings);
        return Scaffold(
          backgroundColor: _quiet ? quietSurface : null,
          appBar: _quiet && !_controlsVisible
              ? null
              : AppBar(
                  title: Text(
                    _quiet
                        ? 'Quiet Reading'
                        : verses.isEmpty
                        ? 'Bible'
                        : '${verses.first.bookName} $chapter',
                  ),
                  actions: [
                    if (_quiet)
                      IconButton(
                        tooltip: 'End My Reading',
                        icon: const Icon(Icons.nightlight_round),
                        onPressed: verses.isEmpty
                            ? null
                            : () => _endMyReading(
                                selected.isEmpty
                                    ? verses.first
                                    : verses.firstWhere(
                                        (verse) => selected.contains(verse.id),
                                        orElse: () => verses.first,
                                      ),
                              ),
                      ),
                    IconButton(
                      tooltip: 'Switch Bible version',
                      onPressed: _switchingVersion ? null : _switchBibleVersion,
                      icon: _switchingVersion
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.translate_rounded),
                    ),
                    IconButton(
                      tooltip: _quiet
                          ? 'Exit Quiet Reading'
                          : 'Reading settings',
                      onPressed: _quiet
                          ? () => _setQuiet(false, settings)
                          : () => _readingSettings(context),
                      icon: Icon(_quiet ? Icons.close : Icons.text_fields),
                    ),
                  ],
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _toggleControls(settings),
            onHorizontalDragUpdate: (details) =>
                _horizontalDrag += details.delta.dx,
            onHorizontalDragEnd: (_) async {
              if (_horizontalDrag.abs() < 90 || selected.isNotEmpty) {
                _horizontalDrag = 0;
                return;
              }
              final moveNext = _horizontalDrag < 0;
              _horizontalDrag = 0;
              if (moveNext) {
                final count = await repo.chapterCount(bookId);
                if (chapter < count && mounted) {
                  setState(() {
                    chapter++;
                    selected.clear();
                  });
                }
              } else if (chapter > 1 && mounted) {
                setState(() {
                  chapter--;
                  selected.clear();
                });
              }
            },
            child: SelectionArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: settings.readingWidth == 'compact'
                        ? 480
                        : settings.readingWidth == 'wide'
                        ? double.infinity
                        : 720,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
                    itemCount: verses.length,
                    itemBuilder: (c, i) {
                      final v = verses[i], hex = highlights[v.id];
                      return Semantics(
                        label: 'Verse ${v.number}',
                        button: true,
                        child: AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: selected.contains(v.id)
                                ? AppTheme.gold.withValues(alpha: .18)
                                : hex == null
                                ? null
                                : _color(hex).withValues(alpha: .24),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            key: ValueKey('verse-${v.number}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (!selected.add(v.id)) selected.remove(v.id);
                              });
                            },
                            onLongPress: () => _actions(context, [v]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    if (settings.showVerseNumbers)
                                      TextSpan(
                                        text: '${v.number}  ',
                                        style: TextStyle(
                                          color: AppTheme.gold,
                                          fontWeight: settings.boldVerseNumbers
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    TextSpan(text: v.text),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: settings.fontSize,
                                  height: settings.lineHeight,
                                  fontFamily: settings.serif ? 'serif' : null,
                                  color: _quiet ? quietInk : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: selected.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _actions(
                    context,
                    verses
                        .where((verse) => selected.contains(verse.id))
                        .toList(),
                  ),
                  icon: const Icon(Icons.more_horiz_rounded),
                  label: Text(
                    selected.length == 1
                        ? '1 verse selected'
                        : '${selected.length} verses selected',
                  ),
                ),
          bottomNavigationBar: _quiet && !_controlsVisible
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: chapter > 1
                                ? () => setState(() {
                                    chapter--;
                                    selected.clear();
                                  })
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final count = await repo.chapterCount(bookId);
                              if (chapter < count && mounted) {
                                setState(() {
                                  chapter++;
                                  selected.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Color _color(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  Future<void> _actions(
    BuildContext context,
    List<BibleVerse> selectedVerses,
  ) async {
    final repo = ref.read(bibleRepositoryProvider);
    final verseIds = selectedVerses.map((verse) => verse.id);
    final first = selectedVerses.first;
    final last = selectedVerses.last;
    final reference = selectedVerses.length == 1
        ? first.reference
        : '${first.bookName} ${first.chapter}:${first.number}-${last.number}';
    final selectedText = selectedVerses
        .map((verse) => '${verse.number} ${verse.text}')
        .join('\n');
    final savedToMemory = selectedVerses.length == 1
        ? await repo.isMemoryVerse(first.id)
        : false;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(c).height * 0.82,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(
                  selectedVerses.length == 1
                      ? 'Toggle bookmark'
                      : 'Toggle bookmarks',
                ),
                onTap: () async {
                  await repo.toggleBookmarks(verseIds);
                  HapticFeedback.lightImpact();
                  if (c.mounted) Navigator.pop(c);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Quick context'),
                enabled: selectedVerses.length == 1,
                subtitle: const Text('See the surrounding passage here'),
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        _quickContext(first);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.center_focus_strong),
                title: const Text('Verse Lens'),
                enabled: selectedVerses.length == 1,
                subtitle: const Text('See this verse in context'),
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        _openLens(first);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.self_improvement),
                title: const Text('Focus'),
                enabled: selectedVerses.length == 1,
                subtitle: const Text('Read, reflect, respond, and pray'),
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FocusVerseScreen(
                              verse: first,
                              onAskSamSam: () => _askSamSam(first),
                            ),
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.format_color_fill_rounded),
                title: const Text('Highlight'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final x in ['F6D365', '8ED1B2', '93B8F4', 'D4A5E8'])
                      GestureDetector(
                        onTap: () {
                          repo.setHighlights(verseIds, x);
                          Navigator.pop(c);
                          setState(() {});
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _color(x),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.psychology_alt_outlined),
                title: Text(savedToMemory ? 'Memory Verse ✓' : 'Remember'),
                enabled: selectedVerses.length == 1,
                subtitle: Text(
                  savedToMemory
                      ? 'Open your saved verse for recall practice'
                      : 'Save this verse for private recall practice',
                ),
                onTap: selectedVerses.length != 1
                    ? null
                    : () async {
                        if (savedToMemory) {
                          if (c.mounted) Navigator.pop(c);
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MemoryVersesScreen(
                                  openVerse: (verse) => openReader(
                                    context,
                                    ref,
                                    verse.bookId,
                                    verse.chapter,
                                    focusVerse: verse.number,
                                  ),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        await repo.saveMemoryVerse(first.id);
                        HapticFeedback.lightImpact();
                        if (c.mounted) {
                          Navigator.pop(c);
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Verse saved to Memory.'),
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: const Text('Ask Sam-Sam'),
                enabled: selectedVerses.length == 1,
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        _askSamSam(first);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.format_color_reset),
                title: const Text('Remove highlight'),
                onTap: () async {
                  await repo.setHighlights(verseIds, null);
                  if (c.mounted) Navigator.pop(c);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Add note'),
                enabled: selectedVerses.length == 1,
                subtitle: selectedVerses.length == 1
                    ? null
                    : const Text('Notes attach to one verse at a time'),
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        _note(context, first);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.hub_rounded),
                title: const Text('Verse connections'),
                enabled: selectedVerses.length == 1,
                subtitle: selectedVerses.length == 1
                    ? const Text('Explore curated related passages')
                    : const Text('Choose one verse to explore connections'),
                onTap: selectedVerses.length != 1
                    ? null
                    : () {
                        Navigator.pop(c);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerseConnectionsScreen(
                              source: first,
                              openPassage: _openConnectedPassage,
                            ),
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '$reference — $selectedText (${first.versionAbbreviation})',
                    ),
                  );
                  Navigator.pop(c);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  final box = context.findRenderObject() as RenderBox?;
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '$reference\n$selectedText\n${first.versionAbbreviation}',
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                  Navigator.pop(c);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(selected.clear);
  }

  void _askSamSam(BibleVerse verse) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SamSamScreen(
        initialQuestion:
            'Let’s talk about ${verse.reference}.\n\n${verse.text}',
      ),
    ),
  );

  void _openLens(BibleVerse verse) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VerseLensScreen(
        verse: verse,
        openPassage: _openConnectedPassage,
        askSamSam: _askSamSam,
      ),
    ),
  );

  void _quickContext(BibleVerse verse) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => QuickContextSheet(
      verse: verse,
      onOpenLens: () {
        Navigator.pop(sheetContext);
        _openLens(verse);
      },
    ),
  );

  Future<void> _openConnectedPassage(PassageReference passage) async {
    final repo = ref.read(bibleRepositoryProvider);
    final book = await repo.bookByOrder(
      ref.read(settingsProvider).defaultVersionId,
      passage.bookOrder,
    );
    if (book == null || !mounted) return;
    final verses = await repo.chapter(book.id, passage.chapter);
    if (verses.isEmpty || !mounted) return;
    await openReader(
      context,
      ref,
      book.id,
      passage.chapter,
      focusVerse: passage.startVerse,
    );
  }

  Future<void> _note(BuildContext context, BibleVerse v) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Note on ${v.reference}'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write your reflection…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(bibleRepositoryProvider)
                    .saveNote(v.id, controller.text.trim());
              }
              Navigator.pop(c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _readingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Consumer(
        builder: (c, ref, _) {
          final s = ref.watch(settingsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Quiet Reading'),
                    subtitle: const Text(
                      'A calm, distraction-free night reader',
                    ),
                    value: _quiet,
                    onChanged: (v) => _setQuiet(v, s),
                  ),
                  Text(
                    'Text size ${s.fontSize.round()}',
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                  Slider(
                    value: s.fontSize,
                    min: 14,
                    max: 32,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(fontSize: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Serif reading font'),
                    value: s.serif,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(serif: v)),
                  ),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.35, label: Text('Compact')),
                      ButtonSegment(value: 1.65, label: Text('Normal')),
                      ButtonSegment(value: 1.95, label: Text('Relaxed')),
                    ],
                    selected: {
                      s.lineHeight < 1.5
                          ? 1.35
                          : s.lineHeight > 1.8
                          ? 1.95
                          : 1.65,
                    },
                    onSelectionChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(lineHeight: v.first)),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'compact', label: Text('Compact')),
                      ButtonSegment(value: 'normal', label: Text('Normal')),
                      ButtonSegment(value: 'wide', label: Text('Wide')),
                    ],
                    selected: {s.readingWidth},
                    onSelectionChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(readingWidth: v.first)),
                  ),
                  SwitchListTile(
                    title: const Text('Bold verse numbers'),
                    value: s.boldVerseNumbers,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(boldVerseNumbers: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Verse numbers'),
                    value: s.showVerseNumbers,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(showVerseNumbers: v)),
                  ),
                  if (_quiet) ...[
                    const SizedBox(height: 8),
                    const Text('Reading tone'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cool', label: Text('Cool Dark')),
                        ButtonSegment(value: 'warm', label: Text('Warm Dark')),
                        ButtonSegment(value: 'system', label: Text('System')),
                      ],
                      selected: {s.quietTone},
                      onSelectionChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .update(s.copyWith(quietTone: v.first)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _endMyReading(BibleVerse verse) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BEFORE YOU REST',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                verse.reference,
                style: Theme.of(
                  c,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '“${verse.text}”',
                style: const TextStyle(fontFamily: 'serif', height: 1.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(c, 'reflect'),
                    child: const Text('Reflect'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(c, 'save'),
                    child: const Text('Save Verse'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(c, 'continue'),
                    child: const Text('Continue Reading'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, 'goodnight'),
                    child: const Text('Good Night'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null || action == 'continue') return;
    if (action == 'reflect') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FocusVerseScreen(
            verse: verse,
            onAskSamSam: () => _askSamSam(verse),
          ),
        ),
      );
      return;
    }
    if (action == 'save') {
      await ref.read(bibleRepositoryProvider).toggleBookmark(verse.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verse saved.')));
      }
      return;
    }
    if (ref.read(settingsProvider).rememberLastLight) {
      await ref.read(bibleRepositoryProvider).saveLastLight(verse);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('GOOD NIGHT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Take this Word with you.'),
            const SizedBox(height: 16),
            Text(
              verse.reference,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '“${verse.text}”',
              style: const TextStyle(fontFamily: 'serif'),
            ),
            const SizedBox(height: 16),
            const Text('Rest well.'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SamSamMessage {
  const _SamSamMessage(
    this.text, {
    required this.fromSamSam,
    this.verses = const [],
    this.online = false,
  });
  final String text;
  final bool fromSamSam;
  final bool online;
  final List<BibleVerse> verses;
}

class SamSamScreen extends ConsumerStatefulWidget {
  const SamSamScreen({super.key, this.initialQuestion});
  final String? initialQuestion;

  @override
  ConsumerState<SamSamScreen> createState() => _SamSamScreenState();
}

class _SamSamScreenState extends ConsumerState<SamSamScreen> {
  static const _welcomeMessage =
      'Hi, I’m Sam-Sam. Ask me about Scripture, share what’s on your mind, or ask for practical help. I’ll keep our conversation in context.';

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final SamSamAssistant _assistant;
  late final OnlineSamSamService _online;
  final _messages = <_SamSamMessage>[
    const _SamSamMessage(_welcomeMessage, fromSamSam: true),
  ];
  bool _thinking = false;
  String _language = 'English';

  static const _suggestions = [
    'Hi Sam-Sam!',
    'What can you do?',
    'What did I read yesterday?',
    'I feel anxious',
    'Tell me about Jesus',
    'Find verses about hope',
  ];

  @override
  void initState() {
    super.initState();
    _assistant = SamSamAssistant(
      ref.read(bibleRepositoryProvider),
      journeyRepository: ref.read(journeyRepositoryProvider),
    );
    _online = OnlineSamSamService();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialQuestion!;
        _ask();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _online.dispose();
    super.dispose();
  }

  Future<void> _ask([String? suggested]) async {
    final question = (suggested ?? _controller.text).trim();
    if (question.isEmpty || _thinking) return;
    _controller.clear();
    final history = _messages
        .where((message) => message.text != _welcomeMessage)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .map(
          (message) => {
            'role': message.fromSamSam ? 'assistant' : 'user',
            'content': message.text.length <= 1200
                ? message.text
                : message.text.substring(0, 1200),
          },
        )
        .toList();
    final offlineConversation = _messages
        .where((message) => !message.fromSamSam)
        .map((message) => message.text)
        .toList();
    setState(() {
      _messages.add(_SamSamMessage(question, fromSamSam: false));
      _thinking = true;
    });
    _scrollToEnd();
    SamSamReply reply;
    var usedOnline = false;
    try {
      if (_online.configured) {
        try {
          reply = SamSamReply(
            await _online.ask(
              question: question,
              language: _language,
              conversation: history,
            ),
          );
          usedOnline = true;
        } on SamSamOnlineException catch (error) {
          reply = await _replyOffline(question, offlineConversation);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_onlineFailureMessage(error)} Using the offline Bible guide.',
                ),
              ),
            );
          }
        }
      } else {
        reply = await _replyOffline(question, offlineConversation);
      }
    } on Exception {
      reply = const SamSamReply(
        'I couldn’t prepare a reply just now. Please try sending your message again.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sam-Sam could not reach the online service or local Bible data. '
              'Please try again when the connection is available.',
            ),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _messages.add(
        _SamSamMessage(
          reply.message,
          fromSamSam: true,
          verses: reply.verses,
          online: usedOnline,
        ),
      );
      _thinking = false;
    });
    _scrollToEnd();
  }

  Future<SamSamReply> _replyOffline(
    String question,
    List<String> offlineConversation,
  ) => _assistant.ask(
    question,
    ref.read(settingsProvider).defaultVersionId,
    language: _language,
    conversation: offlineConversation,
  );

  Future<void> _startNewConversation() async {
    if (_messages.length == 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start a new conversation?'),
        content: const Text(
          'This conversation will be cleared from this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('New chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(const _SamSamMessage(_welcomeMessage, fromSamSam: true));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const _SamSamAvatar(size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sam-Sam'),
              Text(
                _online.configured
                    ? 'Online AI when connected'
                    : 'Offline guide · online AI not configured',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'New conversation',
          onPressed: _thinking ? null : _startNewConversation,
          icon: const Icon(Icons.add_comment_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'Response language',
          initialValue: _language,
          onSelected: (value) => setState(() => _language = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'English', child: Text('English')),
            PopupMenuItem(value: 'Tagalog', child: Text('Tagalog')),
            PopupMenuItem(value: 'Bisaya', child: Text('Bisaya')),
          ],
          icon: const Icon(Icons.translate_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SamSamAvatar(size: 40),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sam-Sam is looking through Scripture…',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  );
                }
                final message = _messages[index];
                return _SamSamBubble(message: message);
              },
            ),
          ),
          if (_messages.length == 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final suggestion in _suggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _ask(suggestion),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: 'Ask Sam-Sam about the Bible…',
                prefixIcon: const Icon(Icons.auto_awesome_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Send',
                  onPressed: _thinking ? null : _ask,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SamSamBubble extends ConsumerWidget {
  const _SamSamBubble({required this.message});
  final _SamSamMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisAlignment: message.fromSamSam
        ? MainAxisAlignment.start
        : MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (message.fromSamSam) ...[
        const _SamSamAvatar(size: 40),
        const SizedBox(width: 10),
      ],
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: message.fromSamSam
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.text),
              if (message.fromSamSam) ...[
                const SizedBox(height: 8),
                Text(
                  message.online
                      ? 'ONLINE • OpenRouter'
                      : 'OFFLINE • Local Scripture',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              for (final verse in message.verses) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => openReader(
                    context,
                    ref,
                    verse.bookId,
                    verse.chapter,
                    focusVerse: verse.number,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${verse.reference} · ${verse.versionAbbreviation}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          verse.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _SamSamAvatar extends StatelessWidget {
  const _SamSamAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SamSamAnimatedCharacter(
    height: size,
    semanticsLabel: 'Sam-Sam, Bible companion',
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  List<BibleVerse>? results;
  bool loading = false;
  int? versionId;
  int? bookId;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> run() async {
    setState(() => loading = true);
    try {
      results = await ref
          .read(bibleRepositoryProvider)
          .search(controller.text, versionId: versionId, bookId: bookId);
    } catch (_) {
      results = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Search Scripture',
    child: Column(
      children: [
        FutureBuilder(
          future: ref.read(bibleRepositoryProvider).versions(),
          builder: (context, snapshot) => DropdownButtonFormField<int?>(
            initialValue: versionId,
            decoration: const InputDecoration(labelText: 'Translation'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All versions')),
              for (final version in snapshot.data ?? <BibleVersion>[])
                DropdownMenuItem(
                  value: version.id,
                  child: Text('${version.name} (${version.abbreviation})'),
                ),
            ],
            onChanged: (value) => setState(() {
              versionId = value;
              bookId = null;
            }),
          ),
        ),
        if (versionId != null) ...[
          const SizedBox(height: 10),
          FutureBuilder(
            future: ref.read(bibleRepositoryProvider).books(versionId!),
            builder: (context, snapshot) => DropdownButtonFormField<int?>(
              initialValue: bookId,
              decoration: const InputDecoration(labelText: 'Book'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All books')),
                for (final book in snapshot.data ?? <BibleBook>[])
                  DropdownMenuItem(value: book.id, child: Text(book.name)),
              ],
              onChanged: (value) => setState(() => bookId = value),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => run(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Love, faith, salvation…',
            suffixIcon: IconButton(
              onPressed: run,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        if (results != null && !loading && results!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 56),
                SizedBox(height: 12),
                Text('No verses found. Try another word or phrase.'),
              ],
            ),
          ),
        if (results != null)
          for (final v in results!)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              title: Text('${v.reference} · ${v.versionAbbreviation}'),
              subtitle: Text(
                v.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => openReader(
                context,
                ref,
                v.bookId,
                v.chapter,
                focusVerse: v.number,
              ),
            ),
      ],
    ),
  );
}

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key, this.refreshToken = 0});
  final int refreshToken;
  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final searchController = TextEditingController();
  bool showHighlights = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Saved Scripture',
    child: Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.bookmark),
              label: Text('Bookmarks'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.highlight),
              label: Text('Highlights'),
            ),
          ],
          selected: {showHighlights},
          onSelectionChanged: (value) =>
              setState(() => showHighlights = value.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Search saved verses and sermon notes',
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (showHighlights) _highlightList(context) else _bookmarkList(context),
      ],
    ),
  );

  Widget _bookmarkList(BuildContext context) => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .bookmarks(query: searchController.text),
    builder: (c, s) {
      final items = s.data ?? <SavedVerse>[];
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        return const _Empty(
          icon: Icons.bookmark_outline,
          title: 'No bookmarks found',
          message: 'Select a verse while reading to save it here.',
        );
      }
      return Column(
        children: [
          for (final saved in items)
            Dismissible(
              key: ValueKey('bookmark-${saved.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(c),
              onDismissed: (_) => ref
                  .read(bibleRepositoryProvider)
                  .removeBookmark(saved.verse.id),
              child: _verseTile(
                c,
                saved.verse,
                sermonTitle: saved.sermonTitle,
                sermonNote: saved.sermonNote,
                onManage: () =>
                    _manageSermonDetails(c, saved, isHighlight: false),
                onRemove: () async {
                  await ref
                      .read(bibleRepositoryProvider)
                      .removeBookmark(saved.verse.id);
                  if (mounted) setState(() {});
                },
              ),
            ),
        ],
      );
    },
  );

  Widget _highlightList(BuildContext context) => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .highlights(query: searchController.text),
    builder: (c, s) {
      final items = s.data ?? <SavedVerse>[];
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        final hasSearch = searchController.text.trim().isNotEmpty;
        return _Empty(
          icon: Icons.highlight,
          title: hasSearch ? 'No matching highlights' : 'No highlights yet',
          message: hasSearch
              ? 'Try another search or clear it to see all your highlights.'
              : 'Select verses in the reader and choose a highlight color.',
        );
      }
      return Column(
        children: [
          for (final saved in items)
            Dismissible(
              key: ValueKey('highlight-${saved.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(c),
              onDismissed: (_) => ref
                  .read(bibleRepositoryProvider)
                  .setHighlight(saved.verse.id, null),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 5,
                      color: Color(int.parse('FF${saved.color}', radix: 16)),
                    ),
                  ),
                ),
                child: _verseTile(
                  c,
                  saved.verse,
                  sermonTitle: saved.sermonTitle,
                  sermonNote: saved.sermonNote,
                  onManage: () =>
                      _manageSermonDetails(c, saved, isHighlight: true),
                  onRemove: () async {
                    await ref
                        .read(bibleRepositoryProvider)
                        .setHighlight(saved.verse.id, null);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _deleteBackground(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.all(20),
    color: Theme.of(context).colorScheme.errorContainer,
    child: const Icon(Icons.delete),
  );

  Future<void> _manageSermonDetails(
    BuildContext context,
    SavedVerse saved, {
    required bool isHighlight,
  }) async {
    final titleController = TextEditingController(
      text: saved.sermonTitle ?? '',
    );
    final noteController = TextEditingController(text: saved.sermonNote ?? '');
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Sermon details · ${saved.verse.reference}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Sermon title or topic',
                    hintText: 'e.g. Hope in difficult times',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Preparation note',
                    hintText: 'Add a reminder for your sermon…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(bibleRepositoryProvider)
                    .updateSermonDetails(
                      verseId: saved.verse.id,
                      isHighlight: isHighlight,
                      title: titleController.text,
                      note: noteController.text,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      titleController.dispose();
      noteController.dispose();
    }
    if (mounted) setState(() {});
  }

  Widget _verseTile(
    BuildContext context,
    BibleVerse verse, {
    String? sermonTitle,
    String? sermonNote,
    required VoidCallback onManage,
    required VoidCallback onRemove,
  }) {
    final hasSermonDetails =
        (sermonTitle?.isNotEmpty ?? false) || (sermonNote?.isNotEmpty ?? false);
    return ListTile(
      title: Text('${verse.reference} · ${verse.versionAbbreviation}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(verse.text, maxLines: 3, overflow: TextOverflow.ellipsis),
          if (hasSermonDetails) ...[
            const SizedBox(height: 8),
            if (sermonTitle?.isNotEmpty ?? false)
              Text(
                sermonTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (sermonNote?.isNotEmpty ?? false)
              Text(
                sermonNote!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
      onTap: () => openReader(
        context,
        ref,
        verse.bookId,
        verse.chapter,
        focusVerse: verse.number,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Manage sermon details',
            onPressed: onManage,
            icon: const Icon(Icons.edit_note_rounded),
          ),
          IconButton(
            tooltip: 'Remove from saved verses',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.refreshToken = 0});
  final int refreshToken;
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageFrame(
      title: 'Notes',
      bottomPadding: 24,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search your notes',
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _notesList(),
        ],
      ),
    ),
  );

  Widget _notesList() => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .notes(query: searchController.text),
    builder: (c, s) {
      if (s.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (s.hasError) {
        return _NotesEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Notes couldn’t load',
          message: 'Please try again.',
          action: TextButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        );
      }
      final items = s.data ?? [];
      if (items.isEmpty) {
        final hasSearch = searchController.text.trim().isNotEmpty;
        return _NotesEmptyState(
          icon: hasSearch ? Icons.search_off_rounded : Icons.edit_note_rounded,
          title: hasSearch ? 'No matching notes' : 'No notes yet',
          message: hasSearch
              ? 'Try a different word or clear your search.'
              : 'Save a reflection from any verse and it will appear here.',
          action: hasSearch
              ? TextButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  child: const Text('Clear search'),
                )
              : null,
        );
      }
      return Column(
        children: [
          for (final n in items) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => openReader(
                c,
                ref,
                n.verse.bookId,
                n.verse.chapter,
                focusVerse: n.verse.number,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            c,
                          ).colorScheme.primaryContainer.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Theme.of(c).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          n.verse.reference,
                          style: Theme.of(c).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(c).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Edit note',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _editNote(c, n),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: 'Delete note',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(c).colorScheme.error,
                          backgroundColor: Theme.of(
                            c,
                          ).colorScheme.errorContainer,
                        ),
                        onPressed: () async {
                          await ref
                              .read(bibleRepositoryProvider)
                              .deleteNote(n.id);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        c,
                      ).colorScheme.surface.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      n.content ?? '',
                      style: Theme.of(c).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: Theme.of(c).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    },
  );

  Future<void> _editNote(BuildContext context, SavedVerse note) async {
    final controller = TextEditingController(text: note.content);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${note.verse.reference}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 7,
          decoration: const InputDecoration(hintText: 'Write your reflection…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                await ref
                    .read(bibleRepositoryProvider)
                    .saveNote(note.verse.id, content, id: note.id);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted) setState(() {});
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, size: 34, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}

class BibleQuizScreen extends ConsumerStatefulWidget {
  const BibleQuizScreen({super.key});

  @override
  ConsumerState<BibleQuizScreen> createState() => _BibleQuizScreenState();
}

class _BibleQuizScreenState extends ConsumerState<BibleQuizScreen> {
  QuizDifficulty? difficulty;
  List<BibleQuizQuestion> questions = const [];
  int current = 0;
  int score = 0;
  String? selected;
  bool loading = false;
  String? error;

  Future<void> _start(QuizDifficulty value) async {
    setState(() {
      difficulty = value;
      loading = true;
      error = null;
      current = 0;
      score = 0;
      selected = null;
    });
    try {
      final versionId = ref.read(settingsProvider).defaultVersionId;
      final verses = await ref
          .read(bibleRepositoryProvider)
          .randomVerses(versionId);
      final generated = BibleQuizFactory().create(verses, value);
      if (!mounted) return;
      setState(() {
        questions = generated;
        loading = false;
        if (generated.isEmpty) {
          error = 'Not enough Scripture data was available for this quiz.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'The offline quiz could not be prepared. Please try again.';
      });
    }
  }

  void _answer(String value) {
    if (selected != null) return;
    setState(() {
      selected = value;
      if (value == questions[current].answer) score++;
    });
  }

  void _next() {
    if (current + 1 == questions.length) {
      setState(() => current = questions.length);
    } else {
      setState(() {
        current++;
        selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageFrame(
      title: 'Offline Bible Quiz',
      actions: [
        if (difficulty != null)
          IconButton(
            tooltip: 'Choose difficulty',
            onPressed: () => setState(() {
              difficulty = null;
              questions = const [];
              selected = null;
            }),
            icon: const Icon(Icons.tune),
          ),
      ],
      child: _content(context),
    ),
  );

  Widget _content(BuildContext context) {
    if (difficulty == null) return _difficultyPicker(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return _Empty(
        icon: Icons.error_outline,
        title: 'Quiz unavailable',
        message: error!,
      );
    }
    if (current >= questions.length) return _results(context);
    final question = questions[current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _QuizStatChip(
              icon: Icons.help_outline_rounded,
              label: 'Question ${current + 1} of ${questions.length}',
            ),
            const Spacer(),
            _QuizStatChip(
              icon: Icons.stars_rounded,
              label: '$score points',
              accent: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (current + 1) / questions.length,
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '“${question.passage}”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QuizOption(
              text: option,
              selected: selected == option,
              correct: selected == null ? null : option == question.answer,
              onTap: () => _answer(option),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 6),
          GlassCard(
            child: Row(
              children: [
                Icon(
                  selected == question.answer
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_rounded,
                  color: selected == question.answer
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected == question.answer
                            ? 'That’s right!'
                            : 'The answer is ${question.answer}.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(question.reference),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('quiz-next'),
            onPressed: _next,
            child: Text(
              current + 1 == questions.length ? 'See results' : 'Next question',
            ),
          ),
        ],
      ],
    );
  }

  Widget _difficultyPicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GlassCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.gold,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your challenge',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Build your Scripture knowledge at your own pace. Every round works offline.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _DifficultyCard(
        title: 'Easy',
        subtitle: 'Identify the Bible book from a verse.',
        icon: Icons.light_mode_outlined,
        onTap: () => _start(QuizDifficulty.easy),
      ),
      _DifficultyCard(
        title: 'Medium',
        subtitle: 'Choose the exact chapter and verse reference.',
        icon: Icons.auto_awesome_outlined,
        onTap: () => _start(QuizDifficulty.medium),
      ),
      _DifficultyCard(
        title: 'Hard',
        subtitle: 'Complete a missing word from Scripture.',
        icon: Icons.local_fire_department_outlined,
        onTap: () => _start(QuizDifficulty.hard),
      ),
    ],
  );

  Widget _results(BuildContext context) {
    final percentage = questions.isEmpty
        ? 0
        : (score * 100 ~/ questions.length);
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 72,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$score / ${questions.length}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text('$percentage% correct'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _start(difficulty!),
            icon: const Icon(Icons.shuffle),
            label: const Text('Play another random quiz'),
          ),
          TextButton(
            onPressed: () => setState(() {
              difficulty = null;
              questions = const [];
            }),
            child: const Text('Change difficulty'),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 26, color: AppTheme.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _QuizStatChip extends StatelessWidget {
  const _QuizStatChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? AppTheme.gold
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.text,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = correct == true
        ? Colors.green
        : selected && correct == false
        ? Theme.of(context).colorScheme.error
        : null;
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: OutlinedButton(
        onPressed: correct == null ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          side: color == null ? null : BorderSide(color: color, width: 2),
        ),
        child: Text(text),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider),
        notifier = ref.read(settingsProvider.notifier);
    return PageFrame(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Section('Appearance'),
          _ThemeSelector(
            selected: s.theme,
            onSelected: (theme) => notifier.update(s.copyWith(theme: theme)),
          ),
          const _Section('Reading'),
          ListTile(
            title: Text('Font size · ${s.fontSize.round()}'),
            subtitle: Slider(
              value: s.fontSize,
              min: 14,
              max: 32,
              onChanged: (v) => notifier.update(s.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: Text('Line spacing · ${s.lineHeight.toStringAsFixed(1)}'),
            subtitle: Slider(
              value: s.lineHeight,
              min: 1.2,
              max: 2.1,
              onChanged: (v) => notifier.update(s.copyWith(lineHeight: v)),
            ),
          ),
          SwitchListTile(
            title: const Text('Serif reading font'),
            value: s.serif,
            onChanged: (v) => notifier.update(s.copyWith(serif: v)),
          ),
          SwitchListTile(
            title: const Text('Show verse numbers'),
            value: s.showVerseNumbers,
            onChanged: (v) => notifier.update(s.copyWith(showVerseNumbers: v)),
          ),
          SwitchListTile(
            title: const Text('Bold verse numbers'),
            value: s.boldVerseNumbers,
            onChanged: (v) => notifier.update(s.copyWith(boldVerseNumbers: v)),
          ),
          ListTile(
            title: const Text('Reading width'),
            subtitle: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'compact', label: Text('Compact')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'wide', label: Text('Wide')),
              ],
              selected: {s.readingWidth},
              onSelectionChanged: (v) =>
                  notifier.update(s.copyWith(readingWidth: v.first)),
            ),
          ),
          SwitchListTile(
            title: const Text('Full-screen reading'),
            subtitle: const Text('Hide system bars while reading Scripture'),
            value: s.fullScreen,
            onChanged: (v) => notifier.update(s.copyWith(fullScreen: v)),
          ),
          const _Section('Quiet Reading'),
          SwitchListTile(
            title: const Text('Quiet Reading'),
            subtitle: const Text('Use a peaceful, minimal reader at night'),
            value: s.quietReading,
            onChanged: (v) => notifier.update(s.copyWith(quietReading: v)),
          ),
          ListTile(
            title: const Text('Reading tone'),
            subtitle: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cool', label: Text('Cool Dark')),
                ButtonSegment(value: 'warm', label: Text('Warm Dark')),
                ButtonSegment(value: 'system', label: Text('System')),
              ],
              selected: {s.quietTone},
              onSelectionChanged: (v) =>
                  notifier.update(s.copyWith(quietTone: v.first)),
            ),
          ),
          ListTile(
            title: const Text('Show controls'),
            subtitle: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tap', label: Text('Tap to show')),
                ButtonSegment(value: 'always', label: Text('Always')),
              ],
              selected: {s.quietControls},
              onSelectionChanged: (v) =>
                  notifier.update(s.copyWith(quietControls: v.first)),
            ),
          ),
          SwitchListTile(
            title: const Text('Keep screen awake'),
            subtitle: const Text('Only while Quiet Reading is open'),
            value: s.keepScreenAwake,
            onChanged: (v) => notifier.update(s.copyWith(keepScreenAwake: v)),
          ),
          SwitchListTile(
            title: const Text('Remember Last Light'),
            subtitle: const Text('Save where you end a quiet reading session'),
            value: s.rememberLastLight,
            onChanged: (v) => notifier.update(s.copyWith(rememberLastLight: v)),
          ),
          const _Section('Sam-Sam'),
          SwitchListTile(
            secondary: const Icon(Icons.smart_toy_outlined),
            title: const Text('Show Sam-Sam companion'),
            subtitle: const Text('Show the companion when Veralume opens'),
            value: s.samSamEnabled,
            onChanged: (enabled) =>
                notifier.update(s.copyWith(samSamEnabled: enabled)),
          ),
          ListTile(
            title: Text('Sam-Sam size · ${(s.samSamScale * 100).round()}%'),
            subtitle: Slider(
              value: s.samSamScale,
              min: .25,
              max: 1.35,
              divisions: 20,
              label: '${(s.samSamScale * 100).round()}%',
              onChanged: (scale) =>
                  notifier.update(s.copyWith(samSamScale: scale)),
            ),
          ),
          const _Section('Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Today’s Word reminder'),
            subtitle: const Text('Show today’s verse every morning at 8:00 AM'),
            value: s.dailyWordReminder,
            onChanged: (enabled) async {
              if (!enabled) {
                await notifier.update(s.copyWith(dailyWordReminder: false));
                try {
                  await DailyWordNotificationService.instance
                      .cancelDailyWords();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not cancel reminders: $error'),
                      ),
                    );
                  }
                }
                return;
              }
              try {
                final granted = await DailyWordNotificationService.instance
                    .requestPermission();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Allow notifications in your device settings to enable this reminder.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                await notifier.update(s.copyWith(dailyWordReminder: true));
                await DailyWordNotificationService.instance.scheduleDailyWords(
                  repository: ref.read(bibleRepositoryProvider),
                  versionId: s.defaultVersionId,
                );
              } catch (error) {
                await notifier.update(s.copyWith(dailyWordReminder: false));
                try {
                  await DailyWordNotificationService.instance
                      .cancelDailyWords();
                } catch (cancelError) {
                  debugPrint('Could not cancel failed reminders: $cancelError');
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not enable reminder: $error'),
                    ),
                  );
                }
              }
            },
          ),
          const _Section('Bible'),
          FutureBuilder(
            future: ref.read(bibleRepositoryProvider).versions(),
            builder: (context, snapshot) => DropdownButtonFormField<int>(
              initialValue:
                  snapshot.data?.any(
                        (version) => version.id == s.defaultVersionId,
                      ) ==
                      true
                  ? s.defaultVersionId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Default Bible version',
              ),
              items: [
                for (final version in snapshot.data ?? <BibleVersion>[])
                  DropdownMenuItem(
                    value: version.id,
                    child: Text('${version.name} (${version.abbreviation})'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setDefaultVersion(value);
                }
              },
            ),
          ),
          const _Section('Data'),
          ListTile(
            leading: const Icon(Icons.psychology_alt_outlined),
            title: const Text('Memory Verses'),
            subtitle: const Text('Practice Scripture privately, offline'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MemoryVersesScreen(
                  openVerse: (verse) => openReader(
                    context,
                    ref,
                    verse.bookId,
                    verse.chapter,
                    focusVerse: verse.number,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('My Reflections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FocusHistoryScreen(prayers: false),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_outlined),
            title: const Text('My Prayers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FocusHistoryScreen(prayers: true),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Prayer Journal'),
            subtitle: const Text('Personal prayers saved on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrayerJournalScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear reading history'),
            onTap: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Clear history?'),
                content: const Text(
                  'Bookmarks, highlights, and notes will remain.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      ref.read(bibleRepositoryProvider).clearHistory();
                      Navigator.pop(c);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
          const _Section('About'),
          ListTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.gold,
            ),
            title: const Text('What’s New'),
            subtitle: const Text('Veralume 1.5.4 • Faith Over Fear'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WhatsNewScreen())),
          ),
          const ListTile(
            leading: Icon(Icons.auto_stories),
            title: Text('Veralume'),
            subtitle: Text(
              'Truth · Light · Scripture\n'
              'Version 1.5.4 • Faith Over Fear\n'
              'ArkByte Technologies',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Developers'),
            subtitle: Text(
              'EARL GULTIA\n'
              'KRISTELLE JOYCE QUIJANO\n'
              'MILES GULTIA\n'
              'ARVEY OCIONES',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.offline_bolt),
            title: Text('Offline by design'),
            subtitle: Text(
              'Bible reading, search, and personal data remain on this device.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Bundled translations'),
            subtitle: Text(
              'ASV, KJV, Tagalog Ang Biblia, Open Ang Salita ng Diyos, Open Ang Pulong sa Dios, Balaan nga Bibliya, MBB-CEB, and CebBugna. See README for licensing notes.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selected, required this.onSelected});
  final VeralumeTheme selected;
  final ValueChanged<VeralumeTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palettes[selected]!;
    return ListTile(
      leading: Icon(Icons.palette_outlined, color: palette.primary),
      title: const Text('Color theme'),
      subtitle: Text(selected.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final color in [
            palette.primary,
            palette.secondary,
            palette.accent,
          ])
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more_rounded),
        ],
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => _ThemePickerSheet(
          selected: selected,
          onSelected: (theme) {
            onSelected(theme);
            Navigator.pop(sheetContext);
          },
        ),
      ),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({required this.selected, required this.onSelected});

  final VeralumeTheme selected;
  final ValueChanged<VeralumeTheme> onSelected;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .72,
    ),
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Text(
            'Choose a color theme',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final theme in VeralumeTheme.values)
          Builder(
            builder: (context) {
              final palette = AppTheme.palettes[theme]!;
              final active = theme == selected;
              return Semantics(
                selected: active,
                button: true,
                label: '${theme.label} theme',
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: active
                      ? palette.primary.withValues(alpha: .10)
                      : null,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in [
                        palette.primary,
                        palette.secondary,
                        palette.accent,
                      ])
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  title: Text(theme.label),
                  trailing: active
                      ? Icon(Icons.check_circle_rounded, color: palette.primary)
                      : null,
                  onTap: () => onSelected(theme),
                ),
              );
            },
          ),
      ],
    ),
  );
}

class RadiantFooter extends StatelessWidget {
  const RadiantFooter({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label:
          'Veralume. Your Word. Your Light. Everywhere. Version 1.5.4 Faith Over Fear.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.surface.withValues(alpha: .52),
                  p.primary.withValues(alpha: .12),
                  p.footer.withValues(alpha: .34),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .32)),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: .12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -50,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent.withValues(alpha: .08),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 72,
                  bottom: -70,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 150,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.primary.withValues(alpha: .18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < 560 ||
                          MediaQuery.textScalerOf(context).scale(16) > 21;
                      final brand = _FooterBrand(
                        accent: p.accent,
                        compact: compact,
                      );
                      final details = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: compact
                            ? WrapAlignment.start
                            : WrapAlignment.end,
                        children: const [
                          _FooterPill(
                            icon: Icons.offline_bolt_rounded,
                            label: 'Offline-first',
                          ),
                          _FooterPill(label: 'Version 1.5.4'),
                        ],
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            brand,
                            const SizedBox(height: 18),
                            details,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: brand),
                          const SizedBox(width: 20),
                          Flexible(child: details),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand({required this.accent, required this.compact});
  final Color accent;
  final bool compact;

  Widget get _logo => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Icon(Icons.auto_stories_rounded, color: accent, size: 28),
  );

  Widget get _name => Text(
    'VERALUME',
    style: TextStyle(
      color: accent,
      fontSize: 17,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.8,
    ),
  );

  Widget get _tagline => Text(
    'Your Word. Your Light. Everywhere.',
    style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.3),
  );

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _logo,
              const SizedBox(width: 14),
              Expanded(child: _name),
            ],
          ),
          const SizedBox(height: 10),
          _tagline,
        ],
      );
    }

    return Row(
      children: [
        _logo,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_name, const SizedBox(height: 3), _tagline],
          ),
        ),
      ],
    );
  }
}

class _FooterPill extends StatelessWidget {
  const _FooterPill({required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white.withValues(alpha: .75), size: 15),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.gold,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        Icon(icon, size: 64, color: AppTheme.gold),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
