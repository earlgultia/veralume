#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS builds require macOS with Xcode." >&2
  exit 1
fi

command -v flutter >/dev/null || {
  echo "Flutter is not available on PATH." >&2
  exit 1
}
command -v xcodebuild >/dev/null || {
  echo "Xcode command-line tools are not installed." >&2
  exit 1
}

flutter pub get
python3 tool/import_bibles.py
python3 -m unittest tool/test_import_bibles.py
flutter analyze
flutter test
flutter build ios --release --no-codesign

echo
echo "Unsigned iOS release verification passed."
echo "To create a signed IPA, select your Apple team in ios/Runner.xcworkspace,"
echo "then run: flutter build ipa --release"
