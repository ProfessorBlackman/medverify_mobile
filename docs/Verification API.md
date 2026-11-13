# Verification Endpoint Integration Guide

## Overview

`POST /v1/verifications` is the new drug verification endpoint. Unlike the existing lookup endpoints (`/v1/search`, `/v1/reg_number`, `/v1/barcode`) which return a binary found/not-found result, this endpoint uses a multi-evidence confidence engine to score how closely a scanned product matches an FDA regulatory record.

It accepts product images, a barcode, and/or a registration number in any combination, and returns a structured result with a confidence score, a human-readable verification state, and an itemised evidence breakdown explaining the score.

---

## Endpoint

```
POST /v1/verifications
Content-Type: multipart/form-data
```

Rate limit: **10 requests / minute** per IP.

---

## Request

The request is a `multipart/form-data` body. All fields are optional individually, but **at least one must be provided**.

| Field                 | Type              | Description                                                                                                 |
|-----------------------|-------------------|-------------------------------------------------------------------------------------------------------------|
| `images`              | File (repeatable) | One or more product images (JPEG, PNG, WebP, GIF). The server runs OCR and barcode detection on each image. |
| `barcode`             | String            | Barcode value scanned directly by the app.                                                                  |
| `registration_number` | String            | Registration number typed or scanned by the user.                                                           |

Accepted input combinations:

- Image(s) only
- Barcode only
- Registration number only
- Barcode + image(s)
- Registration number + image(s)
- Barcode + registration number + image(s)

---

## Response

`HTTP 200 OK` — always returned when the engine completes, regardless of whether a match was found. The `verification_state` field determines the outcome.

```json
{
  "session_id": "3f8a1b2c-...",
  "matched_product_id": 4821,
  "matched_product": {
    "id": 4821,
    "product_name": "Amoxicillin 500mg Capsules",
    "registration_number": "FD1234567",
    "manufacturer": "PharmaCo Ltd",
    "active_ingredient": "Amoxicillin Trihydrate",
    "generic_name": "Amoxicillin",
    "strength": "500mg",
    "dosage_form": "Hard Capsules",
    "category": "Antibiotics",
    "barcode": "5901234123457",
    "expiry_date": "2027-03-31",
    "registration_date": "2019-01-15",
    "status": "verified",
    "country_origin": "Ghana",
    "region": "Greater Accra"
  },
  "confidence": 94.5,
  "verification_state": "VERIFIED_MATCH",
  "evidence": [
    {
      "type": "registration_number",
      "status": "MATCH",
      "weight": 45,
      "score": 45.0,
      "similarity": null,
      "message": "Registration number matches FDA record."
    },
    {
      "type": "barcode",
      "status": "NOT_AVAILABLE",
      "weight": 45,
      "score": 0.0,
      "similarity": null,
      "message": "No barcode available in submission or FDA record."
    },
    {
      "type": "manufacturer",
      "status": "MATCH",
      "weight": 15,
      "score": 15.0,
      "similarity": 0.97,
      "message": "Manufacturer names match."
    },
    {
      "type": "active_ingredients",
      "status": "PARTIAL_MATCH",
      "weight": 15,
      "score": 10.5,
      "similarity": 0.70,
      "message": "Some ingredients matched."
    },
    {
      "type": "generic_name",
      "status": "MATCH",
      "weight": 10,
      "score": 10.0,
      "similarity": 1.0,
      "message": "Generic name matches."
    },
    {
      "type": "product_name",
      "status": "MATCH",
      "weight": 8,
      "score": 8.0,
      "similarity": 0.96,
      "message": "Product name matches."
    },
    {
      "type": "strength",
      "status": "MATCH",
      "weight": 5,
      "score": 5.0,
      "similarity": 1.0,
      "message": "Strength matches."
    },
    {
      "type": "dosage_form",
      "status": "NOT_AVAILABLE",
      "weight": 5,
      "score": 0.0,
      "similarity": null,
      "message": "Dosage form could not be verified."
    },
    {
      "type": "category",
      "status": "NOT_AVAILABLE",
      "weight": 2,
      "score": 0.0,
      "similarity": null,
      "message": "Category could not be verified."
    }
  ],
  "warnings": [],
  "candidate_count": 2,
  "manual_search": false,
  "processing_time": 0.342
}
```

### Response Fields

| Field                | Type             | Description                                                                                             |
|----------------------|------------------|---------------------------------------------------------------------------------------------------------|
| `session_id`         | String (UUID)    | Unique ID for this verification request. Store for support/debugging.                                   |
| `matched_product_id` | Integer or null  | Internal database ID of the matched product. `null` when `verification_state` is `NO_RESULT`.           |
| `matched_product`    | Object or null   | Full product details. `null` when `verification_state` is `NO_RESULT`.                                  |
| `confidence`         | Float (0–100)    | Normalised confidence score.                                                                            |
| `verification_state` | String           | One of the five states described below.                                                                 |
| `evidence`           | Array            | Itemised breakdown of each evidence signal.                                                             |
| `warnings`           | Array of strings | Informational messages (e.g. incomplete FDA data, multiple candidates found). Do not block on warnings. |
| `candidate_count`    | Integer          | Number of FDA candidate records evaluated.                                                              |
| `manual_search`      | Boolean          | `true` when the engine could not find a reliable match and the user should search manually.             |
| `processing_time`    | Float            | Server-side processing time in seconds.                                                                 |

---

## Verification States

| State                      | Confidence | Meaning                                                                                                   |
|----------------------------|------------|-----------------------------------------------------------------------------------------------------------|
| `VERIFIED_MATCH`           | 90–100     | Strong identifiers matched with corroborating evidence. High confidence the product is in the FDA record. |
| `PROBABLE_MATCH`           | 70–89      | Strong evidence present with minor inconsistencies — likely a product variation or incomplete FDA data.   |
| `INSUFFICIENT_INFORMATION` | 40–69      | Partial evidence only. The engine cannot confidently confirm or deny a match.                             |
| `NO_RELIABLE_MATCH`        | 20–39      | Weak evidence. No reliable regulatory match was found.                                                    |
| `NO_RESULT`                | 0–19       | No meaningful confidence. No candidate could be identified.                                               |

---

## Evidence Statuses

Each item in the `evidence` array has a `status` field:

| Status          | Meaning                                                          |
|-----------------|------------------------------------------------------------------|
| `MATCH`         | Signal matched the FDA record (similarity ≥ 95%).                |
| `PARTIAL_MATCH` | Signal partially matched (similarity 70–94%). Score is prorated. |
| `MISMATCH`      | Signal was present on both sides but did not match.              |
| `NOT_AVAILABLE` | Signal was missing from the submission, the FDA record, or both. |

---

## Error Responses

| Status | Condition                                                        |
|--------|------------------------------------------------------------------|
| `422`  | No inputs provided, or an unsupported image format was uploaded. |
| `429`  | Rate limit exceeded (10 requests/minute).                        |
| `500`  | Unexpected server error.                                         |

---

## Frontend Integration Guide

### 1. Display logic by verification state

Map `verification_state` to UI treatment:

| State                      | Badge colour | CTA                                                          |
|----------------------------|--------------|--------------------------------------------------------------|
| `VERIFIED_MATCH`           | Green        | Show full product details                                    |
| `PROBABLE_MATCH`           | Amber        | Show product details with a caution note                     |
| `INSUFFICIENT_INFORMATION` | Orange       | Show partial details with a "data may be incomplete" warning |
| `NO_RELIABLE_MATCH`        | Red          | Show disclaimer, prompt manual search                        |
| `NO_RESULT`                | Red          | Prompt manual search or rescan with a different identifier   |

### 2. Confidence score display

Show `confidence` as a percentage. Recommended: a circular or linear progress indicator alongside the state badge.

```
94% — VERIFIED MATCH
```

Do not show the raw score alone. Always pair it with the `verification_state` label.

### 3. Rendering the evidence breakdown

The `evidence` array is ordered by weight (highest first). A collapsible "How was this score calculated?" section is the recommended pattern.

```
Registration Number   ✓ MATCH          45/45
Manufacturer          ✓ MATCH          15/15  (97% similar)
Generic Name          ✓ MATCH          10/10
Active Ingredients    ~ PARTIAL MATCH  10/15  (70% similar)
Product Name          ✓ MATCH           8/8   (96% similar)
Strength              ✓ MATCH           5/5
Barcode               — NOT AVAILABLE   0/45
Dosage Form           — NOT AVAILABLE   0/5
Category              — NOT AVAILABLE   0/2
```

Each row: `evidence[i].type`, `evidence[i].status`, `evidence[i].score` / `evidence[i].weight`. Show `similarity` as a percentage when it is not `null`.

### 4. Handling warnings

Display `warnings` as a non-blocking informational banner beneath the result, not as errors. Example banner copy: *"Multiple candidate products were evaluated. Showing the best match."*

### 5. Manual search prompt

When `manual_search` is `true` (i.e. state is `NO_RESULT`), guide the user to the existing text search:

```
Could not identify this product.
Try searching by product name using the search bar,
or scan the registration number printed on the packaging.
```

### 6. Multipart request example (Dart / Flutter)

```dart
Future<VerificationResult> verifyProduct({
  List<File>? images,
  String? barcode,
  String? registrationNumber,
}) async {
  final uri = Uri.parse('$baseUrl/v1/verifications');
  final request = http.MultipartRequest('POST', uri);

  if (barcode != null) {
    request.fields['barcode'] = barcode;
  }
  if (registrationNumber != null) {
    request.fields['registration_number'] = registrationNumber;
  }
  if (images != null) {
    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }
  }

  final response = await request.send();
  final body = await response.stream.bytesToString();
  return VerificationResult.fromJson(jsonDecode(body));
}
```

### 7. Recommended scan flow

```
User scans barcode
        ↓
POST /v1/verifications  { barcode: "..." }
        ↓
verification_state == VERIFIED_MATCH / PROBABLE_MATCH
    → show result screen with confidence + evidence
        ↓
verification_state == INSUFFICIENT_INFORMATION
    → show partial result + prompt for reg number rescan
        ↓
verification_state == NO_RELIABLE_MATCH / NO_RESULT
    → show manual search prompt
```

If the initial scan produces `INSUFFICIENT_INFORMATION`, prompt the user to also scan the registration number printed on the box and resubmit with both `barcode` and `registration_number` set. This typically raises the confidence score into `PROBABLE_MATCH` or `VERIFIED_MATCH`.

---

## Relationship to Existing Endpoints

The existing endpoints remain unchanged and continue to work as before:

| Endpoint                         | Type           | Returns                                                 |
|----------------------------------|----------------|---------------------------------------------------------|
| `GET /v1/search?search_term=`    | Text search    | List of matching products (binary, no confidence score) |
| `GET /v1/reg_number?reg_number=` | Exact lookup   | Single product or 404                                   |
| `GET /v1/barcode?bc=`            | Exact lookup   | List of products or empty list                          |
| `POST /v1/verifications`         | Multi-evidence | Confidence-scored result with explainable evidence      |

Use `POST /v1/verifications` for all new scan flows. The legacy endpoints can be kept as a fallback or for direct lookups from search UIs.
