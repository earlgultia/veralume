/// Language-neutral helpers for the local verse-memory exercise.
/// Dart RegExp uses Unicode text directly, so this works with bundled English,
/// Tagalog, Cebuano, apostrophes, hyphens, and punctuation without a dictionary.
class ClozeExercise {
  ClozeExercise(this.text) : tokens = RegExp(r"[\p{L}\p{N}][\p{L}\p{N}'’-]*", unicode: true).allMatches(text).map((m) => m.group(0)!).toList();
  final String text;
  final List<String> tokens;

  List<int> blanks() {
    final candidates = <int>[for (var i = 0; i < tokens.length; i++) if (tokens[i].runes.length > 2) i];
    if (candidates.isEmpty) return const [];
    final wanted = (candidates.length / 3).ceil().clamp(1, 5);
    // Spread blanks through the verse; deterministic practice is less confusing.
    return [for (var i = 0; i < wanted; i++) candidates[(i * candidates.length ~/ wanted + 1) % candidates.length]];
  }

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{N}'’-]+", unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool correct(String answer, String expected) => normalize(answer) == normalize(expected);
}
