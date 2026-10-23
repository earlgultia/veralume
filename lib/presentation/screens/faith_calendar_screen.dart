import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/faith_calendar_event.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class FaithCalendarScreen extends ConsumerStatefulWidget {
  const FaithCalendarScreen({super.key});

  @override
  ConsumerState<FaithCalendarScreen> createState() =>
      _FaithCalendarScreenState();
}

class _FaithCalendarScreenState extends ConsumerState<FaithCalendarScreen> {
  DateTime _selectedDay = DateTime.now();

  Future<void> _editEvent([FaithCalendarEvent? existing]) async {
    final event = await showModalBottomSheet<FaithCalendarEvent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FaithEventEditor(existing: existing),
    );
    if (event == null || !mounted) return;
    try {
      await ref.read(faithCalendarRepositoryProvider).save(event);
      if (mounted) setState(() => _selectedDay = event.startsAt);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save event: $error')));
      }
    }
  }

  Future<void> _delete(FaithCalendarEvent event) async {
    try {
      await ref.read(faithCalendarRepositoryProvider).delete(event.id);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete event: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Faith Calendar'),
      actions: [
        IconButton(
          tooltip: 'Add calendar event',
          onPressed: () => _editEvent(),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editEvent(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Plan time with God'),
    ),
    body: FutureBuilder<List<FaithCalendarEvent>>(
      future: ref.read(faithCalendarRepositoryProvider).events(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your calendar: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data!;
        final selectedEvents = events
            .where((event) => event.occursOn(_selectedDay))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          children: [
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        onPressed: () => setState(
                          () => _selectedDay = DateTime(
                            _selectedDay.year,
                            _selectedDay.month - 1,
                            1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthName(_selectedDay),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        onPressed: () => setState(
                          () => _selectedDay = DateTime(
                            _selectedDay.year,
                            _selectedDay.month + 1,
                            1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final day in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                        Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _CalendarGrid(
                    selectedDay: _selectedDay,
                    events: events,
                    onSelect: (day) => setState(() => _selectedDay = day),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _dayLabel(_selectedDay),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (selectedEvents.isEmpty)
              GlassCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text('A little room for a new rhythm'),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a devotional, prayer, Bible study, church service, or personal faith event.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (final event in selectedEvents) ...[
                _EventCard(
                  event: event,
                  onEdit: () => _editEvent(event),
                  onDelete: () => _delete(event),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
            const Text(
              'Your schedule is stored locally on this device.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    ),
  );

  String _monthName(DateTime date) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  String _dayLabel(DateTime date) =>
      '${_monthName(date)} ${date.day} · Your plan';
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.selectedDay,
    required this.events,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final List<FaithCalendarEvent> events;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final leading = firstOfMonth.weekday - 1;
    final days = DateTime(selectedDay.year, selectedDay.month + 1, 0).day;
    final rows = (leading + days + 6) ~/ 7;
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _dayCell(
                    context,
                    row * 7 + column - leading + 1,
                    days,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, int day, int totalDays) {
    if (day < 1 || day > totalDays) return const SizedBox(height: 44);
    final date = DateTime(selectedDay.year, selectedDay.month, day);
    final selected =
        date.year == selectedDay.year &&
        date.month == selectedDay.month &&
        date.day == selectedDay.day;
    final hasEvent = events.any((event) => event.occursOn(date));
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onSelect(date),
        child: SizedBox(
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: hasEvent ? AppTheme.gold : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final FaithCalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_icon(event.category), color: AppTheme.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${_timeLabel(event.startsAt)} · ${_categoryLabel(event.category)} · ${_repeatLabel(event.repeat)}',
              ),
              if (event.notes.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(event.notes),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit ${event.title}',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete ${event.title}',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    ),
  );

  IconData _icon(FaithCalendarCategory category) => switch (category) {
    FaithCalendarCategory.devotional => Icons.wb_sunny_outlined,
    FaithCalendarCategory.prayer => Icons.volunteer_activism_outlined,
    FaithCalendarCategory.bibleStudy => Icons.menu_book_outlined,
    FaithCalendarCategory.church => Icons.church_outlined,
    FaithCalendarCategory.personal => Icons.event_note_outlined,
  };

  String _categoryLabel(FaithCalendarCategory category) => switch (category) {
    FaithCalendarCategory.devotional => 'Devotional',
    FaithCalendarCategory.prayer => 'Prayer',
    FaithCalendarCategory.bibleStudy => 'Bible study',
    FaithCalendarCategory.church => 'Church',
    FaithCalendarCategory.personal => 'Personal',
  };

  String _repeatLabel(FaithCalendarRepeat repeat) => switch (repeat) {
    FaithCalendarRepeat.once => 'Once',
    FaithCalendarRepeat.daily => 'Daily',
    FaithCalendarRepeat.weekly => 'Weekly',
  };

  String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _FaithEventEditor extends StatefulWidget {
  const _FaithEventEditor({this.existing});

  final FaithCalendarEvent? existing;

  @override
  State<_FaithEventEditor> createState() => _FaithEventEditorState();
}

class _FaithEventEditorState extends State<_FaithEventEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _startsAt =
      widget.existing?.startsAt ?? DateTime.now().add(const Duration(hours: 1));
  late FaithCalendarCategory _category =
      widget.existing?.category ?? FaithCalendarCategory.devotional;
  late FaithCalendarRepeat _repeat =
      widget.existing?.repeat ?? FaithCalendarRepeat.once;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.existing?.title ?? '';
    _notesController.text = widget.existing?.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    setState(
      () => _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startsAt.hour,
        _startsAt.minute,
      ),
    );
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(
      () => _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      22,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            widget.existing == null ? 'Plan time with God' : 'Edit your plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _titleController,
            autofocus: true,
            maxLength: 70,
            decoration: const InputDecoration(
              labelText: 'What would you like to plan?',
              hintText: 'Morning devotional',
              prefixIcon: Icon(Icons.edit_calendar_rounded),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Add a title' : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FaithCalendarCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final category in FaithCalendarCategory.values)
                DropdownMenuItem(
                  value: category,
                  child: Text(_categoryName(category)),
                ),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FaithCalendarRepeat>(
            initialValue: _repeat,
            decoration: const InputDecoration(labelText: 'Repeat'),
            items: [
              for (final repeat in FaithCalendarRepeat.values)
                DropdownMenuItem(
                  value: repeat,
                  child: Text(_repeatName(repeat)),
                ),
            ],
            onChanged: (value) => setState(() => _repeat = value ?? _repeat),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    '${_startsAt.month}/${_startsAt.day}/${_startsAt.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    '${TimeOfDay.fromDateTime(_startsAt).format(context)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                FaithCalendarEvent(
                  id:
                      widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  title: _titleController.text.trim(),
                  startsAt: _startsAt,
                  category: _category,
                  repeat: _repeat,
                  notes: _notesController.text.trim(),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save to calendar'),
          ),
        ],
      ),
    ),
  );

  String _categoryName(FaithCalendarCategory category) => switch (category) {
    FaithCalendarCategory.devotional => 'Devotional',
    FaithCalendarCategory.prayer => 'Prayer time',
    FaithCalendarCategory.bibleStudy => 'Bible study',
    FaithCalendarCategory.church => 'Church / fellowship',
    FaithCalendarCategory.personal => 'Personal faith event',
  };

  String _repeatName(FaithCalendarRepeat repeat) => switch (repeat) {
    FaithCalendarRepeat.once => 'Once',
    FaithCalendarRepeat.daily => 'Every day',
    FaithCalendarRepeat.weekly => 'Every week',
  };
}
