import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class RequestSigner {
  RequestSigner._();
  static final RequestSigner instance = RequestSigner._();

  /// Builds the four auth headers required by every signed endpoint.
  ///
  /// [path] must be the URL path only — no query string, no domain.
  /// [body] must be the exact bytes sent over the wire.
  Map<String, String> buildHeaders({
    required String accessToken,
    required String devicePublicId,
    required String deviceSecretHex,
    required String method,
    required String path,
    required Uint8List body,
  }) {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final signature =
        _computeSignature(deviceSecretHex, method, path, timestamp, body);

    return {
      'Authorization': 'Bearer $accessToken',
      'X-Device-ID': devicePublicId,
      'X-Timestamp': timestamp,
      'X-Signature': signature,
      'Content-Type': 'application/json',
    };
  }

  String _computeSignature(
    String deviceSecretHex,
    String method,
    String path,
    String timestamp,
    Uint8List body,
  ) {
    // Step 1: SHA-256 of raw request body bytes
    final bodyHash = sha256.convert(body).toString();

    // Step 2: canonical message — literal \n separators
    final message = '$method\n$path\n$timestamp\n$bodyHash';

    // Step 3: HMAC-SHA256 with device_secret as key
    final keyBytes = _hexToBytes(deviceSecretHex);
    final digest = Hmac(sha256, keyBytes).convert(utf8.encode(message));

    return digest.toString(); // lowercase hex
  }

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
