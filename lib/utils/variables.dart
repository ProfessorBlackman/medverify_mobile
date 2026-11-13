String backendUrl = "https://medverify-api.twerk.cc";
// String backendUrl="https://ab49-154-160-0-212.ngrok-free.app";

// Barcode scanning and pack photos as a way to *verify* are off for launch:
// we don't have barcode or image data for the register yet, and a scan that
// mostly returns "not found" reads as "this drug is fake". Turn back on once
// enough contributed barcodes have been approved — the scanner and photo code
// paths are still in place.
const bool photoAndBarcodeEnabled = false;

// The "Scan Barcode" / "Add Photos" buttons on a result, which is how that
// data gets collected. Contributions now wait for staff review before going
// live. Only turn this on in a build released *after* the backend with the
// review queue is deployed and the backfill has run — against the old
// backend, a contributed barcode goes live with no review.
const bool contributionsEnabled = false;
