# Veralume iOS release

The Flutter/Dart code, bundled SQLite database, Riverpod state, preferences,
sharing, quiz engine, and responsive UI are cross-platform. The iOS project is
configured for iOS 13 or newer, iPhone and iPad, Swift 5, bundle identifier
`com.veralume.veralume`, and version values supplied by `pubspec.yaml`.

Apple requires macOS, Xcode, an Apple ID, and a signing identity to create an
installable iPhone application. On a Mac:

1. Install the current stable Flutter SDK and Xcode.
2. Run `sudo xcodebuild -license accept` if Xcode requests it.
3. Connect the iPhone or create an iOS Simulator in Xcode.
4. Open `ios/Runner.xcworkspace` in Xcode.
5. Select Runner > Signing & Capabilities, enable automatic signing, and choose
   the ArkByte Technologies Apple Developer team.
6. Keep `com.veralume.veralume` if it is registered to that team; otherwise use
   a unique bundle identifier owned by the team.
7. Run `bash tool/build_ios.sh` for unsigned compilation and all automated tests.
8. Run `flutter run -d <device-id>` for device QA.
9. Run `flutter build ipa --release` to create the signed archive/IPA.

No network, location, camera, microphone, contacts, photo-library, or tracking
permission is requested. Scripture, quizzes, search, bookmarks, highlights,
notes, history, and settings remain on the device. Share actions use the native
iOS share sheet only when the user explicitly invokes them.

Before App Store submission, the account owner must provide the final signing
team, distribution certificate, provisioning profile, App Store listing,
support/privacy URLs, screenshots, age rating, and translation-license review.
