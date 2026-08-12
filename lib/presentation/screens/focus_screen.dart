import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

enum _FocusStage { read, reflect, respond, pray, complete }

class FocusVerseScreen extends ConsumerStatefulWidget {
  const FocusVerseScreen({super.key, required this.verse, this.onAskDavid});
  final BibleVerse verse;
  final VoidCallback? onAskDavid;

  @override
  ConsumerState<FocusVerseScreen> createState() => _FocusVerseScreenState();
}

class _FocusVerseScreenState extends ConsumerState<FocusVerseScreen> {
  _FocusStage _stage = _FocusStage.read;
  late BibleVerse _verse = widget.verse;
  final _reflection = TextEditingController();
  final _prayer = TextEditingController();
  int? _sessionId;
  bool _busy = false;
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  Future<void> _begin() async {
    try {
      final session = await ref
          .read(bibleRepositoryProvider)
          .startFocusSession(_verse.id);
      if (mounted) {
        setState(() => _sessionId = session.id);
      }
    } catch (_) {
      if (mounted) {
        _message(
          'Focus could not be saved right now. You can still reflect privately.',
        );
      }
    }
  }

  @override
  void dispose() {
    _reflection.dispose();
    _prayer.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _mark({
    bool? read,
    bool? reflection,
    bool? respond,
    bool? prayer,
    bool done = false,
  }) async {
    if (_sessionId != null) {
      await ref
          .read(bibleRepositoryProvider)
          .updateFocusSession(
            _sessionId!,
            read: read,
            reflection: reflection,
            respond: respond,
            prayer: prayer,
            completed: done,
          );
    }
  }

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (_stage) {
        case _FocusStage.read:
          await _mark(read: true);
          _stage = _FocusStage.reflect;
        case _FocusStage.reflect:
          if (_reflection.text.trim().isNotEmpty) {
            await ref
                .read(bibleRepositoryProvider)
                .saveNote(
                  _verse.id,
                  _reflection.text.trim(),
                  type: 'reflection',
                );
          }
          await _mark(reflection: _reflection.text.trim().isNotEmpty);
          _stage = _FocusStage.respond;
        case _FocusStage.respond:
          await _mark(respond: _responded);
          _stage = _FocusStage.pray;
        case _FocusStage.pray:
          if (_prayer.text.trim().isNotEmpty) {
            await ref
                .read(bibleRepositoryProvider)
                .savePrayer(_verse.id, _prayer.text.trim());
          }
          await _mark(prayer: _prayer.text.trim().isNotEmpty, done: true);
          _stage = _FocusStage.complete;
        case _FocusStage.complete:
          Navigator.pop(context);
      }
      if (mounted) setState(() {});
    } catch (_) {
      _message('Your entry could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(int direction) async {
    final verse = await ref
        .read(bibleRepositoryProvider)
        .adjacentVerse(_verse, direction);
    if (verse == null) {
      _message(
        direction < 0
            ? 'This is the first verse in the chapter.'
            : 'This is the last verse in the chapter.',
      );
      return;
    }
    setState(() {
      _verse = verse;
      _reflection.clear();
      _prayer.clear();
      _stage = _FocusStage.read;
      _responded = false;
      _sessionId = null;
    });
    await _begin();
  }

  Future<void> _respond(String action) async {
    final repo = ref.read(bibleRepositoryProvider);
    try {
      if (action == 'bookmark') {
        await repo.toggleBookmark(_verse.id);
      }
      if (action == 'highlight') {
        await repo.setHighlight(_verse.id, 'F6D365');
      }
      if (action == 'note') {
        await _openNote();
      }
      if (action == 'david') {
        widget.onAskDavid?.call();
      }
      if (mounted) {
        setState(() => _responded = true);
      }
      if (action != 'david') {
        _message('${action[0].toUpperCase()}${action.substring(1)} saved.');
      }
    } catch (_) {
      _message('That action could not be completed.');
    }
  }

  Future<void> _openNote() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Note on ${_verse.reference}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write a note…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(bibleRepositoryProvider)
                    .saveNote(_verse.id, controller.text.trim());
              }
              if (c.mounted) {
                Navigator.pop(c);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_stage) {
      _FocusStage.read => 'READ',
      _FocusStage.reflect => 'REFLECT',
      _FocusStage.respond => 'RESPOND',
      _FocusStage.pray => 'PRAY',
      _FocusStage.complete => 'FOCUS COMPLETE',
    };
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.1, -.8),
            radius: 1.25,
            colors: [
              AppTheme.gold.withValues(alpha: .18),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                  children: [
                    Text(
                      'FOCUS VERSE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _verse.reference,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    GlassCard(
                      child: Text(
                        '“${_verse.text}”',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: settings.fontSize + 5,
                          height: settings.lineHeight,
                          fontFamily: settings.serif ? 'serif' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${_verse.reference} · ${_verse.versionAbbreviation}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Divider(),
                    ),
                    _stageBody(),
                  ],
                ),
              ),
              if (_stage != _FocusStage.complete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _move(-1),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _move(1),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: FilledButton(
            onPressed: _busy ? null : _continue,
            child: Text(
              _stage == _FocusStage.complete
                  ? 'Done'
                  : _stage == _FocusStage.read
                  ? 'Begin Reflection'
                  : _stage == _FocusStage.reflect
                  ? 'Save Reflection'
                  : _stage == _FocusStage.respond
                  ? 'Continue to Prayer'
                  : 'Save Prayer',
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageBody() => switch (_stage) {
    _FocusStage.read => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'READ',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Take your time with this verse.',
          style: TextStyle(fontSize: 17, height: 1.45),
        ),
      ],
    ),
    _FocusStage.reflect => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is this verse saying to you?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _reflection,
          minLines: 5,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write your reflection…'),
        ),
      ],
    ),
    _FocusStage.respond => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you want to do with what you have read?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _action('bookmark', Icons.bookmark_add_outlined, 'Bookmark'),
            _action('highlight', Icons.highlight_outlined, 'Highlight'),
            _action('note', Icons.edit_note_outlined, 'Add Note'),
            _action('david', Icons.psychology_alt_outlined, 'Ask David'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'You can continue without choosing an action.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    ),
    _FocusStage.pray => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Turn what you have read into a prayer.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _prayer,
          minLines: 5,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write your prayer…'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your prayer stays private on this device.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    ),
    _FocusStage.complete => Column(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: AppTheme.gold, size: 48),
        const SizedBox(height: 12),
        Text(
          'Take this Word with you.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _reflection.text.trim().isEmpty
              ? 'Your quiet time is complete.'
              : 'Your reflection has been saved.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  };

  Widget _action(String value, IconData icon, String label) =>
      OutlinedButton.icon(
        onPressed: () => _respond(value),
        icon: Icon(icon),
        label: Text(label),
      );
}

class FocusHistoryScreen extends ConsumerWidget {
  const FocusHistoryScreen({super.key, required this.prayers});
  final bool prayers;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(prayers ? 'My Prayers' : 'My Reflections')),
    body: FutureBuilder<List<FocusEntry>>(
      future: ref
          .read(bibleRepositoryProvider)
          .focusEntries(prayers ? 'prayers' : 'notes'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Your saved entries could not be opened.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    prayers
                        ? Icons.volunteer_activism_outlined
                        : Icons.edit_note_outlined,
                    size: 58,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prayers ? 'NO SAVED PRAYERS YET' : 'NO REFLECTIONS YET',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prayers
                        ? 'Turn what you read into prayer.'
                        : 'Slow down.\nRead a verse.\nLet the Word speak.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.verse.reference,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(entry.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.45),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
