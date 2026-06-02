import 'package:dio/dio.dart';
import '../utils/variables.dart';

/// Singleton pre-configured Dio instance shared by all services.
///
/// Call [ApiClient.instance.init()] once in main() before runApp.
/// `validateStatus: (_) => true` means all HTTP status codes are returned
/// as normal responses — services handle error codes explicitly rather than
/// relying on thrown DioExceptions for 4xx/5xx.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: backendUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (_) => true,
      ),
    );
  }

  Dio get dio => _dio;
}
