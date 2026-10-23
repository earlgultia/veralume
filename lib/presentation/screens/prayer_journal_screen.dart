import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/prayer_journal_entry.dart';
import '../../data/repositories/prayer_journal_repository.dart';
import '../widgets/glass_card.dart';

class PrayerJournalScreen extends StatefulWidget {
  const PrayerJournalScreen({super.key});

  @override
  State<PrayerJournalScreen> createState() => _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends State<PrayerJournalScreen> {
  final _repository = PrayerJournalRepository();
  late Future<List<PrayerJournalEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _repository.entries();
  }

  void _refresh() {
    setState(() => _entries = _repository.entries());
  }

  Future<void> _edit([PrayerJournalEntry? entry]) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _PrayerEditorDialog(repository: _repository, entry: entry),
    );
    if (updated == true && mounted) _refresh();
  }

  Future<void> _delete(PrayerJournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this prayer?'),
        content: const Text('This prayer will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(entry.id);
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) _showMessage('Could not delete this prayer: $error');
    }
  }

  Future<void> _setAnswered(PrayerJournalEntry entry, bool answered) async {
    try {
      await _repository.setAnswered(entry.id, answered);
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) _showMessage('Could not update this prayer: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prayer Journal'),
      actions: [
        IconButton(
          tooltip: 'Write a prayer',
          onPressed: _edit,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      icon: const Icon(Icons.edit_rounded),
      label: const Text('Write a prayer'),
    ),
    body: FutureBuilder<List<PrayerJournalEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Your prayer journal could not be loaded: ${snapshot.error}',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.volunteer_activism_rounded,
                    size: 48,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A quiet place for your prayers',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Write what is on your heart. Your journal stays on this device.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Write your first prayer'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            Text(
              'YOUR PRAYERS · STORED ON THIS DEVICE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            for (final entry in entries) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Prayer actions',
                          onSelected: (action) {
                            if (action == 'edit') _edit(entry);
                            if (action == 'delete') _delete(entry);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      _dateLabel(entry.createdAt),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(entry.content, style: const TextStyle(height: 1.55)),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        entry.answered ? 'Answered' : 'Mark as answered',
                      ),
                      subtitle: entry.answeredAt == null
                          ? null
                          : Text('Marked ${_dateLabel(entry.answeredAt!)}'),
                      value: entry.answered,
                      onChanged: (value) => _setAnswered(entry, value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    ),
  );

  String _dateLabel(DateTime date) =>
      '${date.toLocal().year}-${date.toLocal().month.toString().padLeft(2, '0')}-${date.toLocal().day.toString().padLeft(2, '0')}';
}

class _PrayerEditorDialog extends StatefulWidget {
  const _PrayerEditorDialog({required this.repository, this.entry});

  final PrayerJournalRepository repository;
  final PrayerJournalEntry? entry;

  @override
  State<_PrayerEditorDialog> createState() => _PrayerEditorDialogState();
}

class _PrayerEditorDialogState extends State<_PrayerEditorDialog> {
  late final _title = TextEditingController(text: widget.entry?.title ?? '');
  late final _content = TextEditingController(
    text: widget.entry?.content ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        title: _title.text,
        content: _content.text,
        id: widget.entry?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ArgumentError
              ? error.message.toString()
              : 'Could not save this prayer: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.entry == null ? 'Write a prayer' : 'Edit prayer'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            minLines: 5,
            maxLines: 9,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Your prayer',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save prayer'),
      ),
    ],
  );
}
