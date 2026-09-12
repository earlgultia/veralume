import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veralume/core/theme/app_theme.dart';

void main() {
  test('Radiant exposes exactly ten complete themes', () {
    expect(VeralumeTheme.values, hasLength(10));
    expect(AppTheme.palettes.keys.toSet(), VeralumeTheme.values.toSet());
    for (final theme in VeralumeTheme.values) {
      final data = AppTheme.forTheme(theme);
      expect(data.extension<VeralumePalette>(), isNotNull);
    }
  });

  test('Midnight is the dark Radiant palette', () {
    expect(AppTheme.palettes[VeralumeTheme.midnight]!.brightness, Brightness.dark);
    expect(AppTheme.palettes.values.where((p) => p.brightness == Brightness.dark), hasLength(1));
  });
}
