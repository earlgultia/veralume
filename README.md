# Veralume 1.5.4 — Faith Over Fear

Your Word. Your Light. Everywhere.

This release centers on courage rooted in Scripture, with encouragement, daily
devotionals, and a private prayer journal to help make space for hope.

## Sam-Sam Bible companion

Sam-Sam 2.0 is the app's Bible companion, with a name inspired by the book of Psalms. His greetings,
Bible facts, facial expressions, gestures, and sprite art are bundled locally and work offline.
The pop-up companion is enabled by default; turn it off any time in **Settings → Sam-Sam**.
It starts small and can be resized with a pinch gesture or the Settings slider. Double-tapping
no longer hides the companion. Sam-Sam can share another fact or open a conversation about the
related passage.
The supplied character sheet provides static poses and expressions, so the app animates them as
offline sprites rather than pretending the unrigged 3D model has skeletal animation.

Sam-Sam's lightweight offline guide works without downloading or bundling a large language model.
It uses bundled Scripture, curated Bible topics, and recent questions to answer Bible-related
questions on every supported platform. If a question is outside the local guide, Sam-Sam says so
instead of inventing an answer. Open-ended conversational help is available through the online
service.

## Online Sam-Sam configuration

Online requests go from the app to the Supabase Edge Function `david`, which calls
OpenRouter. It tries the optional `OPENROUTER_MODEL` first, then falls back to
the `openrouter/free` model router, `liquid/lfm-2.5-2.6b:free`,
`nvidia/nemotron-3.5-lightning:free`, and `google/gemma-4-26b-a4b-it:free`.
The OpenRouter API key stays in Supabase and is never included in the APK.

```sh
supabase functions deploy david

flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

First set `OPENROUTER_API_KEY` in the Supabase project dashboard under Edge Function secrets,
then deploy the function from the repository root. The Supabase project URL and publishable key are
client configuration, not provider secrets; configure both with `--dart-define` when building.
Do not put the OpenRouter key in Flutter source, build arguments, or the APK. Rotate any provider
key that has been shared or committed.

The function tries the configured `OPENROUTER_MODEL` first, if set, followed by the
OpenRouter free-model router and listed free models. Free-model availability and
behavior can change over time.
Each provider attempt has a timeout, and failed attempts move on to the next model.

The function validates request size and conversation history, forwards requests to OpenRouter,
and returns only the generated answer. If the online service is unavailable, the app falls back to
its bundled Scripture-grounded guide and labels the answer as offline rather than presenting it as
an online response.
The function disables JWT verification because the app has no sign-in flow and Supabase
publishable keys are not user JWTs. The endpoint can therefore be called by other clients too.
Apply provider spending limits and add server-side rate limiting or authenticated access before
broad public release.

Developed by ArkByte Technologies: Earl Gultia, Kristelle Joyce Quijano,
Miles Gultia, and Arvey Ociones.

Veralume is an offline-first Flutter Bible reader for Android and iOS. It provides book/chapter/verse navigation, local Scripture browsing and FTS5 search, persistent bookmarks and highlights with sermon topics and preparation notes, personal notes, reading history, randomized easy/medium/hard Bible quizzes, appearance controls, and a focused liquid-glass-inspired interface. Saved verses and sermon details can be searched and removed. Bible reading and quizzes do not require an account or network connection.

## Daily devotionals and prayer journal

The Daily Devotional presents a verse of the day, a short reflection, a practical
lesson, and a prayer. The Prayer Journal stores dated personal prayers locally,
supports editing and deletion, and lets users mark prayers as answered. These
entries remain on the device and require no account or backend.

An optional Today’s Word notification can be enabled in Settings. After notification permission is granted, the app schedules the next 30 daily verses for 8:00 AM local time and refreshes the schedule when the app is opened or the selected Bible version changes.

## Faith Calendar

Plan devotional, prayer, Bible study, church, and personal faith events on a monthly calendar.
Events can repeat daily or weekly, include notes, and be edited or removed. Calendar entries are
stored locally on the device.

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
