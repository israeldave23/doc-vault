# Document Expiry Vault

Scan your IDs, licenses, and permits. Get reminded before they expire. 100% offline and private.

Built with Flutter by DGA Studios. Full product spec: [docs/SPEC.md](docs/SPEC.md).

## Status: Week 2 of 6

- [x] Project structure, theme (light/dark), design tokens
- [x] Data models (`Document`, `Profile`, `AppSettings`) with hand-written Hive adapters
- [x] AES-encrypted local database (key stored in Android Keystore via `flutter_secure_storage`)
- [x] Dashboard sorted by soonest expiry with red/amber/green status
- [x] Add / Edit / Delete documents, profile filter, search
- [x] Sample data seeded in debug builds
- [x] Week 2: camera & gallery capture (`image_picker`), crop/rotate (`image_cropper`), AES-256 encrypted photo storage (`SecureImageStore`), front/back carousel, and pinch-to-zoom viewer
- [x] Step 1 cleanup: sample data now debug-only (`kDebugMode`), Profiles management screen (add / rename / delete with documents reassigned to "Me"), status filter chips, search across title / category label / ID number / notes, per-document reminder-days editor
- [x] Week 3: OCR date detection (`google_mlkit_text_recognition`) — offline date parsing for ISO, `DD MMM YYYY`, `DD/MM/YYYY` and passport MRZ, offered as a "Detected from photo" suggestion
- [x] Week 4: local reminders (`flutter_local_notifications` + `timezone`) — 09:00 local scheduling for every configured lead, daily repeats across the final week, full resync on app start / document edit / delete, reboot rescheduling, Android 13+ permission flow with an explainer dialog
- [x] Week 5: app lock (PIN + `local_auth` biometrics, locks on launch and resume), encrypted backup/restore (single PBKDF2 + AES-256 `.dvault` file with photos included), Settings screen (appearance, default reminders, security, backup, privacy), wired `AppSettings` theme mode
- [x] Week 6: AdMob banner (test IDs until the real AdMob account exists), Pro unlock via `in_app_purchase` with the 10-document / 2-profile caps, paywall, 3-slide onboarding, release signing via `key.properties`, Play Store listing + privacy policy drafts (`docs/`)

## Getting started

Requires Flutter 3.35 or newer (stable channel).

```bash
git clone https://github.com/israeldave23/doc-vault.git
cd doc-vault
flutter pub get
flutter run
```

The Android project is already generated (`applicationId com.dgastudios.doc_vault`, `minSdk 23`, which `flutter_secure_storage` and biometrics need). To add iOS later run `flutter create . --platforms ios`.

## Project layout

```
lib/
  main.dart                  # bootstraps Hive and Riverpod
  app.dart                   # MaterialApp + theme
  core/
    theme/app_theme.dart     # colors, Material 3 theme
    constants/categories.dart# PH-first document category presets
    utils/expiry_status.dart # days-remaining math and status colors
  data/
    local/
      hive_service.dart        # encrypted boxes, key management, seed data
      secure_image_store.dart  # AES-256-CBC photo encryption + random IV
    repositories/              # thin wrappers around Hive boxes
  features/
    documents/
      models/document.dart     # model + Hive adapter
      providers/               # Riverpod notifiers + decryptedImageProvider
      services/                # camera/gallery pick + crop + encrypt flow, OCR date detection
      screens/                 # dashboard, add/edit, detail
      widgets/                 # document card, status chip, encrypted photo viewer
    profiles/                # Profile model + providers + management screen
    reminders/                # reminder scheduling maths + local notifications service
    lock/                     # LockGate + PIN keypad
    pro/                       # free-tier limits, IAP service, paywall
    ads/                       # AdMob banner (free tier only)
    onboarding/                # first-run slides
    core/security/            # PBKDF2 passphrase/PIN key derivation
    settings/                # AppSettings model
test/                        # unit tests (run with `flutter test`)
docs/SPEC.md                 # product spec and 6-week plan
```

## Architecture notes

- **State:** Riverpod `Notifier` classes. Screens only talk to providers.
- **Storage:** Hive CE boxes encrypted with `HiveAesCipher`. Adapters are hand-written (no build_runner) so the project stays simple to follow. Never reuse or renumber adapter field indexes once shipped.
- **Privacy:** no accounts, no server. The only document data that ever leaves the device is a user-initiated encrypted backup (Week 5). The free tier's AdMob banner is the one component that touches the network, and Pro removes it.

## Running checks

```bash
flutter analyze
flutter test
```

CI runs both on every push to `main`.
