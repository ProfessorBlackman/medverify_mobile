
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
    String? email,
    String? phone,
    required String feedbackType,
    required String message,
    List<File>? attachments,
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      List<String> attachmentUrls = [];
      if (attachments != null && attachments.isNotEmpty) {
        final count = attachments.length;
        for (var i = 0; i < count; i++) {
          // Each file owns an equal slice of the 0→1 progress range.
          void Function(double)? fileProgress;
          if (onUploadProgress != null) {
            fileProgress = (p) => onUploadProgress((i + p) / count);
          }
          final result = await _uploadService.uploadFile(
            attachments[i],
            FilePurpose.feedback,
            onProgress: fileProgress,
          );
          if (result.isSuccess) attachmentUrls.add(result.url!);
        }
        onUploadProgress?.call(1.0);
      }

      // Serialize once — same bytes used for HMAC signing and the HTTP body.
      // Omit null/empty contact fields so anonymous submissions are truly sparse.
      final Map<String, dynamic> payload = {
        'feedback_type': feedbackType,
        'message': message,
        'attachments': attachmentUrls,
      };
      if (name != null && name.isNotEmpty) payload['name'] = name;
      if (email != null && email.isNotEmpty) payload['email'] = email;
      if (phone != null && phone.isNotEmpty) payload['phone'] = phone;
      final bodyBytes =
          Uint8List.fromList(utf8.encode(jsonEncode(payload)));

      final response = await DeviceAuthService.instance
          .authenticatedPost('/v1/feedback', bodyBytes);

      return response.statusCode == 201;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
  }
}
