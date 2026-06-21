# MedVerify Mobile API Reference

**Base URL:** `https://medverify-api.methuselah.site`  
**API version prefix:** `/v1`  
**Full API base:** `https://medverify-api.methuselah.site/v1`

---

## Table of Contents

1. [Authentication Overview](#1-authentication-overview)
2. [Request Signing](#2-request-signing)
3. [Token Lifecycle](#3-token-lifecycle)
4. [Device Registration & Auth](#4-device-registration--auth)
5. [Product Verification](#5-product-verification)
6. [Feedback](#6-feedback)
7. [File Uploads](#7-file-uploads)
8. [Scans & Analytics](#8-scans--analytics)
9. [Push Notifications](#9-push-notifications)
10. [Error Reference](#10-error-reference)

---

## 1. Authentication Overview

There are two endpoint tiers:

| Tier | Auth required | Used for |
|---|---|---|
| **Public** | None | Product search and lookup |
| **Device authenticated** | Bearer JWT | All write operations (scan, feedback, upload) |
| **Device authenticated + signed** | Bearer JWT + HMAC headers | Write operations (replay-protected) |

### What you need to store securely

Use the platform's secure storage (Android Keystore / iOS Keychain / `flutter_secure_storage`) for all five of these. **Never store in SharedPreferences or UserDefaults.**

| Key | Description | Source |
|---|---|---|
| `device_public_id` | Your device's permanent identifier | You generate (UUID v4), confirmed in registration response |
| `device_secret` | 64-char hex signing key | Returned **once** by `POST /v1/register-device` — never returned again |
| `user_id` | Server-assigned identity | Returned by `POST /v1/register-device` |
| `access_token` | Short-lived JWT (30 min) | Registration + token refresh |
| `refresh_token` | Long-lived opaque token (90 days) | Registration + token refresh |

---

## 2. Request Signing

Every **write endpoint** (scan, feedback, file upload) requires four HTTP headers in addition to the request body:

```
Authorization: Bearer <access_token>
X-Device-ID:   <device_public_id>
X-Timestamp:   <unix_epoch_in_seconds>
X-Signature:   <hmac_sha256_hex>
```

### Signature algorithm

```
1. body_hash = SHA-256(raw_body_bytes).toHexString()     // lowercase hex
2. message   = METHOD + "\n" + PATH + "\n" + TIMESTAMP + "\n" + body_hash
3. key       = hexToBytes(device_secret)                  // 32 bytes from 64-char hex
4. signature = HMAC-SHA256(key, utf8Encode(message)).toHexString()
```

### Dart implementation

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

String computeSignature({
  required String deviceSecretHex,
  required String method,
  required String path,
  required String timestamp,
  required Uint8List body,
}) {
  final bodyHash = sha256.convert(body).toString();
  final message = '$method\n$path\n$timestamp\n$bodyHash';
  final keyBytes = _hexToBytes(deviceSecretHex);
  final hmacSha256 = Hmac(sha256, keyBytes);
  return hmacSha256.convert(utf8.encode(message)).toString();
}

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

Map<String, String> buildSignedHeaders({
  required String accessToken,
  required String devicePublicId,
  required String deviceSecretHex,
  required String method,
  required String path,
  required Uint8List body,
}) {
  final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final signature = computeSignature(
    deviceSecretHex: deviceSecretHex,
    method: method,
    path: path,
    timestamp: timestamp,
    body: body,
  );
  return {
    'Authorization': 'Bearer $accessToken',
    'X-Device-ID':   devicePublicId,
    'X-Timestamp':   timestamp,
    'X-Signature':   signature,
    'Content-Type':  'application/json',
  };
}
```

### Critical rules

- `PATH` is the URL path only — no query string, no domain.  
  ✅ `/v1/analytics/scan`  
  ❌ `https://medverify-api.methuselah.site/v1/analytics/scan`
- `TIMESTAMP` must be Unix epoch in **seconds**, not milliseconds, as a **string**.
- Serialise your JSON body **once** and use the exact same bytes for hashing and the HTTP body. Do not re-serialise.
- Empty body → `SHA-256(Uint8List(0))` — do not pass an empty string.
- The server rejects requests where `|server_time − X-Timestamp| > 300 seconds`. Keep device clock in sync with NTP.
- Signature comparison is **case-insensitive** on the server — always send lowercase.

---

## 3. Token Lifecycle

```
App first launch
    │
    ▼
Generate UUID v4 locally ────────────────────────────────────────────────┐
POST /v1/register-device                                                  │
    │                                                                     │
    ▼                                                                     │
Store securely:                                                           │
  device_public_id  ← use value from RESPONSE (may differ if collision)  │
  device_secret     ← store immediately; never returned again            │
  user_id                                                                 │
  access_token      ← valid 30 min                                       │
  refresh_token     ← valid 90 days                                      │
    │                                                                     │
    ▼                                                                     │
Before each API call:                                                     │
  Is access_token expiring within 60 s?                                  │
    YES → POST /v1/token/refresh                                         │
            ├─ 200: store new access_token + refresh_token               │
            └─ 401/403: tokens expired or device blocked                 │
                        → clear all credentials → re-register ──────────┘
```

**Refresh tokens rotate on every use.** After calling `POST /v1/token/refresh`, the old refresh token is immediately invalidated. Always store the new one returned in the response.

---

## 4. Device Registration & Auth

### `POST /v1/register-device`

Register a new device and receive credentials.

**Security:** None (public)  
**Rate limit:** 5 requests / hour per IP

**Request body:**

```json
{
  "device_public_id": "550e8400-e29b-41d4-a716-446655440000",
  "platform": "android",
  "app_version": "1.0.0"
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `device_public_id` | string | Yes | Valid UUID v4 (case-insensitive) |
| `platform` | string | No | `"android"` or `"ios"` |
| `app_version` | string | No | max 20 chars |

**Re-registration** (app reinstall with Keystore intact — proves ownership of existing device):

Add these headers when `device_public_id` already exists on the server:

```
X-Timestamp: <unix_epoch_seconds>
X-Signature: <hmac of empty body for /register-device>
```

Signature for re-registration: use `body = Uint8List(0)` (empty bytes) and `path = "/register-device"`.

**Response `201 Created`:**

```json
{
  "user_id": "a3f2b1c4-...",
  "device_public_id": "550e8400-...",
  "device_secret": "a1b2c3d4e5f6...64chars",
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "f7e8d9c0b1a2...64chars",
  "token_type": "bearer",
  "expires_in": 1800
}
```

> ⚠️ **`device_secret` is returned exactly once.** Store it immediately in hardware-backed secure storage. If lost, re-registration creates an entirely new identity — the old account is unrecoverable by design.

> ⚠️ **Always use the `device_public_id` from the response**, not the one you sent. In the rare case of a UUID collision without ownership proof, the server silently assigns a new identity with a different `device_public_id`.

**Registration scenarios:**

| Situation | Result |
|---|---|
| New `device_public_id` | Fresh identity created |
| Existing ID + valid signature headers | Secret rotated, new tokens issued, old tokens revoked |
| Existing ID + missing / invalid signature | New anonymous identity issued silently (different `device_public_id` in response) |

---

### `POST /v1/token/refresh`

Exchange a refresh token for a new access token and a rotated refresh token.

**Security:** None (public)  
**Rate limit:** 10 requests / hour per IP

**Request body:**

```json
{
  "refresh_token": "f7e8d9c0b1a2...64chars"
}
```

| Field | Type | Constraints |
|---|---|---|
| `refresh_token` | string | Exactly 64 chars |

**Response `200 OK`:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "new64chartoken...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

**Errors:**

| Status | Meaning | Action |
|---|---|---|
| `401` | Invalid or expired refresh token | Clear credentials → re-register |
| `403` | Device is blocked | Show user a message; do not retry |

---

### `PATCH /v1/device/fcm-token`

Attach or update the Firebase Cloud Messaging token for push notifications. Call this after registration and whenever `FirebaseMessaging.onTokenRefresh` fires.

**Security:** Bearer JWT (no HMAC signature required)  
**Rate limit:** 10 requests / hour per device

**Headers:**

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request body:**

```json
{
  "fcm_token": "cGVuZ3Vpbm1vYmlsZS..."
}
```

| Field | Type | Constraints |
|---|---|---|
| `fcm_token` | string | 1–500 chars |

**Response `200 OK`:**

```json
{ "status": "ok" }
```

---

## 5. Product Verification

All three endpoints are **public** — no authentication or headers required.

### `GET /v1/search`

Search for a drug by name or registration number using fuzzy matching.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Query parameters:**

| Param | Type | Required | Constraints |
|---|---|---|---|
| `search_term` | string | Yes | 1–200 chars |

**Example request:**

```
GET /v1/search?search_term=Paracetamol
```

**Response `200 OK`:**

```json
[
  {
    "status": "valid",
    "product_name": "Paracetamol 500mg Tablets",
    "manufacturer": "ABC Pharmaceuticals Ltd",
    "country_origin": "Ghana",
    "region": "Greater Accra",
    "registration_number": "GH-1234-56",
    "expiry_date": "2027-06-01",
    "registration_date": "2022-01-15",
    "active_ingredient": "Paracetamol",
    "email": "info@abcpharma.com.gh",
    "postal_address": "P.O. Box 123, Accra",
    "registration_type": "Local",
    "image_url": [
      "https://medverify-storage.s3.us-east-1.amazonaws.com/products/uuid.jpg"
    ],
    "barcode": "1234567890123",
    "category": "Analgesics",
    "price": "GHS 5.00"
  }
]
```

**`status` values:**

| Value | Meaning |
|---|---|
| `verified` | Confirmed by FDA Ghana |
| `valid` | Currently registered and within expiry |
| `invalid` | Registration invalid |
| `unregistered` | Not found in FDA Ghana registry |
| `expired` | Registration has expired |
| `recalled` | Product has been recalled |
| `near_expiry` | Expiring within threshold period |
| `pending` | Registration pending |
| `none` | Status could not be determined |

Returns an empty array `[]` if nothing is found.

---

### `GET /v1/reg_number`

Exact lookup by FDA registration number.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Query parameters:**

| Param | Type | Required | Constraints |
|---|---|---|---|
| `reg_number` | string | Yes | 1–100 chars |

**Example request:**

```
GET /v1/reg_number?reg_number=GH-1234-56
```

**Response `200 OK`:** Single product object (same shape as a search result item)

**Response `404 Not Found`:**

```json
{ "detail": "Product not found" }
```

---

### `GET /v1/barcode`

Look up products by barcode. A barcode may match multiple pack sizes.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Query parameters:**

| Param | Type | Required | Constraints |
|---|---|---|---|
| `bc` | string | Yes | 1–100 chars |

**Example request:**

```
GET /v1/barcode?bc=1234567890123
```

**Response `200 OK`:** Array of product objects (same shape as search results). Returns `[]` if nothing is found.

---

## 6. Feedback

### `POST /v1/feedback`

Submit user feedback about a product or the app.

**Security:** Bearer JWT + HMAC signature  
**Rate limit:** 20 requests / hour per device

**Headers:**

```
Authorization: Bearer <access_token>
X-Device-ID:   <device_public_id>
X-Timestamp:   <unix_epoch_seconds>
X-Signature:   <hmac_sha256_hex>
Content-Type:  application/json
```

**Request body:**

```json
{
  "feedback_type": "incorrect_info",
  "message": "The listed manufacturer name is incorrect for this product.",
  "name": "Kwame Mensah",
  "email": "kwame@example.com",
  "attachments": [
    "feedbacks/2026/06/550e8400-e29b-41d4-a716-446655440000.jpg"
  ]
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `feedback_type` | string | Yes | max 50 chars |
| `message` | string | Yes | 1–2000 chars |
| `name` | string | No | max 100 chars |
| `email` | string | No | valid email format |
| `attachments` | string[] | No | S3 file keys from upload flow |

> The `submitted_by` field (device's `user_id`) is always set server-side from the JWT. Any value you send in the body for this field is ignored.

**Response `201 Created`:**

```json
{
  "id": 42,
  "submitted_by": "a3f2b1c4-...",
  "feedback_type": "incorrect_info",
  "message": "The listed manufacturer name is incorrect for this product.",
  "name": "Kwame Mensah",
  "email": "kwame@example.com",
  "attachments": ["feedbacks/2026/06/uuid.jpg"],
  "created_at": "2026-06-02T09:30:00"
}
```

---

## 7. File Uploads

Uploads go directly to S3 — the backend generates a pre-authorised URL and the mobile app performs the upload without routing bytes through the server.

### Upload flow

```
1. POST /v1/generate-upload-urls  →  receive presigned S3 PUT URL(s)
2. PUT <upload_url>               →  upload bytes directly to S3
3. (optional) POST /v1/confirm-upload  →  verify the file arrived
4. Include the returned file_key(s) in your feedback / product update request
```

**Allowed file types:** `image/jpeg` · `image/png` · `image/webp` · `application/pdf`  
**Maximum file size:** 10 MB per file

---

### `POST /v1/generate-upload-urls`

Generate presigned URLs for multiple files in one call (e.g., front, back, and side photos of a product).

**Security:** Bearer JWT + HMAC signature  
**Rate limit:** 50 requests / hour per device

**Headers:** (same signed headers as feedback)

**Request body:**

```json
{
  "drug_name": "Paracetamol 500mg",
  "files": [
    { "file_name": "front.jpg", "content_type": "image/jpeg" },
    { "file_name": "back.jpg",  "content_type": "image/jpeg" }
  ]
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `drug_name` | string | Yes | max 255 chars; special characters stripped server-side |
| `files` | array | Yes | 1–10 items |
| `files[].file_name` | string | Yes | max 255 chars |
| `files[].content_type` | string | Yes | must be in the allowed MIME list |

**Response `200 OK`:**

```json
[
  {
    "upload_url": "https://medverify-storage.s3.amazonaws.com/products/paracetamol-500mg/uuid.jpg?X-Amz-Signature=...",
    "file_key": "products/paracetamol-500mg/uuid.jpg",
    "file_url": "https://medverify-storage.s3.us-east-1.amazonaws.com/products/paracetamol-500mg/uuid.jpg"
  }
]
```

**Step 2 — upload to S3:**

```dart
final response = await http.put(
  Uri.parse(uploadUrl),
  headers: {'Content-Type': contentType},
  body: fileBytes,
);
// Expect 200 from S3 on success
```

Store the `file_key` values and pass them in the `attachments` field when submitting feedback.

---

### `POST /v1/generate-upload-url`

Single-file variant.

**Security:** Bearer JWT + HMAC signature  
**Rate limit:** 50 requests / hour per device

**Headers:** (same signed headers)

**Request body:**

```json
{
  "file_name": "evidence.jpg",
  "content_type": "image/jpeg",
  "file_purpose": "feedback"
}
```

| Field | Type | Required | Values |
|---|---|---|---|
| `file_name` | string | Yes | max 255 chars |
| `content_type` | string | Yes | allowed MIME types only |
| `file_purpose` | string | No | `"improve"` (product image) · `"feedback"` (feedback attachment) |

**Response `200 OK`:** Single object with `upload_url`, `file_key`, `file_url`.

---

### `POST /v1/confirm-upload`

Verify a file successfully landed in S3 after uploading. Optional but recommended before referencing the file in a feedback submission.

**Security:** Bearer JWT + HMAC signature  
**Rate limit:** 50 requests / hour per device

**Headers:** (same signed headers, empty body)

**Query parameter:**

| Param | Type | Required | Description |
|---|---|---|---|
| `file_key` | string | Yes | The `file_key` from the generate URL response |

**Example:**

```
POST /v1/confirm-upload?file_key=products/paracetamol-500mg/uuid.jpg
```

**Response `200 OK`:**

```json
{ "status": "success", "message": "File upload confirmed" }
```

**Response `404 Not Found`:** File not found in S3 — the upload did not complete.

---

## 8. Scans & Analytics

### `POST /v1/analytics/scan`

Record a drug scan event. The server always attributes the scan to the authenticated device — any `scanned_by` value you send is ignored.

**Security:** Bearer JWT + HMAC signature  
**Rate limit:** 10 requests / minute per device

**Headers:** (same signed headers)

**Request body:**

```json
{
  "drug_name": "Paracetamol 500mg Tablets",
  "status": "Registered",
  "unique_code": "SCAN-20260602-ABC123",
  "timestamp": "2026-06-02T09:30:00",
  "reg_number": "GH-1234-56",
  "latitude": "5.6037",
  "longitude": "-0.1870",
  "region": "Greater Accra",
  "source": "barcode"
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `drug_name` | string | Yes | max 255 chars |
| `status` | string | Yes | max 50 chars — typically `"Registered"` or `"Unregistered"` |
| `unique_code` | string | Yes | max 100 chars — your locally generated scan identifier |
| `timestamp` | string | Yes | max 50 chars — ISO 8601 or Unix timestamp string |
| `reg_number` | string | No | max 100 chars |
| `latitude` | string | No | max 20 chars |
| `longitude` | string | No | max 20 chars |
| `region` | string | No | max 100 chars — Ghana administrative region |
| `source` | string | No | max 100 chars — e.g., `"barcode"`, `"manual"` |

**Response `201 Created`:** No body.

---

### `GET /v1/analytics/heatmap-data`

Retrieve scan locations for map visualisation.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Query parameters:**

| Param | Type | Default | Constraints |
|---|---|---|---|
| `status` | string | `"Unregistered"` | max 50 chars |
| `days` | integer | `30` | 1–365 |

**Example request:**

```
GET /v1/analytics/heatmap-data?status=Unregistered&days=30
```

**Response `200 OK`:**

```json
{
  "locations": [
    {
      "lat": "5.6037",
      "lng": "-0.1870",
      "drug_name": "Counterfeit Amoxicillin",
      "timestamp": "2026-06-01T14:22:00",
      "region": "Greater Accra"
    }
  ],
  "total_count": 38
}
```

---

### `GET /v1/analytics/regional-stats`

Scan counts grouped by Ghana administrative region.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Query parameters:**

| Param | Type | Default | Constraints |
|---|---|---|---|
| `status` | string | `"Unregistered"` | max 50 chars |

**Response `200 OK`:**

```json
{
  "regional_data": [
    { "region": "Greater Accra", "count": 42 },
    { "region": "Ashanti",       "count": 27 },
    { "region": "Western",       "count": 11 }
  ]
}
```

---

### `GET /v1/analytics/summary-stats`

Overall scan totals and 7-day trend data.

**Security:** None  
**Rate limit:** 30 requests / minute per IP

**Response `200 OK`:**

```json
{
  "total": 1250,
  "registered": 820,
  "unregistered": 430,
  "recent_trends": [
    { "date": "2026-06-02", "count": 47 },
    { "date": "2026-06-01", "count": 61 },
    { "date": "2026-05-31", "count": 53 }
  ]
}
```

---

## 9. Push Notifications

### `POST /subscribe-user/`

Subscribe a device's FCM token to a notification topic. This allows the app to receive broadcast notifications sent to that topic.

**Security:** None  
**Rate limit:** 30 requests / hour per IP

**Query parameters:**

| Param | Type | Required | Description |
|---|---|---|---|
| `token` | string | Yes | The device's FCM token |
| `topic_name` | string | Yes | Topic to subscribe to |

**Example request:**

```
POST /subscribe-user/?token=cGVuZ3Vpbm1...&topic_name=product_alerts
```

**Response `200 OK`:**

```json
{ "status": "success", "message": "Subscribed to product_alerts" }
```

**Response on failure:**

```json
{ "status": "error", "details": [...] }
```

---

## 10. Error Reference

### Standard error shape

```json
{ "detail": "Human-readable error message" }
```

Validation errors (status `422`) include field-level details:

```json
{
  "detail": [
    {
      "loc": ["body", "message"],
      "msg": "String should have at most 2000 characters",
      "type": "string_too_long"
    }
  ]
}
```

### Status codes

| Status | Meaning | Typical action |
|---|---|---|
| `200` | OK | Success |
| `201` | Created | Resource created successfully |
| `400` | Bad request | Missing or malformed headers / parameters |
| `401` | Unauthorised | Missing/expired token or invalid signature → attempt token refresh |
| `403` | Forbidden | Device is permanently blocked → show user a message, do not retry |
| `404` | Not found | Resource does not exist |
| `422` | Validation error | Request body failed schema validation — check `detail` array for field errors |
| `429` | Rate limit exceeded | Back off and retry after the window resets |
| `500` | Server error | Transient server-side issue — retry with exponential backoff |

### Handling `401`

```
On 401 from any authenticated endpoint:
  1. Attempt POST /v1/token/refresh once
     ├─ 200: retry original request with new access_token
     └─ 401 or 403: clear all stored credentials → re-register as new device
```

### Handling `429`

Back off for at least the rate limit window before retrying. Do not retry immediately — the window will reset but repeated fast requests will continue to be rejected.
