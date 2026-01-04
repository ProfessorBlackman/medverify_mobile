
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'flile_upload_service.dart'; // Corrected import

class FeedbackService {
  final String _endpoint = 'https://a0869a4b009d.ngrok-free.app/feedback';
  final FileUploadService _uploadService;

  FeedbackService({FileUploadService? uploadService}) : _uploadService = uploadService ?? FileUploadService();

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
          final url = await _uploadService.uploadFile(file);
          if (url != null) {
            attachmentUrls.add(url);
          }
        }
      }


      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'feedback_type': feedbackType,
          'message': message,
          'attachments': attachmentUrls,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      await Sentry.captureException(e);
      return false;
    }
  }
}
