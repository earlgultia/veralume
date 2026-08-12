import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../data/models/journey_models.dart';
import '../../domain/journey/journey_catalog.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

typedef OpenJourneyPassage = Future<void> Function(PassageReference passage);

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({
    super.key,
    required this.openPassage,
    required this.openBible,
  });
  final OpenJourneyPassage openPassage;
  final VoidCallback openBible;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  int _refresh = 0;

  Future<_JourneyDashboardData> _load() async {
    final journey = ref.read(journeyRepositoryProvider);
    final bible = ref.read(bibleRepositoryProvider);
    final versionId = ref.read(settingsProvider).defaultVersionId;
    final results = await Future.wait<Object?>([
      journey.stats(),
      journey.progressByBook(),
      journey.milestones(),
      bible.books(versionId),
      journey.lastReadingPosition(),
      bible.chapterCounts(versionId),
    ]);
    final books = results[3] as List<BibleBook>;
    return _JourneyDashboardData(
      results[0] as JourneyStats,
      results[1] as Map<int, List<ReadingProgress>>,
      results[2] as List<JourneyMilestone>,
      books,
      results[5] as Map<int, int>,
      results[4] as PassageReference?,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((value) => value.defaultVersionId));
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_JourneyDashboardData>(
        key: ValueKey(_refresh),
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _JourneyError(
              message: 'Your Journey could not be loaded.',
              onRetry: () => setState(() => _refresh++),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _refresh++),
            child: CustomScrollView(
              slivers: [
                const SliverAppBar.large(
                  title: Text('Your Journey'),
                  backgroundColor: Colors.transparent,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        'Walk through the Word, one passage at a time.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 18),
                      _JourneyHero(
                        stats: data.stats,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JourneyStatisticsScreen(
                              stats: data.stats,
                              milestones: data.milestones,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (data.lastPosition != null)
                        _ContinueJourneyCard(
                          passage: data.lastPosition!,
                          books: data.books,
                          onTap: () => widget.openPassage(data.lastPosition!),
                        )
                      else
                        _JourneyEmpty(openBible: widget.openBible),
                      const SizedBox(height: 30),
                      const _JourneyHeading(
                        'Bible Journey',
                        'Follow the path through every book of Scripture',
                      ),
                      const SizedBox(height: 12),
                      _BibleJourneyMap(
                        books: data.books,
                        chapterCounts: data.chapterCounts,
                        progress: data.progress,
                        openPassage: widget.openPassage,
                      ),
                      const SizedBox(height: 30),
                      const _JourneyHeading(
                        'Walk With Me',
                        'Gentle, guided journeys that work offline',
                      ),
                      const SizedBox(height: 12),
                      for (final journey in guidedJourneys.take(3)) ...[
                        _GuidedJourneyCard(
                          journey: journey,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GuidedJourneyScreen(
                                  journey: journey,
                                  openPassage: widget.openPassage,
                                ),
                              ),
                            );
                            if (mounted) setState(() => _refresh++);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WalkWithMeScreen(
                                  openPassage: widget.openPassage,
                                ),
                              ),
                            );
                            if (mounted) setState(() => _refresh++);
                          },
                          icon: const Icon(Icons.directions_walk_rounded),
                          label: const Text('Explore all journeys'),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _JourneyHeading(
                        'Milestones',
                        'Quiet markers along the way',
                      ),
                      const SizedBox(height: 12),
                      _MilestonePreview(milestones: data.milestones),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JourneyDashboardData {
  const _JourneyDashboardData(
    this.stats,
    this.progress,
    this.milestones,
    this.books,
    this.chapterCounts,
    this.lastPosition,
  );
  final JourneyStats stats;
  final Map<int, List<ReadingProgress>> progress;
  final List<JourneyMilestone> milestones;
  final List<BibleBook> books;
  final Map<int, int> chapterCounts;
  final PassageReference? lastPosition;
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({required this.stats, required this.onTap});
  final JourneyStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.gold,
            ),
            const SizedBox(width: 8),
            Text(
              '${stats.currentStreak} day streak',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _HeroStat('${stats.chaptersRead}', 'Chapters'),
            _HeroStat('${stats.booksExplored}', 'Books'),
            _HeroStat(
              '${(stats.scriptureProgress * 100).round()}%',
              'Scripture',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Semantics(
          label:
              '${(stats.scriptureProgress * 100).round()} percent of Scripture journey',
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: stats.scriptureProgress),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 650),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppTheme.gold.withValues(alpha: .12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('View journey statistics'),
            SizedBox(width: 5),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _JourneyHeading extends StatelessWidget {
  const _JourneyHeading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 2),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ContinueJourneyCard extends StatelessWidget {
  const _ContinueJourneyCard({
    required this.passage,
    required this.books,
    required this.onTap,
  });
  final PassageReference passage;
  final List<BibleBook> books;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final matches = books.where((book) => book.order == passage.bookOrder);
    final name = matches.isEmpty ? 'Scripture' : matches.first.name;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route_rounded, color: AppTheme.gold),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$name ${passage.chapter}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('Return to your latest reading position.'),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}

class _JourneyEmpty extends StatelessWidget {
  const _JourneyEmpty({required this.openBible});
  final VoidCallback openBible;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        const Icon(Icons.wb_sunny_outlined, color: AppTheme.gold, size: 42),
        const SizedBox(height: 10),
        Text(
          'YOUR JOURNEY HAS JUST BEGUN',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every journey starts with a single step.\nOpen a Bible passage and begin.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: openBible,
          icon: const Icon(Icons.auto_stories_rounded),
          label: const Text('Read the Bible'),
        ),
      ],
    ),
  );
}

class _BibleJourneyMap extends StatelessWidget {
  const _BibleJourneyMap({
    required this.books,
    required this.chapterCounts,
    required this.progress,
    required this.openPassage,
  });
  final List<BibleBook> books;
  final Map<int, int> chapterCounts;
  final Map<int, List<ReadingProgress>> progress;
  final OpenJourneyPassage openPassage;

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<BibleBook>>{};
    for (final book in books) {
      sections.putIfAbsent(testamentSection(book.order), () => []).add(book);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final testament in const ['OT', 'NT']) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              testament == 'OT' ? 'OLD TESTAMENT' : 'NEW TESTAMENT',
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ),
          for (final entry in sections.entries.where((entry) {
            final isOld = entry.value.first.order <= 39;
            return testament == 'OT' ? isOld : !isOld;
          })) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 7),
              child: Text(
                entry.key,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                childAspectRatio: 2.05,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final book = entry.value[index];
                final bookProgress =
                    progress[book.order] ?? const <ReadingProgress>[];
                final completed = bookProgress
                    .where((item) => item.completed)
                    .length;
                final total = chapterCounts[book.order] ?? 0;
                final current = bookProgress.isEmpty
                    ? null
                    : bookProgress.reduce(
                        (a, b) => a.lastReadAt.isAfter(b.lastReadAt) ? a : b,
                      );
                final status = completed == total && total > 0
                    ? 'Completed'
                    : bookProgress.isNotEmpty
                    ? 'Started'
                    : 'Unread';
                return _BookMapCard(
                  book: book,
                  status: status,
                  completed: completed,
                  total: total,
                  currentChapter: current?.chapter,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookJourneyScreen(
                        book: book,
                        chapterCount: total,
                        progress: bookProgress,
                        openPassage: openPassage,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _BookMapCard extends StatelessWidget {
  const _BookMapCard({
    required this.book,
    required this.status,
    required this.completed,
    required this.total,
    required this.currentChapter,
    required this.onTap,
  });
  final BibleBook book;
  final String status;
  final int completed, total;
  final int? currentChapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = status != 'Unread';
    return Semantics(
      button: true,
      label: '${book.name}, $status, $completed of $total chapters read',
      child: Material(
        color: active
            ? AppTheme.gold.withValues(alpha: status == 'Completed' ? .20 : .10)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: active
                ? AppTheme.gold.withValues(alpha: .45)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(
                      status == 'Completed'
                          ? Icons.check_circle_rounded
                          : active
                          ? Icons.wb_sunny_rounded
                          : Icons.circle_outlined,
                      size: 15,
                      color: active ? AppTheme.gold : null,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  currentChapter == null
                      ? status
                      : 'Chapter $currentChapter · $status',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookJourneyScreen extends StatelessWidget {
  const BookJourneyScreen({
    super.key,
    required this.book,
    required this.chapterCount,
    required this.progress,
    required this.openPassage,
  });
  final BibleBook book;
  final int chapterCount;
  final List<ReadingProgress> progress;
  final OpenJourneyPassage openPassage;

  @override
  Widget build(BuildContext context) {
    final byChapter = {for (final item in progress) item.chapter: item};
    final complete = progress.where((item) => item.completed).length;
    final fraction = chapterCount == 0 ? 0.0 : complete / chapterCount;
    final current = progress.isEmpty
        ? null
        : progress
              .reduce((a, b) => a.lastReadAt.isAfter(b.lastReadAt) ? a : b)
              .chapter;
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$chapterCount chapters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$complete / $chapterCount chapters read · ${(fraction * 100).round()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var chapter = 1; chapter <= chapterCount; chapter++)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: byChapter[chapter]?.completed == true
                        ? AppTheme.gold.withValues(alpha: .22)
                        : null,
                    child: Text('$chapter'),
                  ),
                  title: Text('Chapter $chapter'),
                  subtitle: Text(
                    byChapter[chapter]?.completed == true
                        ? 'Read'
                        : current == chapter
                        ? 'Currently reading'
                        : 'Not read yet',
                  ),
                  trailing: Icon(
                    byChapter[chapter]?.completed == true
                        ? Icons.check_rounded
                        : current == chapter
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    color:
                        byChapter[chapter]?.completed == true ||
                            current == chapter
                        ? AppTheme.gold
                        : null,
                  ),
                  onTap: () =>
                      openPassage(PassageReference(book.order, chapter)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidedJourneyCard extends StatelessWidget {
  const _GuidedJourneyCard({required this.journey, required this.onTap});
  final GuidedJourney journey;
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
            color: AppTheme.gold.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${journey.days.length} days · ${journey.theme}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class WalkWithMeScreen extends StatelessWidget {
  const WalkWithMeScreen({super.key, required this.openPassage});
  final OpenJourneyPassage openPassage;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Walk With Me')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const Text(
            'Curated journeys through Scripture for the season you are walking through. Everything here is available offline.',
          ),
          const SizedBox(height: 20),
          for (final journey in guidedJourneys) ...[
            _GuidedJourneyCard(
              journey: journey,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GuidedJourneyScreen(
                    journey: journey,
                    openPassage: openPassage,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    ),
  );
}

class GuidedJourneyScreen extends ConsumerStatefulWidget {
  const GuidedJourneyScreen({
    super.key,
    required this.journey,
    required this.openPassage,
  });
  final GuidedJourney journey;
  final OpenJourneyPassage openPassage;
  @override
  ConsumerState<GuidedJourneyScreen> createState() =>
      _GuidedJourneyScreenState();
}

class _GuidedJourneyScreenState extends ConsumerState<GuidedJourneyScreen> {
  int _refresh = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.journey.title)),
    body: FutureBuilder<GuidedJourneyProgress>(
      key: ValueKey(_refresh),
      future: ref
          .read(journeyRepositoryProvider)
          .guidedProgress(widget.journey.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _JourneyError(
            message: 'This guided journey could not be loaded.',
            onRetry: () => setState(() => _refresh++),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final progress = snapshot.data!;
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.journey.days.length} DAY JOURNEY · ${widget.journey.theme.toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.journey.description,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value:
                          progress.completedDays.length /
                          widget.journey.days.length,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${progress.completedDays.length} of ${widget.journey.days.length} days complete',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final day in widget.journey.days) ...[
                _JourneyDayCard(
                  day: day,
                  completed: progress.completedDays.contains(day.day),
                  enabled:
                      day.day == 1 ||
                      progress.completedDays.contains(day.day - 1) ||
                      progress.completedDays.contains(day.day),
                  openPassage: widget.openPassage,
                  onComplete: () async {
                    await ref
                        .read(journeyRepositoryProvider)
                        .completeGuidedDay(
                          widget.journey.id,
                          day.day,
                          widget.journey.days.length,
                        );
                    if (mounted) setState(() => _refresh++);
                  },
                ),
                const SizedBox(height: 11),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _JourneyDayCard extends StatelessWidget {
  const _JourneyDayCard({
    required this.day,
    required this.completed,
    required this.enabled,
    required this.openPassage,
    required this.onComplete,
  });
  final GuidedJourneyDay day;
  final bool completed, enabled;
  final OpenJourneyPassage openPassage;
  final VoidCallback onComplete;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Opacity(
      opacity: enabled ? 1 : .55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DAY ${day.day}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (completed)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.gold,
                  semanticLabel: 'Completed',
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PassageLabel(passage: day.passage),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? () => openPassage(day.passage) : null,
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Read Passage'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: enabled && !completed ? onComplete : null,
                  icon: Icon(
                    completed
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(completed ? 'Complete' : 'Reflect'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.gold,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'David\n“${day.reflection}”',
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PassageLabel extends ConsumerWidget {
  const _PassageLabel({required this.passage});
  final PassageReference passage;
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => FutureBuilder<BibleBook?>(
    future: ref
        .read(bibleRepositoryProvider)
        .bookByOrder(
          ref.read(settingsProvider).defaultVersionId,
          passage.bookOrder,
        ),
    builder: (context, snapshot) {
      final suffix = passage.startVerse == null
          ? ''
          : ':${passage.startVerse}${passage.endVerse != null ? '–${passage.endVerse}' : ''}';
      return Text(
        '${snapshot.data?.name ?? 'Scripture'} ${passage.chapter}$suffix',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      );
    },
  );
}

class _MilestonePreview extends StatelessWidget {
  const _MilestonePreview({required this.milestones});
  final List<JourneyMilestone> milestones;
  @override
  Widget build(BuildContext context) {
    final visible = [...milestones]
      ..sort(
        (a, b) => a.isUnlocked == b.isUnlocked
            ? 0
            : a.isUnlocked
            ? -1
            : 1,
      );
    return Column(
      children: [
        for (final milestone in visible.take(4))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(child: Text(milestone.symbol)),
            title: Text(
              milestone.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              milestone.isUnlocked
                  ? 'Reached on ${_shortDate(milestone.unlockedAt!)}'
                  : milestone.description,
            ),
            trailing: Icon(
              milestone.isUnlocked
                  ? Icons.check_circle_rounded
                  : Icons.lock_outline_rounded,
              color: milestone.isUnlocked ? AppTheme.gold : null,
            ),
          ),
      ],
    );
  }
}

class JourneyStatisticsScreen extends StatelessWidget {
  const JourneyStatisticsScreen({
    super.key,
    required this.stats,
    required this.milestones,
  });
  final JourneyStats stats;
  final List<JourneyMilestone> milestones;
  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Current streak', '${stats.currentStreak} days'),
      ('Longest streak', '${stats.longestStreak} days'),
      ('Chapters read', '${stats.chaptersRead}'),
      ('Books explored', '${stats.booksExplored}'),
      ('Verses read', '${stats.versesRead}'),
      ('Reading days', '${stats.readingDays}'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const Text('A quiet record of time spent walking through Scripture.'),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    items[index].$2,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(items[index].$1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Milestones',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _MilestonePreview(milestones: milestones),
        ],
      ),
    );
  }
}

String _shortDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DailyLightScreen extends ConsumerWidget {
  const DailyLightScreen({super.key, required this.openPassage});
  final OpenJourneyPassage openPassage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.read(journeyRepositoryProvider);
    final light = journey.dailyLight(DateTime.now());
    final versionId = ref.watch(
      settingsProvider.select((value) => value.defaultVersionId),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Your Light for Today')),
      body: FutureBuilder<List<BibleVerse>>(
        future: journey.resolvePassage(light.passage, versionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _JourneyError(
              message: 'Today’s passage could not be opened.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final verses = snapshot.data!;
          if (verses.isEmpty) {
            return const _JourneyError(
              message: 'Today’s passage is unavailable in this Bible version.',
            );
          }
          final first = verses.first;
          final reference = verses.length == 1
              ? first.reference
              : '${first.bookName} ${first.chapter}:${first.number}–${verses.last.number}';
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.55, -.7),
                radius: 1.25,
                colors: [
                  AppTheme.gold.withValues(alpha: .18),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.light_mode_rounded,
                              color: AppTheme.gold,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'SCRIPTURE',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '“${verses.map((verse) => verse.text).join(' ')}”',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontFamily: 'serif', height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$reference · ${first.versionAbbreviation}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Divider(),
                        ),
                        const Text(
                          'REFLECTION',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          light.reflection,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => openPassage(light.passage),
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text('Read Passage'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'The reflection is a reading companion, not Scripture.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VerseConnectionsScreen extends ConsumerWidget {
  const VerseConnectionsScreen({
    super.key,
    required this.source,
    required this.openPassage,
  });
  final BibleVerse source;
  final OpenJourneyPassage openPassage;

  Future<List<_ResolvedConnection>> _load(WidgetRef ref) async {
    final journey = ref.read(journeyRepositoryProvider);
    final versionId = ref.read(settingsProvider).defaultVersionId;
    final definitions = await journey.connectionsFor(source);
    final resolved = <_ResolvedConnection>[];
    for (final definition in definitions) {
      final verses = await journey.resolvePassage(definition.target, versionId);
      if (verses.isNotEmpty) {
        resolved.add(_ResolvedConnection(definition, verses));
      }
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider.select((value) => value.defaultVersionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Verse Connections')),
      body: FutureBuilder<List<_ResolvedConnection>>(
        future: _load(ref),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _JourneyError(
              message: 'Verse connections could not be loaded.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final connections = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT PASSAGE',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      source.reference,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      source.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (connections.isEmpty)
                const _JourneyEmptyConnections()
              else ...[
                const Text(
                  'Curated Scripture connections',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                for (final connection in connections) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => openPassage(connection.definition.target),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.definition.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _connectionReference(connection.verses),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connection.verses
                              .map((verse) => verse.text)
                              .join(' '),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 12),
              const Text(
                'Connections are from a small bundled, curated dataset. No theological relationships are generated by AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResolvedConnection {
  const _ResolvedConnection(this.definition, this.verses);
  final VerseConnection definition;
  final List<BibleVerse> verses;
}

class _JourneyEmptyConnections extends StatelessWidget {
  const _JourneyEmptyConnections();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 50),
    child: Column(
      children: [
        Icon(Icons.hub_outlined, size: 54, color: AppTheme.gold),
        SizedBox(height: 12),
        Text(
          'NO CURATED CONNECTIONS YET',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'The data model is ready for more verified cross-references.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _connectionReference(List<BibleVerse> verses) => verses.length == 1
    ? verses.first.reference
    : '${verses.first.bookName} ${verses.first.chapter}:${verses.first.number}–${verses.last.number}';

class _JourneyError extends StatelessWidget {
  const _JourneyError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.light_mode_outlined, color: AppTheme.gold, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    ),
  );
}
