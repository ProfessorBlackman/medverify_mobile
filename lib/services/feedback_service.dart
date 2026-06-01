
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'device_auth_service.dart';
import 'file_upload_service.dart';

class FeedbackService {
  final FileUploadService _uploadService;

  FeedbackService({FileUploadService? uploadService})
      : _uploadService = uploadService ?? FileUploadService();

  Future<bool> sendFeedback({
    String? name,
    required String email,
    required String feedbackType,
    required String message,
    List<File>? attachments,
  }) async {
    try {
      List<String> attachmentUrls = [];
      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          final url =
              await _uploadService.uploadFile(file, FilePurpose.feedback);
          if (url != null) attachmentUrls.add(url);
        }
      }

      // Serialize once — same bytes used for HMAC signing and the HTTP body
      final bodyBytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'name': name,
        'email': email,
        'feedback_type': feedbackType,
        'message': message,
        'attachments': attachmentUrls,
      })));

      final response = await DeviceAuthService.instance
          .authenticatedPost('/feedback', bodyBytes);

      return response.statusCode == 201;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
  }
}
