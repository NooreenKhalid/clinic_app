# Smart Clinic App — Release Checklist

## Changes made

- Set the user-facing name to **Smart Clinic App** for Flutter, Android, iOS, and web metadata.
- Applied the dark clinical design system and responsive patient-management UI without changing Firestore fields, collections, authentication roles, or CRUD operations.
- Replaced the hardcoded image-upload provider credential with the `IMGBB_API_KEY` build-time define.
- Replaced raw sign-in/add-patient error messages with safe user-facing messages.
- Added an ignored Android signing configuration template at `android/key.properties.example`.
- Updated the Android/iOS splash backgrounds to match the dark app experience.

## Validation status

- `git diff --check`: passed.
- Flutter static analysis and Android builds: not completed in this Windows environment because the Flutter CLI did not return before the command timeout.
- Firebase runtime/authentication/Firestore verification: requires the authorized project credentials and a test account; no production records were accessed or modified.

## Android release setup

1. Create a production keystore and keep it outside source control.
2. Copy `android/key.properties.example` to `android/key.properties` and replace its placeholder values locally.
3. Supply the image provider credential only in the build environment:

   ```powershell
   flutter build apk --release --dart-define=IMGBB_API_KEY=YOUR_VALUE
   flutter build appbundle --release --dart-define=IMGBB_API_KEY=YOUR_VALUE
   ```

4. After successful builds, copy/rename these verified artifacts as requested:

   - `build/app/outputs/flutter-apk/app-release.apk` → `SmartClinicApp-release.apk`
   - `build/app/outputs/bundle/release/app-release.aab` → `SmartClinicApp-release.aab`

The current Gradle release configuration uses the external keystore only when `android/key.properties` exists. A build made without it is debug-signed and **must not** be distributed or submitted to Play.

## Android production checks

- Preserve the existing application ID: changing it would invalidate the current Firebase Android configuration and create a different Play listing.
- Confirm the installed Flutter SDK targets Android API 36 or newer before uploading after 31 August 2026.
- The current Android permissions are camera, network, and image-media access. Confirm each is used and disclose camera/image handling in the Play Console Health apps and Data safety forms.
- Replace the default launcher icon with approved original Smart Clinic App artwork before store submission. No icon artwork was generated in this environment.

## iOS status

- Display name and dark launch background are prepared.
- The existing iOS bundle identifier and Firebase iOS options remain unchanged.
- A signed IPA cannot be built on Windows. On a Mac with Xcode:

   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ipa --release --dart-define=IMGBB_API_KEY=YOUR_VALUE
   ```

- In Xcode, select the Runner target, configure the Apple Developer Team and provisioning profile, confirm the bundle identifier, then use **Product → Archive → Distribute App**.

## Firebase and security review

- Firebase Auth role routing remains `admin`/`staff` from the existing `users` collection.
- Existing patient documents and fields remain unchanged.
- Firestore security rules and indexes were not present locally and must be reviewed/deployed in Firebase Console. Enforce authenticated access plus role-appropriate access to `users` and `patients`; client UI alone is not security.
- Rotate the previously exposed image-upload provider credential in its provider dashboard, then supply the replacement only through the build environment.
- Restrict Firebase API keys in Google Cloud Console to the correct Android package/SHA-1 and iOS bundle ID. Do not treat Firebase client configuration as a secret, but do restrict it.
- Verify Cloud Firestore security rules, audit logging, retention/deletion processes, and access revocation with the clinic's security owner before real patient data is used.

## Google Play and privacy/manual steps

- Create a privacy policy that accurately documents collection of contact details, patient/health details, images, authentication data, hosting, sharing, retention, deletion, and security practices.
- Complete the Data safety form for all Play tracks that require it, and the Health apps declaration. Do not claim medical or diagnostic capability unless legally reviewed.
- Provide prominent in-app disclosure and affirmative consent before collecting camera/images or health-related data where required.
- Complete content rating, app access/testing-account information, target audience, category, store listing, and screenshots using only non-sensitive test data.
- Begin with internal testing. If the Play account is a personal account created after 13 November 2023, run a closed test with at least 12 opted-in testers for 14 continuous days before applying for production access.
- Complete developer identity/package registration requirements in Play Console/Android Developer Console as applicable.

## Remaining manual release gate

Do not publish until a real-device test confirms login/logout, patient add/search/update/delete, patient image upload/download/delete, role access, offline failures, and keyboard/small-screen layout behavior against a non-production test dataset.
