import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../domain/assistant/david_assistant.dart';
import '../../domain/memory/verse_memory.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'focus_screen.dart';
import 'verse_lens_screen.dart';

typedef OpenMemoryVerse = Future<void> Function(BibleVerse verse);

class MemoryVersesScreen extends ConsumerStatefulWidget {
  const MemoryVersesScreen({super.key, required this.openVerse});
  final OpenMemoryVerse openVerse;
  @override
  ConsumerState<MemoryVersesScreen> createState() => _MemoryVersesScreenState();
}

class _MemoryVersesScreenState extends ConsumerState<MemoryVersesScreen> {
  int refresh = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Memory Verses')),
    body: FutureBuilder<List<MemoryVerse>>(
      key: ValueKey(refresh), future: ref.read(bibleRepositoryProvider).memoryVerses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final verses = snapshot.data!;
        if (verses.isEmpty) return _MemoryEmpty(openVerse: widget.openVerse);
        final mastered = verses.where((v) => v.status == MemoryStatus.mastered).length;
        final practicing = verses.where((v) => v.status == MemoryStatus.practicing || v.status == MemoryStatus.remembered).length;
        return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 32), children: [
          Text('Carry the Word with you.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          GlassCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Stat('${verses.length}', 'Saved'), _Stat('$mastered', 'Mastered'), _Stat('$practicing', 'Practicing'),
          ])),
          const SizedBox(height: 22),
          Text('REVIEW TODAY', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.gold, letterSpacing: 1.3)),
          const SizedBox(height: 6),
          Text('${verses.length} ${verses.length == 1 ? 'verse is' : 'verses are'} ready whenever you are.'),
          const SizedBox(height: 14),
          for (final memory in verses) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(onTap: () => _open(memory), child: _MemoryTile(memory: memory))),
        ]);
      },
    ),
  );
  Future<void> _open(MemoryVerse memory) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryVerseDetail(memory: memory, openVerse: widget.openVerse)));
    if (mounted) setState(() => refresh++);
  }
}

class _Stat extends StatelessWidget { const _Stat(this.value, this.label); final String value, label; @override Widget build(BuildContext c) => Column(children:[Text(value, style:Theme.of(c).textTheme.headlineSmall?.copyWith(color:AppTheme.gold)), Text(label)]); }
class _MemoryTile extends StatelessWidget { const _MemoryTile({required this.memory}); final MemoryVerse memory; @override Widget build(BuildContext c) => Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(memory.verse.reference, style:Theme.of(c).textTheme.titleMedium), const SizedBox(height:3), Text(memory.verse.versionAbbreviation, style:const TextStyle(color:AppTheme.gold,fontWeight:FontWeight.bold)), const SizedBox(height:8), Text('“${memory.verse.text}”', maxLines:2, overflow:TextOverflow.ellipsis), const SizedBox(height:12), LinearProgressIndicator(value:memory.progress), const SizedBox(height:6), Text(memory.status.label)]); }
class _MemoryEmpty extends StatelessWidget { const _MemoryEmpty({required this.openVerse}); final OpenMemoryVerse openVerse; @override Widget build(BuildContext c) => Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.psychology_alt_outlined,size:64,color:AppTheme.gold),const SizedBox(height:16),Text('Carry the Word with you.',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),const Text('Save a verse you want to remember and practice it anytime.',textAlign:TextAlign.center),const SizedBox(height:18),FilledButton.icon(onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.auto_stories),label:const Text('Open Bible'))]))); }

class MemoryVerseDetail extends ConsumerStatefulWidget { const MemoryVerseDetail({super.key,required this.memory,required this.openVerse}); final MemoryVerse memory; final OpenMemoryVerse openVerse; @override ConsumerState<MemoryVerseDetail> createState()=>_MemoryVerseDetailState(); }
class _MemoryVerseDetailState extends ConsumerState<MemoryVerseDetail> {
  bool practicing=false, revealed=false, checked=false; late ClozeExercise exercise=ClozeExercise(widget.memory.verse.text); late List<int> blanks=exercise.blanks(); late List<TextEditingController> answers=List.generate(blanks.length,(_)=>TextEditingController());
  @override void dispose(){for(final c in answers){c.dispose();}super.dispose();}
  Future<void> _check() async { final correct=[for(var i=0;i<blanks.length;i++) exercise.correct(answers[i].text,exercise.tokens[blanks[i]])]; final success=correct.isNotEmpty && correct.every((v)=>v); await ref.read(bibleRepositoryProvider).recordMemoryPractice(widget.memory.verse.id,successful:success); if(mounted)setState(()=>checked=true); }
  @override Widget build(BuildContext c) { final m=widget.memory; return Scaffold(appBar:AppBar(title:const Text('Verse Memory'),actions:[IconButton(tooltip:'Remove from Memory',icon:const Icon(Icons.delete_outline),onPressed:() async {final remove=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('Remove from Memory?'),content:const Text('Your bookmarks, highlights, notes, and reading history will remain.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Remove'))]));if(remove==true){await ref.read(bibleRepositoryProvider).removeMemoryVerse(m.verse.id);if(c.mounted)Navigator.pop(c);}})]),body:ListView(padding:const EdgeInsets.all(18),children:[Text(m.verse.reference,style:Theme.of(c).textTheme.headlineSmall),Text(m.verse.versionAbbreviation,style:const TextStyle(color:AppTheme.gold,fontWeight:FontWeight.bold)),const SizedBox(height:18),GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('STATUS',style:TextStyle(color:AppTheme.gold,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(m.status.label),const SizedBox(height:8),LinearProgressIndicator(value:m.progress)])),const SizedBox(height:16),if(!practicing)_actions(c) else _practice(c),]); }
  Widget _actions(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FilledButton.icon(onPressed:()=>setState(()=>practicing=true),icon:const Icon(Icons.psychology_alt_outlined),label:const Text('Practice')),OutlinedButton.icon(onPressed:()=>widget.openVerse(widget.memory.verse),icon:const Icon(Icons.menu_book),label:const Text('Read Full Passage')),OutlinedButton.icon(onPressed:()=>Navigator.of(c).push(MaterialPageRoute(builder:(_)=>FocusVerseScreen(verse:widget.memory.verse,onAskDavid:()=>_david()))),icon:const Icon(Icons.auto_awesome_outlined),label:const Text('Focus')),OutlinedButton.icon(onPressed:()=>Navigator.of(c).push(MaterialPageRoute(builder:(_)=>VerseLensScreen(verse:widget.memory.verse,openPassage:(_)=>widget.openVerse(widget.memory.verse),askDavid:(_)=>_david()))),icon:const Icon(Icons.visibility_outlined),label:const Text('Verse Lens')),TextButton.icon(onPressed:_david,icon:const Icon(Icons.psychology_alt_outlined),label:const Text('Ask David about this verse'))]);
  void _david()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>DavidScreen(initialQuestion:'Let’s talk about ${widget.memory.verse.reference}.\n\n${widget.memory.verse.text}')));
  Widget _practice(BuildContext c) { final theme=Theme.of(c).textTheme; if(revealed)return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('“${widget.memory.verse.text}”',style:theme.titleLarge?.copyWith(fontFamily:'serif',height:1.5)),const SizedBox(height:18),FilledButton(onPressed:()=>setState(()=>practicing=false),child:const Text('Done'))]); final spans=<InlineSpan>[];var cursor=0;for(var i=0;i<blanks.length;i++){final match=RegExp(r"[\p{L}\p{N}][\p{L}\p{N}'’-]*",unicode:true).allMatches(widget.memory.verse.text).elementAt(blanks[i]);spans.add(TextSpan(text:widget.memory.verse.text.substring(cursor,match.start)));spans.add(WidgetSpan(alignment:PlaceholderAlignment.middle,child:SizedBox(width:95,child:TextField(controller:answers[i],enabled:!checked,decoration:const InputDecoration(isDense:true,hintText:'_____')))));cursor=match.end;}spans.add(TextSpan(text:widget.memory.verse.text.substring(cursor))); final correct=checked?[for(var i=0;i<blanks.length;i++)exercise.correct(answers[i].text,exercise.tokens[blanks[i]])]:<bool>[];return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Can you remember this verse without looking?',style:theme.titleMedium),const SizedBox(height:18),GlassCard(child:Text.rich(TextSpan(style:theme.titleMedium?.copyWith(fontFamily:'serif',height:1.8),children:spans))),if(checked)...[const SizedBox(height:16),Text(correct.every((v)=>v)?'✓ Well remembered':'Good work. You remembered ${correct.where((v)=>v).length} of ${correct.length} missing words.',style:TextStyle(color:correct.every((v)=>v)?Colors.green:AppTheme.gold,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('“${widget.memory.verse.text}”')],const SizedBox(height:16),if(!checked)FilledButton(onPressed:_check,child:const Text('Check Answer')) else FilledButton(onPressed:(){setState((){checked=false;for(final a in answers){a.clear();}});},child:const Text('Practice Again')),TextButton(onPressed:()=>setState(()=>revealed=true),child:const Text('Reveal Verse'))]); }
}
