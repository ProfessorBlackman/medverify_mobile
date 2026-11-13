# MedVerify Mobile — Production Readiness Audit (Re-audit)

**Original audit:** 2026-05-31  
**Re-audit date:** 2026-06-02  
**Auditor:** Claude Code  
**Scope:** Full Dart codebase (`lib/`), `pubspec.yaml`  
**App version audited:** 1.0.0+1

---

## Production Readiness Score: 5.5 / 10

The security and data-integrity work completed between the original audit and this re-audit
was substantial — the original Critical (concurrent token refresh race), all five High-severity
security gaps, and most Medium findings are now resolved. However, a fresh pass of the codebase
reveals **three new Critical issues** and **six new High issues** that must be fixed before any
public release. The app cannot go to production in its current state.

---

## Severity Legend

| Level        | Meaning                                                                      |
|--------------|------------------------------------------------------------------------------|
| **Critical** | Repeatable crash or data/security breach in production                       |
| **High**     | Will cause incorrect behaviour, data loss, or serious security weakness      |
| **Medium**   | Degrades reliability or UX in common scenarios                               |
| **Low**      | Code quality, build hygiene, or minor UX polish                              |

---

## Part 1 — Resolved Since Original Audit

All items below were confirmed fixed by code inspection.

| ID       | Finding                                                   | Fix applied                                                 |
|----------|-----------------------------------------------------------|-------------------------------------------------------------|
| SEC-01   | Concurrent token refresh wipes device identity (Critical) | `Completer` mutex in `_refreshTokens`                       |
| SEC-02   | URL query parameters not encoded                          | `Uri.replace(queryParameters: ...)`                         |
| SEC-03   | No timeout on `registerDevice` / `_refreshTokens`         | `.timeout(Duration(seconds: 30))`                           |
| SEC-04   | Sentry DSN hardcoded in source                            | `String.fromEnvironment('SENTRY_DSN')`                      |
| SEC-05   | FCM URL handler allows any HTTPS domain                   | `_trustedDomains` allowlist added                           |
| SEC-06   | User ID stored in unencrypted SharedPreferences           | Migrated to `DeviceAuthService.getUserId()`                 |
| SEC-07   | S3 upload URL not domain-validated                        | Host validated against `.amazonaws.com`                     |
| SEC-08   | FCM payload decoded without null/try-catch guard          | Null check + try-catch added                                |
| GAP-2    | Token refresh race condition                              | Same as SEC-01                                              |
| GAP-3    | Blocked device (403) not handled                          | `DeviceBlockedException` thrown and credentials cleared     |
| GAP-4    | Invalid signature (400) not handled                       | `SignatureException` + analytics event                      |
| GAP-5    | No connectivity check before requests                     | `requireConnectivity()` guard in all entry points           |
| GAP-6    | No file validation before upload                          | MIME type + 10 MB size check in `FileUploadService`         |
| GAP-7    | No upload retry logic                                     | Dio with 3-attempt exponential backoff                      |
| GAP-8    | No upload progress tracking                               | `onSendProgress` callback threaded to `FeedbackScreen`      |
| GAP-9    | Zero security analytics events                            | Six events wired (registration, refresh, signature, upload) |
| GAP-10   | Dead parallel identity (`user_identification.dart`)       | File deleted; analytics reads from secure storage           |
| DAT-01   | `updateResult` uses timestamp as lookup key (type error)  | UUID `id` field added; Hive keyed by UUID                   |
| DAT-02   | DateTime serialized in local timezone                     | `.toUtc().toIso8601String()` in `toMap`                     |
| DAT-03   | Unknown drug status silently becomes `pending`            | Logs to Sentry; defaults to `unregistered` (red)            |
| DAT-04   | `_loadHistoryFromDb` no error handling                    | `try/catch/finally` with Sentry capture                     |
| DAT-05   | Hive history order not guaranteed                         | Explicit `scannedAt` descending sort                        |
| STATE-01 | `clearHistory()` not awaited                              | `async/await` + `context.mounted` guard                     |
| STATE-02 | Async work in `AppProvider` constructor                   | `init()` awaited in `main()` before `runApp`                |
| NET-01   | `catchError` return type mismatch on scan analytics       | `async` lambda with typed `Object e` parameter              |
| NET-02   | Double exception wrapping and double Sentry capture       | Outer catch removed; specific catches for Timeout/Socket    |
| NET-03   | Response not type-guarded before `.map()`                 | `decoded is! List` check added                              |
| NET-04   | Timeout clock starts after auth resolves                  | Same fix as SEC-03                                          |
| CODE-01  | Dead `user_identification.dart` parallel identity system  | File deleted                                                |
| CODE-02  | Committed ngrok dev URL                                   | Line deleted from `variables.dart`                          |
| CODE-03  | New `unique_code` generated per retry                     | UUID generated in `logDrugScan`, passed as parameter        |
| CODE-04  | FCM topics subscribed unconditionally on every cold start | SharedPreferences gate + `unsubscribeFromTopics()`          |
| UX-01    | Splash screen fake progress bar                           | Real async steps drive progress; no blank-screen wait       |
| UX-02    | Hardcoded version string in splash screen                 | `PackageInfo.fromPlatform()` used                           |
| UX-03    | Hardcoded `app_version: '1.0.0'` in `registerDevice`      | `PackageInfo.fromPlatform()` used                           |

---

## Part 2 — New Findings (Re-audit)

---

### Critical

---

### CRIT-01 — Scanner crashes on unregistered barcode (every failed scan)

**File:** `lib/screens/scanner_screen.dart`

After `results.isEmpty` is detected a `Navigator.push(ManualEntryScreen)` is called with no
`return`. Execution falls through to `results.first` on the empty set, throwing
`StateError: No element`. The `catch` block then pushes `ManualEntryScreen` a second time,
leaving two copies on the navigation stack.

**Impact:** Every scan of a drug not in the FDA database — a core real-world scenario — crashes
the scanner. This is a repeatable, user-facing crash on the app's primary feature.

---

### CRIT-02 — Product improvement writes are completely unauthenticated

**File:** `lib/screens/results_screen.dart`, `_uploadProductImprovements()`

```dart
final url = Uri.parse('$backendUrl/update_product');
// ...
await http.post(url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(body),
);
```

No `Authorization` header, no HMAC signature, no device ID. Any HTTP client can submit
arbitrary `barcode`, `image_url`, or `price` values for any `registration_number` to the FDA
drug database without authentication.

**Impact:** Anyone who reverse-engineers the API endpoint (trivial from the app binary) can
corrupt product records for any drug in Ghana's FDA registry. This is a critical data-integrity
and safety issue for a medical application.

---

### CRIT-03 — 401 refresh failure silently swallowed; callers receive stale response

**File:** `lib/services/device_auth_service.dart`, `authenticatedPost()`

```dart
if (response.statusCode == 401) {
  try {
    await _refreshTokens();
    response = await doRequest();
  } catch (e) {
    await Sentry.captureException(e); // no rethrow
  }
}
```

When `_refreshTokens()` fails (expired refresh token, network error), the exception is captured
to Sentry and then **swallowed**. `authenticatedPost` returns the original `401` response
object. All callers (`FeedbackService`, `FileUploadService`, `AnalyticsService`) only check for
success status codes and silently treat the failed request as having succeeded or failed for an
unknown reason.

**Impact:** After a session expires, background operations silently fail with no user feedback.
Feedback submissions appear to succeed but are never delivered.

---

### High

---

### HIGH-01 — FCM `route` payload navigates to any registered route without allowlist

**File:** `lib/services/notifications_service.dart`, `handleMessage()`

```dart
final route = data['route'] as String?;
if (route != null && route.startsWith('/')) {
  navigatorKey.currentState?.pushNamed(route);
}
```

Any FCM message can navigate the user to `/results` (crashes — no arguments), `/welcome`
(resets the onboarding UI), or any other registered route. A trusted-domain check exists for
URL payloads but nothing equivalent exists for route payloads.

---

### HIGH-02 — `VerificationStatus.values[int]` throws `RangeError` on out-of-range Hive data

**File:** `lib/models/verification_result.dart`, `fromMap()`

```dart
status: map['status'] != null
    ? VerificationStatus.values[map['status'] as int]
    : null,
```

If the enum is reordered (any new status inserted before an existing one), or a Hive record
was written with a corrupt index, this throws an uncaught `RangeError`. One bad record breaks
`fetchHistory()` for the entire app with no recovery path. The `as int` cast also throws
`TypeError` if Hive deserializes the value as `double` (which MessagePack can do).

---

### HIGH-03 — Video files accepted in UI but silently discarded by upload service

**File:** `lib/screens/feedback_screen.dart` vs `lib/services/file_upload_service.dart`

The feedback screen lets users attach a video (up to 20 MB), shows it in the attachments list,
and shows "Feedback sent successfully!" after submit. `FileUploadService._allowedMimeTypes`
only permits `image/jpeg`, `image/png`, `image/webp`, and `application/pdf`. Any `video/*`
file hits `FileValidationException`, returns `UploadResult.failure`, and is silently skipped
by `FeedbackService`. The user's video is never uploaded and they are never told.

---

### HIGH-04 — Loading flags never reset on exception in `ResultsScreen`

**File:** `lib/screens/results_screen.dart`

`_takeAndUploadPhoto`, `_scanAndAddBarcode`, and `_addPrice` all set `_isUploadingPhoto`,
`_isSendingBarcode`, or `_isAddingPrice` to `true` with no `try/finally` block. If any
downstream call throws (`DeviceBlockedException`, network error, etc.), the flag stays `true`
for the entire session — the loading spinner is permanent and the buttons stay disabled.

---

### HIGH-05 — `doRequest()` inside `authenticatedPost` has no HTTP timeout

**File:** `lib/services/device_auth_service.dart`

`registerDevice` and `_refreshTokens` have `.timeout(Duration(seconds: 30))`, but the inner
`doRequest()` closure that handles every other endpoint (`/feedback`, `/analytics/scan`,
`/generate-upload-url`, `/confirm-upload`, `/update_product`) has no timeout. Requests can
hang indefinitely on a stalled connection.

---

### HIGH-06 — `firebase_analytics` pinned to an unversioned mutable git branch

**File:** `pubspec.yaml`

```yaml
dependency_overrides:
  firebase_analytics:
    git:
      url: https://github.com/firebase/flutterfire.git
      ref: analytics_18297
```

`ref: analytics_18297` is a branch name, not a commit SHA. Its HEAD can be rewritten at any
time. A `flutter pub get` after such a rewrite silently pulls a different commit into the
production build. This also bypasses the `pub.dev` package signing chain entirely.

---

### Medium

---

### MED-01 — Duplicate notification listeners registered twice

**File:** `lib/services/notifications_service.dart`

`initNotifications()` registers `getInitialMessage().then(handleMessage)` and
`FirebaseMessaging.onMessageOpenedApp.listen(handleMessage)` (lines 61–64), then immediately
calls `initPushNotifications()` which registers the same two handlers again (lines 115–118).
Every notification tap triggers `handleMessage` twice — double route pushes, double URL opens.

---

### MED-02 — All foreground notifications share `id: 0`, each overwrites the previous

**File:** `lib/services/notifications_service.dart`, line 138

```dart
_localNotifications.show(title: ..., body: ..., id: 0, ...);
```

Concurrent push notifications while the app is in the foreground silently discard all but the
last, because every notification replaces the one with `id: 0`.

---

### MED-03 — `AnalyticsService.logDrugScan` not awaited at call site

**File:** `lib/screens/results_screen.dart`

`AnalyticsService.instance.logDrugScan(...)` is called without `await`. The GPS request,
geocoding, and backend analytics POST all execute as untracked futures. Any exception thrown
by those paths is silently dropped (the outer fire-and-forget `.catchError` only covers
`_postScanToBackend`, not `logDrugScan` itself).

---

### MED-04 — `onTokenRefresh` listener discards its returned Future

**File:** `lib/services/notifications_service.dart`

```dart
_firebaseMessaging.onTokenRefresh.listen((newToken) {
  uploadTokenToServer(newToken); // future discarded
});
```

Any exception from `uploadTokenToServer` (auth failure, network error) becomes an unhandled
exception in the stream's async zone.

---

### MED-05 — `hive_generator` and `build_runner` in `dependencies` instead of `dev_dependencies`

**File:** `pubspec.yaml`

Both are code-generation dev tools. Having them in `dependencies` bundles them into the
production binary unnecessarily, increasing app size.

---

### MED-06 — Both `hive` and `hive_ce` listed as dependencies simultaneously

**File:** `pubspec.yaml`

`hive: ^2.2.3`, `hive_flutter: ^1.1.0`, and `hive_ce: ^2.16.0` are all present. `hive_ce` is
a community fork of `hive`. None of the service files import `hive_ce` — it appears unused.
Having both risks symbol collisions and inflates the binary.

---

### Low

---

### LOW-01 — `AppSettingsScreen` shows hardcoded `v1.0.0`

**File:** `lib/screens/app_settings_screen.dart`

The splash screen correctly reads from `PackageInfo.fromPlatform()`, but the settings screen
still shows the static string `'MedVerify v1.0.0'`. It will be wrong for every release after
the first.

---

### LOW-02 — `ModalRoute.of(context)!` force-unwrap in `ResultsScreen`

**File:** `lib/screens/results_screen.dart`

`ModalRoute.of(context)!` crashes if the screen is ever constructed outside a named route
(tests, deep-link navigation, embedding). Prefer a null-checked fallback or passing arguments
explicitly via the constructor.

---

### LOW-03 — `SENTRY_DSN` build-time omission produces a no-op Sentry instance with no warning

**File:** `lib/main.dart`

`const String.fromEnvironment('SENTRY_DSN')` resolves to `''` if `--dart-define` is omitted.
Sentry initialises silently in no-op mode. A CI step should assert the variable is non-empty
for release builds.

---

### LOW-04 — `backendUrl` has no environment separation

**File:** `lib/utils/variables.dart`

The production URL is hardcoded with no mechanism for a staging build. A `--dart-define`
approach (like the Sentry DSN) would allow QA builds to target a staging environment without
source edits.

---

## Part 3 — Recommended Fix Order

### Must fix before any public release (Critical)

1. **CRIT-01** — Add `return` after the empty-results navigation in scanner; guard `results.first`
2. **CRIT-02** — Route `_uploadProductImprovements` through `DeviceAuthService.authenticatedPost`
3. **CRIT-03** — Rethrow after capturing in the 401 catch block of `authenticatedPost`

### Fix before first external beta (High)

4. **HIGH-01** — Add a route allowlist to the FCM `route` handler
5. **HIGH-02** — Guard `VerificationStatus.values[int]` with bounds check; catch `TypeError`
6. **HIGH-03** — Either add `video/*` to `_allowedMimeTypes` or remove video from the feedback UI; notify the user on validation failure
7. **HIGH-04** — Wrap `_takeAndUploadPhoto`, `_scanAndAddBarcode`, and `_addPrice` in `try/finally` to reset flags
8. **HIGH-05** — Add `.timeout(const Duration(seconds: 30))` to `http.post` inside `doRequest()`
9. **HIGH-06** — Pin `firebase_analytics` override to an immutable commit SHA or remove the override once the issue it works around is resolved upstream

### Fix before v1.1 (Medium)

10. **MED-01** — Remove the duplicate listener registrations in `initNotifications` or `initPushNotifications`
11. **MED-02** — Use `notification.hashCode` (or a counter) as the notification ID
12. **MED-03** — `await AnalyticsService.instance.logDrugScan(...)` at the call site
13. **MED-04** — Add `.catchError((_) {})` to the `onTokenRefresh` listener callback
14. **MED-05** — Move `hive_generator` and `build_runner` to `dev_dependencies`
15. **MED-06** — Remove the unused `hive_ce` dependency

### Nice-to-have (Low)

16. **LOW-01** — Read version in `AppSettingsScreen` from `PackageInfo.fromPlatform()`
17. **LOW-02** — Null-check `ModalRoute.of(context)` in `ResultsScreen`
18. **LOW-03** — Add a CI assertion that `SENTRY_DSN` is non-empty for release builds
19. **LOW-04** — Move `backendUrl` to `--dart-define` for environment separation

---

## Summary

| Category          | Critical | High | Medium | Low |
|-------------------|----------|------|--------|-----|
| Crashes / Safety  | 1        | 0    | 0      | 0   |
| Security          | 1        | 2    | 0      | 0   |
| Data Integrity    | 1        | 1    | 0      | 0   |
| State / UI        | 0        | 2    | 1      | 1   |
| Reliability       | 0        | 1    | 2      | 0   |
| Build / Deps      | 0        | 1    | 2      | 2   |
| **Total**         | **3**    | **7**| **5**  | **3**|
