import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final int initialTabIndex; // 0 for Terms, 1 for Privacy

  const PrivacyPolicyScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _selectedTab == 0 ? 'Legal' : 'Legal & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Tabs
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTab(0, 'Terms of Service'),
                    _buildTab(1, 'Privacy Policy'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTab == 0) _buildTermsContent() else _buildPrivacyContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundLight,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppTheme.backgroundLight,
              Colors.white,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true to indicate acceptance
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'I Understand & Accept',
              style: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _buildDisclaimer(),
        const SizedBox(height: 6),
        _buildSectionTitle('User Conduct'),
        const SizedBox(height: 8),
        Text(
          'By using this application to scan pharmaceutical products, you agree to provide accurate information and use the scanner only for its intended purpose of verifying drug authenticity with the FDA of Ghana.',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Users are prohibited from attempting to bypass security protocols, spoofing geolocation data, or reverse-engineering the scanning algorithm to generate fraudulent verification results.',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Data Collection'),
        const SizedBox(height: 8),
        Text(
          'To ensure the safety of the pharmaceutical supply chain in Ghana, we collect the following information during each scan: ',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildBulletPoint('Batch numbers and manufacturing dates on the product.'),
            _buildBulletPoint('Device geolocation to track potential areas of counterfeit distribution.'),
            _buildBulletPoint('Device metadata for security and performance auditing.'),
    ]
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Accountability'),
        const SizedBox(height: 8),
        Text(
          'Counterfeit drug detection is a critical public health initiative. If a product is flagged as "Invalid" or "Counterfeit," the application may prompt you to report the location of purchase to the FDA authorities. This reporting is voluntary but encouraged for public safety.',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'LAST UPDATED: OCTOBER 24, 2023',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF61896F),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Data Collection'),
        const SizedBox(height: 8),
        Text(
          'To ensure the safety of the pharmaceutical supply chain in Ghana, we collect the following information during each scan:',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildBulletPoint('Batch numbers and manufacturing dates on the product.'),
        _buildBulletPoint('Device geolocation to track potential areas of counterfeit distribution.'),
        _buildBulletPoint('Device metadata for security and performance auditing.'),
        const SizedBox(height: 24),
        _buildSectionTitle('Data Protection'),
        const SizedBox(height: 8),
        Text(
          'Your data is encrypted using industry-standard protocols. We do not sell your personal information to third parties. All scanned data is stored securely and only used for authenticity verification and public health reporting to the FDA Ghana.',
          style: GoogleFonts.publicSans(fontSize: 16, color: const Color(0xFF4A5F50), height: 1.5),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Questions or Concerns?',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any questions regarding your data privacy or how we handle your information, please reach out to our support team.',
                style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF4A5F50), height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/feedback');
                  },
                  icon: const Icon(Icons.contact_support_outlined),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool isSmall = false, IconData? icon}) {
    if (isSmall && icon != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      title,
      style: GoogleFonts.publicSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textLight,
      ),
    );
  }

  Widget _buildDisclaimer() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DISCLAIMER',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'This application is an independent verification \n tool. While we use official Ghana FDA data, this \n app is not a substitute for professional medical \n advice or consultation with the Food and Drugs \n Authority',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
