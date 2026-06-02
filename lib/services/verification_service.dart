import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/verification_result.dart';
import '../utils/variables.dart';

class VerificationService {
  static const _timeout = Duration(seconds: 30);

  Future<Set<VerificationResult>> verifyBarcode(String barcode) async {
    final url = Uri.parse(backendUrl).replace(
      path: '/barcode',
      queryParameters: {'bc': barcode},
    );

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((j) => VerificationResult.fromJson(j)).toSet();
        } on FormatException catch (e) {
          await Sentry.captureException(e);
          throw Exception('Invalid response format from server');
        }
      } else {
        await Sentry.captureMessage('Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to perform search: $e');
    }
  }

  Future<Set<VerificationResult>> verifyFuzzySearch(String drugName) async {
    final url = Uri.parse(backendUrl).replace(
      path: '/search',
      queryParameters: {'search_term': drugName},
    );

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((j) => VerificationResult.fromJson(j)).toSet();
        } on FormatException catch (e) {
          await Sentry.captureException(e);
          throw Exception('Invalid response format from server');
        }
      } else {
        await Sentry.captureMessage('Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to perform search: $e');
    }
  }
}
