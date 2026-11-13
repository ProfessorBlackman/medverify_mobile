import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_exceptions.dart';

/// Throws [NoConnectivityException] if the device has no active network.
/// Call this before any HTTP request to surface offline state cleanly
/// instead of letting a SocketException bubble up.
Future<void> requireConnectivity() async {
  final results = await Connectivity().checkConnectivity();
  // every() returns true on an empty list (vacuous truth), covering that case.
  if (results.every((r) => r == ConnectivityResult.none)) {
    throw const NoConnectivityException();
  }
}
