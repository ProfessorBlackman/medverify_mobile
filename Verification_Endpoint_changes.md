# Verification Endpoint — Breaking Changes

**Endpoint:** `POST /verifications`

These changes affect the response shape. The request body is unchanged.

---

## What changed

### 1. Response now returns a ranked list of matches

Previously the endpoint returned a single best-match product at the top level. It now returns a `matches` array, sorted by confidence score (highest first). Every candidate the pipeline evaluated is included so the client can present ranked results or pick the best one.

### 2. `matched_product`, `matched_product_id`, `confidence`, `verification_state`, and `evidence` are removed from the top level

These fields no longer exist on the root response object. The equivalent data is now on each item inside `matches`.

### 3. `NO_RESULT` is no longer used as a per-match state

Previously, a found product with a low confidence score would still be labelled `NO_RESULT`. This was confusing. The `NO_RESULT` state now only appears when the `matches` array is empty (i.e. the database returned no candidates at all). Match-level states are now one of:

| `verification_state` | Meaning |
|---|---|
| `VERIFIED_MATCH` | Confidence ≥ 90 — strong match across multiple fields |
| `PROBABLE_MATCH` | Confidence ≥ 70 — likely the correct product |
| `INSUFFICIENT_INFORMATION` | Confidence ≥ 40 — partial match, more input would help |
| `NO_RELIABLE_MATCH` | Confidence < 40 — candidate found but confidence is low |

---

## New response shape

```jsonc
{
  "session_id": "string",
  "matches": [
    {
      "product": {
        "id": 123,
        "product_name": "PATANOL EYE DROPS",
        "registration_number": "FDA/SD.233-121617",
        "manufacturer": "SA Alcon-Convireus N.V",
        "active_ingredient": "Olopatadine hydrochloride",
        "generic_name": "string | null",
        "strength": "string | null",
        "dosage_form": "EYE DROPS",
        "category": "DRUG",
        "barcode": "string | null",
        "expiry_date": "2027-05-01",
        "registration_date": "2023-12-15",
        "status": "valid",
        "country_origin": "Belgium",
        "region": "string | null"
      },
      "confidence": 91.5,          // 0–100
      "verification_state": "VERIFIED_MATCH",
      "evidence": [
        {
          "type": "product_name",
          "status": "MATCH",        // MATCH | PARTIAL_MATCH | MISMATCH | NOT_AVAILABLE
          "weight": 8,
          "score": 8.0,
          "similarity": 1.0,        // null when NOT_AVAILABLE
          "message": "Product name matched with similarity 1.00."
        }
        // ...one item per evidence type
      ]
    }
    // ...additional candidates, sorted best-first
  ],
  "warnings": ["string"],
  "candidate_count": 4,
  "manual_search": false,   // true only when matches is empty
  "processing_time": 0.015
}
```

### Empty result (no candidates found)

```jsonc
{
  "session_id": "string",
  "matches": [],
  "warnings": ["No candidate products found. Please search manually or scan another identifier."],
  "candidate_count": 0,
  "manual_search": true,
  "processing_time": 0.008
}
```

---

## Migration guide

| Old field | Replacement |
|---|---|
| `matched_product` | `matches[0].product` |
| `matched_product_id` | `matches[0].product.id` |
| `confidence` | `matches[0].confidence` |
| `verification_state` | `matches[0].verification_state` |
| `evidence` | `matches[0].evidence` |

To replicate the previous single-product behaviour, read `matches[0]` and check `matches[0].verification_state`. Always guard against an empty `matches` array before indexing.

---

## Recommended client logic

```
if matches is empty:
    → show "product not found, try a manual search" UI

else if matches[0].verification_state == "VERIFIED_MATCH" or "PROBABLE_MATCH":
    → show matches[0].product as the confirmed result

else:
    → show matches list as suggestions for the user to pick from
      (useful when only a product name was provided and multiple candidates exist)
```
