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
    this.onboarded = false,
    this.fullScreen = false,
    this.defaultVersionId = 1,
    this.loaded = false,
  });
  final ThemeMode themeMode;
  final double fontSize, lineHeight;
  final bool serif, showVerseNumbers, onboarded, fullScreen, loaded;
  final int defaultVersionId;
  ReadingSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    double? lineHeight,
    bool? serif,
    bool? showVerseNumbers,
    bool? onboarded,
    bool? fullScreen,
    int? defaultVersionId,
    bool? loaded,
  }) => ReadingSettings(
    themeMode: themeMode ?? this.themeMode,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    serif: serif ?? this.serif,
    showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
    onboarded: onboarded ?? this.onboarded,
    fullScreen: fullScreen ?? this.fullScreen,
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
      onboarded: p.getBool('onboarded') ?? false,
      fullScreen: p.getBool('fullScreen') ?? false,
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
      p.setBool('onboarded', value.onboarded),
      p.setBool('fullScreen', value.fullScreen),
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
