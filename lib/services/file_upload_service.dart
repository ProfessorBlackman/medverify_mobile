
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'device_auth_service.dart';

enum FilePurpose {
  feedback,
  improve,
}

class FileUploadService {
  static const _timeout = Duration(seconds: 60);

  Future<String?> uploadFile(File file, FilePurpose purpose) async {
    try {
      final presignedUrlResponse = await _getPresignedUrl(file, purpose);
      if (presignedUrlResponse == null) return null;

      final uploadSuccess = await _uploadToS3(
        file,
        presignedUrlResponse['upload_url']!,
        presignedUrlResponse['content_type']!,
      );

      if (!uploadSuccess) return null;

      final confirmed = await _confirmUpload(presignedUrlResponse['file_key']!);
      if (!confirmed) {
        await Sentry.captureMessage('Upload confirmation failed for key: ${presignedUrlResponse['file_key']}');
        return null;
      }

      return presignedUrlResponse['file_url'];
    } catch (e) {
      await Sentry.captureException(e);
      return null;
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

  Future<bool> _uploadToS3(
    File file,
    String uploadUrl,
    String contentType,
  ) async {
    try {
      final bytes = await file.readAsBytes();

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
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
