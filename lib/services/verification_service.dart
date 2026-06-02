import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    final http.Response response;
    try {
      response = await http.get(url).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection.');
    } on SocketException {
      throw Exception('No internet connection.');
    }

    if (response.statusCode != 200) {
      await Sentry.captureMessage('Barcode lookup error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw FormatException(
          'Unexpected response shape: expected List, got ${decoded.runtimeType}');
    }
    return decoded
        .map((j) => VerificationResult.fromJson(j as Map<String, dynamic>))
        .toSet();
  }

  Future<Set<VerificationResult>> verifyFuzzySearch(String drugName) async {
    final url = Uri.parse(backendUrl).replace(
      path: '/search',
      queryParameters: {'search_term': drugName},
    );

    final http.Response response;
    try {
      response = await http.get(url).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection.');
    } on SocketException {
      throw Exception('No internet connection.');
    }

    if (response.statusCode != 200) {
      await Sentry.captureMessage('Drug search error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw FormatException(
          'Unexpected response shape: expected List, got ${decoded.runtimeType}');
    }
    return decoded
        .map((j) => VerificationResult.fromJson(j as Map<String, dynamic>))
        .toSet();
  }
}
