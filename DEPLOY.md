# Citideals deploy & bootstrap

End-to-end steps to take the app from this branch to a fully working install.

## 1. Enable Firebase services

Firebase Console → project **citideals**:

- **Authentication → Sign-in method**: enable **Email/Password** and **Google**.
- **Firestore Database**: create database in **Native** mode, location of your choice (`nam5` or `eur3` are common).
- **Functions**: must be on the **Blaze (pay-as-you-go)** plan — required for Cloud Functions and outbound HTTPS. Free tier is generous; you will pay $0 at typical MVP traffic.

## 2. Deploy rules, indexes, and functions

```bash
cd /Users/vientrevor/development/citideals
firebase use citideals
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

If `firebase deploy --only functions` reports "Cannot find module 'firebase-admin'", the dependencies didn't install — run `cd functions && npm install` first.

## 3. Bootstrap your first admin

The `setAdminClaim` callable refuses unless the caller is *already* an admin or appears in a bootstrap allowlist.

**Option A — one-time CLI (recommended):**

```bash
# 1. Sign up via the app once. Grab your UID from Firebase Console → Authentication.
# 2. Run this Node one-liner from a shell with `firebase-admin` available:
node -e "
const a = require('firebase-admin');
a.initializeApp({ credential: a.credential.applicationDefault(), projectId: 'citideals' });
a.auth().setCustomUserClaims('YOUR_UID_HERE', { admin: true })
  .then(() => console.log('done'));
"
```

(`gcloud auth application-default login` first if you don't have application-default credentials.)

**Option B — in-app:**

1. Edit `functions/src/index.ts`, add your UID to `BOOTSTRAP_ADMIN_UIDS`.
2. Redeploy: `firebase deploy --only functions:setAdminClaim`.
3. From a Dart console (or temporary debug button), call:
   ```dart
   await FirebaseFunctions.instance
     .httpsCallable('setAdminClaim')
     .call({'uid': 'YOUR_UID_HERE', 'grant': true});
   ```
4. **Remove your UID from the allowlist and redeploy** so the bootstrap door closes.

Either way, after the claim is set, sign out and back in (or `FirebaseAuth.currentUser.getIdToken(true)`) to refresh the token. The **Admin** tab will appear in the bottom nav.

## 4. Run the app

```bash
flutter run
# Cloudinary creds are baked into lib/core/env.dart (cloud=dku2rpjdk,
# preset=citideals_unsigned). To override per-build:
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=dku2rpjdk \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=citideals_unsigned
```

## 5. Smoke tests

| What | Expected |
| --- | --- |
| Sign up new email → check Firestore | `users/{uid}` doc auto-created by `onUserCreate` |
| Tap "List item" FAB → submit a Watches lot with 3 photos | `auctions/{id}` doc has `status: pending`, `imageUrls` are Cloudinary `secure_url`s |
| Sign in as admin → Admin tab → filter by Watches | Submission appears; Approve → flips to `status: approved`, surfaces on Home/Live within ~1s |
| Place a bid from a second account | `placeBid` Cloud Function returns success, `currentBid` updates live in the detail screen |
| Try to bid below `currentBid + minIncrement` | Function returns "Bid must be at least $X" via inline toast |
| Try to bid on your own listing | Function returns "You cannot bid on your own item" |
| Profile → Appearance → Light/Dark/System | Theme switches instantly, persists across restart |

## 6. Production hardening (not in scope for MVP)

- Move Cloudinary to **signed** uploads (small Cloud Function returning a signature). Unsigned presets are scrapable from a built APK.
- Wire **FCM notifications** in the `approveSubmission` TODO so sellers know their lot is live or rejected.
- Add a **scheduled function** (Cloud Scheduler, 1-minute cron) that flips `status: approved → ended` when `endTime` passes, and fires sale-completion logic.
- Add **bid sniping protection** in `placeBid`: if `endTime - now < 2min`, extend it by 2min.
- Add **App Store Apple Sign-In** before iOS submission (guideline 4.8 requires it once Google Sign-In is shown).
- Remove `lib/data/mock_data.dart` once you've seeded real data.
