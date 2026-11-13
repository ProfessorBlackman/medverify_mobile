# PRD: MedVerify Multi-Evidence Verification Flow (Flutter)

## Status

Draft

---

# Objective

Redesign the mobile verification experience to support the new multi-evidence verification engine.

Instead of scanning a single image or barcode, users should be able to provide multiple pieces of evidence (images and identifiers) during one verification session, allowing the backend to produce more accurate and explainable results.

The mobile application should guide users through capturing useful evidence while keeping the experience simple and intuitive.

---

# Background

The previous verification flow assumed that one image or one barcode was sufficient to identify a product.

In reality:

* Some products have no barcode.
* Some products have no visible FDA registration number.
* OCR may fail on one side of the packaging.
* Important information is often spread across multiple sides of the package.

The new flow allows the user to submit multiple images and identifiers as evidence for a single verification request.

---

# Goals

* Support multi-image verification.
* Improve verification accuracy.
* Guide users to capture useful images.
* Present explainable verification results.
* Reduce false negatives caused by incomplete product information.

---

# Non-Goals

* Offline verification.
* Image editing.
* Manual OCR correction.
* Counterfeit detection from packaging.

---

# User Journey

```text
Home
    ↓
Start Verification
    ↓
Capture Evidence
    ↓
Review Evidence
    ↓
Upload
    ↓
Verification Processing
    ↓
Verification Result
```

---

# Verification Session

A verification begins when the user taps **Verify Product**.

A temporary verification session is created locally.

The session stores:

* Captured images
* Detected barcode (optional)
* Manual registration number (optional)
* Upload state

The session is discarded after completion unless verification history is enabled.

---

# Capture Evidence Screen

This becomes the primary verification screen.

Instead of requesting a single image, users can add multiple pieces of evidence.

Supported inputs:

* Product photos
* Barcode scan
* Manual registration number

The UI should encourage—but not require—multiple inputs.

---

# Image Capture

Users may capture multiple images.

Suggested guidance:

* Front of package
* Back of package
* Side panel
* Barcode
* Leaflet (optional)

There should be no strict requirement for a specific number of images.

---

# Image Gallery

Captured images should appear as thumbnails.

Users should be able to:

* Preview
* Delete
* Retake
* Add additional images

---

# Barcode Support

Users may:

* Scan a barcode
* Skip barcode scanning

If a barcode is successfully detected, it should be attached to the verification request automatically.

---

# Manual Registration Number

Provide an optional input field.

Purpose:

* Products without readable packaging
* OCR failures
* Damaged packaging

The user should be able to enter the FDA registration number manually.

---

# Evidence Summary

Before submission, display a summary.

Example:

```text
✓ 3 Images

✓ Barcode

No Registration Number
```

Users can still continue.

---

# Upload

When the user taps **Verify**, upload:

* Images
* Barcode (if available)
* Registration number (if provided)

Display upload progress.

---

# Processing Screen

Show an indeterminate loading state.

Suggested messaging:

> Analyzing product information...

Possible progress indicators:

* Reading product information
* Searching FDA records
* Comparing evidence
* Preparing verification result

The mobile app should not attempt to estimate actual backend progress.

---

# Verification Results

Display one of five verification states.

---

## VERIFIED_MATCH

Display:

* Green success indicator
* Confidence score
* Product information
* Manufacturer
* Registration number
* Evidence summary

---

## PROBABLE_MATCH

Display:

* Amber indicator
* Confidence score
* Product information
* Explanation of inconsistencies
* Warnings

---

## INSUFFICIENT_INFORMATION

Display:

* Neutral indicator
* Partial product information
* Warnings
* Suggestion to capture more images

---

## NO_RELIABLE_MATCH

Display:

* Orange indicator
* Weak match disclaimer
* Confidence score
* Recommendation to manually verify

---

## NO_RESULT

Display:

* Neutral information state
* No product displayed
* Message explaining that no sufficiently reliable match could be found

Actions:

* Search manually
* Try another scan
* Capture additional images

---

# Evidence Section

Every verification result should explain how the decision was made.

Example:

```text
Registration Number

✓ Matched

Manufacturer

✓ Matched

Product Name

⚠ Similar Match

Strength

✓ Matched

Barcode

Unavailable
```

The app should never display only a confidence score.

---

# Warnings

Display backend warnings prominently.

Examples:

* Product name differs slightly from FDA record.
* Registration number not visible.
* Public FDA data appears incomplete.
* Multiple product variations found.

Warnings should not be presented as errors.

---

# Confidence Display

Show confidence visually.

Example:

```text
Confidence

92%
```

Confidence should always appear together with:

* Verification state
* Evidence summary

Confidence alone should never determine the user's interpretation.

---

# Retry Flow

If verification fails due to poor evidence:

Provide actions:

* Capture more images
* Scan barcode
* Enter registration number
* Search manually

---

# Manual Search Shortcut

For `NO_RESULT` and `NO_RELIABLE_MATCH`, provide a one-tap shortcut to the manual search screen.

This allows users to continue verification without starting over.

---

# Error Handling

Handle gracefully:

* Network failure
* Upload timeout
* OCR extraction failure
* Backend unavailable
* Invalid images
* Verification timeout

The user should always have a clear recovery action.

---

# Accessibility

* Support screen readers.
* Large touch targets.
* High contrast verification states.
* Clear icons alongside color.
* Avoid relying solely on color to communicate status.

---

# Analytics

Track:

* Verification started
* Images captured
* Barcode scanned
* Manual registration entered
* Verification completed
* Verification state returned
* Retry initiated
* Manual search selected

No sensitive product images should be included in analytics events.

---

# Future Enhancements

The UI should be designed to accommodate future evidence sources without significant redesign.

Potential additions:

* Batch number scanning
* QR code verification
* Manufacturer authentication
* Pharmacy inventory confirmation
* Product recall alerts
* AI packaging analysis

---

# Acceptance Criteria

* Users can attach multiple images during one verification session.
* Users can optionally scan a barcode.
* Users can optionally enter a registration number manually.
* Verification requests support any combination of evidence inputs.
* Upload progress is displayed.
* Five verification states are supported.
* Every verification result includes an evidence summary.
* Warnings are displayed when provided by the backend.
* `NO_RESULT` directs users toward manual search or additional evidence collection.
* Users can retry verification without restarting the entire flow.
* The UI is designed to accommodate future evidence types with minimal changes.
