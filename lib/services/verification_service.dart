import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/verification_result.dart';

class VerificationService {
  Future<VerificationResult> verifyBarcode(String barcode) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (barcode.startsWith('000')) {
      return VerificationResult(
        status: VerificationStatus.unregistered,
        productName: 'Unknown Product',
        manufacturer: 'Unknown Manufacturer',
        regNumber: 'N/A',
        message: 'Product Not Found in FDA Database',
        category: "UNKNOWN",
      );
    } else if (barcode.startsWith('999')) {
      return VerificationResult(
        status: VerificationStatus.recalled,
        productName: 'Dangerous Product',
        manufacturer: 'Bad Pharma Inc.',
        regNumber: 'FDA/GHA/99999',
        message: 'This batch has been recalled by the FDA for safety reasons.',
        category: "DRUG",
      );
    } else {
      // Default to Verified (Amoxicillin example)
      return VerificationResult(
        status: VerificationStatus.verified,
        productName: 'Amoxicillin Capsules BP',
        manufacturer: 'Ernest Chemists Ltd.',
        regNumber: 'FDA/GHA/12345',
        approvalDate: DateTime(2023, 1, 12),
        expiryDate: DateTime(2025, 10, 15),
        message: 'Authenticity confirmed by FDA Ghana',
        category: "DRUG",
      );
    }
  }

//   verify using the FDA number
  Future<VerificationResult> verifyFDANumber(String fdaNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // TODO: Implement FDA number verification logic here
    return VerificationResult(
      status: VerificationStatus.verified,
      productName: 'Amoxicillin Capsules BP',
      manufacturer: 'Ernest Chemists Ltd.',
      regNumber: 'FDA/GHA/12345',
      approvalDate: DateTime(2023, 1, 12),
      expiryDate: DateTime(2025, 10, 15),
      message: 'Authenticity confirmed by FDA Ghana',
      category: "DRUG",
    );
  }

  //   verify using fuzzy search
  Future<Set<VerificationResult>> verifyFuzzySearch(String drugName) async {
    final url = Uri.parse('https://8e28daff9252.ngrok-free.app/search?search_term=$drugName');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Assuming your VerificationResult has a fromJson factory constructor
        // If not, you'll need to create one.
        return data.map((json) => VerificationResult.fromJson(json)).toSet();
      } else {
        // Handle server errors (e.g., 500, 404)
        await Sentry.captureMessage('Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors (e.g., no connection)
      await Sentry.captureException(e);
      throw Exception('Failed to perform search: $e');
    }
  }
}
