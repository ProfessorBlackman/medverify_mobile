# MedVerify — mobile app

Checks a medicine's **registration status** against Ghana Food and Drugs
Authority records, and shows what the official record holds about it.

It is not an authenticity test. A counterfeit carrying a registration number
copied from a genuine product will match. What the app can tell you is that a
product is not in the register at all, or that its registration is not what
the pack claims — see the Information Hub in-app, which covers this in the
words users actually need.

## Three ways to check

| | When to use it | What comes back |
|---|---|---|
| **Search** | You can read the product name or the FDA registration number | The register entry — fuzzy name matching, so spelling need not be exact |
| **Scan barcode** | The pack has a scannable barcode | The register entry |
| **Multi-evidence verify** | The pack gives you neither cleanly | A **confidence score** with every piece of evidence listed, including partial matches |

Multi-evidence weighs whatever you can supply — manufacturer, active
ingredient, strength, dosage form, part of a name — against the register
together. Details you cannot supply are left out of the score rather than
counted against you.

Reading the details off a photograph automatically (OCR) is in progress and
not yet shipped.

## Running it

```bash
flutter pub get
flutter run
```

Release builds need `android/key.properties` and a keystore, neither of which
is in the repository. See `android/.gitignore`.

Firebase (`firebase_core`, `firebase_messaging`, `firebase_analytics`) is used
for push notifications and analytics only; everything else goes through the
backend API.

## How it fits together

```
Flutter app  ──HTTPS + HMAC-signed requests──▶  FastAPI backend  ──▶  Supabase Postgres
                                                      │
                                                      └──▶  Ghana FDA public register (read nightly)
```

The app has **no accounts**. On first launch it generates a device key, keeps
it in the platform keystore, and signs every write request with it. There is
no email address, phone number or profile anywhere in the system.

Scan history is stored locally (Hive), so a lookup already made still answers
without a connection.

## Where things live

| Path | |
|---|---|
| `lib/theme.dart` | The design system — palette, Public Sans / Noto Sans, 12px radius. The landing page derives its tokens from this file. |
| `lib/widgets/confidence_card.dart` | Overall verification states and their colours |
| `lib/widgets/evidence_summary_card.dart` | Per-signal evidence rows, labels and score/weight |
| `lib/services/device_auth_service.dart` | Anonymous identity, token refresh, request signing |
| `lib/screens/privacy_policy_screen.dart` | Terms and Privacy, **hardcoded** — keep in step with `PRIVACY_POLICY.md` and `TERMS_OF_SERVICE.md`, which are what the published policy URL serves |
| `docs/` | API contract, security layer, migration notes |

## Accuracy

The app may not claim more than a register lookup supports. It reports
registration status; it does not establish that a medicine is genuine, safe,
or still good. `PROJECT_DOCUMENTATION.md` and the Information Hub both say so,
and any new copy should too.
