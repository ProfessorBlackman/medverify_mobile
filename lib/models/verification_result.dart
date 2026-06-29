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
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null,
      approvalDate: map['approvalDate'] != null ? DateTime.tryParse(map['approvalDate']) : null,
      scannedAt: map['scannedAt'] != null ? DateTime.tryParse(map['scannedAt']) : null,
      price: map['price'],
      source: map['source'],
    );
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    String statusStr = json['status']?.toString() ?? '';
    if (statusStr == 'near_expiry') {
      statusStr = 'nearExpiry';
    }

    final statusMap = {
      for (final e in VerificationStatus.values) e.name: e,
    };

    final resolvedStatus = statusMap[statusStr];
    if (resolvedStatus == null) {
      Sentry.captureMessage('Unknown drug status received: "$statusStr"');
    }

    // Handle both new list format ('image_urls') and legacy string format ('image_url').
    List<String>? imageUrls;
    if (json['image_urls'] is List) {
      imageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (json['image_url'] is String) {
      imageUrls = [json['image_url'] as String];
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
      approvalDate: json['registration_date'] != null ? DateTime.tryParse(json['registration_date'] as String) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
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
