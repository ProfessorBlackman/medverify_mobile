# MedVerify Mobile — Data Collection Reference

This document describes all data the MedVerify mobile app collects from users, how each category is used, where it is stored, and which system processes it.

---

## 1. Identity & Contact Data

| Field            | Source                 | Required | Purpose                           |
|------------------|------------------------|----------|-----------------------------------|
| Name             | Feedback form          | Optional | Attribute feedback submissions    |
| Email address    | Feedback form          | Required | Contact user about their feedback |
| Feedback message | Feedback form          | Required | Improve the platform              |
| Feedback type    | Feedback form dropdown | Required | Route feedback to the right team  |
| File attachments | Feedback form          | Optional | Support evidence for bug reports  |

**Where it goes:** `POST /v1/feedback` → backend server  
**Stored:** Not stored locally; sent once on submission

---

## 2. Pharmaceutical & Product Data

Collected during drug verification and product improvement flows.

| Field                            | Source                                | Purpose                                        |
|----------------------------------|---------------------------------------|------------------------------------------------|
| Product name                     | Scan / manual entry result            | Identify the verified product                  |
| Registration / FDA number        | Manual entry, barcode scan, or camera | Look up the product in the regulatory database |
| Barcode                          | Barcode scanner or user contribution  | Match product to regulatory record             |
| Manufacturer                     | Regulatory database response          | Display verification result                    |
| Active ingredient / generic name | Regulatory database response          | Display verification result                    |
| Dosage form, strength, category  | Regulatory database response          | Display verification result                    |
| Expiry date / registration date  | Regulatory database response          | Display verification result                    |
| Country of origin / region       | Regulatory database response          | Display verification result                    |
| Price (user-contributed)         | Results screen input                  | Crowdsource drug pricing data                  |

**Where it goes:**
- Look-up queries → `GET /v1/barcode` or `GET /v1/search`
- User contributions (barcode, image, price) → `POST /v1/update_product`
- Full result saved locally in an encrypted Hive database (`scan_history`)

---

## 3. Images & Document Files

| Data                     | Collection Method               | Max Size                  | Formats              |
|--------------------------|---------------------------------|---------------------------|----------------------|
| Product packaging photos | Device camera or gallery picker | 10 MB each                | JPEG, PNG, WebP, PDF |
| Cropped product images   | In-app crop editor              | 10 MB each                | JPEG, PNG, WebP      |
| Feedback attachments     | Gallery picker                  | 10 MB each, up to 5 files | JPEG, PNG, WebP, PDF |

**Upload flow:**
1. App requests a presigned S3 URL → `POST /v1/generate-upload-url` (with `file_purpose`: `feedback`, `improve`, or `temporary`)
2. File is uploaded directly to AWS S3 via the presigned URL
3. App confirms the upload → `POST /v1/confirm-upload`

**Where it goes:** AWS S3 (cloud object storage); URL reference passed to verification or feedback endpoints

---

## 4. Location Data

| Data                                   | Collection Method                       | Purpose                                                        |
|----------------------------------------|-----------------------------------------|----------------------------------------------------------------|
| GPS coordinates (latitude / longitude) | Device Geolocator (requires permission) | Tag scan events with geographic context                        |
| Reverse-geocoded region name           | On-device geocoding of GPS fix          | Human-readable location for analytics                          |
| Purchase location text                 | Manual text input (location dialog)     | Associate a scan with a specific pharmacy, hospital, or clinic |

**Where it goes:** Sent with every scan event to `POST /v1/analytics/scan`; also logged to Firebase Analytics  
**Permission:** Location access is requested at runtime; the user may deny it

---

## 5. Device & Authentication Data

| Data                      | Storage                    | Purpose                                                  |
|---------------------------|----------------------------|----------------------------------------------------------|
| `device_public_id` (UUID) | Flutter Secure Storage     | Unique, stable device identifier                         |
| `device_secret` (hex key) | Flutter Secure Storage     | HMAC-SHA256 request signing key                          |
| `user_id`                 | Flutter Secure Storage     | Server-assigned account reference                        |
| `access_token` (JWT)      | Flutter Secure Storage     | Authenticate API requests                                |
| `refresh_token` (JWT)     | Flutter Secure Storage     | Renew expired access tokens                              |
| Platform & app version    | Sent once at registration  | `POST /v1/register-device` payload                       |
| FCM token                 | SharedPreferences + server | Deliver push notifications; `PATCH /v1/device/fcm-token` |

**Credential security:** All five credential fields are stored in the OS-level encrypted keystore (Flutter Secure Storage). The device secret never leaves the device in plain text; it is only used locally to sign outbound requests.

---

## 6. Scan & Usage Analytics

Every successful drug scan fires a structured analytics event containing:

| Field                    | Value                                            |
|--------------------------|--------------------------------------------------|
| `drug_name`              | Product name from verification result            |
| `reg_number`             | Registration / FDA number                        |
| `status`                 | Verification outcome (e.g., VERIFIED, NOT_FOUND) |
| `unique_code`            | Barcode value                                    |
| `timestamp`              | Unix epoch (seconds)                             |
| `latitude` / `longitude` | GPS fix at time of scan                          |
| `region`                 | Reverse-geocoded administrative area             |
| `source`                 | User-entered purchase location                   |
| `scanned_by`             | User ID                                          |

**Where it goes:**
- `POST /v1/analytics/scan` — backend analytics pipeline
- Firebase Analytics — `drug_scan` custom event

**Additional Firebase Analytics events:**
- `device_registration_success` / `device_registration_failure`
- `token_refresh_success` / `token_refresh_failure`
- `signature_failure`
- `upload_retry` / `upload_failure`
- Automatic screen-view events (all screens, via NavigatorObserver)

---

## 7. Error & Crash Data

| Data                       | Collector | Configuration                    |
|----------------------------|-----------|----------------------------------|
| Unhandled exceptions       | Sentry    | Trace sample rate: 20%           |
| Performance traces         | Sentry    | Profile sample rate: 20%         |
| Stack traces & breadcrumbs | Sentry    | DSN set via `SENTRY_DSN` env var |

**Where it goes:** Sentry cloud service (third-party error tracking)

---

## 8. Notification Preferences

| Data                         | Storage                   | Purpose                              |
|------------------------------|---------------------------|--------------------------------------|
| Notifications enabled (bool) | SharedPreferences         | Respect user's notification opt-out  |
| First-launch flag (bool)     | SharedPreferences         | Show onboarding only once            |
| FCM topic subscriptions      | Firebase (`news`, `info`) | Segmented push notification delivery |

---

## 9. Local Scan History

Every completed verification is persisted locally:

| Data                             | Storage                                      | Purpose                                |
|----------------------------------|----------------------------------------------|----------------------------------------|
| Full `VerificationResult` object | Hive encrypted database (`scan_history` box) | Let the user review past scans offline |
| `scannedAt` timestamp            | Same box, used as sort key                   | Chronological history display          |

The database is encrypted with Hive's built-in AES encryption; the key is derived from the device keystore.

---

## Summary Table

| Category           | Data Examples                         | Backend Endpoint(s)                               | Third-Party              |
|--------------------|---------------------------------------|---------------------------------------------------|--------------------------|
| Identity / contact | Name, email                           | `/v1/feedback`                                    | —                        |
| Pharmaceutical     | Drug name, reg number, barcode, price | `/v1/barcode`, `/v1/search`, `/v1/update_product` | —                        |
| Images / files     | Packaging photos, attachments         | `/v1/generate-upload-url`, S3                     | AWS S3                   |
| Location           | GPS lat/long, region, pharmacy name   | `/v1/analytics/scan`                              | Firebase Analytics       |
| Device / auth      | Device ID, JWT tokens, platform       | `/v1/register-device`, `/v1/token/refresh`        | —                        |
| Scan analytics     | Scan outcome, timestamp, location     | `/v1/analytics/scan`                              | Firebase Analytics       |
| Error / crash      | Stack traces, breadcrumbs             | —                                                 | Sentry                   |
| Notifications      | FCM token, topics, preferences        | `/v1/device/fcm-token`                            | Firebase Cloud Messaging |
| Local history      | Past scan results                     | (local only)                                      | —                        |

---

## Data Handling Notes

- **All authenticated API calls are signed** with HMAC-SHA256 using the device secret, preventing replay attacks and request tampering.
- **Credentials are never stored in plain text**; Flutter Secure Storage uses the Android Keystore / iOS Secure Enclave.
- **Location permission is request-time only**; users who deny it will not have GPS data attached to their scans.
- **Image files are validated** for MIME type and size (≤ 10 MB) before upload.
- **No passwords are collected**; authentication is device-key-based — there is no traditional username/password login.
