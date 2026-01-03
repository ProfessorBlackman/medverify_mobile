
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

class FeedbackService {
  final String _endpoint = 'http://localhost:8000/feedback';

  Future<bool> sendFeedback({
    String? name,
    required String email,
    required String feedbackType,
    required String message,
    List<File>? attachments,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));

      // Add text fields
      request.fields['email'] = email;
      request.fields['feedback_type'] = feedbackType;
      request.fields['message'] = message;
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      // Add attachments if any
      if (attachments != null) {
        for (final file in attachments) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments', // Field name on the backend
              file.path,
            ),
          );
        }
      }

      final response = await request.send();

      return response.statusCode == 200;
    } catch (e) {
      // In a real app, you'd want to log this error
      await Sentry.captureException(e);
      return false;
    }
  }
}
