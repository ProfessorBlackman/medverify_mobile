import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

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
            _buildTextField(label: 'Name (Optional)', hint: 'Enter your name'),
            _buildTextField(label: 'Email Address', hint: 'name@example.com'),
            _buildDropdownField(),
            _buildTextField(
              label: 'Your Message',
              hint: 'Describe your issue or idea...',
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            Text(
              'Attachments (Optional)',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentButton(
                    icon: Icons.camera_alt,
                    label: 'Attach Screenshot',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttachmentButton(
                    icon: Icons.videocam,
                    label: 'Attach Recording',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is used solely to improve our service and drug safety monitoring.',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: const Color(0xFF102216),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.send),
              label: Text(
                'Send Message',
                style: GoogleFonts.publicSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Or connect directly',
                    style: GoogleFonts.publicSans(color: Colors.grey[500]),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Need direct help?',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@ghana-fda-verify.com',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.language,
              title: 'Visit our Website',
              subtitle: 'FAQs & Documentation',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
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
          TextField(
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
            initialValue: 'Report a Bug',
            items:
                [
                      'Report a Bug',
                      'Feature Suggestion',
                      'Drug Verification Issue',
                      'General Inquiry',
                    ]
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: AppTheme.primaryGreen),
      label: Text(
        label,
        style: GoogleFonts.publicSans(color: AppTheme.textLight),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryGreen,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.publicSans(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
