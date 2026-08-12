import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/journey_repository.dart';

final bibleRepositoryProvider = Provider((ref) => BibleRepository());
final journeyRepositoryProvider = Provider((ref) => JourneyRepository());

class ReadingSettings {
  const ReadingSettings({
    this.themeMode = ThemeMode.system,
    this.fontSize = 19,
    this.lineHeight = 1.65,
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
    this.defaultVersionId = 1,
    this.loaded = false,
  });
  final ThemeMode themeMode;
  final double fontSize, lineHeight;
  final bool serif,
      showVerseNumbers,
      boldVerseNumbers,
      onboarded,
      fullScreen,
      quietReading,
      keepScreenAwake,
      rememberLastLight,
      loaded;
  final String readingWidth, quietTone, quietControls;
  final int defaultVersionId;
  ReadingSettings copyWith({
    ThemeMode? themeMode,
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
    int? defaultVersionId,
    bool? loaded,
  }) => ReadingSettings(
    themeMode: themeMode ?? this.themeMode,
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
      themeMode: ThemeMode.values[p.getInt('theme') ?? 0],
      fontSize: p.getDouble('fontSize') ?? 19,
      lineHeight: p.getDouble('lineHeight') ?? 1.65,
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
      defaultVersionId: p.getInt('defaultVersionId') ?? 1,
      loaded: true,
    );
  }

  Future<void> update(ReadingSettings value) async {
    state = value;
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setInt('theme', value.themeMode.index),
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
