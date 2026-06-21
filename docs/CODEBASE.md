# MedVerify Mobile — Codebase Documentation

> A Flutter mobile application that enables Ghanaians to instantly verify the authenticity and FDA approval status of medications by scanning barcodes/QR codes or searching by drug name against the Ghana Food & Drugs Authority (FDA) database.

**Version:** 1.0.0  
**Platform:** Android & iOS (Flutter)  
**Backend API:** `https://medverify-api.methuselah.site`  
**Android Target/Compile SDK:** 36  

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [App Initialization Flow](#2-app-initialization-flow)
3. [Screens & Pages](#3-screens--pages)
4. [Features](#4-features)
5. [Navigation & Routing](#5-navigation--routing)
6. [State Management](#6-state-management)
7. [Data Model](#7-data-model)
8. [Services](#8-services)
9. [Widgets](#9-widgets)
10. [Utilities](#10-utilities)
11. [External Services & API](#11-external-services--api)
12. [Theme & Design System](#12-theme--design-system)
13. [Android Build Configuration](#13-android-build-configuration)
14. [Dependencies](#14-dependencies)
15. [Permissions](#15-permissions)

---

## 1. Project Structure

```
medverify_mobile/
├── lib/
│   ├── main.dart                        # Entry point, Firebase init, MultiProvider setup
│   ├── theme.dart                       # AppTheme — colors, light/dark Material 3 themes
│   ├── firebase_options.dart            # Auto-generated Firebase config
│   │
│   ├── screens/                         # 13 full-page screens
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── scanner_screen.dart
│   │   ├── manual_entry_screen.dart
│   │   ├── results_screen.dart
│   │   ├── history_screen.dart
│   │   ├── info_hub_screen.dart
│   │   ├── feedback_screen.dart
│   │   ├── app_settings_screen.dart
│   │   ├── about_screen.dart
│   │   ├── how_it_works_screen.dart
│   │   └── privacy_policy_screen.dart
│   │
│   ├── models/
│   │   └── verification_result.dart     # Core data model + VerificationStatus enum
│   │
│   ├── providers/
│   │   └── app_provider.dart            # AppProvider (ChangeNotifier) — scan history state
│   │
│   ├── services/
│   │   ├── verification_service.dart    # Barcode + fuzzy-search API calls
│   │   ├── local_database.dart          # Hive DB (singleton)
│   │   ├── analytics_service.dart       # Firebase Analytics + geolocation
│   │   ├── notifications_service.dart   # FCM + local notifications
│   │   ├── feedback_service.dart        # Feedback form submission
│   │   └── file_upload_service.dart     # S3 presigned URL upload flow
│   │
│   ├── widgets/
│   │   ├── dashboard_widgets.dart       # DashboardHeader, ScanCard, CustomBottomNavBar, etc.
│   │   ├── barcode_scanner_modal.dart   # Bottom-sheet barcode scanner
│   │   ├── location_input_dialog.dart   # Pharmacy name prompt dialog
│   │   └── scanner_overlay.dart         # Animated scan-frame overlay
│   │
│   └── utils/
│       ├── globals.dart                 # navigatorKey (context-free navigation)
│       ├── variables.dart               # backendUrl constant
│       └── user_identification.dart     # UUID-based user identity (SharedPreferences)
│
├── android/
│   └── app/build.gradle.kts            # SDK versions, signing, Firebase BOM
├── pubspec.yaml                         # Flutter dependencies
└── CODEBASE.md                          # This file
```

---

## 2. App Initialization Flow

`main()` runs the following steps in sequence before rendering the UI:

1. **Sentry** — crash tracking initialized via `SentryFlutter.init()`
2. **Hive** — local database initialized via `LocalDatabase.instance.init()`
3. **Firebase** — `Firebase.initializeApp()` with `DefaultFirebaseOptions`
4. **FCM** — `FirebaseApi().initNotifications()` registers token, subscribes to `news`/`info` topics, sets up background/foreground message handlers
5. **Analytics** — `AnalyticsService.instance.init()` requests location permission for geo-tagged events
6. **SharedPreferences** — reads `isFirstTime` flag to choose initial route
7. **MultiProvider** — wraps app in `AppProvider` + `VerificationService` providers
8. **MaterialApp** — builds with named routes, system-responsive theme, and `NavigatorObserver` for screen tracking
9. **Initial route** — `WelcomeScreen` (first launch) or `SplashScreen` → `DashboardScreen`

---

## 3. Screens & Pages

### Splash Screen
**File:** `lib/screens/splash_screen.dart`  
**Route:** `/` (returning users)  
Animated logo with a progress bar. Displays "Initializing secure database…" while loading scan history from Hive, then navigates to `/dashboard`.

---

### Welcome Screen
**File:** `lib/screens/welcome_screen.dart`  
**Route:** `/welcome`  
Auto-playing 4-slide `PageView` onboarding carousel. Includes links to Terms of Service and Privacy Policy. A "Get Started" button navigates to `/dashboard` and persists `isFirstTime = false`.

---

### Dashboard Screen
**File:** `lib/screens/dashboard_screen.dart`  
**Route:** `/dashboard`  
Main hub of the app. Contains:
- `CustomSearchBar` → navigates to `/manual`
- `ScanCard` → launches `BarcodeScannerModal` (bottom sheet) or navigates to `/scanner`
- Quick action cards → History and How It Works
- `RecentScansList` sourced from `AppProvider`
- `CustomBottomNavBar` for tab navigation

---

### Scanner Screen
**File:** `lib/screens/scanner_screen.dart`  
**Route:** `/scanner`  
Full-screen camera view using the `MobileScanner` package. Features:
- Animated `ScannerOverlay` frame
- Zoom toggle (1× / 2×)
- Upload image from gallery
- Manual code entry fallback
- Processing state while awaiting API response

---

### Manual Entry Screen
**File:** `lib/screens/manual_entry_screen.dart`  
**Route:** `/manual`  
Text-field drug lookup. Calls `VerificationService.verifyFuzzySearch()`. Displays example search terms, loading state, and no-results / error messages. On success, navigates to `/results`.

---

### Results Screen
**File:** `lib/screens/results_screen.dart`  
**Route:** `/results`  
Receives a `VerificationResult` argument. Displays:
- Status header (color-coded icon, title, and description)
- `ProductInfoCard` — name, manufacturer, category, active ingredient, country of origin
- `LicenseDetailsCard` — registration number, type, approval/expiry dates
- `OtherMatches` — expandable list of alternate results from the same query
- `ImproveCard` — buttons to contribute a photo, barcode, or price
- Bottom actions: Report Problem / Scan Again

---

### History Screen
**File:** `lib/screens/history_screen.dart`  
**Route:** `/history`  
Full scan history from `AppProvider` with:
- Search bar (filters by drug name)
- Status filter chips: All / Verified / Not Approved / Warning
- Type filter chips: All / Scanned / Searched / Manual
- Results grouped by date: Today / Yesterday / Older

---

### Info Hub Screen
**File:** `lib/screens/info_hub_screen.dart`  
**Route:** `/info`  
Safety reference page. Sections include:
- Hero card with call-to-action
- Signs of counterfeit drugs (packaging, spelling errors, FDA registration, reporting)
- FAQ expansion tiles
- Contact buttons (phone, email)
- Links to Privacy Policy and Terms of Service

---

### Feedback Screen
**File:** `lib/screens/feedback_screen.dart`  
**Route:** `/feedback`  
User feedback submission form with:
- Fields: name, email, feedback type, message
- Attachment picker (images/video with size limits)
- Client-side validation
- Calls `FeedbackService.sendFeedback()` + `FileUploadService` for attachments

---

### App Settings Screen
**File:** `lib/screens/app_settings_screen.dart`  
**Route:** `/settings`  
Settings grouped into sections:
- **About & Feedback** — rate app, share app, view About screen, Privacy Policy
- **Data Management** — view history, clear all scan data
- App version display

---

### About Screen
**File:** `lib/screens/about_screen.dart`  
**Route:** `/about`  
Static informational screen: logo, version, mission statement, developer credits (The Laughing Chicken), links to FDA website and developer site.

---

### How It Works Screen
**File:** `lib/screens/how_it_works_screen.dart`  
**Route:** `/how_it_works`  
Visual 4-step tutorial guide with a hero image and FDA trust badge. Accessible from the Dashboard quick action card.

---

### Privacy Policy Screen
**File:** `lib/screens/privacy_policy_screen.dart`  
**Route:** `/privacy`  
Two-tab `TabBar` layout:
- **Terms of Service**
- **Privacy Policy**

Accepts an `initialTabIndex` argument to open directly to either tab.

---

## 4. Features

### Drug Verification
- **Barcode/QR scanning** via `MobileScanner`
- **Fuzzy name/reg-number search** via text input
- **Multi-result handling** — best match shown with expandable alternate matches

### Verification Statuses

| Status               | Display              | Color  |
|----------------------|----------------------|--------|
| `verified` / `valid` | Verified Safe        | Green  |
| `nearExpiry`         | Nearing Expiry       | Orange |
| `expired`            | License Expired      | Red    |
| `recalled`           | Product Recalled     | Red    |
| `unregistered`       | Unregistered Product | Red    |
| `pending`            | Unknown Status       | Gray   |

### Scan History
- All scans stored locally in Hive (`scan_history` box)
- Grouped and filterable in the History screen
- Clearable from Settings

### Community Contributions
Users can improve the database from the Results screen:
- **Photo upload** — crop & upload packaging images to S3 via presigned URLs
- **Barcode entry** — add missing barcodes
- **Price reporting** — submit GHS prices for market tracking
- **Location tagging** — pharmacy name/location attached at scan time via `LocationInputDialog`

### Push Notifications
- Firebase Cloud Messaging for drug alerts and news
- Local notification banners via `flutter_local_notifications`
- Notification payloads can carry a URL that triggers in-app navigation via `navigatorKey`

### Analytics
- Firebase Analytics logs drug scan events with product metadata
- Geolocation captured (with permission) to tag events by region
- Screen tracking via `NavigatorObserver`

### Error Tracking
- Sentry captures exceptions and stack traces automatically
- User-facing errors are shown as `SnackBar` messages

---

## 5. Navigation & Routing

Navigation uses `MaterialApp.routes` (named routes) combined with `Navigator.push` for cases requiring custom transitions.

| Route           | Screen              | Notes                                  |
|-----------------|---------------------|----------------------------------------|
| `/`             | SplashScreen        | Returning users only                   |
| `/welcome`      | WelcomeScreen       | First-time users                       |
| `/dashboard`    | DashboardScreen     | Main hub                               |
| `/scanner`      | ScannerScreen       | Camera scanning                        |
| `/manual`       | ManualEntryScreen   | Text search                            |
| `/results`      | ResultsScreen       | Requires `VerificationResult` argument |
| `/history`      | HistoryScreen       |                                        |
| `/info`         | InfoHubScreen       |                                        |
| `/feedback`     | FeedbackScreen      |                                        |
| `/how_it_works` | HowItWorksScreen    |                                        |
| `/privacy`      | PrivacyPolicyScreen | Optional `initialTabIndex` argument    |
| `/settings`     | AppSettingsScreen   |                                        |
| `/about`        | AboutScreen         |                                        |

Context-free navigation (e.g. from notification handlers) uses the global `navigatorKey` defined in `lib/utils/globals.dart`.

---

## 6. State Management

**Pattern:** Provider (ChangeNotifier)

### AppProvider — `lib/providers/app_provider.dart`

| Member                         | Type                       | Description                           |
|--------------------------------|----------------------------|---------------------------------------|
| `_scanHistory`                 | `List<VerificationResult>` | In-memory scan history                |
| `_isLoading`                   | `bool`                     | Loading state during DB fetch         |
| `addScan(result)`              | method                     | Persists to Hive + notifies listeners |
| `updateResult(result, source)` | method                     | Updates pharmacy source field         |
| `checkLocalLookup(query)`      | method                     | Fast in-memory search                 |
| `todayScans`                   | getter                     | Filtered list for today               |
| `clearHistory()`               | method                     | Wipes Hive box + resets list          |

UI reads state via `Consumer<AppProvider>` and calls methods via `context.read<AppProvider>()`.

`VerificationService` is also provided at the top level so any screen can call the API without instantiating it directly.

---

## 7. Data Model

### VerificationResult — `lib/models/verification_result.dart`

```dart
enum VerificationStatus {
  verified, valid, invalid, unregistered, expired, recalled, nearExpiry, pending
}

class VerificationResult {
  // Product Info
  String? productName, manufacturer, countryOrigin, region;
  String? activeIngredient, category, message;

  // Regulatory
  String? regNumber, registrationType, email, postalAddress;

  // Dates
  DateTime? approvalDate, expiryDate, scannedAt;

  // Media & Tracking
  String? imageUrl, barcode, price, source;

  // Status
  VerificationStatus? status;
}
```

**Serialization methods:**
- `toMap()` / `fromMap()` — Hive storage
- `fromJson(Map)` — API response parsing
- `copyWith()` — immutable field updates

---

## 8. Services

### VerificationService — `lib/services/verification_service.dart`
- `verifyBarcode(String barcode)` → `GET /barcode?bc={barcode}` → `List<VerificationResult>`
- `verifyFuzzySearch(String term)` → `GET /search?search_term={term}` → `List<VerificationResult>`

### LocalDatabase — `lib/services/local_database.dart`
Singleton managing a Hive box named `scan_history`.
- `init()` — opens box
- `insertResult(VerificationResult)` — saves to box
- `fetchHistory()` — returns all stored results
- `clearAll()` — deletes all entries

### AnalyticsService — `lib/services/analytics_service.dart`
Singleton wrapping Firebase Analytics.
- `init()` — requests location permission
- `logDrugScan(result, source)` — logs scan event with product metadata + geolocation

### FirebaseApi (NotificationsService) — `lib/services/notifications_service.dart`
- `initNotifications()` — requests permission, registers FCM token via `/register-user`, subscribes to topics, sets background/foreground handlers
- Foreground messages shown as local notification banners
- Notification tap navigates via `navigatorKey`

### FeedbackService — `lib/services/feedback_service.dart`
- `sendFeedback({name, email, type, message, attachmentUrls})` → `POST /feedback`

### FileUploadService — `lib/services/file_upload_service.dart`
Three-step S3 upload:
1. `POST /generate-upload-url` — get presigned URL + `file_key`
2. `PUT` file bytes directly to S3 presigned URL
3. `POST /confirm-upload` with `file_key` — confirm completion
Returns the public `file_url` for use in subsequent API calls.

---

## 9. Widgets

### `lib/widgets/dashboard_widgets.dart`
- `DashboardHeader` — app logo + greeting
- `CustomSearchBar` — tappable search field navigating to `/manual`
- `ScanCard` — primary CTA to open scanner
- `QuickActionCard` — reusable card for History and How It Works shortcuts
- `RecentScanItem` — single row in the recent scans list
- `CustomBottomNavBar` — tab bar (Dashboard / History / Info / Settings)

### `lib/widgets/barcode_scanner_modal.dart`
Bottom sheet presenting a compact `MobileScanner` camera view, used as a quick-scan shortcut from the Dashboard without navigating to the full Scanner screen.

### `lib/widgets/location_input_dialog.dart`
`AlertDialog` prompting the user to enter a pharmacy name/location immediately after a scan, attaching it to the `VerificationResult` as the `source` field.

### `lib/widgets/scanner_overlay.dart`
Custom `CustomPainter` that draws the scanning frame with a looping animated scan line over the camera feed.

---

## 10. Utilities

| File                             | Export                             | Purpose                                                                   |
|----------------------------------|------------------------------------|---------------------------------------------------------------------------|
| `utils/globals.dart`             | `navigatorKey`                     | `GlobalKey<NavigatorState>` for context-free navigation                   |
| `utils/variables.dart`           | `backendUrl`                       | Base URL constant for all API calls                                       |
| `utils/user_identification.dart` | `getUserId()`, `getUserUniqueId()` | UUID-v4 identity persisted in SharedPreferences; sent as `User-ID` header |

---

## 11. External Services & API

### Backend REST API

**Base URL:** `https://medverify-api.methuselah.site`

| Endpoint                     | Method | Purpose                                              |
|------------------------------|--------|------------------------------------------------------|
| `/barcode?bc={code}`         | GET    | Look up drug by barcode                              |
| `/search?search_term={term}` | GET    | Fuzzy search by name or registration number          |
| `/update_product`            | POST   | Submit community improvement (barcode, image, price) |
| `/feedback`                  | POST   | Submit user feedback + attachment URLs               |
| `/generate-upload-url`       | POST   | Request S3 presigned upload URL                      |
| `/confirm-upload`            | POST   | Confirm S3 file upload completion                    |
| `/register-user`             | POST   | Register FCM push token                              |

All requests include a `User-ID` header populated by `getUserUniqueId()`.

### Firebase
| Service                  | Usage                                                     |
|--------------------------|-----------------------------------------------------------|
| Firebase Core            | Initialization                                            |
| Firebase Analytics       | Drug scan events, screen tracking, geolocation properties |
| Firebase Cloud Messaging | Push notifications, topic subscriptions (`news`, `info`)  |

---

## 12. Theme & Design System

**File:** `lib/theme.dart`

### Colors

| Role               | Hex       | Usage                        |
|--------------------|-----------|------------------------------|
| Primary Green      | `#13EC5B` | CTA buttons, verified status |
| Secondary Green    | `#02A137` | Accent, secondary actions    |
| Background (light) | `#F6F8F6` | Main background              |
| Background (dark)  | `#102216` | Main background              |
| Text (light)       | `#111813` | Primary text                 |
| Text (dark)        | `#ECFDF3` | Primary text                 |
| Muted Text         | `#618983` | Secondary / hint text        |
| Error / Invalid    | `#EF4444` | Errors, expired, recalled    |
| Warning            | `#F59E0B` | Near-expiry, caution states  |
| Logo Tint          | `#D0F2ED` | Branding surfaces            |

### Typography
- **Headings:** Public Sans (weight 600–800)
- **Body:** Noto Sans (weight 400–600)
- **Buttons:** Public Sans Bold (weight 600–700)

### Theme Mode
`ThemeMode.system` — follows the device light/dark preference. Both themes use Material Design 3 with the same green primary color.

---

## 13. Android Build Configuration

**File:** `android/app/build.gradle.kts`

```
Application ID : com.tlc.medverify_mobile
Compile SDK    : 36
Target SDK     : 36
Min SDK        : Flutter default (21)
Java Version   : 17
Kotlin JVM     : 17
Multi-DEX      : enabled
Firebase BOM   : 34.8.0
Desugaring     : enabled (coreLibraryDesugaring)
```

---

## 14. Dependencies

### UI
| Package                  | Version   | Purpose                       |
|--------------------------|-----------|-------------------------------|
| `google_fonts`           | ^8.0.1    | Public Sans + Noto Sans fonts |
| `cupertino_icons`        | ^1.0.8    | iOS icon set                  |
| `material_symbols_icons` | ^4.2892.0 | Extended Material icons       |

### Local Storage
| Package              | Version | Purpose                           |
|----------------------|---------|-----------------------------------|
| `hive`               | ^2.2.3  | NoSQL key-value database          |
| `hive_flutter`       | ^1.1.0  | Flutter adapter for Hive          |
| `hive_ce`            | ^2.16.0 | Hive with encryption support      |
| `shared_preferences` | ^2.5.4  | Lightweight key-value persistence |

### State Management
| Package    | Version  | Purpose                    |
|------------|----------|----------------------------|
| `provider` | ^6.1.5+1 | ChangeNotifier-based state |

### Camera & Media
| Package          | Version | Purpose                        |
|------------------|---------|--------------------------------|
| `mobile_scanner` | ^7.1.4  | Barcode/QR code scanning       |
| `camera`         | ^0.12.0 | Raw camera access              |
| `image_picker`   | ^1.2.1  | Gallery/camera image selection |
| `image_cropper`  | ^12.2.1 | Image cropping before upload   |
| `file_picker`    | 10.3.8  | General file selection         |

### Networking
| Package | Version | Purpose                         |
|---------|---------|---------------------------------|
| `http`  | ^1.6.0  | HTTP client                     |
| `mime`  | ^2.0.0  | MIME type detection for uploads |

### Firebase
| Package              | Version | Purpose                  |
|----------------------|---------|--------------------------|
| `firebase_core`      | ^4.3.0  | Firebase initialization  |
| `firebase_analytics` | ^12.1.0 | Event + screen analytics |
| `firebase_messaging` | ^16.1.0 | Cloud Messaging (FCM)    |

### Notifications
| Package                       | Version | Purpose                           |
|-------------------------------|---------|-----------------------------------|
| `flutter_local_notifications` | ^21.0.0 | In-app local notification banners |

### Utilities
| Package          | Version | Purpose                           |
|------------------|---------|-----------------------------------|
| `uuid`           | ^4.5.2  | UUID generation for user identity |
| `intl`           | ^0.20.2 | Date/time formatting              |
| `url_launcher`   | ^6.3.2  | Open external URLs                |
| `share_plus`     | ^12.0.1 | Native share sheet                |
| `geolocator`     | ^14.0.2 | GPS location                      |
| `geocoding`      | ^4.0.0  | Reverse geocoding                 |
| `sentry_flutter` | ^9.14.0 | Crash and error reporting         |

### Dev
| Package          | Version | Purpose                      |
|------------------|---------|------------------------------|
| `build_runner`   | ^2.4.13 | Code generation              |
| `hive_generator` | ^2.0.1  | Hive type adapter generation |

---

## 15. Permissions

| Permission               | Platform    | Trigger                                 |
|--------------------------|-------------|-----------------------------------------|
| `INTERNET`               | Android     | All API calls                           |
| `CAMERA`                 | Android/iOS | Barcode scanner                         |
| `READ_EXTERNAL_STORAGE`  | Android     | Image picker                            |
| `WRITE_EXTERNAL_STORAGE` | Android     | Image save                              |
| `ACCESS_FINE_LOCATION`   | Android/iOS | Analytics geolocation (runtime prompt)  |
| `ACCESS_COARSE_LOCATION` | Android     | Analytics geolocation                   |
| `POST_NOTIFICATIONS`     | Android 13+ | FCM push notifications (runtime prompt) |
