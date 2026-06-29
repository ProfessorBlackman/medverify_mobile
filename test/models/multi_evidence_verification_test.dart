import 'package:flutter_test/flutter_test.dart';
import 'package:medverify_mobile/models/multi_evidence_verification.dart';

void main() {
  // ── VerificationEvidence ──────────────────────────────────────────────────

  group('VerificationEvidence.fromJson', () {
    test('parses MATCH status', () {
      final e = VerificationEvidence.fromJson({
        'type': 'barcode',
        'status': 'MATCH',
        'weight': 3,
        'score': 0.95,
        'message': 'Exact barcode match',
      });
      expect(e.status, EvidenceStatus.match);
      expect(e.type, 'barcode');
      expect(e.weight, 3);
      expect(e.score, 0.95);
      expect(e.similarity, isNull);
    });

    test('parses PARTIAL_MATCH status', () {
      final e = VerificationEvidence.fromJson({
        'type': 'image',
        'status': 'PARTIAL_MATCH',
        'weight': 2,
        'score': 0.6,
        'similarity': 0.72,
        'message': 'Partial visual match',
      });
      expect(e.status, EvidenceStatus.partialMatch);
      expect(e.similarity, 0.72);
    });

    test('parses MISMATCH status', () {
      final e = VerificationEvidence.fromJson({
        'type': 'registration',
        'status': 'MISMATCH',
        'weight': 4,
        'score': 0.0,
        'message': 'Registration number does not match',
      });
      expect(e.status, EvidenceStatus.mismatch);
    });

    test('falls back to notAvailable for unknown status', () {
      final e = VerificationEvidence.fromJson({
        'type': 'unknown',
        'status': 'SOMETHING_NEW',
        'weight': 1,
        'score': 0.5,
        'message': '',
      });
      expect(e.status, EvidenceStatus.notAvailable);
    });

    test('handles null / missing fields gracefully', () {
      final e = VerificationEvidence.fromJson({});
      expect(e.type, '');
      expect(e.weight, 0);
      expect(e.score, 0.0);
      expect(e.message, '');
      expect(e.similarity, isNull);
      expect(e.status, EvidenceStatus.notAvailable);
    });
  });

  // ── MatchedProduct ────────────────────────────────────────────────────────

  group('MatchedProduct.fromJson', () {
    test('parses all required fields', () {
      final p = MatchedProduct.fromJson({
        'id': 42,
        'product_name': 'Paracetamol 500mg',
        'registration_number': 'FD1234567',
        'manufacturer': 'PharmaCo Ltd',
        'status': 'REGISTERED',
      });
      expect(p.id, 42);
      expect(p.productName, 'Paracetamol 500mg');
      expect(p.registrationNumber, 'FD1234567');
      expect(p.manufacturer, 'PharmaCo Ltd');
      expect(p.status, 'REGISTERED');
    });

    test('parses optional fields when present', () {
      final p = MatchedProduct.fromJson({
        'id': 1,
        'product_name': 'Amoxicillin 500mg',
        'registration_number': 'FD9876543',
        'manufacturer': 'HealthCo',
        'status': 'REGISTERED',
        'active_ingredient': 'Amoxicillin Trihydrate',
        'generic_name': 'Amoxicillin',
        'strength': '500mg',
        'dosage_form': 'Capsule',
        'category': 'Antibiotic',
        'barcode': '1234567890123',
        'expiry_date': '2027-12-31',
        'registration_date': '2022-01-15',
        'country_origin': 'Ghana',
        'region': 'Greater Accra',
      });
      expect(p.activeIngredient, 'Amoxicillin Trihydrate');
      expect(p.genericName, 'Amoxicillin');
      expect(p.strength, '500mg');
      expect(p.expiryDate, DateTime(2027, 12, 31));
      expect(p.registrationDate, DateTime(2022, 1, 15));
      expect(p.countryOrigin, 'Ghana');
    });

    test('optional fields default to null when absent', () {
      final p = MatchedProduct.fromJson({
        'id': 1,
        'product_name': 'Test Drug',
        'registration_number': '',
        'manufacturer': 'Unknown',
        'status': '',
      });
      expect(p.activeIngredient, isNull);
      expect(p.genericName, isNull);
      expect(p.strength, isNull);
      expect(p.expiryDate, isNull);
    });

    test('falls back to safe defaults on missing required fields', () {
      final p = MatchedProduct.fromJson({});
      expect(p.id, 0);
      expect(p.productName, 'Unknown Product');
      expect(p.manufacturer, 'Unknown Manufacturer');
    });

    test('handles invalid date string gracefully', () {
      final p = MatchedProduct.fromJson({
        'id': 1,
        'product_name': 'Drug',
        'registration_number': '',
        'manufacturer': '',
        'status': '',
        'expiry_date': 'not-a-date',
      });
      expect(p.expiryDate, isNull);
    });
  });

  // ── MultiVerificationResult ───────────────────────────────────────────────

  group('MultiVerificationResult.fromJson', () {
    final sampleJson = {
      'session_id': 'sess-abc-123',
      'matches': [
        {
          'product': {
            'id': 1,
            'product_name': 'Paracetamol 500mg',
            'registration_number': 'FD1234567',
            'manufacturer': 'PharmaCo',
            'status': 'REGISTERED',
          },
          'confidence': 0.93,
          'verification_state': 'VERIFIED_MATCH',
          'evidence': [
            {
              'type': 'barcode',
              'status': 'MATCH',
              'weight': 3,
              'score': 0.95,
              'message': 'Barcode matched',
            }
          ],
        }
      ],
      'warnings': ['Low image quality'],
      'candidate_count': 3,
      'manual_search': false,
      'processing_time': 1.23,
    };

    test('parses full response', () {
      final r = MultiVerificationResult.fromJson(sampleJson);
      expect(r.sessionId, 'sess-abc-123');
      expect(r.matches.length, 1);
      expect(r.warnings, ['Low image quality']);
      expect(r.candidateCount, 3);
      expect(r.manualSearch, false);
      expect(r.processingTime, 1.23);
    });

    test('bestMatch returns first match', () {
      final r = MultiVerificationResult.fromJson(sampleJson);
      expect(r.bestMatch, isNotNull);
      expect(r.bestMatch!.product.productName, 'Paracetamol 500mg');
    });

    test('overallState reflects best match state', () {
      final r = MultiVerificationResult.fromJson(sampleJson);
      expect(r.overallState, MultiVerificationState.verifiedMatch);
      expect(r.overallConfidence, closeTo(0.93, 0.001));
    });

    test('empty matches returns noResult and zero confidence', () {
      final r = MultiVerificationResult.fromJson({
        'session_id': 'empty',
        'matches': [],
        'warnings': [],
        'candidate_count': 0,
        'manual_search': true,
        'processing_time': 0.5,
      });
      expect(r.hasMatches, false);
      expect(r.bestMatch, isNull);
      expect(r.overallState, MultiVerificationState.noResult);
      expect(r.overallConfidence, 0.0);
    });

    test('handles completely empty json with defaults', () {
      final r = MultiVerificationResult.fromJson({});
      expect(r.sessionId, '');
      expect(r.matches, isEmpty);
      expect(r.warnings, isEmpty);
      expect(r.candidateCount, 0);
      expect(r.manualSearch, false);
    });
  });

  // ── MultiVerificationState parsing ────────────────────────────────────────

  group('MultiVerificationState via VerificationMatch.fromJson', () {
    MultiVerificationState parseState(String raw) {
      final match = VerificationMatch.fromJson({
        'product': {
          'id': 1,
          'product_name': 'X',
          'registration_number': '',
          'manufacturer': '',
          'status': '',
        },
        'confidence': 0.5,
        'verification_state': raw,
        'evidence': [],
      });
      return match.verificationState;
    }

    test('VERIFIED_MATCH', () => expect(parseState('VERIFIED_MATCH'), MultiVerificationState.verifiedMatch));
    test('PROBABLE_MATCH', () => expect(parseState('PROBABLE_MATCH'), MultiVerificationState.probableMatch));
    test('INSUFFICIENT_INFORMATION', () => expect(parseState('INSUFFICIENT_INFORMATION'), MultiVerificationState.insufficientInformation));
    test('NO_RELIABLE_MATCH', () => expect(parseState('NO_RELIABLE_MATCH'), MultiVerificationState.noReliableMatch));
    test('unknown value defaults to noResult', () => expect(parseState('UNKNOWN_STATE'), MultiVerificationState.noResult));
    test('empty string defaults to noResult', () => expect(parseState(''), MultiVerificationState.noResult));
  });
}
