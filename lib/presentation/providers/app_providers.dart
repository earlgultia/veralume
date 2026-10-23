import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/faith_calendar_repository.dart';
import '../../core/theme/app_theme.dart';

final bibleRepositoryProvider = Provider((ref) => BibleRepository());
final journeyRepositoryProvider = Provider((ref) => JourneyRepository());
final faithCalendarRepositoryProvider = Provider(
  (ref) => FaithCalendarRepository(),
);

class ReadingSettings {
  const ReadingSettings({
    this.theme = VeralumeTheme.royalPurple,
    this.fontSize = 20,
    this.lineHeight = 1.7,
    this.serif = true,
    this.showVerseNumbers = true,
    this.readingWidth = 'normal',
    this.boldVerseNumbers = true,
    this.onboarded = false,
    this.fullScreen = false,
    this.quietReading = false,
    this.quietTone = 'cool',
    this.quietControls = 'tap',
    this.keepScreenAwake = false,
    this.rememberLastLight = true,
    this.dailyWordReminder = false,
    this.samSamEnabled = true,
    this.samSamScale = .4,
    this.defaultVersionId = 1,
    this.loaded = false,
  });
  final VeralumeTheme theme;
  final double fontSize, lineHeight;
  final bool serif,
      showVerseNumbers,
      boldVerseNumbers,
      onboarded,
      fullScreen,
      quietReading,
      keepScreenAwake,
      rememberLastLight,
      dailyWordReminder,
      samSamEnabled,
      loaded;
  final double samSamScale;
  final String readingWidth, quietTone, quietControls;
  final int defaultVersionId;
  ReadingSettings copyWith({
    VeralumeTheme? theme,
    double? fontSize,
    double? lineHeight,
    bool? serif,
    bool? showVerseNumbers,
    bool? boldVerseNumbers,
    String? readingWidth,
    bool? onboarded,
    bool? fullScreen,
    bool? quietReading,
    String? quietTone,
    String? quietControls,
    bool? keepScreenAwake,
    bool? rememberLastLight,
    bool? dailyWordReminder,
    bool? samSamEnabled,
    double? samSamScale,
    int? defaultVersionId,
    bool? loaded,
  }) => ReadingSettings(
    theme: theme ?? this.theme,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    serif: serif ?? this.serif,
    showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
    boldVerseNumbers: boldVerseNumbers ?? this.boldVerseNumbers,
    readingWidth: readingWidth ?? this.readingWidth,
    onboarded: onboarded ?? this.onboarded,
    fullScreen: fullScreen ?? this.fullScreen,
    quietReading: quietReading ?? this.quietReading,
    quietTone: quietTone ?? this.quietTone,
    quietControls: quietControls ?? this.quietControls,
    keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    rememberLastLight: rememberLastLight ?? this.rememberLastLight,
    dailyWordReminder: dailyWordReminder ?? this.dailyWordReminder,
    samSamEnabled: samSamEnabled ?? this.samSamEnabled,
    samSamScale: samSamScale ?? this.samSamScale,
    defaultVersionId: defaultVersionId ?? this.defaultVersionId,
    loaded: loaded ?? this.loaded,
  );
}

class SettingsController extends StateNotifier<ReadingSettings> {
  SettingsController() : super(const ReadingSettings()) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ReadingSettings(
      theme:
          VeralumeTheme.values[(p.getInt('radiantTheme') ??
                  ((p.getInt('theme') == ThemeMode.dark.index)
                      ? VeralumeTheme.midnight.index
                      : VeralumeTheme.royalPurple.index))
              .clamp(0, VeralumeTheme.values.length - 1)],
      fontSize: p.getDouble('fontSize') ?? 20,
      lineHeight: p.getDouble('lineHeight') ?? 1.7,
      serif: p.getBool('serif') ?? true,
      showVerseNumbers: p.getBool('verseNumbers') ?? true,
      boldVerseNumbers: p.getBool('boldVerseNumbers') ?? true,
      readingWidth: p.getString('readingWidth') ?? 'normal',
      onboarded: p.getBool('onboarded') ?? false,
      fullScreen: p.getBool('fullScreen') ?? false,
      quietReading: p.getBool('quietReading') ?? false,
      quietTone: p.getString('quietTone') ?? 'cool',
      quietControls: p.getString('quietControls') ?? 'tap',
      keepScreenAwake: p.getBool('keepScreenAwake') ?? false,
      rememberLastLight: p.getBool('rememberLastLight') ?? true,
      dailyWordReminder: p.getBool('dailyWordReminder') ?? false,
      samSamEnabled: p.getBool('samSamEnabled') ?? true,
      samSamScale: (p.getDouble('samSamScale') ?? .4).clamp(.25, 1.35),
      defaultVersionId: p.getInt('defaultVersionId') ?? 1,
      loaded: true,
    );
  }

  Future<void> update(ReadingSettings value) async {
    state = value;
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setInt('radiantTheme', value.theme.index),
      p.setDouble('fontSize', value.fontSize),
      p.setDouble('lineHeight', value.lineHeight),
      p.setBool('serif', value.serif),
      p.setBool('verseNumbers', value.showVerseNumbers),
      p.setBool('boldVerseNumbers', value.boldVerseNumbers),
      p.setString('readingWidth', value.readingWidth),
      p.setBool('onboarded', value.onboarded),
      p.setBool('fullScreen', value.fullScreen),
      p.setBool('quietReading', value.quietReading),
      p.setString('quietTone', value.quietTone),
      p.setString('quietControls', value.quietControls),
      p.setBool('keepScreenAwake', value.keepScreenAwake),
      p.setBool('rememberLastLight', value.rememberLastLight),
      p.setBool('dailyWordReminder', value.dailyWordReminder),
      p.setBool('samSamEnabled', value.samSamEnabled),
      p.setDouble('samSamScale', value.samSamScale),
      p.setInt('defaultVersionId', value.defaultVersionId),
    ]);
  }

  Future<void> setDefaultVersion(int versionId) =>
      update(state.copyWith(defaultVersionId: versionId));
}

final settingsProvider =
    StateNotifierProvider<SettingsController, ReadingSettings>(
      (ref) => SettingsController(),
    );
