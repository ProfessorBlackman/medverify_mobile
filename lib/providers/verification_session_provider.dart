import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/multi_evidence_verification.dart';
import '../services/file_upload_service.dart';
import '../services/multi_evidence_verification_service.dart';

class VerificationSessionProvider extends ChangeNotifier {
  VerificationSession _session = VerificationSession(
    id: const Uuid().v4(),
    images: [],
    status: VerificationUploadStatus.idle,
  );

  MultiVerificationResult? _result;
  String? _errorMessage;

  // 0.0–1.0 progress across all images during the S3 upload phase.
  // Stays at 0.0 (and is ignored by the UI) during the processing phase.
  double _imageUploadProgress = 0.0;

  VerificationSession get session => _session;
  MultiVerificationResult? get result => _result;
  String? get errorMessage => _errorMessage;
  double get imageUploadProgress => _imageUploadProgress;

  bool get hasEvidence =>
      _session.images.isNotEmpty ||
      _session.barcode != null ||
      _session.registrationNumber != null;

  void addImage(File image) {
    _session = _session.copyWith(images: [..._session.images, image]);
    notifyListeners();
  }

  void removeImage(int index) {
    final updated = List<File>.from(_session.images)..removeAt(index);
    _session = _session.copyWith(images: updated);
    notifyListeners();
  }

  void setBarcode(String barcode) {
    _session = _session.copyWith(barcode: barcode);
    notifyListeners();
  }

  void clearBarcode() {
    _session = _session.copyWith(clearBarcode: true);
    notifyListeners();
  }

  void setRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      _session = _session.copyWith(clearRegistrationNumber: true);
    } else {
      _session = _session.copyWith(registrationNumber: value.trim());
    }
    notifyListeners();
  }

  void reset() {
    _session = VerificationSession(
      id: const Uuid().v4(),
      images: [],
      status: VerificationUploadStatus.idle,
    );
    _result = null;
    _errorMessage = null;
    _imageUploadProgress = 0.0;
    notifyListeners();
  }

  Future<void> submitVerification(
    MultiEvidenceVerificationService verificationService,
    FileUploadService uploadService,
  ) async {
    if (!hasEvidence) return;

    _result = null;
    _errorMessage = null;
    _imageUploadProgress = 0.0;
    _session = _session.copyWith(status: VerificationUploadStatus.uploading);
    notifyListeners();

    // ── Phase 1: Upload images to S3 ─────────────────────────────────────────
    final imageUrls = <String>[];
    final totalImages = _session.images.length;

    for (var i = 0; i < totalImages; i++) {
      final uploadResult = await uploadService.uploadFile(
        _session.images[i],
        FilePurpose.temporary,
        onProgress: (progress) {
          // Spread progress evenly across all images.
          _imageUploadProgress = (i + progress) / totalImages;
          notifyListeners();
        },
      );

      if (!uploadResult.isSuccess) {
        _errorMessage = uploadResult.error ??
            'Failed to upload image ${i + 1} of $totalImages.';
        _session = _session.copyWith(status: VerificationUploadStatus.failure);
        notifyListeners();
        return;
      }

      imageUrls.add(uploadResult.url!);
      _imageUploadProgress = (i + 1) / totalImages;
      notifyListeners();
    }

    // ── Phase 2: Call the verification API with the S3 URLs ───────────────────
    _session = _session.copyWith(status: VerificationUploadStatus.processing);
    notifyListeners();

    try {
      final result = await verificationService.verifyProduct(
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        barcode: _session.barcode,
        registrationNumber: _session.registrationNumber,
      );

      _result = result;
      _session = _session.copyWith(status: VerificationUploadStatus.success);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _session = _session.copyWith(status: VerificationUploadStatus.failure);
    }

    notifyListeners();
  }
}
