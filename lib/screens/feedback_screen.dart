import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../services/feedback_service.dart';
import '../theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedFeedbackType = 'Report a Bug';
  final List<File> _attachments = [];
  bool _isLoading = false;
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);

  final FeedbackService _feedbackService = FeedbackService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _uploadProgress.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress.value = 0.0;
    });

    final success = await _feedbackService.sendFeedback(
      name: _nameController.text,
      email: _emailController.text,
      feedbackType: _selectedFeedbackType,
      message: _messageController.text,
      attachments: _attachments,
      onUploadProgress: (p) => _uploadProgress.value = p,
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
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick Images from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Pick Video from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickVideo();
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Note: You can attach up to 5 images (max 5MB each) and 1 video (max 20MB).',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final imageCount = _attachments
        .where((f) => (lookupMimeType(f.path) ?? '').startsWith('image/'))
        .length;
    final slotsAvailable = 5 - imageCount;

    if (slotsAvailable <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already attached the maximum of 5 images.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);

    if (pickedFiles.isNotEmpty) {
      final validFiles = <File>[];
      final oversizedFiles = <String>[];

      final filesToProcess = pickedFiles.take(slotsAvailable);

      for (var xfile in filesToProcess) {
        final file = File(xfile.path);
        if (await file.length() > 5 * 1024 * 1024) {
          // 5MB limit
          oversizedFiles.add(xfile.name);
        } else {
          validFiles.add(file);
        }
      }

      if (validFiles.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _attachments.addAll(validFiles);
        });
      }

      if (mounted) {
        if (pickedFiles.length > slotsAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You can only attach up to 5 images. Some images were not added.')),
          );
        }
        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Some images were not added because they exceed the 5MB limit.')),
          );
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    final hasVideo = _attachments
        .any((f) => (lookupMimeType(f.path) ?? '').startsWith('video/'));
    if (hasVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only attach one video.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (await file.length() > 20 * 1024 * 1024) {
        // 20MB limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'The selected video exceeds the 20MB size limit and was not added.')),
          );
        }
      } else {
        if (!mounted) return;
        setState(() {
          _attachments.add(file);
        });
      }
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
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
              if (_isLoading && _attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _uploadProgress,
                    builder: (_, progress, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryGreen),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uploading attachments (${(progress * 100).toInt()}%)...',
                          style: GoogleFonts.publicSans(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
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
