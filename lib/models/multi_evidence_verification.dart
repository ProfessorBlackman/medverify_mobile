import 'dart:io';

enum MultiVerificationState {
  verifiedMatch,
  probableMatch,
  insufficientInformation,
  noReliableMatch,
  noResult,
}

enum EvidenceStatus {
  match,
  partialMatch,
  mismatch,
  notAvailable,
}

enum VerificationUploadStatus {
  idle,
  uploading,
  processing,
  success,
  failure,
}

// Module-level parser used by both VerificationMatch and MultiVerificationResult.
MultiVerificationState _parseVerificationState(String raw) {
  switch (raw) {
    case 'VERIFIED_MATCH':
      return MultiVerificationState.verifiedMatch;
    case 'PROBABLE_MATCH':
      return MultiVerificationState.probableMatch;
    case 'INSUFFICIENT_INFORMATION':
      return MultiVerificationState.insufficientInformation;
    case 'NO_RELIABLE_MATCH':
      return MultiVerificationState.noReliableMatch;
    default:
      return MultiVerificationState.noResult;
  }
}

class VerificationEvidence {
  final String type;
  final EvidenceStatus status;
  final int weight;
  final double score;
  final double? similarity;
  final String message;

  const VerificationEvidence({
    required this.type,
    required this.status,
    required this.weight,
    required this.score,
    this.similarity,
    required this.message,
  });

  static EvidenceStatus _parseStatus(String raw) {
    switch (raw) {
      case 'MATCH':
        return EvidenceStatus.match;
      case 'PARTIAL_MATCH':
        return EvidenceStatus.partialMatch;
      case 'MISMATCH':
        return EvidenceStatus.mismatch;
      default:
        return EvidenceStatus.notAvailable;
    }
  }

  factory VerificationEvidence.fromJson(Map<String, dynamic> json) {
    return VerificationEvidence(
      type: json['type'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? ''),
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      similarity: json['similarity'] != null
          ? (json['similarity'] as num).toDouble()
          : null,
      message: json['message'] as String? ?? '',
    );
  }
}

class MatchedProduct {
  final int id;
  final String productName;
  final String registrationNumber;
  final String manufacturer;
  final String? activeIngredient;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String? category;
  final String? barcode;
  final DateTime? expiryDate;
  final DateTime? registrationDate;
  final String status;
  final String? countryOrigin;
  final String? region;

  const MatchedProduct({
    required this.id,
    required this.productName,
    required this.registrationNumber,
    required this.manufacturer,
    this.activeIngredient,
    this.genericName,
    this.strength,
    this.dosageForm,
    this.category,
    this.barcode,
    this.expiryDate,
    this.registrationDate,
    required this.status,
    this.countryOrigin,
    this.region,
  });

  factory MatchedProduct.fromJson(Map<String, dynamic> json) {
    return MatchedProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown Product',
      registrationNumber: json['registration_number'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? 'Unknown Manufacturer',
      activeIngredient: json['active_ingredient'] as String?,
      genericName: json['generic_name'] as String?,
      strength: json['strength'] as String?,
      dosageForm: json['dosage_form'] as String?,
      category: json['category'] as String?,
      barcode: json['barcode'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      registrationDate: json['registration_date'] != null
          ? DateTime.tryParse(json['registration_date'] as String)
          : null,
      status: json['status'] as String? ?? '',
      countryOrigin: json['country_origin'] as String?,
      region: json['region'] as String?,
    );
  }
}

/// A single ranked candidate returned by the verification engine.
class VerificationMatch {
  final MatchedProduct product;
  final double confidence;
  final MultiVerificationState verificationState;
  final List<VerificationEvidence> evidence;

  const VerificationMatch({
    required this.product,
    required this.confidence,
    required this.verificationState,
    required this.evidence,
  });

  factory VerificationMatch.fromJson(Map<String, dynamic> json) {
    return VerificationMatch(
      product:
          MatchedProduct.fromJson(json['product'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      verificationState: _parseVerificationState(
          json['verification_state'] as String? ?? ''),
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) =>
                  VerificationEvidence.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Top-level verification response.
///
/// [matches] is a ranked list (best first). An empty list means the engine
/// found no candidates at all — check [manualSearch] and surface the
/// no-result UI in that case.
class MultiVerificationResult {
  final String sessionId;
  final List<VerificationMatch> matches;
  final List<String> warnings;
  final int candidateCount;
  final bool manualSearch;
  final double processingTime;

  const MultiVerificationResult({
    required this.sessionId,
    required this.matches,
    required this.warnings,
    required this.candidateCount,
    required this.manualSearch,
    required this.processingTime,
  });

  // ── Convenience accessors ──────────────────────────────────────────────────

  bool get hasMatches => matches.isNotEmpty;

  VerificationMatch? get bestMatch =>
      matches.isNotEmpty ? matches.first : null;

  /// Overall state: [MultiVerificationState.noResult] when [matches] is empty,
  /// otherwise the state of the best (first) match.
  MultiVerificationState get overallState => matches.isEmpty
      ? MultiVerificationState.noResult
      : matches.first.verificationState;

  /// Confidence of the best match, or 0.0 when there are no matches.
  double get overallConfidence =>
      matches.isEmpty ? 0.0 : matches.first.confidence;

  factory MultiVerificationResult.fromJson(Map<String, dynamic> json) {
    return MultiVerificationResult(
      sessionId: json['session_id'] as String? ?? '',
      matches: (json['matches'] as List<dynamic>?)
              ?.map(
                  (m) => VerificationMatch.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((w) => w as String)
              .toList() ??
          [],
      candidateCount: (json['candidate_count'] as num?)?.toInt() ?? 0,
      manualSearch: json['manual_search'] as bool? ?? false,
      processingTime: (json['processing_time'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VerificationSession {
  final String id;
  final List<File> images;
  final String? barcode;
  final String? registrationNumber;
  final String? productName;
  final List<String> manufacturers;
  final List<String> ingredients;
  final VerificationUploadStatus status;

  const VerificationSession({
    required this.id,
    required this.images,
    this.barcode,
    this.registrationNumber,
    this.productName,
    this.manufacturers = const [],
    this.ingredients = const [],
    required this.status,
  });

  VerificationSession copyWith({
    String? id,
    List<File>? images,
    String? barcode,
    bool clearBarcode = false,
    String? registrationNumber,
    bool clearRegistrationNumber = false,
    String? productName,
    bool clearProductName = false,
    List<String>? manufacturers,
    List<String>? ingredients,
    VerificationUploadStatus? status,
  }) {
    return VerificationSession(
      id: id ?? this.id,
      images: images ?? this.images,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      registrationNumber: clearRegistrationNumber
          ? null
          : (registrationNumber ?? this.registrationNumber),
      productName:
          clearProductName ? null : (productName ?? this.productName),
      manufacturers: manufacturers ?? this.manufacturers,
      ingredients: ingredients ?? this.ingredients,
      status: status ?? this.status,
    );
  }
}
