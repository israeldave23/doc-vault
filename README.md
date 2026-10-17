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
- [ ] Week 3: OCR date detection, profiles management
- [ ] Week 4: local notifications
- [ ] Week 5: app lock, encrypted backup, settings
- [ ] Week 6: AdMob, Pro unlock, onboarding, Play Store release

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
      services/                # camera/gallery pick + crop + encrypt flow
      screens/                 # dashboard, add/edit, detail
      widgets/                 # document card, status chip, encrypted photo viewer
    profiles/                # Profile model + providers
    settings/                # AppSettings model
test/                        # unit tests (run with `flutter test`)
docs/SPEC.md                 # product spec and 6-week plan
```

## Architecture notes

- **State:** Riverpod `Notifier` classes. Screens only talk to providers.
- **Storage:** Hive CE boxes encrypted with `HiveAesCipher`. Adapters are hand-written (no build_runner) so the project stays simple to follow. Never reuse or renumber adapter field indexes once shipped.
- **Privacy:** no network calls, no accounts. The only data that ever leaves the device is a user-initiated encrypted backup (Week 5).

## Running checks

```bash
flutter analyze
flutter test
```

CI runs both on every push to `main`.
