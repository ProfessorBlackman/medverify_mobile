enum VerificationStatus {
  verified,
  unregistered,
  expired,
  recalled,
  nearExpired
}

class VerificationResult {
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


  VerificationResult({
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
  });

  Map<String, dynamic> toMap() {
    return {
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
    };
  }

  static VerificationResult fromMap(Map<String, dynamic> map) {
    return VerificationResult(
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
    );
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      status: VerificationStatus.values.firstWhere(
            (e) => e.toString() == 'VerificationStatus.${json['status']}',
        orElse: () => VerificationStatus.unregistered, // Default value
      ),
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
    );
  }
}