
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/variables.dart';

enum FilePurpose {
  feedback,
  improve,
}

class FileUploadService {
  static final String baseUrl = backendUrl; // Using the feedback service base URL

  Future<String?> uploadFile(File file, FilePurpose purpose) async {
    try {
      // Step 1: Get presigned URL from backend
      final presignedUrlResponse = await _getPresignedUrl(file, purpose);
      if (presignedUrlResponse == null) return null;

      // Step 2: Upload file directly to S3
      final uploadSuccess = await _uploadToS3(
        file,
        presignedUrlResponse['upload_url']!,
        presignedUrlResponse['content_type']!,
      );

      if (uploadSuccess) {
        // Step 3: Optionally confirm upload with backend
        await _confirmUpload(presignedUrlResponse['file_key']!);

        // Return the file URL for your backend to store
        return presignedUrlResponse['file_url'];
      }

      return null;
    } catch (e) {
      await Sentry.captureException(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getPresignedUrl(
      File file, FilePurpose purpose) async {
    final fileName = file.path.split('/').last;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final response = await http.post(
      Uri.parse('$baseUrl/generate-upload-url'),
      headers: {
        'Content-Type': 'application/json',
        // Add your authentication headers here if needed
        // 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'file_name': fileName,
        'content_type': mimeType,
        'file_purpose': purpose.name,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'upload_url': data['upload_url'],
        'file_key': data['file_key'],
        'file_url': data['file_url'],
        'content_type': mimeType,
      };
    }
    await Sentry.captureMessage('Server error: ${response.statusCode}');
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
      );

      return response.statusCode == 200;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
  }

  Future<void> _confirmUpload(String fileKey) async {
    await http.post(
      Uri.parse('$baseUrl/confirm-upload'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'file_key': fileKey}),
    );
  }
}
