import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/network_guard.dart';
import '../utils/variables.dart';
import 'auth_exceptions.dart';
import 'request_signer.dart';

const _kDevicePublicId = 'device_public_id';
const _kDeviceSecret = 'device_secret';
const _kUserId = 'user_id';
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

class DeviceAuthService {
  DeviceAuthService._();
  static final DeviceAuthService instance = DeviceAuthService._();

  final _storage = const FlutterSecureStorage();

  // Mutex: when non-null, a refresh is already in flight.
  // Concurrent callers await this future instead of starting a second refresh,
  // preventing the second caller from invalidating the rotated refresh token.
  Completer<void>? _refreshCompleter;

  Future<bool> isRegistered() async {
    final secret = await _storage.read(key: _kDeviceSecret);
    final id = await _storage.read(key: _kDevicePublicId);
    return secret != null && id != null;
  }

  /// Called on app startup. Registers if no credentials exist; proactively
  /// refreshes the access token if credentials are present but token is stale.
  Future<void> ensureRegistered() async {
    if (await isRegistered()) {
      try {
        await getValidAccessToken();
      } catch (_) {
        // Token refresh failed (expired or device blocked) — start fresh
        await _storage.deleteAll();
        await registerDevice();
      }
    } else {
      await registerDevice();
    }
  }

  Future<void> registerDevice() async {
    await requireConnectivity();

    final deviceId = const Uuid().v4();

    final response = await http.post(
      Uri.parse('$backendUrl/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_public_id': deviceId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': '1.0.0',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Device registration failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Use device_public_id from response — server may assign a different one
    // on UUID collision (Case C in the migration spec).
    await _storage.write(
        key: _kDevicePublicId, value: data['device_public_id'] as String);
    await _storage.write(
        key: _kDeviceSecret, value: data['device_secret'] as String);
    await _storage.write(key: _kUserId, value: data['user_id'] as String);
    await _storage.write(
        key: _kAccessToken, value: data['access_token'] as String);
    await _storage.write(
        key: _kRefreshToken, value: data['refresh_token'] as String);
  }

  /// Returns a valid access token, refreshing it proactively if it expires
  /// within 60 seconds.
  Future<String> getValidAccessToken() async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) throw Exception('Not registered');

    final decoded = JwtDecoder.decode(token);
    final exp = decoded['exp'] as int;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    if (DateTime.now().add(const Duration(seconds: 60)).isAfter(expiresAt)) {
      await _refreshTokens();
    }

    return (await _storage.read(key: _kAccessToken))!;
  }

  Future<String> getDevicePublicId() async {
    return (await _storage.read(key: _kDevicePublicId)) ?? '';
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _kUserId);
  }

  Future<void> _refreshTokens() async {
    // If a refresh is already in flight, piggyback on it rather than starting
    // a second one. A concurrent second refresh would use the already-rotated
    // refresh token and receive a 401, triggering deleteAll() and wiping the
    // device identity.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      await requireConnectivity();

      final refreshToken = await _storage.read(key: _kRefreshToken);
      if (refreshToken == null) throw Exception('No refresh token');

      final response = await http.post(
        Uri.parse('$backendUrl/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _storage.deleteAll();
        throw Exception('Session expired, re-registration required');
      }

      if (response.statusCode != 200) {
        throw Exception('Token refresh failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _storage.write(
          key: _kAccessToken, value: data['access_token'] as String);
      await _storage.write(
          key: _kRefreshToken, value: data['refresh_token'] as String);

      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Makes a signed POST request with automatic 401 → refresh → retry.
  ///
  /// [path] is the URL path only (e.g. '/feedback') — no domain, no query
  /// string. Pass [queryString] separately if needed (e.g. 'file_key=abc');
  /// it is appended to the URL but NOT included in the signature path.
  /// [body] must be the exact bytes to send; use [Uint8List(0)] for empty
  /// bodies.
  Future<http.Response> authenticatedPost(
    String path,
    Uint8List body, {
    String? queryString,
  }) async {
    await requireConnectivity();

    // Ensure the stored access token is fresh before we sign
    await getValidAccessToken();

    Future<http.Response> doRequest() async {
      final accessToken = (await _storage.read(key: _kAccessToken)) ?? '';
      final devicePublicId =
          (await _storage.read(key: _kDevicePublicId)) ?? '';
      final deviceSecret = (await _storage.read(key: _kDeviceSecret)) ?? '';

      final headers = RequestSigner.instance.buildHeaders(
        accessToken: accessToken,
        devicePublicId: devicePublicId,
        deviceSecretHex: deviceSecret,
        method: 'POST',
        path: path,
        body: body,
      );

      final uri = queryString != null
          ? Uri.parse('$backendUrl$path?$queryString')
          : Uri.parse('$backendUrl$path');

      return http.post(uri, headers: headers, body: body);
    }

    var response = await doRequest();

    if (response.statusCode == 401) {
      try {
        await _refreshTokens();
        response = await doRequest();
      } catch (e) {
        await Sentry.captureException(e);
      }
    }

    if (response.statusCode == 403) {
      // Device blocked by the backend — credentials are permanently invalid.
      // The app must not retry; surface a permanent message to the user.
      await _storage.deleteAll();
      throw const DeviceBlockedException();
    }

    if (response.statusCode == 400) {
      // Malformed or missing signature headers. Throw so callers can
      // distinguish this from a transient server error.
      throw SignatureException(
          'Signature rejected by server for path: $path');
    }

    return response;
  }
}
