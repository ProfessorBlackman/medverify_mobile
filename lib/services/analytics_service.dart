import 'dart:convert';
import 'dart:typed_data';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'device_auth_service.dart';



class AnalyticsService {
  // Private constructor
  AnalyticsService._();

  // Singleton instance
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Getter for the NavigatorObserver (used in MaterialApp)
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> _askPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }

  Future<void> init(){
    return _askPermission();
  }

  /// 1. Request Location Permission & Get Coordinates
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // Log a custom event
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logDrugScan({
    required String drugName,
    required String regNumber,
    required String status,
    String? source,
  }) async {
    // Generate once here so a 401-refresh retry in authenticatedPost reuses
    // the same code and avoids creating a duplicate backend scan record.
    final uniqueCode = const Uuid().v4();

    Position? pos = await _getCurrentLocation();
    String region = await _getRegion(pos);
    String userId = await DeviceAuthService.instance.getUserId() ?? '';

    setUserId(userId);
    await _analytics.logEvent(
      name: 'drug_scan',
      parameters: {
        'drug_name': drugName,
        'reg_number': regNumber,
        'status': status,
        'source': '$source',
        'lat': pos?.latitude ?? 0.0,
        'lng': pos?.longitude ?? 0.0,
        'region': region,
        'scanned_by': userId,
      },
    );

    // Mirror the scan to the backend for server-side attribution.
    // Non-fatal: a backend failure must not break the scan flow.
    _postScanToBackend(
      drugName: drugName,
      regNumber: regNumber,
      status: status,
      source: source,
      pos: pos,
      region: region,
      uniqueCode: uniqueCode,
    ).catchError((Object e) async {
      await Sentry.captureException(e);
    });
  }

  Future<void> _postScanToBackend({
    required String drugName,
    required String regNumber,
    required String status,
    String? source,
    Position? pos,
    required String region,
    required String uniqueCode,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    final bodyBytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'drug_name': drugName,
      'status': status,
      'unique_code': uniqueCode,
      'timestamp': timestamp,
      'reg_number': regNumber,
      'latitude': pos?.latitude.toString(),
      'longitude': pos?.longitude.toString(),
      'region': region,
      'source': source,
    })));

    await DeviceAuthService.instance
        .authenticatedPost('/analytics/scan', bodyBytes);
  }

  Future<String> _getRegion(Position? pos) async {
    String region = "Unknown";
    
    if (pos != null) {
      try {
        // Reverse geocode the coordinates to get the Region name
        List<Placemark> placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude
        );
    
        if (placemarks.isNotEmpty) {
          // 'administrativeArea' usually maps to the Region (e.g., Ashanti Region)
          region = placemarks.first.administrativeArea ?? "Unknown";
        }
      } catch (e) {
        await Sentry.captureException(e);
      }
    }
    return region;
  }

  // Log screen views manually (useful if not using the observer)
  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Set User Properties (e.g., user_type: 'premium')
  Future<void> setUserProperty({required String name, required String value}) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Log User IDs for cross-platform tracking
  Future<void> setUserId(String id) async {
    await _analytics.setUserId(id: id);
  }
}