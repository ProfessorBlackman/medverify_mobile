# MedVerify AI Coding Agent Instructions

## Feature: Multi-Evidence Verification Flow (Flutter)

## Objective

Implement a new verification flow in the Flutter application that supports the new backend multi-evidence verification API.

The implementation should replace the current single-image verification experience with a verification session capable of collecting multiple pieces of evidence before submitting a verification request.

The project uses:

* Flutter
* Dio (HTTP client)

Do **not** modify the existing verification flow. Build this as a new implementation that can replace the old flow once fully tested.

---

# High-Level Flow

```text
Verify Product
        ↓
Create Verification Session
        ↓
Capture Evidence
        ↓
Review Evidence
        ↓
Upload
        ↓
Receive Verification Result
        ↓
Display Result
```

The UI should be built around the concept of a **Verification Session**.

---

# Design Principles

* Keep widgets small and reusable.
* Separate UI from business logic.
* Use immutable models where practical.
* Keep API code isolated.
* Make adding future evidence types straightforward.
* Never tightly couple UI to backend response structures.

---

# Architecture

Organize the feature similarly to:

```text
features/

    verification/

        presentation/

            screens/

            widgets/

        domain/

            models/

            repositories/

        data/

            datasource/

            repositories/

            dto/

        services/

        state/
```

If the project already follows another architecture (e.g. Clean Architecture, MVVM, Riverpod, Bloc), follow the existing conventions instead of introducing a new pattern.

---

# Verification Session

Create a VerificationSession model.

Responsibilities:

* Store captured images.
* Store scanned barcode.
* Store manually entered registration number.
* Track upload state.
* Track processing state.

Suggested properties:

```dart
id
images
barcode
registrationNumber
status
```

This object should exist only during one verification.

---

# New Verification Screen

Create a new screen.

Example:

```text
VerificationSessionScreen
```

This replaces the old single-image verification screen.

---

# Capture Evidence

Allow users to:

* Capture multiple images
* Select multiple images from gallery (if supported)
* Scan barcode
* Enter registration number manually

The screen should not require all evidence types.

Any combination should be accepted.

---

# Image Management

Support:

* Add image
* Remove image
* Retake image
* Preview image

Display images in a responsive grid.

Do not limit the number of images unless required by backend constraints.

---

# Barcode Support

Reuse the existing barcode scanner if one already exists.

If no scanner exists:

Create a barcode scanning component.

When scanning succeeds:

Store barcode inside the Verification Session.

Do not immediately call the backend.

---

# Manual Registration Entry

Provide an optional text field.

Requirements:

* Optional
* Editable
* Clear button

Do not validate formatting aggressively.

The backend performs normalization.

---

# Evidence Summary

Before upload, display:

```text
Images

3 Attached

Barcode

Available

Registration Number

Entered
```

Allow editing before submission.

---

# Upload

Create a new API client method using Dio.

Example:

```dart
verifyProduct()
```

Use multipart/form-data.

The request should support:

* Multiple image files
* Barcode
* Registration number

The networking layer should be isolated from the UI.

---

# API Layer

Create:

```text
VerificationApi
```

Responsibilities:

* Build multipart requests.
* Upload images.
* Deserialize responses.
* Handle API errors.

No business logic should exist inside the API layer.

---

# Repository

Create:

```text
VerificationRepository
```

Responsibilities:

* Call VerificationApi.
* Convert DTOs into domain models.
* Handle repository-level failures.

---

# Processing Screen

Display a loading state while verification is in progress.

Suggested messaging:

* Uploading evidence...
* Reading product information...
* Comparing FDA records...
* Preparing verification...

Do not fake backend progress percentages.

---

# Verification Result Screen

Create a dedicated result screen.

The screen should support all five backend states.

---

## VERIFIED_MATCH

Display:

* Green success indicator
* Product information
* Confidence score
* Evidence summary

---

## PROBABLE_MATCH

Display:

* Amber indicator
* Product information
* Confidence score
* Warnings
* Evidence summary

---

## INSUFFICIENT_INFORMATION

Display:

* Neutral indicator
* Partial information
* Suggestion to capture more evidence

---

## NO_RELIABLE_MATCH

Display:

* Orange indicator
* Strong disclaimer
* Confidence score
* Manual search button

---

## NO_RESULT

Display:

No product information.

Instead show:

* No reliable match found.
* Manual search button.
* Scan again button.
* Add more evidence button.

---

# Evidence Widget

Create a reusable widget.

Example:

```text
EvidenceSummaryCard
```

Display:

```text
Registration Number

Matched

Manufacturer

Matched

Product Name

Similar Match

Strength

Matched

Barcode

Unavailable
```

This widget should render dynamically from backend evidence.

Do not hardcode evidence fields.

---

# Warning Widget

Create:

```text
VerificationWarnings
```

Display backend warnings.

Example:

* Product variation detected.
* Registration number missing.
* FDA public data appears incomplete.

Warnings should be informational.

---

# Confidence Widget

Create:

```text
ConfidenceCard
```

Display:

* Confidence percentage
* Verification state

Do not display confidence without its verification state.

---

# Retry Flow

Support:

* Add more images
* Retake images
* Scan barcode
* Enter registration number
* Retry verification

Users should not have to restart the entire session.

---

# Manual Search

Provide navigation to the existing manual search screen.

Used primarily from:

* NO_RESULT
* NO_RELIABLE_MATCH

---

# Networking

Use Dio.

Requirements:

* Multipart upload
* Upload progress
* Request timeout
* Error handling
* Response parsing

Handle:

* Network errors
* Timeout
* Server errors
* Invalid response

Gracefully.

---

# State Management

Use the project's existing state management solution.

The verification state should include:

* Idle
* CapturingEvidence
* Uploading
* Processing
* Success
* Failure

Avoid storing UI state inside widgets.

---

# Models

Create models for:

VerificationSession

VerificationResult

Evidence

Warning

VerificationState

Use immutable models if consistent with the project.

---

# Error Handling

Handle:

* No internet
* Upload failure
* API timeout
* Invalid images
* Backend failure
* Empty response

Every error should provide a user recovery action.

---

# Performance

* Compress images if the existing project already supports it.
* Avoid loading full-resolution images unnecessarily into memory.
* Dispose image resources properly.
* Upload asynchronously.

---

# Accessibility

Support:

* Screen readers
* Large tap targets
* Icons alongside colors
* Responsive layouts
* Dark mode (if supported by the project)

---

# Code Quality

* Follow the existing Flutter project conventions.
* Do not introduce unnecessary dependencies.
* Keep widgets under reasonable size.
* Avoid duplicated UI code.
* Use reusable components wherever possible.

---

# Testing

Create tests for:

## Unit Tests

* Repository
* API client
* DTO parsing
* Verification session logic

## Widget Tests

* Evidence Summary
* Verification Result
* Warning Widget
* Confidence Widget

## Integration Tests

* Multiple image upload
* Barcode only
* Registration number only
* Mixed evidence
* NO_RESULT flow
* Retry flow

---

# Deliverables

The implementation should include:

* New verification flow
* Verification session model
* Multi-image capture
* Barcode support
* Manual registration input
* Evidence summary screen
* Dio multipart upload implementation
* New verification API client
* Repository layer
* Processing screen
* Verification result screen
* Evidence summary widget
* Warning widget
* Confidence widget
* Retry workflow
* Manual search integration
* Unit tests
* Widget tests
* Integration tests

The final implementation should provide a clean, modular, and extensible verification experience that supports future evidence types and integrates seamlessly with the new backend Evidence & Confidence Engine.
