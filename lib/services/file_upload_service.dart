
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'auth_exceptions.dart';
import 'device_auth_service.dart';

enum FilePurpose {
  feedback,
  improve,
}

class UploadResult {
  final String? url;
  final String? error;

  const UploadResult._({this.url, this.error});

  static UploadResult success(String url) => UploadResult._(url: url);
  static UploadResult failure(String error) => UploadResult._(error: error);

  bool get isSuccess => url != null;
}

class FileUploadService {
  static const _timeout = Duration(seconds: 60);

  static const _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  };
  static const _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  void _validateFile(File file) {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    if (!_allowedMimeTypes.contains(mimeType)) {
      throw const FileValidationException(
          'Unsupported file type. Allowed types: JPEG, PNG, WebP, PDF.');
    }
    if (file.lengthSync() > _maxFileSizeBytes) {
      throw const FileValidationException(
          'File too large. Maximum size is 10 MB.');
    }
  }

  Future<UploadResult> uploadFile(
    File file,
    FilePurpose purpose, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      _validateFile(file);
    } on FileValidationException catch (e) {
      // User error — low severity, no Sentry
      await FirebaseAnalytics.instance.logEvent(
        name: 'upload_failure',
        parameters: {'stage': 'validation'},
      );
      return UploadResult.failure(e.message);
    }

    try {
      final presignedUrlResponse = await _getPresignedUrl(file, purpose);
      if (presignedUrlResponse == null) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'upload_failure',
          parameters: {'stage': 'presign'},
        );
        return UploadResult.failure('Failed to get upload URL.');
      }

      final uploadUrl = presignedUrlResponse['upload_url']!;
      final uploadHost = Uri.parse(uploadUrl).host;
      if (!uploadHost.endsWith('.amazonaws.com')) {
        throw Exception('Unexpected upload host: $uploadHost');
      }

      final uploadSuccess = await _uploadToS3(
        file,
        uploadUrl,
        presignedUrlResponse['content_type']!,
        onProgress: onProgress,
      );

      if (!uploadSuccess) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'upload_failure',
          parameters: {'stage': 'upload'},
        );
        return UploadResult.failure('File upload failed.');
      }

      final confirmed =
          await _confirmUpload(presignedUrlResponse['file_key']!);
      if (!confirmed) {
        await Sentry.captureMessage(
            'Upload confirmation failed for key: ${presignedUrlResponse['file_key']}');
        await FirebaseAnalytics.instance.logEvent(
          name: 'upload_failure',
          parameters: {'stage': 'confirm'},
        );
        return UploadResult.failure('Upload confirmation failed.');
      }

      return UploadResult.success(presignedUrlResponse['file_url']!);
    } catch (e) {
      await Sentry.captureException(e);
      return UploadResult.failure('Upload failed due to an unexpected error.');
    }
  }

  Future<Map<String, dynamic>?> _getPresignedUrl(
      File file, FilePurpose purpose) async {
    final fileName = file.path.split('/').last;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    // Serialize once — same bytes used for HMAC signing and the HTTP body
    final bodyBytes = Uint8List.fromList(utf8.encode(json.encode({
      'file_name': fileName,
      'content_type': mimeType,
      'file_purpose': purpose.name,
    })));

    final response = await DeviceAuthService.instance
        .authenticatedPost('/generate-upload-url', bodyBytes)
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'upload_url': data['upload_url'],
        'file_key': data['file_key'],
        'file_url': data['file_url'],
        'content_type': mimeType,
      };
    }
    await Sentry.captureMessage('Presigned URL error: ${response.statusCode}');
    return null;
  }

  // Uploads to S3 using Dio for streaming progress and retry support.
  // Retries up to 3 times with exponential backoff (1 s, 2 s, 4 s) on
  // timeouts and 5xx responses; other errors are reported and not retried.
  Future<bool> _uploadToS3(
    File file,
    String uploadUrl,
    String contentType, {
    void Function(double progress)? onProgress,
  }) async {
    final dio = Dio();
    const maxAttempts = 3;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final fileSize = await file.length();

        final response = await dio.put<void>(
          uploadUrl,
          data: file.openRead(),
          options: Options(
            headers: {
              'Content-Type': contentType,
              'Content-Length': fileSize,
            },
            sendTimeout: _timeout,
            receiveTimeout: _timeout,
          ),
          onSendProgress: (sent, total) {
            // Use measured file size as fallback when Dio reports total = -1
            final denominator = total > 0 ? total : fileSize;
            onProgress?.call(sent / denominator);
          },
        );

        return (response.statusCode ?? 0) == 200;
      } on DioException catch (e) {
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response != null && (e.response!.statusCode ?? 0) >= 500);

        if (!isRetryable || attempt == maxAttempts - 1) {
          await Sentry.captureException(e);
          return false;
        }

        await FirebaseAnalytics.instance.logEvent(
          name: 'upload_retry',
          parameters: {'attempt': attempt + 1},
        );

        // Exponential backoff: 1 s, 2 s, 4 s
        await Future.delayed(Duration(seconds: 1 << attempt));
      } catch (e) {
        await Sentry.captureException(e);
        return false;
      }
    }
    return false;
  }

  Future<bool> _confirmUpload(String fileKey) async {
    try {
      // Spec: POST /confirm-upload?file_key=<key> with empty body.
      // Path used for signing is /confirm-upload (no query string).
      final response = await DeviceAuthService.instance
          .authenticatedPost(
            '/confirm-upload',
            Uint8List(0),
            queryString: 'file_key=${Uri.encodeComponent(fileKey)}',
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
  }
}
