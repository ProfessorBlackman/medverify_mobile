import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/feedback_service.dart';
import '../theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedFeedbackType = 'Report a Bug';
  final List<File> _attachments = [];
  bool _isLoading = false;

  final FeedbackService _feedbackService = FeedbackService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _feedbackService.sendFeedback(
      name: _nameController.text,
      email: _emailController.text,
      feedbackType: _selectedFeedbackType,
      message: _messageController.text,
      attachments: _attachments,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Feedback sent successfully!'
              : 'Failed to send feedback. Please try again.'),
          backgroundColor: success ? AppTheme.primaryGreen : AppTheme.warningRed,
        ),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _attachments.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Feedback & Support',
          style: GoogleFonts.publicSans(
            color: AppTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your feedback',
                style: GoogleFonts.publicSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us ensure every drug in Ghana is safe. Let us know if you found a bug or have a suggestion for the FDA verification process.',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Name (Optional)',
                hint: 'Enter your name',
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'name@example.com',
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              _buildDropdownField(),
              _buildTextField(
                controller: _messageController,
                label: 'Your Message',
                hint: 'Describe your issue or idea...',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildAttachmentButton(
                icon: Icons.attach_file,
                label: 'Add Attachments',
                onPressed: _pickAttachment,
              ),
              _buildAttachmentsList(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsList() {
    if (_attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _attachments
            .map((file) => Chip(
                  label: Text(file.path.split('/').last),
                  onDeleted: () {
                    setState(() {
                      _attachments.remove(file);
                    });
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitFeedback,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: const Color(0xFF102216),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.black),
            )
          : const Icon(Icons.send),
      label: Text(
        _isLoading ? 'Sending...' : 'Send Message',
        style: GoogleFonts.publicSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.publicSans(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is this regarding?',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            initialValue: _selectedFeedbackType,
            items: [
              'Report a Bug',
              'Feature Suggestion',
              'Drug Verification Issue',
              'General Inquiry',
            ]
                .map(
                  (label) => DropdownMenuItem(value: label, child: Text(label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFeedbackType = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 56),
      ),
      icon: Icon(icon, color: AppTheme.primaryGreen),
      label: Text(
        label,
        style: GoogleFonts.publicSans(color: AppTheme.textLight),
      ),
    );
  }
}
