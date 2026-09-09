import 'package:flutter_test/flutter_test.dart';
import 'package:medverify_mobile/models/verification_result.dart';

void main() {
  // The API returns `image_url` as a *list*, ordered operator-first. Parsing it
  // as a string dropped every product photograph from /v1/search and
  // /v1/barcode silently, which is what these cover.

  group('VerificationResult.fromJson — images', () {
    Map<String, dynamic> payload(Map<String, dynamic> extra) => {
          'status': 'valid',
          'product_name': 'Paracetamol 500mg Tablets',
          'registration_number': 'GH-1234-56',
          ...extra,
        };

    test('parses image_url as a list, preserving order', () {
      final r = VerificationResult.fromJson(payload({
        'image_url': [
          'https://x.supabase.co/storage/v1/object/public/b/operator.jpg',
          'https://x.supabase.co/storage/v1/object/public/b/community.jpg',
        ],
      }));
      expect(r.imageUrls, hasLength(2));
      // Operator-first ordering is how priority reaches the client; the first
      // entry is what the UI renders as the thumbnail.
      expect(r.imageUrls!.first, endsWith('operator.jpg'));
    });

    test('accepts the legacy single-string image_url', () {
      final r = VerificationResult.fromJson(
        payload({'image_url': 'https://example.test/one.jpg'}),
      );
      expect(r.imageUrls, ['https://example.test/one.jpg']);
    });

    test('accepts image_urls from older cached payloads', () {
      final r = VerificationResult.fromJson(
        payload({'image_urls': ['https://example.test/cached.jpg']}),
      );
      expect(r.imageUrls, ['https://example.test/cached.jpg']);
    });

    test('is null when the field is absent', () {
      expect(VerificationResult.fromJson(payload({})).imageUrls, isNull);
    });

    test('is null for an empty list rather than an empty list', () {
      final r = VerificationResult.fromJson(payload({'image_url': []}));
      expect(r.imageUrls, isNull);
    });

    test('drops empty strings', () {
      final r = VerificationResult.fromJson(payload({
        'image_url': ['', 'https://example.test/real.jpg'],
      }));
      expect(r.imageUrls, ['https://example.test/real.jpg']);
    });
  });

  // Both /v1/search and /v1/verifications send this vocabulary. A second,
  // hand-rolled copy of this mapping in verification_result_v2_screen.dart is
  // what made every matched product render as UNREGISTERED.

  group('verificationStatusFromApi', () {
    test('maps the snake_case wire value for near expiry', () {
      expect(verificationStatusFromApi('near_expiry'),
          VerificationStatus.nearExpiry);
      expect(verificationStatusFromApi('near-expiry'),
          VerificationStatus.nearExpiry);
      expect(verificationStatusFromApi('near expiry'),
          VerificationStatus.nearExpiry);
    });

    test('maps every remaining status the API can send', () {
      const wire = {
        'verified': VerificationStatus.verified,
        'valid': VerificationStatus.valid,
        'invalid': VerificationStatus.invalid,
        'unregistered': VerificationStatus.unregistered,
        'expired': VerificationStatus.expired,
        'recalled': VerificationStatus.recalled,
        'pending': VerificationStatus.pending,
        'none': VerificationStatus.none,
      };
      wire.forEach((value, expected) {
        expect(verificationStatusFromApi(value), expected, reason: value);
      });
    });

    test('is case- and whitespace-insensitive', () {
      expect(verificationStatusFromApi('  Valid '), VerificationStatus.valid);
      expect(
          verificationStatusFromApi('NEAR_EXPIRY'), VerificationStatus.nearExpiry);
    });

    test('returns null rather than guessing at an unknown value', () {
      // Must not resolve to `unregistered` — that is a claim about the
      // product, not an admission that parsing failed.
      expect(verificationStatusFromApi('Active'), isNull);
      expect(verificationStatusFromApi(''), isNull);
      expect(verificationStatusFromApi(null), isNull);
    });
  });

  group('VerificationResult.fromJson — status', () {
    test('parses near_expiry off the wire', () {
      final r = VerificationResult.fromJson(
        {'status': 'near_expiry', 'product_name': 'X'},
      );
      expect(r.status, VerificationStatus.nearExpiry);
    });

    test('an unknown status falls back to unregistered, as before', () {
      // Long-standing behaviour of this constructor, left as-is; the v2
      // product card is the surface that must not make that claim.
      final r = VerificationResult.fromJson(
        {'status': 'Active', 'product_name': 'X'},
      );
      expect(r.status, VerificationStatus.unregistered);
    });
  });
}
