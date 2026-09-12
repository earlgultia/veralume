# Veralume 1.5.1 — Radiant

Your Word. Your Light. Everywhere.

## Online David configuration

David remains useful offline through the bundled Scripture database. Online answers use the
`supabase/functions/david` Edge Function, which reads `GEMINI_API_KEY` (and optional
`GEMINI_MODEL`) from Supabase secrets. Never add that key to Flutter configuration.

Deploy the function, then build the app with the public endpoint and anon key:

```sh
flutter build apk --release \
  --dart-define=DAVID_FUNCTION_URL=https://PROJECT.supabase.co/functions/v1/david \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Developed by ArkByte Technologies: Earl Gultia, Kristelle Joyce Quijano,
Miles Gultia, and Arvey Ociones.

Veralume is an offline-first Flutter Bible reader for Android and iOS. It provides book/chapter/verse navigation, local Scripture browsing and FTS5 search, persistent bookmarks, highlights, notes, reading history, randomized easy/medium/hard Bible quizzes, appearance controls, and a focused liquid-glass-inspired interface. Bible reading and quizzes do not require an account or network connection.

## Bible data audit and licensing

The supplied `VERALUME.apk` was inspected as a ZIP/APK. It is a WebView application whose Bible data is stored as six UTF-8 JSON assets (`meta -> books -> chapters -> verses`) and a generated JavaScript bundle—not SQLite. Source filenames were misleading, so embedded metadata and text were used:

| APK filename | Declared translation | Result |
|---|---|---|
| `bible_en_niv.json` | English KJV | Bundled; public-domain source metadata |
| `bible_en_esv.json` | English ASV | Bundled; public-domain source metadata |
| `bible_tl_mbbtag.json` | Tagalog Ang Biblia | Bundled; APK identifies public-domain source |
| `bible_en_isv.json` | English ISV | Excluded; full-text redistribution permission not present |
| `bible_bisaya_mbbceb.json` | Maayong Balita Biblia Cebuano | APK copy excluded; replaced by the user-supplied licensed MySword module |
| `bible_bisaya_cebbugna.json` | Bisaya CebBugna | APK copy excluded; replaced by the user-supplied public-domain MySword module |

Additional approved sources are Biblica Open Ang Salita ng Diyos 2025 and Biblica Open Ang Pulong sa Dios (CC BY-SA 4.0), Balaan nga Bibliya (CC BY-SA 4.0), the user-supplied MBB-CEB MySword module (CC BY-ND 4.0; © 1999 Philippine Bible Society), and the user-supplied public-domain Cebuano Bugna module. MBBTAG is not bundled: the publisher's standard terms permit limited quotation, not complete-text redistribution without written permission. KJV can have special Crown restrictions in the United Kingdom. This is an engineering record, not legal advice.

The clean bundled database contains **8 versions, 528 version-specific books, 9,512 chapters, and 248,314 verses**. Source files are migration inputs only and are not runtime dependencies.

## Architecture and storage

- `lib/core`: theme and shared presentation foundations
- `lib/data`: SQLite initialization, models, repositories
- `lib/presentation`: Riverpod state, screens, reusable glass surfaces
- `assets/data/veralume.db`: independently generated offline SQLite database
- `tool/import_usfm.py` and `tool/import_mysword.py`: licensed-source converters
- `tool/import_bibles.py`: deterministic JSON-to-SQLite importer and validator
- `migration_sources`: normalized migration inputs retained for reproducible builds
- `docs/apk-inspection-report.json`: complete six-file APK audit, including excluded-source defects
- `docs/data-validation-report.json`: machine-readable packaged-data validation and counts
- `docs/final-qa-report.md`: analyzer, test, emulator, build, signature, and APK checksum results

Scripture uses normalized `bible_versions`, `books`, `chapters`, and `verses` tables plus a Unicode SQLite FTS5 index. User data is kept separately in `bookmarks`, `highlights`, `notes`, and `reading_history`. Preferences use SharedPreferences. The database is copied to the app sandbox on first launch; no remote API, Firebase, analytics SDK, or network permission is required by core reading.

## Development

```powershell
flutter pub get
python tool/import_bibles.py
python -m unittest tool/test_import_bibles.py
flutter analyze
flutter test
flutter run
```

## Install on Android now

Copy `dist/Veralume-1.4.2.apk` to an Android 7.0-or-newer phone, open it, and approve installation from that file-manager source when Android prompts. The APK is self-contained; airplane mode can remain enabled.

With USB debugging and an authorized device connected:

```powershell
.\toolchains\android-sdk\platform-tools\adb.exe install -r .\dist\Veralume-1.4.2.apk
```

Android release build with the project-local verified toolchain:

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_android.ps1
```

iOS (requires macOS and Xcode):

```bash
flutter build ios --release
```

The local SDK provisioned during development can be invoked as `.\.flutter-sdk\bin\flutter.bat` on Windows.

## Major packages

`flutter_riverpod`, `sqflite`, `shared_preferences`, `share_plus`, and `path`. Material 3 supplies the core adaptive UI. All Scripture queries and mutations are local.

## Validation

The importer rejects duplicate identities, empty text, non-sequential chapters, invalid/out-of-order verse numbers, broken relationships, and failed SQLite integrity checks. Numbering gaps are retained when present in a source translation (for example, translations that combine verse ranges). Re-run both commands whenever source data changes:

```powershell
python tool/import_bibles.py
python -m unittest tool/test_import_bibles.py
```

The repository includes project-local Flutter, Java 17, and Android SDK toolchains used for the verified build. iOS builds cannot be executed on Windows; run the documented command on macOS with Xcode to perform Apple signing and device verification.
