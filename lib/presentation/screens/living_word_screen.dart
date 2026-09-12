import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../data/models/living_word_models.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'focus_screen.dart';
import 'memory_verses_screen.dart';
import 'verse_lens_screen.dart';

class LivingWordScreen extends ConsumerStatefulWidget {
  const LivingWordScreen({super.key, required this.session, required this.openVerse, required this.askDavid});
  final LivingWordSession session;
  final Future<void> Function(BibleVerse verse) openVerse;
  final void Function(BibleVerse verse) askDavid;
  @override
  ConsumerState<LivingWordScreen> createState() => _LivingWordScreenState();
}

class _LivingWordScreenState extends ConsumerState<LivingWordScreen> {
  late LivingWordSession session = widget.session;
  late int stage = session.currentStage;
  late List<bool> stages = List.of(session.stages);
  final reflection = TextEditingController();
  final application = TextEditingController();
  final prayer = TextEditingController();
  int? reflectionId, prayerId, applicationId;
  bool busy = false;
  static const labels = ['READ', 'UNDERSTAND', 'REFLECT', 'REMEMBER', 'APPLY', 'PRAY'];
  @override void initState() { super.initState(); _loadEntries(); }
  Future<void> _loadEntries() async {
    final repo = ref.read(bibleRepositoryProvider);
    final values = await Future.wait([repo.reflectionForVerse(session.verse.id), repo.prayerForVerse(session.verse.id), repo.applicationForSession(session.id)]);
    if (!mounted) return;
    final r = values[0] as FocusEntry?; final p = values[1] as FocusEntry?; final a = values[2] as ApplicationEntry?;
    setState(() { reflection.text = r?.content ?? ''; reflectionId = r?.id; prayer.text = p?.content ?? ''; prayerId = p?.id; application.text = a?.content ?? ''; applicationId = a?.id; if (r != null) stages[2] = true; if (a != null) stages[4] = true; if (p != null) stages[5] = true; });
  }
  @override void dispose() { reflection.dispose(); application.dispose(); prayer.dispose(); super.dispose(); }
  Future<void> _advance({bool skipped = false}) async {
    if (busy) return; setState(() => busy = true);
    try {
      final repo = ref.read(bibleRepositoryProvider);
      if (!skipped && stage == 2 && reflection.text.trim().isNotEmpty) { await repo.saveNote(session.verse.id, reflection.text.trim(), id: reflectionId, type: 'reflection'); stages[2] = true; }
      if (!skipped && stage == 4 && application.text.trim().isNotEmpty) { await repo.saveApplication(session.id, session.verse.id, application.text.trim(), id: applicationId); stages[4] = true; }
      if (!skipped && stage == 5 && prayer.text.trim().isNotEmpty) { await repo.savePrayer(session.verse.id, prayer.text.trim(), id: prayerId); stages[5] = true; }
      if (stage == 0 || stage == 1 || stage == 3) stages[stage] = !skipped;
      final next = stage + 1;
      await repo.updateLivingWord(session.id, stage: next, stages: stages, complete: next >= 6);
      if (mounted) setState(() { stage = next; });
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your Living Word progress could not be saved.'))); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> _lens() async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => VerseLensScreen(verse: session.verse, openPassage: (_) => widget.openVerse(session.verse), askDavid: widget.askDavid))); if (mounted) setState(() => stages[1] = true); }
  Future<void> _focus() async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FocusVerseScreen(verse: session.verse, onAskDavid: () => widget.askDavid(session.verse)))); await _loadEntries(); if (mounted) setState(() { if (reflection.text.trim().isNotEmpty) stages[2] = true; if (prayer.text.trim().isNotEmpty) stages[5] = true; }); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LIVING WORD'), centerTitle: true),
    body: SafeArea(top: false, child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
      Text('${stage >= 6 ? 'LIVING WORD COMPLETE' : labels[stage]}  ·  ${stage >= 6 ? 6 : stage + 1}/6', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 12), LinearProgressIndicator(value: (stage.clamp(0, 6)) / 6), const SizedBox(height: 24),
      Text(session.verse.reference, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(session.verse.versionAbbreviation, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gold)), const SizedBox(height: 16),
      GlassCard(child: Text('“${session.verse.text}”', textAlign: TextAlign.center, style: TextStyle(fontSize: ref.watch(settingsProvider).fontSize + 3, height: ref.watch(settingsProvider).lineHeight, fontFamily: ref.watch(settingsProvider).serif ? 'serif' : null))), const SizedBox(height: 24),
      if (stage >= 6) _complete() else _body(),
    ])),
    bottomNavigationBar: stage >= 6 ? null : SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Row(children: [Expanded(child: OutlinedButton(onPressed: busy ? null : () => _advance(skipped: true), child: const Text('Skip'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: busy ? null : _advance, child: Text(stage == 5 ? 'Complete' : 'Continue')))]))),
  );
  Widget _body() => switch (stage) {
    0 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Take a moment to read the passage slowly.', style: TextStyle(fontSize: 18, height: 1.45)), const SizedBox(height: 14), OutlinedButton.icon(onPressed: () => widget.openVerse(session.verse), icon: const Icon(Icons.auto_stories_outlined), label: const Text('Open in Bible Reader'))]),
    1 => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('What is happening around this verse?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 10), const Text('Explore context, connections, key words, and Scripture with Verse Lens.'), const SizedBox(height: 14), FilledButton.tonalIcon(onPressed: _lens, icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Explore Verse Lens')), TextButton.icon(onPressed: () => widget.askDavid(session.verse), icon: const Icon(Icons.psychology_alt_outlined), label: const Text('Ask David'))])),
    2 => _entry('What is this Scripture saying to you?', reflection, 'Write your reflection…', _focus, 'Open Focus'),
    3 => FutureBuilder<bool>(future: ref.read(bibleRepositoryProvider).isMemoryVerse(session.verse.id), builder: (context, s) => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Carry this Scripture with you.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 14), FilledButton.tonalIcon(onPressed: () async { final repo = ref.read(bibleRepositoryProvider); if (s.data == true) { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryVersesScreen(openVerse: widget.openVerse))); } else { await repo.saveMemoryVerse(session.verse.id); if (mounted) setState(() => stages[3] = true); } }, icon: Icon(s.data == true ? Icons.psychology_alt : Icons.add), label: Text(s.data == true ? 'Practice Verse' : 'Add to Memory'))]))),
    4 => _entry('How can you live this Scripture today?', application, 'What will you do differently today?', null, null),
    _ => _entry('Turn what you’ve read into prayer.', prayer, 'Write your prayer…', _focus, 'Open Focus'),
  };
  Widget _entry(String prompt, TextEditingController controller, String hint, Future<void> Function()? action, String? actionLabel) => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 14), TextField(controller: controller, minLines: 5, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: hint)), if (action != null) ...[const SizedBox(height: 10), TextButton.icon(onPressed: action, icon: const Icon(Icons.auto_awesome_outlined), label: Text(actionLabel!))]]));
  Widget _complete() => Column(children: [const Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 54), const SizedBox(height: 12), const Text('Take the Word with you.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 18), for (var i = 0; i < labels.length; i++) ListTile(leading: Icon(stages[i] ? Icons.check_circle : Icons.circle_outlined, color: stages[i] ? AppTheme.gold : null), title: Text(labels[i])), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))]);
}

class LivingWordHistoryScreen extends ConsumerWidget {
  const LivingWordHistoryScreen({super.key, required this.open}); final Future<void> Function(LivingWordSession) open;
  @override Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('My Living Word')), body: FutureBuilder<List<LivingWordSession>>(future: ref.read(bibleRepositoryProvider).livingWordHistory(), builder: (context, s) { if (!s.hasData) return const Center(child: CircularProgressIndicator()); if (s.data!.isEmpty) return const Center(child: Text('Your Living Word moments will appear here.')); return ListView.separated(padding: const EdgeInsets.all(18), itemCount: s.data!.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) { final item = s.data![i]; return GlassCard(onTap: () => open(item), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.verse.reference, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.gold)), const SizedBox(height: 6), Text(item.localDate), const SizedBox(height: 8), Text(item.stages.asMap().entries.where((e) => e.value).map((e) => LivingWordScreenLabels.labels[e.key]).join('  ·  '))])); }); }));
}
class LivingWordScreenLabels { static const labels = ['Read', 'Understand', 'Reflect', 'Remember', 'Apply', 'Pray']; }
