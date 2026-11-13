# Security Client Layer — Gap Analysis & Implementation Plan

**Spec:** Mobile Anonymous Identity & Security Client Layer (Draft v1)  
**Date:** 2026-05-31  
**Status:** Pending consent to implement

---

## Part 1 — What Is Already Implemented

The following spec sections are fully or substantially satisfied by the code introduced in the backend migration.

| Spec Section           | Requirement                                                  | File                                             | Status    |
|------------------------|--------------------------------------------------------------|--------------------------------------------------|-----------|
| §4 First Launch Flow   | Check existing identity                                      | `DeviceAuthService.isRegistered()`               | ✅ Done    |
| §4 First Launch Flow   | Generate UUID identity                                       | `DeviceAuthService.registerDevice()`             | ✅ Done    |
| §4 First Launch Flow   | Register with backend                                        | `POST /register-device`                          | ✅ Done    |
| §4 First Launch Flow   | Store all tokens                                             | `FlutterSecureStorage`                           | ✅ Done    |
| §5 Device Identity     | `device_public_id → UUID`                                    | `Uuid().v4()` in `registerDevice`                | ✅ Done    |
| §5 Device Identity     | Persist across sessions                                      | Secure storage, survives restart                 | ✅ Done    |
| §5 Device Identity     | Regenerate only after wipe                                   | `ensureRegistered` checks before re-registering  | ✅ Done    |
| §6 Secure Storage      | Android Keystore / iOS Keychain                              | `flutter_secure_storage` uses these natively     | ✅ Done    |
| §6 Secure Storage      | Store device secret, tokens, device ID                       | All five keys in `FlutterSecureStorage`          | ✅ Done    |
| §7 API Request Headers | `Authorization`, `X-Device-ID`, `X-Timestamp`, `X-Signature` | `RequestSigner.buildHeaders()`                   | ✅ Done    |
| §8 Request Signing     | HMAC-SHA256 algorithm                                        | `RequestSigner._computeSignature()`              | ✅ Done    |
| §8 Request Signing     | Centralized interceptor                                      | `DeviceAuthService.authenticatedPost()`          | ✅ Done    |
| §8 Request Signing     | Automatic signing                                            | All protected endpoints use `authenticatedPost`  | ✅ Done    |
| §9 Token Management    | Automatic refresh                                            | `getValidAccessToken()`                          | ✅ Done    |
| §9 Token Management    | Refresh before expiry (60s window)                           | `getValidAccessToken()`                          | ✅ Done    |
| §9 Token Management    | Silent renewal                                               | Transparent to all callers                       | ✅ Done    |
| §9 Token Management    | 401 → Refresh → Retry                                        | `authenticatedPost` 401 branch                   | ✅ Done    |
| §10 Upload Workflow    | Get upload permission (signed request)                       | `FileUploadService._getPresignedUrl()`           | ✅ Done    |
| §10 Upload Workflow    | Receive upload URL                                           | Parsed from presigned URL response               | ✅ Done    |
| §10 Upload Workflow    | Upload file to S3                                            | `FileUploadService._uploadToS3()`                | ✅ Done    |
| §10 Upload Workflow    | Notify backend after upload                                  | `FileUploadService._confirmUpload()`             | ✅ Done    |
| §11 Failure Handling   | Expired tokens                                               | 401 → refresh → retry in `authenticatedPost`     | ✅ Done    |
| §11 Failure Handling   | Upload failures logged                                       | Sentry `captureException` in `FileUploadService` | ✅ Partial |

---

## Part 2 — What Is Not Implemented (Gaps)

### GAP-1 — `device_secret` generated server-side, not client-side (§5)

**Spec says:** `device_secret → 256-bit random` under "Generate" — implying client generation.

**Current behaviour:** The server generates `device_secret` and returns it in the `POST /register-device` response. The client stores it as received.

**Assessment:** This is a conflict between this spec and the FLUTTER_MIGRATION_GUIDE, which explicitly states *"Returned once by POST /register-device. Never returned again."* Transmitting the secret over the wire (even over TLS) is weaker than generating it locally and never sending it. True zero-knowledge would have the client generate a random 256-bit secret and send only a public proof during registration. **This requires a coordinated backend API change** and cannot be fixed client-side alone. It is flagged here for discussion; the remaining plan assumes the current server-returns-secret model until the backend team confirms a change.

---

### GAP-2 — Signing is not race-condition safe (§8 "retry-safe")

**File:** `lib/services/device_auth_service.dart`

**Current behaviour:** `authenticatedPost` calls `getValidAccessToken()`, which may call `_refreshTokens()`. If two `authenticatedPost` calls run concurrently (e.g., scan analytics fires at the same time as file upload), both enter `_refreshTokens()` simultaneously. The first refresh rotates the refresh token. The second refresh uses the now-invalidated old token, gets a `401`, triggers `_storage.deleteAll()`, and silently wipes the entire device identity.

**Spec requirement §8:** "Retry-safe" — signing and token management must be safe under concurrent use.

---

### GAP-3 — Blocked device (403) not handled distinctly (§11)

**File:** `lib/services/device_auth_service.dart` line 167

**Current behaviour:** `authenticatedPost` only branches on `statusCode == 401`. A `403` (device blocked by backend admin or risk system) is returned to the caller as a raw `http.Response` with no special handling. Callers (feedback, file upload, analytics) all silently return `false`/`null` without surfacing the block to the user.

**Spec requirement §11:** "Blocked device" is an explicit failure case that must be handled.

---

### GAP-4 — Invalid signature (400) not handled distinctly (§11)

**File:** `lib/services/device_auth_service.dart`

**Current behaviour:** A `400` response (missing or malformed signature headers) is returned raw to callers. There is no logging to Firebase Analytics or distinct user message.

**Spec requirement §11:** "Invalid signatures" is an explicit failure case.

---

### GAP-5 — No connectivity check before requests (§11)

**Current behaviour:** All network calls proceed unconditionally. When the device is offline, every call throws a `SocketException` which bubbles up as a generic Sentry event and a non-specific error to the user.

**Spec requirement §11:** "Connectivity loss" is an explicit failure case that must be handled.

---

### GAP-6 — No file validation before upload (§10)

**File:** `lib/services/file_upload_service.dart` `_getPresignedUrl()`

**Current behaviour:** The file's MIME type is looked up, but there is no validation that the MIME type is on the server's allowlist, or that the file size is within the 10 MB limit. The first signal of a bad file is the backend returning a `422` or S3 rejecting the PUT — both are silent to the user.

**Spec requirement §10:** "Validate file locally first."

Allowed types per backend spec: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`. Max size: 10 MB.

---

### GAP-7 — No upload retry logic (§10)

**File:** `lib/services/file_upload_service.dart` `_uploadToS3()`

**Current behaviour:** If the S3 PUT fails (timeout, transient network error), the method returns `false` immediately with no retry.

**Spec requirement §10:** "Retry uploads."

---

### GAP-8 — No upload progress tracking (§10)

**File:** `lib/services/file_upload_service.dart` `_uploadToS3()`

**Current behaviour:** `http.put` sends the full file bytes in a single call. There is no progress callback. Large files (up to 10 MB) produce no UI feedback.

**Spec requirement §10:** "Track progress."

---

### GAP-9 — Zero analytics events for security layer (§12)

**Spec requires tracking:**

| Event                | Currently tracked?                      |
|----------------------|-----------------------------------------|
| Registration success | ❌                                       |
| Registration failure | ❌                                       |
| Upload failure       | ❌ (Sentry only, not Firebase Analytics) |
| Signature failure    | ❌                                       |
| Token refresh event  | ❌                                       |

Without these events, the §13 success metrics (>99% registration success, <1% refresh failures, <2% upload failures) cannot be measured.

---

### GAP-10 — `user_id` still in SharedPreferences (§6)

**File:** `lib/utils/user_identification.dart`  
**Callers:** `lib/services/analytics_service.dart` line 72

**Current behaviour:** `getUserId()` reads/writes a UUID from unencrypted `SharedPreferences`. `analytics_service.dart` calls this instead of `DeviceAuthService.instance.getUserId()`, so the Firebase Analytics user ID is a *different identity* from the backend's authenticated `user_id`.

**Spec requirement §6:** "Never store plain secrets in shared preferences." Device IDs are identity material and fall under this requirement.

---

## Part 3 — Implementation Plan

Changes are grouped by which file owns them, ordered from foundational (must land first) to additive.

---

### Phase 1 — Fix the refresh race condition (GAP-2)

**File:** `lib/services/device_auth_service.dart`

Add a `Completer<void>?` field (`_refreshCompleter`) as a mutex. When `_refreshTokens()` is called while a refresh is already in progress, new callers await the in-flight `Completer` instead of starting a second refresh. The `Completer` is always cleared in a `finally` block. This is the most important change because all other phases depend on `authenticatedPost` being safe.

No other files change in this phase.

---

### Phase 2 — Migrate `analytics_service.dart` off `user_identification.dart` (GAP-10)

**Files:** `lib/services/analytics_service.dart`, `lib/utils/user_identification.dart`

Replace `getUserId()` call (which reads from SharedPreferences) with `await DeviceAuthService.instance.getUserId()` (reads from secure storage). The `user_identification.dart` file becomes unused and is deleted. The Firebase Analytics user ID now matches the backend user_id.

---

### Phase 3 — Add blocked-device and signature-failure handling (GAP-3, GAP-4)

**File:** `lib/services/device_auth_service.dart`

Extend `authenticatedPost` to explicitly branch on `403` and `400`:

- **403 (device blocked):** Clear credentials (device cannot recover), throw a typed `DeviceBlockedException`. Callers surface this to the user with a permanent message: "This device has been blocked. Please contact support." The app must not silently retry.
- **400 (bad signature):** Log to Firebase Analytics as `signature_failure` event (see Phase 5), throw a typed `SignatureException` so callers can distinguish it from a server error.

A custom exception class file (`lib/services/auth_exceptions.dart`) is created with `DeviceBlockedException` and `SignatureException` to give callers typed catches.

---

### Phase 4 — Add connectivity check (GAP-5)

**Package addition:** `connectivity_plus: ^6.0.0` in `pubspec.yaml`

**New file:** `lib/utils/network_guard.dart`  
A small utility `requireConnectivity()` that checks the current `ConnectivityResult` and throws a `NoConnectivityException` (defined in `auth_exceptions.dart`) if offline.

**Usage:** Called at the top of `authenticatedPost`, `registerDevice`, and `_refreshTokens` before making any HTTP call. Callers already have error handling; they will now receive a meaningful exception rather than a `SocketException` timeout.

---

### Phase 5 — Add security analytics events (GAP-9)

**File:** `lib/services/device_auth_service.dart`, `lib/services/file_upload_service.dart`

Add private calls to `AnalyticsService.instance.logCustomEvent(...)` at the following points:

| Location                                     | Event name                    | Parameters                       |
|----------------------------------------------|-------------------------------|----------------------------------|
| `registerDevice` — success path              | `device_registration_success` | `platform`                       |
| `registerDevice` — catch block               | `device_registration_failure` | `error_type`                     |
| `_refreshTokens` — success path              | `token_refresh_success`       | _(none)_                         |
| `_refreshTokens` — 401/403 path              | `token_refresh_failure`       | `status_code`                    |
| `authenticatedPost` — 400 branch             | `signature_failure`           | `path`                           |
| `FileUploadService.uploadFile` — null return | `upload_failure`              | `stage` (presign/upload/confirm) |

These events directly feed the §13 success metrics.

---

### Phase 6 — Add client-side file validation (GAP-6)

**File:** `lib/services/file_upload_service.dart`

Add a `_validateFile(File file)` method called at the start of `uploadFile`, before `_getPresignedUrl`. It checks:

1. **MIME type:** Must be one of `image/jpeg`, `image/png`, `image/webp`, `application/pdf`. Throws `FileValidationException` (added to `auth_exceptions.dart`) with a user-readable message if not.
2. **File size:** Must be ≤ 10 MB (`file.lengthSync()`). Throws `FileValidationException` if exceeded.

`uploadFile` catches `FileValidationException` separately from generic errors, logs it at a lower severity (not Sentry — it's user error), and returns a typed failure result so the UI can show the specific constraint that was violated.

A small model change is needed: change `Future<String?>` to return a result type that carries either a URL or an error reason, so the calling screen (feedback screen) can display "File too large" vs "Unsupported file type" vs "Upload failed".

---

### Phase 7 — Add upload retry with progress (GAP-7, GAP-8)

**Package addition:** `dio: ^5.7.0` in `pubspec.yaml` (replaces the raw `http.put` for S3 only — the rest of the app stays on `http`)

**File:** `lib/services/file_upload_service.dart`

Replace `_uploadToS3` with a Dio-based implementation that:

1. **Progress callback:** `onSendProgress: (sent, total) => progressCallback(sent / total)` — a `void Function(double)?` parameter threaded from `uploadFile` through to the call site.
2. **Retry logic:** Up to 3 attempts with exponential backoff (1s, 2s, 4s) on timeout or 5xx responses. Each retry logs a `upload_retry` Firebase Analytics event.

The `uploadFile` signature gains an optional `void Function(double progress)?` parameter. The feedback screen wires it to a `ValueNotifier<double>` that drives a linear progress indicator.

---

### Summary of File Changes

| File                                    | Action                                                                | Phases     |
|-----------------------------------------|-----------------------------------------------------------------------|------------|
| `pubspec.yaml`                          | Add `connectivity_plus`, `dio`                                        | 4, 7       |
| `lib/services/device_auth_service.dart` | Refresh mutex; 403/400 handling; analytics events; connectivity guard | 1, 3, 4, 5 |
| `lib/services/auth_exceptions.dart`     | **Create** — typed exceptions                                         | 3, 4, 6    |
| `lib/utils/network_guard.dart`          | **Create** — connectivity utility                                     | 4          |
| `lib/services/analytics_service.dart`   | Migrate off `user_identification.dart`                                | 2          |
| `lib/utils/user_identification.dart`    | **Delete**                                                            | 2          |
| `lib/services/file_upload_service.dart` | File validation; Dio-based retry + progress                           | 5, 6, 7    |
| `lib/screens/feedback_screen.dart`      | Wire upload progress indicator                                        | 7          |

---

### Note on GAP-1 (device_secret ownership)

This gap requires a backend API change — the server would need to accept a client-generated secret during registration rather than generating one itself. **No client work is planned for this gap** until the backend team confirms the API will be updated. Once confirmed, the change is:

- Generate `crypto.getRandomValues(Uint8List(32))` locally in `registerDevice`
- Convert to 64-char hex and include in the `POST /register-device` body
- Do not store the secret in the response — it was never sent there
- The server stores the public key of the secret (or the hash) for later verification

---

### Dependency on PRODUCTION_AUDIT.md

Two issues in `PRODUCTION_AUDIT.md` are closely related to this plan and should be fixed in the same pass:

- **SEC-01** (audit) = **GAP-2** (this plan) — same root cause, same fix (Phase 1)
- **SEC-06** (audit) = **GAP-10** (this plan) — same fix (Phase 2)

Fixing GAP-2 and GAP-10 here closes those audit findings without separate work.
