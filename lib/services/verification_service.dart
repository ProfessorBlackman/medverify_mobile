import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/verification_result.dart';
import 'api_client.dart';

class VerificationService {
  Future<Set<VerificationResult>> verifyBarcode(String barcode) async {
    final Response<dynamic> response;
    try {
      response = await ApiClient.instance.dio
          .get('/v1/barcode', queryParameters: {'bc': barcode});
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

    if (response.statusCode != 200) {
      await Sentry.captureMessage(
          'Barcode lookup error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }

    if (response.data is! List) {
      throw FormatException(
          'Unexpected response shape: expected List, got ${response.data.runtimeType}');
    }
    return (response.data as List)
        .map((j) => VerificationResult.fromJson(j as Map<String, dynamic>))
        .toSet();
  }

  Future<Set<VerificationResult>> verifyFuzzySearch(String drugName) async {
    final Response<dynamic> response;
    try {
      response = await ApiClient.instance.dio
          .get('/v1/search', queryParameters: {'search_term': drugName});
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

    if (response.statusCode != 200) {
      await Sentry.captureMessage('Drug search error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }

    if (response.data is! List) {
      throw FormatException(
          'Unexpected response shape: expected List, got ${response.data.runtimeType}');
    }
    return (response.data as List)
        .map((j) => VerificationResult.fromJson(j as Map<String, dynamic>))
        .toSet();
  }
}
