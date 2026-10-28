# Release checklist (Week 6)

Everything below is required once, before the first Play Store upload. Nothing
here can be completed from this repository alone — it needs your Play Console,
AdMob and Play App Signing accounts.

## 1. Signing key

Generate **once**, then store the file somewhere safe (password manager +
backup). Never commit it — `.gitignore` already excludes `*.jks` and
`key.properties`.

```bash
keytool -genkeypair -v \
  -keystore ~/keys/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias doc-vault-upload
```

Create `android/key.properties` (gitignored):

```properties
storeFile=/absolute/path/to/upload-keystore.jks
keyAlias=doc-vault-upload
keyPassword=YOUR_KEY_PASSWORD
storePassword=YOUR_STORE_PASSWORD
```

With that file present, `flutter build appbundle --release` signs the app
bundle with it; without it the build falls back to the debug key so CI keeps
producing test APKs.

**Play App Signing:** Play Console creates and holds the actual app signing
key; you upload the *upload* key above. If you ever lose it, request an upload
key reset in Play Console — that is why the file must be backed up.

## 2. AdMob (free tier banner)

1. Create an AdMob app (package `com.dgastudios.doc_vault`) and a **banner**
   unit.
2. Replace the two placeholders:
   - `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
     (currently Google's **test** App ID `ca-app-pub-3940256099942544~3347511713`)
   - `lib/features/ads/widgets/ad_banner.dart` → `_productionBannerUnitId`
     (currently an intentionally invalid placeholder, so release builds show
     no ad rather than a test ad)
3. While developing, keep the test IDs: Google's test units never risk policy
   violations for invalid clicks.

## 3. In-app purchase (Pro unlock)

In Play Console → Monetise → Products → **In-app products**:

| Field | Value |
|---|---|
| Product ID | `pro_unlock` (must match `FreeTier.proProductId` exactly) |
| Type | Managed product (one-time) |
| Price | test between PHP 199–299 / USD 3.99–4.99 per the spec |
| Status | Active |

Add at least two license testers before closed testing — IAP silently fails
for regular accounts before production. The app queries this product at
runtime; until it exists, the paywall shows "Purchases unavailable".

## 4. Build

```bash
flutter analyze && flutter test
flutter build appbundle --release     # bundle for Play
flutter build apk --release           # sideload/test APK
```

CI (`.github/workflows/flutter_ci.yml`) still builds a **debug-signed** test
APK on every push to `main` — intentional, so the pipeline never depends on
secrets. Add the keystore as CI secrets yourself if you want CI to produce the
store-ready bundle.

## 5. Closed testing

Play requires 12 testers opted in for 14 days for a new personal developer
account. Before applying for production:

- [ ] Banner shows on the dashboard for free users, disappears for Pro
- [ ] `pro_unlock` purchase and restore both work for a license tester
- [ ] Reminders fire on 3 physical devices, including after a reboot
- [ ] App lock on launch **and** after backgrounding on a sub-screen
- [ ] Backup export → wipe → restore round trip
- [ ] OCR suggestion and manual date entry
- [ ] Two accounts/profiles isolation (documents stay with their person)
- [ ] Privacy policy URL published and linked in the listing
