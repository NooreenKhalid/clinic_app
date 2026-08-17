# Firebase Security Configuration

## What the app currently uses

- **Firebase Authentication:** email/password sign-in and sign-out.
- **Firestore:** `users/{uid}` for the existing `role` (`admin` or `staff`) and `patients/{patientId}` for clinic records.
- **Firebase Storage:** not used by this app. No Firebase Storage package or Storage API call is present.
- **Image uploads:** the app sends patient images to ImageBB and stores returned URLs in the existing `image_urls` and legacy `imageUrl` fields.

The Firebase configuration references one consistent Firebase project across Android, iOS, web, Windows, and macOS. Android's application ID and the Firebase Android registration match; iOS's bundle identifier and Firebase iOS registration match. Do not change either identifier without registering a new Firebase app first.

## Firestore rules added

`firestore.rules` provides the following access model without changing document structure:

| Path | Admin | Staff | Other / unauthenticated |
| --- | --- | --- | --- |
| `users/{own uid}` | Read own role | Read own role | Denied |
| `users/*` writes/listing | Denied from client | Denied from client | Denied |
| `patients/*` reads | Allowed | Allowed | Denied |
| `patients/*` create | Allowed when `patientId` and `createdBy` match current app behavior | Same | Denied |
| `patients/*` update | Allowed | Only `image_urls` / `imageUrl` updates | Denied |
| `patients/*` delete | Allowed | Denied | Denied |

## Deploy the rules

1. In Firebase Console, confirm every application user has a `users/{uid}` document with a valid `role` of `admin` or `staff`.
2. In a separate Firebase test project or during a maintenance window, run the Firebase Rules Playground/Emulator tests for the matrix above.
3. Deploy only these rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. Verify login and the existing admin/staff patient workflows against test accounts. Deploying these rules before role documents exist will deny access.

No Firestore rules were available locally before this change, so the currently deployed Console rules remain unknown until reviewed in Firebase Console.

## Image-upload credential rotation

An ImageBB API key had previously been embedded in `lib/services/imagebb_service.dart`. It has been removed from the current source, but should be treated as compromised because it may exist in Git history or past builds.

1. Sign in to the ImageBB account that owns the key.
2. Revoke/delete the exposed key (or regenerate it if the provider offers rotation).
3. Create a replacement key with the narrowest available restrictions and monitoring.
4. Store the replacement only in CI/CD or a protected local secret manager—never in Dart, Git, `key.properties`, screenshots, or chat.
5. Build with the replacement injected at compile time:

   ```bash
   flutter build appbundle --release --dart-define=IMGBB_API_KEY=YOUR_VALUE
   ```

6. Verify image upload with a fake test patient. Without the build-time value, image uploads fail safely and no key is exposed.

## Remaining security actions

- Review and deploy the rules above in Firebase Console.
- Restrict Firebase client API keys in Google Cloud Console to the matching Android package/SHA certificate and iOS bundle ID; Firebase client configuration is not a service-account credential, but restriction still reduces abuse.
- Confirm Firebase Authentication has only the intended sign-in providers enabled and remove unused test accounts.
- Establish a server-side, audited process for creating/changing user role documents; client writes are intentionally blocked.
- Confirm ImageBB's privacy, data residency, retention, deletion, and access controls are acceptable for patient images. Public third-party image URLs are a material privacy risk for clinical data; this needs clinic/legal approval before production use.
- If Firebase Storage is later adopted, add a dedicated `storage.rules` file and upload through authenticated, path-scoped Firebase Storage—not through public URLs.
