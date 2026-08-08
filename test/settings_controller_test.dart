import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veralume/presentation/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading settings load and persist every user preference', () async {
    SharedPreferences.setMockInitialValues({
      'theme': ThemeMode.dark.index,
      'fontSize': 23.0,
      'lineHeight': 1.8,
      'serif': false,
      'verseNumbers': false,
      'onboarded': true,
      'fullScreen': true,
      'defaultVersionId': 2,
    });
    final controller = SettingsController();
    for (var attempt = 0; attempt < 20 && !controller.state.loaded; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(controller.state.loaded, isTrue);
    expect(controller.state.themeMode, ThemeMode.dark);
    expect(controller.state.fontSize, 23);
    expect(controller.state.lineHeight, 1.8);
    expect(controller.state.serif, isFalse);
    expect(controller.state.showVerseNumbers, isFalse);
    expect(controller.state.fullScreen, isTrue);
    expect(controller.state.defaultVersionId, 2);

    await controller.update(
      controller.state.copyWith(
        themeMode: ThemeMode.light,
        fontSize: 18,
        fullScreen: false,
        defaultVersionId: 3,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('theme'), ThemeMode.light.index);
    expect(preferences.getDouble('fontSize'), 18);
    expect(preferences.getBool('fullScreen'), isFalse);
    expect(preferences.getInt('defaultVersionId'), 3);
    controller.dispose();
  });
}
