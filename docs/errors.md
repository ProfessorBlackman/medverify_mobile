Code Review — MedVerify Mobile

  ---
Critical Security Issues

1. Hardcoded Sentry DSN — lib/main.dart:33
   The Sentry DSN is embedded in plain text in the source code. It can be extracted from a compiled APK and used to inject fake error events or exhaust your quota. Move it to a build-time environment variable or --dart-define.

2. Unvalidated URL launch from notifications — lib/services/notifications_service.dart:139
   URLs from FCM message payloads are launched directly with url_launcher without any domain or scheme validation. A malicious/compromised notification could open a phishing page. Whitelist the allowed host before calling
   launchUrl.

3. No HTTP timeout on any request — lib/services/verification_service.dart, lib/services/file_upload_service.dart
   Every http.get() and http.post() call has no timeout. If the backend is slow or unreachable, the app hangs forever with a spinner. Add .timeout(const Duration(seconds: 30)) to all calls.

  ---
Bugs

1. _confirmUpload() is fire-and-forget — lib/services/file_upload_service.dart:100
   The confirmation call is not awaited and has no error handling. If it fails silently, the backend never knows the upload is completed, and the file becomes an orphan on S3.

2. Forced unwrap on route arguments — lib/screens/results_screen.dart:40
   ModalRoute.of(context)!.settings.arguments uses ! without a null check. Any navigation path that doesn't pass a VerificationResult (e.g. from a notification deep link) will crash the app.

3. TextEditingController never disposed — lib/widgets/location_input_dialog.dart:14
   The _locationController is created but not disposed when the dialog closes, causing a memory leak on every scan.

4. Upload image button is a no-op — lib/screens/scanner_screen.dart:254
   The "Upload Image" gallery button has onPressed: () {} — it does nothing. Expected behavior is to pick an image and run barcode detection on it.

5. "Where can I find FDA number?" is unimplemented — lib/screens/manual_entry_screen.dart:297
   The help button has an empty callback. Users who don't know what format to enter have no guidance.

6. Fragile Hive record update — lib/services/local_database.dart:24
   Records are matched by comparing scannedAt.toIso8601String(). Microsecond-level timestamp drift means the match can silently fail and source updates are lost.

7. Status parsing silently defaults — lib/models/verification_result.dart:105
   firstWhere(..., orElse: () => VerificationStatus.unregistered) swallows unknown status strings from the API. New status values added on the backend will appear as "Unregistered" with no log or alert.

  ---
Performance Issues

1. shouldRepaint always returns true — lib/widgets/scanner_overlay.dart:150
   The scanner overlay CustomPainter forces a full repaint every animation frame regardless of whether anything changed. Return oldDelegate.animationValue != animationValue instead.

2. ListView nested in SingleChildScrollView with shrinkWrap: true — lib/screens/dashboard_screen.dart:135
   This forces Flutter to lay out the entire list at once, bypassing lazy rendering. With a large history it causes visible jank. Refactor to CustomScrollView with SliverList.

3. Filtering computed on every rebuild — lib/screens/history_screen.dart:222
   The history filter and search logic runs inside the Consumer build method, so it recalculates on every state change. Move it to a getter in AppProvider and cache the result.

4. Location request is synchronous in analytics event — lib/services/analytics_service.dart:68
   logDrugScan() calls _getCurrentLocation() inline, blocking the current async chain during a GPS lookup. This delays the results screen from appearing. Fetch location in the background and attach it if available within a short
   window.

5. Image.network() with no cache — lib/screens/results_screen.dart:540
   Drug product images are fetched over the network every time the results screen opens. Add cached_network_image to avoid redundant downloads.

  ---
Error Handling Gaps

1. Empty catch block on dashboard — lib/widgets/dashboard_widgets.dart:163
   The catch (e) block does nothing — no log, no Sentry capture, no user feedback. Errors silently disappear.

2. JSON decode not wrapped in try-catch — lib/services/verification_service.dart:22
   jsonDecode() throws FormatException on malformed responses. Only the HTTP call is guarded; a bad response body will crash.

3. mounted check missing after async picks — lib/screens/feedback_screen.dart:71
   _pickImages() and _pickVideo() do not verify if (!mounted) return after await. If the user navigates away during the picker, setState() will throw.

  ---
Architecture Issues

1. results_screen.dart is 1082 lines — god class
   The results screen handles state management, image uploading, barcode submission, price validation, dialog presentation, and rendering all in one file. It should be split into a ResultsViewModel, and separate widget files for
   StatusHeader, ProductInfoCard, LicenseDetailsCard, and ImproveCard.

2. backendUrl duplicated — lib/services/file_upload_service.dart:16
   The base URL is defined in lib/utils/variables.dart but re-declared in FileUploadService. One will drift from the other.

3. Duplicate verification call logic — lib/screens/scanner_screen.dart:56 and lib/screens/manual_entry_screen.dart
   Both screens replicate the same result-handling and navigation code after an API call. This should live in a shared method or in VerificationService.

4. Singletons make testing impossible
   AnalyticsService.instance, LocalDatabase.instance, and FirebaseApi are all hard singletons. None can be mocked in tests. Expose them through the Provider tree instead so they can be swapped.

5. verifyFDANumber() is a placeholder — lib/services/verification_service.dart:35
   Returns hardcoded mock data and is never called from the UI. Either implement or remove it.

  ---
Validation Gaps

1. Negative prices accepted — lib/screens/results_screen.dart:275
   The price field validator only checks for empty/non-numeric input. double.parse(value) > 0 check is missing.

2. Weak email validation — lib/screens/feedback_screen.dart:256
   value.contains('@') passes "@@", "a@", and "@b". Use a proper regex or the email_validator package.

3. No search query max length — lib/screens/manual_entry_screen.dart:25
   An unbounded text field lets users submit arbitrarily long strings to the fuzzy search endpoint.

  ---
Accessibility Issues

1. Primary green fails WCAG AA contrast
   #13EC5B on #F6F8F6 achieves approximately 3.5:1 contrast ratio. WCAG AA requires 4.5:1 for normal text. The darker #02A137 should be used for text/icon colors on light backgrounds.

2. No semantic labels on scanner overlay
   The animated scanning frame has no Semantics wrapper. Screen readers give no feedback that a scan is in progress.

3. Product images have no semanticLabel
   Image.network() on the results screen does not set semanticLabel, so VoiceOver/TalkBack users get no description of the drug packaging image.

  ---
Dead Code

1. Commented-out code left in production — scanner_screen.dart:172, app_settings_screen.dart:142, about_screen.dart:258. Remove it; it's in version control if needed.

  ---
Priority Order
#13EC5B on #F6F8F6 achieves approximately 3.5:1 contrast ratio. WCAG AA requires 4.5:1 for normal text. The darker #02A137 should be used for text/icon colors on light backgrounds.

1. No semantic labels on scanner overlay
   The animated scanning frame has no Semantics wrapper. Screen readers give no feedback that a scan is in progress.

2. Product images have no semanticLabel
   Image.network() on the results screen does not set semanticLabel, so VoiceOver/TalkBack users get no description of the drug packaging image.

  ---
Dead Code

1. Commented-out code left in production — scanner_screen.dart:172, app_settings_screen.dart:142, about_screen.dart:258. Remove it; it's in version control if needed.

  ---
Priority Order

┌──────────┬──────────────────────────────────────┬─────────────────────────────────────────────────────┐
│ Priority │                Issue                 │                        File                         │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P0       │ No HTTP timeouts                     │ verification_service.dart, file_upload_service.dart │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P0       │ Unvalidated notification URL launch  │ notifications_service.dart:139                      │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P0       │ Fire-and-forget _confirmUpload       │ file_upload_service.dart:100                        │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P1       │ Hardcoded Sentry DSN                 │ main.dart:33                                        │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P1       │ Forced unwrap on route arguments     │ results_screen.dart:40                              │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P1       │ TextEditingController leak in dialog │ location_input_dialog.dart:14                       │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P1       │ Upload image button is a no-op       │ scanner_screen.dart:254                             │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P2       │ Fragile Hive record matching         │ local_database.dart:24                              │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P2       │ shouldRepaint always true            │ scanner_overlay.dart:150                            │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P2       │ ListView + shrinkWrap performance    │ dashboard_screen.dart:135                           │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P2       │ Filtering on every rebuild           │ history_screen.dart:222                             │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P3       │ God class refactor                   │ results_screen.dart                                 │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P3       │ Singletons → injectable services     │ Architecture-wide                                   │
├──────────┼──────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ P3       │ WCAG contrast on primary green       │ theme.dart                                          │
└──────────┴──────────────────────────────────────┴─────────────────────────────────────────────────────┘
