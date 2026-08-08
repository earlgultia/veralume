# Veralume 1.2.0 QA report

Date: 2026-08-08

## Data

- Bundled translations: ASV, KJV, Tagalog Ang Biblia, Open Ang Salita ng
  Diyos, Open Ang Pulong sa Dios, Balaan nga Bibliya, MBB-CEB, CebBugna
- Versions: 8
- Version-specific book records: 528 (66 per version)
- Chapters: 9,512 (1,189 per version)
- Verses: 248,314
- FTS rows: 248,314
- Duplicate verse identities: 0
- Empty verse text: 0
- Broken foreign keys: 0
- SQLite integrity: OK

MBB-CEB has 30,595 verse rows because its source combines or omits some
standalone verse-number rows. Veralume retains the supplied source numbering and
does not invent missing text.

## Automated verification

- Python data tests: 5 passed
- Flutter unit/widget/repository/settings/quiz tests: 13 passed
- `flutter analyze`: no issues
- Android release build: passed
- APK v2 signature verification: passed
- Offline database asset present in APK: yes
- Internet permission present: no

Repository tests cover version/book/chapter loading, filtered FTS search,
bookmark ranges and database-reopen persistence, highlight create/recolor/remove,
note create/search/edit/delete/persistence, reading history, equivalent-version
navigation, deterministic daily verse selection, and all reading preferences.
Quiz tests cover four unique choices, exact-reference questions, missing-word
generation, and correct-answer integrity across easy, medium, and hard modes.

## Android release smoke test

The release APK was installed successfully on an Android 15 emulator. It stayed
running for at least 30 seconds with no fatal Android or SQLite exception. ADB
accessibility inspection confirmed onboarding, all six navigation destinations,
all eight version names, MBB-CEB book/chapter navigation, and rendered MBB-CEB
Genesis 1 Scripture text. Version 1.2.0 smoke testing also opened the quiz from
Home, displayed all three difficulty modes, and generated a 10-question Easy
round with four randomized offline choices.

The Flutter debug integration-test harness was attempted twice but caused the
headless emulator process itself to exit/offline during the test connection.
This was not reproduced by the release APK and is recorded as an environment
limitation rather than reported as an integration-test pass.

## Artifact

- File: `dist/Veralume-1.2.0.apk`
- Size: 85,152,922 bytes
- SHA-256: `898866B1EF68ECDA75A9CF7C48B36DF3B1F795F694423811F2A2CA654ABC2C4E`
- Package: `com.veralume.veralume`
- Minimum Android: 7.0 / API 24
- Target Android API: 36

The APK currently uses the local Android debug certificate, suitable for direct
sideloading and testing. Store publication requires an owner-controlled release
key. iOS compilation and signing require macOS and Xcode and were not executed
on this Windows host.
