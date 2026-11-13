import 'package:sentry_flutter/sentry_flutter.dart';

enum VerificationStatus {
  verified,
  valid,
  invalid,
  unregistered,
  expired,
  recalled,
  nearExpiry,
  pending,
  // The register holds a value we do not recognise. Distinct from
  // `unregistered`, which is the positive claim that a product is absent from
  // the register — never show one as the other. Appended last on purpose:
  // Hive persists this enum by index, so existing scan history keeps its
  // meaning.
  none,
}

/// Maps the API's `status` string onto [VerificationStatus].
///
/// The wire format is snake_case (`near_expiry`) and the enum is lowerCamel,
/// so the two need an explicit bridge. Every caller must use this one —
/// `/v1/search` and `/v1/verifications` both send this vocabulary, and a
/// second hand-rolled copy of this mapping is what caused matched products to
/// render as UNREGISTERED.
///
/// Returns `null` for a value this build does not know, so the caller can
/// decide what to do; it does **not** silently fall back to a status that
/// makes a claim about the product.
VerificationStatus? verificationStatusFromApi(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) return null;

  const wireNames = <String, VerificationStatus>{
    'near_expiry': VerificationStatus.nearExpiry,
    'near-expiry': VerificationStatus.nearExpiry,
    'near expiry': VerificationStatus.nearExpiry,
  };

  final normalised = value.toLowerCase();
  final aliased = wireNames[normalised];
  if (aliased != null) return aliased;

  for (final status in VerificationStatus.values) {
    if (status.name.toLowerCase() == normalised) return status;
  }
  return null;
}

class VerificationResult {
  final String? id;
  final VerificationStatus? status;
  final String? productName;
  final String? manufacturer;
  final String? countryOrigin;
  final String? region;
  final String? regNumber; // registration_number
  final DateTime? expiryDate; // expiry_date
  final String? activeIngredient;
  final String? email;
  final DateTime? approvalDate; // registration_date
  final String? postalAddress;
  final String? registrationType;
  final List<String>? imageUrls;
  final String? barcode;
  final String? category;
  final String? message;
  final DateTime? scannedAt;
  final String? price;
  final String? source;

  VerificationResult({
    this.id,
    this.status,
    this.productName,
    this.manufacturer,
    this.countryOrigin,
    this.region,
    this.regNumber,
    this.expiryDate,
    this.activeIngredient,
    this.email,
    this.approvalDate,
    this.postalAddress,
    this.registrationType,
    this.imageUrls,
    this.barcode,
    this.category,
    this.message,
    this.scannedAt,
    this.price,
    this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status?.index,
      'productName': productName,
      'manufacturer': manufacturer,
      'countryOrigin': countryOrigin,
      'region': region,
      'regNumber': regNumber,
      'expiryDate': expiryDate?.toUtc().toIso8601String(),
      'activeIngredient': activeIngredient,
      'email': email,
      'approvalDate': approvalDate?.toUtc().toIso8601String(),
      'postalAddress': postalAddress,
      'registrationType': registrationType,
      'imageUrls': imageUrls,
      'barcode': barcode,
      'category': category,
      'message': message,
      'scannedAt': scannedAt?.toUtc().toIso8601String(),
      'price': price,
      'source': source,
    };
  }

  static VerificationStatus? _statusFromIndex(dynamic raw) {
    if (raw == null) return null;
    // Hive's MessagePack can deserialise integers as double — normalise first.
    final index = (raw as num).toInt();
    if (index < 0 || index >= VerificationStatus.values.length) {
      Sentry.captureMessage('Out-of-range VerificationStatus index: $index');
      return null;
    }
    return VerificationStatus.values[index];
  }

  static VerificationResult fromMap(Map<String, dynamic> map) {
    // Backward compatibility: old Hive records stored a single 'imageUrl' string.
    // New records store 'imageUrls' as a list.
    List<String>? imageUrls;
    if (map['imageUrls'] != null) {
      imageUrls = (map['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (map['imageUrl'] != null) {
      imageUrls = [map['imageUrl'] as String];
    }

    return VerificationResult(
      id: map['id'] as String?,
      status: _statusFromIndex(map['status']),
      productName: map['productName'],
      manufacturer: map['manufacturer'],
      countryOrigin: map['countryOrigin'],
      region: map['region'],
      regNumber: map['regNumber'],
      activeIngredient: map['activeIngredient'],
      email: map['email'],
      postalAddress: map['postalAddress'],
      registrationType: map['registrationType'],
      imageUrls: imageUrls,
      barcode: map['barcode'],
      category: map['category'],
      message: map['message'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'])
          : null,
      approvalDate: map['approvalDate'] != null
          ? DateTime.tryParse(map['approvalDate'])
          : null,
      scannedAt: map['scannedAt'] != null
          ? DateTime.tryParse(map['scannedAt'])
          : null,
      price: map['price'],
      source: map['source'],
    );
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final resolvedStatus = verificationStatusFromApi(json['status']);
    if (resolvedStatus == null) {
      Sentry.captureMessage(
        'Unknown drug status received: "${json['status']}"',
      );
    }

    // 'image_url' is what the API actually returns, and it is a list — see
    // VerificationResult in the backend's schemas/drug_schemas.py. It is
    // ordered operator-first, so imageUrls.first is the most accountable
    // photograph. 'image_urls' is only ever a *request* field on
    // /v1/verifications; it is accepted here for older cached payloads, as is
    // the single-string form 'image_url' predates.
    List<String>? imageUrls;
    final rawImages = json['image_url'] ?? json['image_urls'];
    if (rawImages is List) {
      imageUrls = rawImages
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      if (imageUrls.isEmpty) imageUrls = null;
    } else if (rawImages is String && rawImages.isNotEmpty) {
      imageUrls = [rawImages];
    }

    return VerificationResult(
      status: resolvedStatus ?? VerificationStatus.unregistered,
      productName: json['product_name'] ?? 'Unknown Product',
      manufacturer: json['manufacturer'] ?? 'Unknown Manufacturer',
      regNumber: json['registration_number'] ?? 'N/A',
      message: json['message'] ?? '',
      category: json['category'] ?? 'UNKNOWN',
      countryOrigin: json['country_origin'],
      region: json['region'],
      activeIngredient: json['active_ingredient'],
      email: json['email'],
      postalAddress: json['postal_address'],
      registrationType: json['registration_type'],
      imageUrls: imageUrls,
      barcode: json['barcode'],
      approvalDate: json['registration_date'] != null
          ? DateTime.tryParse(json['registration_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      price: json['price'],
      source: json['source'],
    );
  }

  VerificationResult copyWith({
    String? id,
    VerificationStatus? status,
    String? productName,
    String? manufacturer,
    String? countryOrigin,
    String? region,
    String? regNumber,
    DateTime? expiryDate,
    String? activeIngredient,
    String? email,
    DateTime? approvalDate,
    String? postalAddress,
    String? registrationType,
    List<String>? imageUrls,
    String? barcode,
    String? category,
    String? message,
    DateTime? scannedAt,
    String? price,
    String? source,
  }) {
    return VerificationResult(
      id: id ?? this.id,
      status: status ?? this.status,
      productName: productName ?? this.productName,
      manufacturer: manufacturer ?? this.manufacturer,
      countryOrigin: countryOrigin ?? this.countryOrigin,
      region: region ?? this.region,
      regNumber: regNumber ?? this.regNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      email: email ?? this.email,
      approvalDate: approvalDate ?? this.approvalDate,
      postalAddress: postalAddress ?? this.postalAddress,
      registrationType: registrationType ?? this.registrationType,
      imageUrls: imageUrls ?? this.imageUrls,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      message: message ?? this.message,
      scannedAt: scannedAt ?? this.scannedAt,
      price: price ?? this.price,
      source: source ?? this.source,
    );
  }
}
