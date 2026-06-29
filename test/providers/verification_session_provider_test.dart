import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medverify_mobile/models/multi_evidence_verification.dart';
import 'package:medverify_mobile/providers/verification_session_provider.dart';

// Creates a File stub — only the path is used; the file need not exist
// because provider state tests never read file bytes.
File _file(String name) => File('/tmp/$name.jpg');

void main() {
  late VerificationSessionProvider provider;

  setUp(() => provider = VerificationSessionProvider());

  // ── Image management ───────────────────────────────────────────────────────

  group('addImage', () {
    test('adds a single image', () {
      provider.addImage(_file('img1'));
      expect(provider.session.images.length, 1);
    });

    test('enforces 4-image cap — 5th image is silently dropped', () {
      for (int i = 0; i < 5; i++) {
        provider.addImage(_file('img$i'));
      }
      expect(provider.session.images.length, VerificationSessionProvider.maxImages);
    });

    test('exactly 4 images are accepted', () {
      for (int i = 0; i < 4; i++) {
        provider.addImage(_file('img$i'));
      }
      expect(provider.session.images.length, 4);
    });
  });

  group('removeImage', () {
    test('removes image at correct index', () {
      provider.addImage(_file('a'));
      provider.addImage(_file('b'));
      provider.addImage(_file('c'));
      provider.removeImage(1);
      expect(provider.session.images.length, 2);
      expect(provider.session.images[0].path, contains('a'));
      expect(provider.session.images[1].path, contains('c'));
    });

    test('allows adding again after removal', () {
      for (int i = 0; i < 4; i++) {
        provider.addImage(_file('img$i'));
      }
      provider.removeImage(0);
      provider.addImage(_file('new'));
      expect(provider.session.images.length, 4);
    });
  });

  // ── Barcode ────────────────────────────────────────────────────────────────

  group('barcode', () {
    test('setBarcode stores value', () {
      provider.setBarcode('123456789');
      expect(provider.session.barcode, '123456789');
    });

    test('clearBarcode removes value', () {
      provider.setBarcode('123456789');
      provider.clearBarcode();
      expect(provider.session.barcode, isNull);
    });
  });

  // ── Registration number ────────────────────────────────────────────────────

  group('setRegistrationNumber', () {
    test('trims and stores non-empty value', () {
      provider.setRegistrationNumber('  FD1234567  ');
      expect(provider.session.registrationNumber, 'FD1234567');
    });

    test('clears on empty string', () {
      provider.setRegistrationNumber('FD1234567');
      provider.setRegistrationNumber('');
      expect(provider.session.registrationNumber, isNull);
    });

    test('clears on null', () {
      provider.setRegistrationNumber('FD1234567');
      provider.setRegistrationNumber(null);
      expect(provider.session.registrationNumber, isNull);
    });

    test('clears on whitespace-only string', () {
      provider.setRegistrationNumber('FD1234567');
      provider.setRegistrationNumber('   ');
      expect(provider.session.registrationNumber, isNull);
    });
  });

  // ── Product name ───────────────────────────────────────────────────────────

  group('setProductName', () {
    test('stores trimmed value', () {
      provider.setProductName('  Amoxicillin  ');
      expect(provider.session.productName, 'Amoxicillin');
    });

    test('clears on empty string', () {
      provider.setProductName('Amoxicillin');
      provider.setProductName('');
      expect(provider.session.productName, isNull);
    });
  });

  // ── Manufacturers & ingredients ────────────────────────────────────────────

  group('manufacturers', () {
    test('adds trimmed manufacturer', () {
      provider.addManufacturer('  PharmaCo Ltd  ');
      expect(provider.session.manufacturers, ['PharmaCo Ltd']);
    });

    test('ignores empty or whitespace-only value', () {
      provider.addManufacturer('   ');
      expect(provider.session.manufacturers, isEmpty);
    });

    test('removes manufacturer at index', () {
      provider.addManufacturer('A');
      provider.addManufacturer('B');
      provider.removeManufacturer(0);
      expect(provider.session.manufacturers, ['B']);
    });
  });

  group('ingredients', () {
    test('adds and removes ingredients', () {
      provider.addIngredient('Paracetamol');
      provider.addIngredient('Caffeine');
      provider.removeIngredient(1);
      expect(provider.session.ingredients, ['Paracetamol']);
    });
  });

  // ── hasEvidence ────────────────────────────────────────────────────────────

  group('hasEvidence', () {
    test('false on fresh provider', () {
      expect(provider.hasEvidence, false);
    });

    test('true when an image is added', () {
      provider.addImage(_file('x'));
      expect(provider.hasEvidence, true);
    });

    test('true when barcode is set', () {
      provider.setBarcode('123');
      expect(provider.hasEvidence, true);
    });

    test('true when registration number is set', () {
      provider.setRegistrationNumber('FD123');
      expect(provider.hasEvidence, true);
    });

    test('true when product name is set', () {
      provider.setProductName('Drug X');
      expect(provider.hasEvidence, true);
    });
  });

  // ── reset ──────────────────────────────────────────────────────────────────

  group('reset', () {
    test('clears all evidence and state', () {
      provider.addImage(_file('img1'));
      provider.setBarcode('12345');
      provider.setRegistrationNumber('FD999');
      provider.setProductName('Test Drug');
      provider.addManufacturer('Co A');
      provider.addIngredient('Ingredient X');

      provider.reset();

      expect(provider.session.images, isEmpty);
      expect(provider.session.barcode, isNull);
      expect(provider.session.registrationNumber, isNull);
      expect(provider.session.productName, isNull);
      expect(provider.session.manufacturers, isEmpty);
      expect(provider.session.ingredients, isEmpty);
      expect(provider.session.status, VerificationUploadStatus.idle);
      expect(provider.result, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.hasEvidence, false);
    });

    test('generates a new session id after reset', () {
      final idBefore = provider.session.id;
      provider.reset();
      expect(provider.session.id, isNot(idBefore));
    });
  });
}
