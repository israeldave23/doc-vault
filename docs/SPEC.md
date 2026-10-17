# Document Expiry Vault — Feature Spec & Flutter Project Plan

**Studio:** DGA Studios
**Platform:** Android (Google Play) first, iOS later
**Stack:** Flutter 3.x, Dart, on-device storage (no backend for MVP)
**Monetization:** Free with banner ads + one-time "Pro" unlock (in-app purchase)

---

## 1. One-line pitch

Never let a passport, license, ID, insurance, or registration expire again. Scan it once, and the app reminds you months before it lapses. Everything stays on your phone.

## 2. Who it's for (launch audience)

- Filipino families managing many IDs (passport, driver's license, PhilHealth, SSS, UMID, PRC license, TIN, postal ID, national ID)
- Vehicle owners (LTO registration, driver's license, insurance, Autosweep/Easytrip RFID)
- OFWs and frequent travelers (passport, visas, OEC, work permits, vaccination cards)
- Freelancers and small business owners (DTI permit, Mayor's permit, BIR registration, contracts)

The problem is universal, so the same app works worldwide, but the category presets and copy are PH-first at launch.

## 3. Why users will trust and pay

- **Offline-first and private:** no account, no cloud, no server. Data stays on-device, encrypted. This is the main selling point and must be stated on the first screen.
- **Reminders that actually fire:** reliable local notifications at 90 / 60 / 30 / 7 / 1 day(s) before expiry, configurable per document.
- **Zero friction:** add a document in under 20 seconds with a photo and an auto-detected date.

---

## 4. MVP feature list (Version 1.0)

### Must have
| # | Feature | Notes |
|---|---------|-------|
| 1 | Add document | Title, category, expiry date, optional issue date, optional ID number, notes, 1–3 photos (front/back) |
| 2 | Category presets | Passport, Driver's License, National ID, PhilHealth, SSS/UMID, PRC License, Vehicle Registration, Insurance, Visa, Work Permit, Business Permit, Warranty, Credit/Debit Card, Other |
| 3 | Camera capture + crop | Use device camera or gallery; simple crop/rotate |
| 4 | OCR date detection | On-device text recognition (Google ML Kit) scans the photo and suggests expiry date; user confirms |
| 5 | Local reminders | Default 90/30/7/1 days before; per-document override; repeat daily in the final week if unacknowledged |
| 6 | Home dashboard | Sorted by soonest expiry; color status: red (expired/<30d), amber (<90d), green (OK) |
| 7 | Search & filter | By title, category, status, person |
| 8 | Family profiles | Tag each document to a person (Me, Spouse, Child, Parent); filter by person |
| 9 | App lock | PIN or biometric (fingerprint/face) on launch |
| 10 | Encrypted local backup | Export/import an encrypted file to Google Drive or local storage; user holds the passphrase |
| 11 | Banner ads (free tier) | One banner on the dashboard bottom; none on the add/edit screens |
| 12 | Pro unlock (one-time IAP) | Removes ads, unlimited documents (free tier capped at 10), unlimited profiles (free capped at 2), renewal checklists |

### Should have (v1.1–1.2)
- **Renewal checklists:** for each PH preset, a step list of requirements and where to renew (e.g., DFA passport appointment link, LTO online portal). Static content, updated with app releases.
- **Renewal cost & fee tracker:** log what you paid and when.
- **Home-screen widget:** "Next 3 expiring documents."
- **Share a document securely:** time-limited export of a single document as PDF (for sending to HR, agencies).
- **Calendar sync:** optional export of expiry dates to Google Calendar.

### Later (v2+)
- Optional encrypted cloud sync across devices (paid subscription tier).
- Smart renewal reminders based on lead time (passports need ~6 months validity for travel).
- Localization: Tagalog, Bisaya, Bahasa, Vietnamese, Thai, Spanish.

### Explicitly out of scope
- No account creation, no server-side storage of document images.
- No automatic submission to government agencies.
- No scanning of credit card numbers via OCR (store only last 4 digits manually).

---

## 5. Screens (UX flow)

1. **Onboarding (3 slides):** "Your documents stay on your phone" → "Reminders before it's too late" → "Lock it with your fingerprint." Then set PIN/biometrics.
2. **Dashboard:** list/grid of documents with status chips; FAB "+ Add"; filter by person at top; banner ad at bottom (free tier).
3. **Add/Edit Document:** camera button first, then title, category (chips), expiry date (prefilled by OCR), person, reminders toggle, notes. Save.
4. **Document Detail:** large photo viewer (tap to zoom, front/back swipe), days-remaining counter, reminder schedule, renewal checklist (Pro), edit/delete.
5. **Profiles:** manage people.
6. **Settings:** default reminders, app lock, backup/restore, Pro upgrade, privacy policy, rate app.
7. **Paywall:** one screen, one price, "Unlock Pro forever." Shown when hitting the 10-document cap or tapping "Remove ads."

Design direction: clean, card-based, high contrast status colors, large touch targets (many users will be parents and older relatives). Dark mode supported from day one.

---

## 6. Data model

```dart
class Document {
  String id;              // uuid
  String title;
  String category;        // enum key
  String? idNumber;       // masked in list view
  DateTime? issueDate;
  DateTime expiryDate;
  String profileId;       // person
  List<String> imagePaths; // encrypted files in app sandbox
  String? notes;
  List<int> reminderDaysBefore; // e.g. [90, 30, 7, 1]
  bool remindersEnabled;
  DateTime createdAt;
  DateTime updatedAt;
}

class Profile {
  String id;
  String name;
  String? avatarEmoji;
}

class AppSettings {
  List<int> defaultReminderDays;
  bool appLockEnabled;
  bool biometricsEnabled;
  bool isPro;
  bool darkMode;
}
```

---

## 7. Recommended Flutter packages

| Need | Package |
|------|---------|
| Local database | `isar` or `drift` (Isar is simpler for this scale) |
| Secure key storage | `flutter_secure_storage` |
| File encryption | `encrypt` (AES-256) with key from secure storage |
| Camera / gallery | `image_picker`, `camera` |
| Crop | `image_cropper` |
| OCR | `google_mlkit_text_recognition` (on-device, free) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Biometrics | `local_auth` |
| Ads | `google_mobile_ads` |
| In-app purchase | `in_app_purchase` (or RevenueCat `purchases_flutter` for easier receipt handling) |
| State management | `riverpod` (or `provider` if you prefer simpler) |
| Backup to Drive | `googleapis` + `google_sign_in` (v1.1) |
| Widgets | `home_widget` (v1.1) |

Android notes: request `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` and `POST_NOTIFICATIONS` (Android 13+). Test on battery-optimized phones (Xiaomi, Oppo, Vivo, Realme are common in PH and aggressively kill background tasks); include an in-app "Why reminders may not fire" help page with per-brand instructions.

---

## 8. Monetization plan

**Free tier**
- Up to 10 documents, 2 profiles
- Banner ad on dashboard only
- All reminders and encryption included (never gate safety features)

**Pro (one-time purchase)**
- Suggested price: PHP 199–299 (around USD 3.99–4.99). Test two prices via Play Console experiments.
- Unlimited documents and profiles, ad-free, renewal checklists, home-screen widget, PDF export
- Launch promo: 50% off for the first 2 weeks to earn early reviews

**Why one-time instead of subscription:** utilities with a trust angle convert better with a single clear price; subscriptions feel wrong for "a vault." A future encrypted sync feature can be the subscription tier later.

**Revenue levers**
- Interstitial ad only after saving a 3rd+ document in a session (never on launch)
- "Remove ads" prompt after the user has set up 3 documents (they are now invested)
- Ask for a Play Store rating after the first reminder notification is tapped and the document is marked renewed

---

## 9. Build plan (6 weeks, solo, AI-assisted)

| Week | Goal | Deliverable |
|------|------|-------------|
| 1 | Project setup, design system, data model, Isar DB, Dashboard + Add screen (no camera yet) | Working CRUD with mock data |
| 2 | Camera, gallery, crop, encrypted image storage | Photos saved securely and displayed |
| 3 | OCR date detection, category presets, profiles | Add flow under 20 seconds |
| 4 | Local notifications (all schedules), status colors, search/filter | Reminders fire correctly on 3 test devices |
| 5 | App lock (PIN + biometrics), encrypted backup/restore, settings | Full privacy story works end to end |
| 6 | AdMob banner, IAP Pro unlock, paywall, onboarding, Play Store listing, privacy policy | Closed-test release on Play Console |

After launch: 2 weeks of closed testing with 20 testers (Play requires this for new personal accounts), then production.

---

## 10. Play Store listing (draft)

**Title:** Document Expiry Vault – ID & License Reminders
**Short description:** Scan your IDs, licenses, and permits. Get reminded before they expire. 100% offline and private.
**Keywords to target:** document expiry reminder, passport expiry, license renewal reminder, ID wallet offline, document organizer, LTO renewal reminder, PhilHealth, SSS

**Privacy policy must state:** no data leaves the device unless the user exports a backup; ads SDK collects advertising ID only; no document images are ever uploaded.

---

## 11. Validation checklist before coding

- [ ] Search Play Store for "document expiry reminder" and read 1–3 star reviews of the top 5 apps; list the top 10 complaints and make sure the MVP addresses at least 5.
- [ ] Post a mockup in 2–3 PH Facebook groups (OFW, car owners, freelancers) and ask "would you use this?" Collect 30+ replies.
- [ ] Confirm ML Kit reads dates on real PH IDs (passport MRZ, driver's license, UMID). If accuracy is weak, fall back to a manual date picker with a big "same as photo" helper.

---

## 12. Vibe-coding prompts (copy-paste to your AI assistant)

**Prompt 1 — Scaffold**
> Create a Flutter app called `doc_vault` using Riverpod for state and Isar for local storage. Define `Document`, `Profile`, and `AppSettings` models exactly as follows: [paste Section 6]. Build a Dashboard screen listing documents sorted by expiryDate with a status chip (red if expired or <30 days, amber if <90 days, green otherwise) and a FAB that opens an Add Document screen with fields: title, category chips, expiry date picker, profile dropdown, notes. Use Material 3 with dark mode support.

**Prompt 2 — Secure photos**
> Add photo capture with `image_picker` and cropping with `image_cropper`. Encrypt each image with AES-256 using the `encrypt` package; store the key in `flutter_secure_storage`. Save encrypted files in the app documents directory and decrypt in memory only when displaying. Write a `SecureImageStore` class with `save()`, `load()`, and `delete()`.

**Prompt 3 — OCR**
> Using `google_mlkit_text_recognition`, scan the captured image and extract candidate dates in formats DD MMM YYYY, DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD, and passport MRZ (YYMMDD). Return the latest future date as the suggested expiry. Show it prefilled in the date field with a "Detected from photo" label the user can change.

**Prompt 4 — Reminders**
> Implement `ReminderService` with `flutter_local_notifications` and `timezone`. For each document, schedule notifications at each value in `reminderDaysBefore` at 9:00 AM local time. Cancel and reschedule when a document is edited or deleted. Reschedule all on app start and after device reboot. Handle Android 13+ notification permission and exact-alarm permission with a friendly explainer dialog.

**Prompt 5 — Monetization**
> Add `google_mobile_ads` with a single adaptive banner at the bottom of the Dashboard, hidden when `isPro` is true. Add `in_app_purchase` with a non-consumable product `pro_unlock`. Build a Paywall screen with one price and a "Restore purchase" button. Gate documents beyond 10 and profiles beyond 2 behind Pro.

---

## 13. Success metrics (first 90 days)

- 1,000 installs, 4.5+ star rating
- Day-7 retention 25%+
- Pro conversion 3–5% of installs
- Crash-free rate 99.5%+
- Top review theme: "finally reminded me before my license expired"

---

## Sources

- NativeExpress, "App Ideas for 2026: 26 You Can Build and Charge For" — document expiry tracker concept and one-time unlock pricing: https://www.native.express/blog/app-ideas
- TrendApps, "12 Low-Competition App Ideas for 2026" — utility niches where small apps earn: https://trendapps.dev/blog/trends/profitable-mobile-app-ideas-2026/
- BigIdeasDB, "40 Mobile App Ideas for 2026" — Flutter + Firebase/Supabase build timelines for solo devs: https://bigideasdb.com/mobile-app-ideas-2026
