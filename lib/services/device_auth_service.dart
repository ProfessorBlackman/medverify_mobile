import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/network_guard.dart';
import 'api_client.dart';
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
      } catch (e, stackTrace) {
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

    final platform = Platform.isAndroid ? 'android' : 'ios';
    final deviceId = const Uuid().v4();
    final appVersion = (await PackageInfo.fromPlatform()).version;

    try {
      final response = await ApiClient.instance.dio.post(
        '/v1/register-device',
        data: {
          'device_public_id': deviceId,
          'platform': platform,
          'app_version': appVersion,
        },
      );

      if (response.statusCode != 201) {
        throw Exception('Device registration failed: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;

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

      await FirebaseAnalytics.instance.logEvent(
        name: 'device_registration_success',
        parameters: {'platform': platform},
      );
    } catch (e) {
      await FirebaseAnalytics.instance.logEvent(
        name: 'device_registration_failure',
        parameters: {'error_type': e.runtimeType.toString()},
      );
      rethrow;
    }
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

      final response = await ApiClient.instance.dio.post(
        '/v1/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _storage.deleteAll();
        await FirebaseAnalytics.instance.logEvent(
          name: 'token_refresh_failure',
          parameters: {'status_code': response.statusCode ?? 0},
        );
        throw Exception('Session expired, re-registration required');
      }

      if (response.statusCode != 200) {
        throw Exception('Token refresh failed: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      await _storage.write(
          key: _kAccessToken, value: data['access_token'] as String);
      await _storage.write(
          key: _kRefreshToken, value: data['refresh_token'] as String);

      await FirebaseAnalytics.instance.logEvent(name: 'token_refresh_success');
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
  /// [path] is the full URL path including the /v1 prefix (e.g. '/v1/feedback').
  /// Pass [queryString] separately if needed (e.g. 'file_key=abc'); it is
  /// appended to the URL but NOT included in the signature path.
  /// [body] must be the exact bytes to send; use [Uint8List(0)] for empty bodies.
  Future<Response<dynamic>> authenticatedPost(
    String path,
    Uint8List body, {
    String? queryString,
  }) async {
    await requireConnectivity();

    // Ensure the stored access token is fresh before we sign.
    await getValidAccessToken();

    Future<Response<dynamic>> doRequest() async {
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

      final requestPath =
          queryString != null ? '$path?$queryString' : path;

      // Decode bytes to string so Dio sends the exact same UTF-8 bytes that
      // were used to compute the HMAC. Passing Uint8List directly risks
      // content-type or encoding mutations.
      final bodyData = body.isEmpty ? null : utf8.decode(body);

      return ApiClient.instance.dio.post(
        requestPath,
        data: bodyData,
        options: Options(headers: headers),
      );
    }

    var response = await doRequest();

    if (response.statusCode == 401) {
      try {
        await _refreshTokens();
        response = await doRequest();
      } catch (e) {
        await Sentry.captureException(e);
        rethrow; // CRIT-03: propagate — never silently return a stale 401
      }
    }

    if (response.statusCode == 403) {
      // Device blocked by the backend — credentials are permanently invalid.
      await _storage.deleteAll();
      throw const DeviceBlockedException();
    }

    if (response.statusCode == 400) {
      await FirebaseAnalytics.instance.logEvent(
        name: 'signature_failure',
        parameters: {'path': path},
      );
      throw SignatureException('Signature rejected by server for path: $path');
    }

    return response;
  }
}
