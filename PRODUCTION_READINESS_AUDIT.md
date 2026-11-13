# Production Readiness Audit — MedVerify Mobile

**Original Audit:** 2026-06-27  
**Re-audit:** 2026-06-28  
**Auditor:** Claude Code

---

## Overall Score: 7 / 10

> **Conditionally ready for limited beta distribution** (direct APK). All security blockers and the missing test suite have been resolved. Three items remain open, none of which are functional blockers for a controlled beta: the production keystore (deferred by design), a brittle dependency override, and a GitHub Secret that needs to be added before Sentry monitoring activates.

**Score change: 3 → 7**

---

## Score Breakdown

| Category | Before | After | Notes |
|---|---|---|---|
| Security | 2/10 | 9/10 | All auth issues resolved; manifest hardened |
| Build & Distribution | 2/10 | 6/10 | Debug signing acceptable for beta APK; Play Store blocked until keystore configured |
| Reliability / Error Monitoring | 4/10 | 8/10 | CI injects DSN; GitHub Secret must be added |
| Test Coverage | 1/10 | 7/10 | 45 tests, 0 failures; `flutter analyze` clean |
| Code Quality | 7/10 | 9/10 | 0 analyzer issues |
| UI / UX | 7/10 | 8/10 | Image cap, correct app name |
| Architecture | 7/10 | 8/10 | All endpoints now authenticated |

---

## What Changed Since the Original Audit

| # | Issue | Status | Resolution |
|---|---|---|---|
| 1 | Access tokens printed to `logcat` | ✅ Fixed | Print statements removed from `device_auth_service.dart` |
| 2 | Multi-evidence verification unauthenticated | ✅ Fixed | `authenticatedPost()` with HMAC signing — same as all other endpoints |
| 3 | Release APK signed with debug key | ⏳ Deferred | User decision — acceptable for beta APK distribution; keystore steps pre-written in `release.yml` |
| 4 | Zero automated tests | ✅ Fixed | 45 unit tests across models and provider state machine |
| 5 | Sentry DSN empty in builds | ✅ Fixed | Both CI pipelines pass `--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}`; `sentry.properties` documents all required fields |
| 6 | `firebase_analytics` git override | ⚠️ Open | Still pinned to unpublished commit — see below |
| 7 | No image count cap | ✅ Fixed | Hard cap at 4; Add Photo button disappears after 4 |
| 8 | App name mismatch `'DrugChecker'` | ✅ Fixed | `MaterialApp.title` and `android:label` both read `'MedVerify'` |
| 9 | Missing `ACCESS_COARSE_LOCATION` | ✅ Fixed | Added alongside `ACCESS_FINE_LOCATION` |
| 10 | Unused `RECEIVE_BOOT_COMPLETED` | ✅ Fixed | Removed from manifest; commented receiver code also removed |
| 11 | ProGuard rules | ✅ Verified | File exists with standard Flutter keep rules |
| 12 | API timeout may be too short | ⚠️ Open | 30s `receiveTimeout` still applies to the verification call — see below |
| 13 | `pubspec.yaml` placeholder description | ✅ Fixed | Updated to proper product description |
| 14 | 2 `flutter analyze` warnings | ✅ Fixed | Unused import and unused catch variable removed |
| 15 | Cleartext traffic + backup risks | ✅ Fixed | `usesCleartextTraffic="false"` and `allowBackup="false"` added to manifest |

---

## Remaining Open Items

### 1. `SENTRY_DSN` GitHub Secret Must Be Added — Action Required

The code and CI pipeline are correctly wired. The only missing step is adding the actual DSN as a repository secret. Until this is done, the release APK will be built with an empty DSN and Sentry will be silently disabled.

**Action:** In your GitHub repo → Settings → Secrets and variables → Actions → New repository secret:
- Name: `SENTRY_DSN`
- Value: your Sentry DSN (found at `https://sentry.io/settings/<org>/projects/<project>/keys/`)

This is a 2-minute step and must be done before the first monitored release.

---

### 2. Production Keystore — Deferred

**Status:** Acceptable for beta APK distribution via GitHub releases. The release workflow builds an APK signed with the debug key, which works for direct installation but cannot be published to Google Play.

**When ready:** The `release.yml` workflow already has the keystore steps pre-written as commented-out blocks. Steps:
1. Generate a keystore: `keytool -genkey -v -keystore medverify-release.jks -alias medverify -keyalg RSA -keysize 2048 -validity 10000`
2. Base64-encode it: `base64 medverify-release.jks | tr -d '\n'`
3. Add four GitHub Secrets: `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`
4. Uncomment the two keystore steps in `release.yml`

---

### 3. `firebase_analytics` Pinned to Unpublished Git Commit — Medium Risk

**File:** [pubspec.yaml](pubspec.yaml)

The `dependency_overrides` block pins `firebase_analytics` to commit `ea4aa777` in the FlutterFire repo. This is not a published release. The risk is that:
- The commit may have had a bug that was reverted before the next stable release
- Future `flutter pub upgrade` runs will still pull from that specific commit
- The dependency is non-auditable by standard package tooling

**Action:** Test whether the override can be removed:
```bash
# Remove the dependency_overrides block in pubspec.yaml, then:
flutter pub upgrade firebase_analytics
flutter pub get
# If the app builds and analytics events appear in the Firebase console, the override is safe to remove.
```
If removal causes a build failure, document the reason in a comment next to the override so the team knows when it is safe to remove.

---

### 4. `receiveTimeout: 30s` May Cause False Failures on Verification

**File:** [lib/services/api_client.dart](lib/services/api_client.dart)

The shared Dio instance has a 30-second `receiveTimeout`. The verification endpoint processes uploaded images through an AI/ML pipeline. On a slow mobile connection, or with 4 images, the server may take longer than 30 seconds to respond — causing the user to see a timeout error even though the server successfully processed the request.

**Recommendation:** Either increase `receiveTimeout` to `Duration(seconds: 90)` on `ApiClient`, or create a dedicated Dio instance in `MultiEvidenceVerificationService` with a longer timeout for that specific call only.

---

## Pre-Launch Checklist

| Task | Owner | Done? |
|---|---|---|
| Add `SENTRY_DSN` GitHub Secret | Dev | ☐ |
| Test end-to-end verify flow on a physical device | QA | ☐ |
| Confirm Firebase Analytics events appear in the console | Dev | ☐ |
| Confirm Sentry receives a test error after first CI build | Dev | ☐ |
| Verify the `release` branch push triggers `release.yml` correctly | Dev | ☐ |
| Decide on `firebase_analytics` override — remove or document | Dev | ☐ |

---

## What Is Now Solid

- **Security:** No credentials or tokens logged anywhere. All API endpoints (including the new multi-evidence flow) are HMAC-signed. Device auth uses `FlutterSecureStorage`. Manifest blocks cleartext traffic and disallows backup of sensitive data.
- **CI/CD:** Push to `master` triggers analyze → test → debug APK build. Push to `release` branch builds and publishes a GitHub release. Both pass Sentry DSN at build time.
- **Tests:** 45 unit tests covering all JSON parsers (every field, every enum, null-safety), and all provider state transitions (add/remove images, cap enforcement, reset, `hasEvidence`).
- **Static analysis:** `flutter analyze` returns 0 issues.
- **Monitoring:** Sentry SDK integrated with 20% traces and profiles sample rate; ready to receive events as soon as the DSN secret is added.
