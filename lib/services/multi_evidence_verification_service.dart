import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../models/multi_evidence_verification.dart';
import 'api_client.dart';

class MultiEvidenceVerificationService {
  Future<MultiVerificationResult> verifyProduct({
    List<String>? imageUrls,
    String? barcode,
    String? registrationNumber,
    String? productName,
    List<String>? manufacturers,
    List<String>? ingredients,
  }) async {
    final hasEvidence = (imageUrls != null && imageUrls.isNotEmpty) ||
        barcode != null ||
        registrationNumber != null ||
        productName != null ||
        (manufacturers != null && manufacturers.isNotEmpty) ||
        (ingredients != null && ingredients.isNotEmpty);

    if (!hasEvidence) {
      throw ArgumentError('At least one piece of evidence must be provided.');
    }

    final body = <String, dynamic>{};
    if (imageUrls != null && imageUrls.isNotEmpty) {
      body['image_urls'] = imageUrls;
    }
    if (barcode != null) body['barcode'] = barcode;
    if (registrationNumber != null) {
      body['registration_number'] = registrationNumber;
    }
    if (productName != null) body['product_name'] = productName;
    if (manufacturers != null && manufacturers.isNotEmpty) {
      body['manufacturers'] = manufacturers;
    }
    if (ingredients != null && ingredients.isNotEmpty) {
      body['ingredients'] = ingredients;
    }

    final Response<dynamic> response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/verifications',
        data: body,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Check your connection.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection.');
      }
      rethrow;
    }

    if (response.statusCode == 422) {
      throw Exception(
          'Invalid request: no valid inputs provided or unsupported image format.');
    }
    if (response.statusCode == 429) {
      throw Exception(
          'Too many requests. Please wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      await Sentry.captureMessage(
          'Multi-evidence verification error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }

    if (response.data is! Map<String, dynamic>) {
      throw FormatException(
          'Unexpected response shape: ${response.data.runtimeType}');
    }
    return MultiVerificationResult.fromJson(
        response.data as Map<String, dynamic>);
  }
}
