import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../data/models/journey_models.dart';
import '../../data/repositories/bible_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'focus_screen.dart';
import 'journey_screens.dart';

typedef OpenLensPassage = Future<void> Function(PassageReference passage);
typedef AskDavidForVerse = void Function(BibleVerse verse);

class VerseLensScreen extends ConsumerStatefulWidget {
  const VerseLensScreen({
    super.key,
    required this.verse,
    required this.openPassage,
    required this.askDavid,
  });
  final BibleVerse verse;
  final OpenLensPassage openPassage;
  final AskDavidForVerse askDavid;

  @override
  ConsumerState<VerseLensScreen> createState() => _VerseLensScreenState();
}

class _VerseLensScreenState extends ConsumerState<VerseLensScreen> {
  late BibleVerse _selected = widget.verse;
  int _contextCount = 5;
  int _refresh = 0;

  Future<void> _focus() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusVerseScreen(
          verse: _selected,
          onAskDavid: () => widget.askDavid(_selected),
        ),
      ),
    );
    if (mounted) setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final bible = ref.read(bibleRepositoryProvider);
    final journey = ref.read(journeyRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verse Lens')),
      body: FutureBuilder(
        key: ValueKey('${_selected.id}:$_contextCount:$_refresh'),
        future: Future.wait<Object?>([
          bible.contextFor(_selected, _contextCount),
          journey.connectionsFor(_selected),
          bible.reflectionForVerse(_selected.id),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Verse Lens could not be loaded.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final values = snapshot.data!;
          final verses = values[0]! as List<BibleVerse>;
          final connections = values[1]! as List<VerseConnection>;
          final reflection = values[2] as FocusEntry?;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              Text(
                _selected.reference,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selected.versionAbbreviation,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTEXT',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_contextCount verses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _contextCount.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_contextCount verses',
                      onChanged: (value) =>
                          setState(() => _contextCount = value.round()),
                    ),
                    const Text(
                      'Expand the surrounding passage. Context stays within this chapter.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _LensHeading('BEFORE & AFTER'),
              const SizedBox(height: 8),
              for (final verse in verses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LensVerseCard(
                    verse: verse,
                    selected: verse.id == _selected.id,
                    onTap: () => setState(() {
                      _selected = verse;
                      _refresh++;
                    }),
                  ),
                ),
              const SizedBox(height: 12),
              const _LensHeading('CONNECTIONS'),
              const SizedBox(height: 8),
              if (connections.isEmpty)
                const _LensEmpty(
                  'No connections available yet.',
                  'This verse doesn’t have connected passages available yet.',
                )
              else
                GlassCard(
                  child: Column(
                    children: [
                      for (final connection in connections)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.hub_rounded,
                            color: AppTheme.gold,
                          ),
                          title: _ConnectionTitle(passage: connection.target),
                          subtitle: Text(connection.type),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.openPassage(connection.target),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VerseConnectionsScreen(
                                source: _selected,
                                openPassage: widget.openPassage,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View all'),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              const _LensHeading('KEY WORDS'),
              const SizedBox(height: 8),
              _KeyWords(verse: _selected),
              const SizedBox(height: 18),
              const _LensHeading('MY REFLECTION'),
              const SizedBox(height: 8),
              GlassCard(
                child: reflection == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No reflection yet',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Take a moment to reflect on this passage.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: _focus,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Focus on This Verse'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ Reflection saved',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            reflection.content,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reflection.updatedAt
                                    ?.toLocal()
                                    .toString()
                                    .split(' ')
                                    .first ??
                                '',
                            style: const TextStyle(color: AppTheme.gold),
                          ),
                          TextButton(
                            onPressed: _focus,
                            child: const Text('View reflection in Focus'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              const _LensHeading('ASK DAVID'),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Have a conversation about this verse.'),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => widget.askDavid(_selected),
                      icon: const Icon(Icons.psychology_alt_outlined),
                      label: const Text('Ask David'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share verse'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _share(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text:
            '${_selected.reference}\n${_selected.text}\n${_selected.versionAbbreviation}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class QuickContextSheet extends ConsumerWidget {
  const QuickContextSheet({
    super.key,
    required this.verse,
    required this.onOpenLens,
  });
  final BibleVerse verse;
  final VoidCallback onOpenLens;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: FutureBuilder<List<BibleVerse>>(
      future: ref.read(bibleRepositoryProvider).contextFor(verse, 5),
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: snapshot.hasData
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Context · ${verse.reference}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final item in snapshot.data!)
                    _LensVerseCard(verse: item, selected: item.id == verse.id),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onOpenLens,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Open Verse Lens'),
                    ),
                  ),
                ],
              )
            : const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
      ),
    ),
  );
}

class GiveMeAVerseScreen extends ConsumerStatefulWidget {
  const GiveMeAVerseScreen({
    super.key,
    required this.openVerse,
    required this.askDavid,
  });
  final Future<void> Function(BibleVerse verse) openVerse;
  final AskDavidForVerse askDavid;
  @override
  ConsumerState<GiveMeAVerseScreen> createState() => _GiveMeAVerseScreenState();
}

class _GiveMeAVerseScreenState extends ConsumerState<GiveMeAVerseScreen> {
  _VersePrompt? _choice;
  @override
  Widget build(BuildContext context) {
    final version = ref.watch(
      settingsProvider.select((s) => s.defaultVersionId),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Give Me a Verse')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            _choice == null ? 'I need…' : 'A Verse for You',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _choice == null
                ? 'Choose what you are experiencing.'
                : _choice!.label,
          ),
          const SizedBox(height: 18),
          if (_choice == null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final prompt in _prompts)
                  ActionChip(
                    avatar: Icon(prompt.icon),
                    label: Text(prompt.label),
                    onPressed: () => setState(() => _choice = prompt),
                  ),
              ],
            )
          else
            FutureBuilder<BibleVerse?>(
              future: _choice!.verseFor(
                ref.read(bibleRepositoryProvider),
                version,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final verse = snapshot.data;
                if (verse == null) {
                  return const _LensEmpty(
                    'Verse unavailable',
                    'This translation does not include the selected verse.',
                  );
                }
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.reference,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '“${verse.text}”',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontFamily: 'serif', height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.versionAbbreviation,
                        style: const TextStyle(color: AppTheme.gold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => widget.openVerse(verse),
                            icon: const Icon(Icons.auto_stories_rounded),
                            label: const Text('Read Passage'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FocusVerseScreen(
                                  verse: verse,
                                  onAskDavid: () => widget.askDavid(verse),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Focus'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(bibleRepositoryProvider)
                                  .toggleBookmark(verse.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bookmark updated.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Save'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => widget.askDavid(verse),
                            icon: const Icon(Icons.psychology_alt_outlined),
                            label: const Text('Ask David'),
                          ),
                        ],
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
}

class _VersePrompt {
  const _VersePrompt(this.label, this.icon, this.references);
  final String label;
  final IconData icon;
  final List<(int, int, int)> references;
  Future<BibleVerse?> verseFor(BibleRepository repo, int versionId) {
    final date = DateTime.now();
    final reference =
        references[(date.year * 372 + date.month * 31 + date.day) %
            references.length];
    return repo.verseAt(
      versionId: versionId,
      bookOrder: reference.$1,
      chapter: reference.$2,
      number: reference.$3,
    );
  }
}

const _prompts = <_VersePrompt>[
  _VersePrompt('Hope', Icons.favorite_outline, [(19, 46, 1), (45, 15, 13)]),
  _VersePrompt('Peace', Icons.spa_outlined, [(50, 14, 27), (50, 16, 33)]),
  _VersePrompt('Strength', Icons.fitness_center_outlined, [
    (19, 46, 1),
    (23, 41, 10),
  ]),
  _VersePrompt('Prayer', Icons.volunteer_activism_outlined, [
    (50, 5, 14),
    (59, 5, 16),
  ]),
  _VersePrompt('Rest', Icons.nights_stay_outlined, [(40, 11, 28), (19, 62, 1)]),
  _VersePrompt('Courage', Icons.local_fire_department_outlined, [
    (6, 1, 9),
    (23, 41, 10),
  ]),
  _VersePrompt('Wisdom', Icons.lightbulb_outline, [(20, 3, 5), (59, 1, 5)]),
  _VersePrompt('Encouragement', Icons.wb_sunny_outlined, [
    (52, 4, 16),
    (45, 15, 13),
  ]),
  _VersePrompt('Gratitude', Icons.celebration_outlined, [
    (52, 5, 18),
    (19, 107, 1),
  ]),
  _VersePrompt('A fresh start', Icons.sunny, [(47, 3, 23), (23, 43, 19)]),
];

class _LensHeading extends StatelessWidget {
  const _LensHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.gold,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class _LensVerseCard extends StatelessWidget {
  const _LensVerseCard({
    required this.verse,
    this.selected = false,
    this.onTap,
  });
  final BibleVerse verse;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    selected: selected,
    label: '${selected ? 'Selected ' : ''}${verse.reference}',
    child: Material(
      color: selected
          ? AppTheme.gold.withValues(alpha: .18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse.reference,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.gold : null,
                ),
              ),
              const SizedBox(height: 5),
              Text(verse.text, style: const TextStyle(height: 1.45)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LensEmpty extends StatelessWidget {
  const _LensEmpty(this.title, this.message);
  final String title, message;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(message),
      ],
    ),
  );
}

class _ConnectionTitle extends ConsumerWidget {
  const _ConnectionTitle({required this.passage});
  final PassageReference passage;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .bookByOrder(
          ref.read(settingsProvider).defaultVersionId,
          passage.bookOrder,
        ),
    builder: (_, s) => Text(
      '${s.data?.name ?? 'Scripture'} ${passage.chapter}${passage.startVerse == null ? '' : ':${passage.startVerse}${passage.endVerse == null ? '' : '–${passage.endVerse}'}'}',
    ),
  );
}

class _KeyWords extends StatelessWidget {
  const _KeyWords({required this.verse});
  final BibleVerse verse;
  @override
  Widget build(BuildContext context) {
    final words = verse.text
        .split(RegExp(r'[^A-Za-zÀ-ÿ]+'))
        .where((word) => word.length >= 5)
        .map((word) => word.toUpperCase())
        .toSet()
        .take(4)
        .toList();
    return GlassCard(
      child: words.isEmpty
          ? const Text(
              'Key word information isn’t available for this passage yet.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final word in words)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      word,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                const Text(
                  'Important words from this verse. Definitions are not available offline yet.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
    );
  }
}
