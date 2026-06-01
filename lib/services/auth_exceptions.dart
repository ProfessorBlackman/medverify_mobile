class DeviceBlockedException implements Exception {
  final String message;
  const DeviceBlockedException(
      [this.message =
          'This device has been blocked. Please contact support.']);

  @override
  String toString() => 'DeviceBlockedException: $message';
}

class SignatureException implements Exception {
  final String message;
  const SignatureException(
      [this.message = 'Request signature was rejected by the server.']);

  @override
  String toString() => 'SignatureException: $message';
}

class NoConnectivityException implements Exception {
  const NoConnectivityException();

  @override
  String toString() => 'NoConnectivityException: No internet connection.';
}

class FileValidationException implements Exception {
  final String message;
  const FileValidationException(this.message);

  @override
  String toString() => 'FileValidationException: $message';
}
