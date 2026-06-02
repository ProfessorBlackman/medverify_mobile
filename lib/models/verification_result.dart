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
  final String? imageUrl;
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
    this.imageUrl,
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
      'expiryDate': expiryDate?.toIso8601String(),
      'activeIngredient': activeIngredient,
      'email': email,
      'approvalDate': approvalDate?.toIso8601String(),
      'postalAddress': postalAddress,
      'registrationType': registrationType,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'category': category,
      'message': message,
      'scannedAt': scannedAt?.toIso8601String(),
      'price': price,
      'source': source,
    };
  }

  static VerificationResult fromMap(Map<String, dynamic> map) {
    return VerificationResult(
      id: map['id'] as String?,
      status: map['status'] != null ? VerificationStatus.values[map['status'] as int] : null,
      productName: map['productName'],
      manufacturer: map['manufacturer'],
      countryOrigin: map['countryOrigin'],
      region: map['region'],
      regNumber: map['regNumber'],
      activeIngredient: map['activeIngredient'],
      email: map['email'],
      postalAddress: map['postalAddress'],
      registrationType: map['registrationType'],
      imageUrl: map['imageUrl'],
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

    return VerificationResult(
      status: statusMap[statusStr] ?? VerificationStatus.pending,
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
      imageUrl: json['image_url'],
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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      message: message ?? this.message,
      scannedAt: scannedAt ?? this.scannedAt,
      price: price ?? this.price,
      source: source ?? this.source,
    );
  }
}
