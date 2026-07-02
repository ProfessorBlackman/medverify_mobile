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

  static const _bodyColor = Color(0xFF4A5F50);
  static const _borderColor = Color(0xFFE5E7EB);

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

            const Divider(height: 1, color: _borderColor),

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

  // ── Terms of Service ─────────────────────────────────────────────────────

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _buildDisclaimer(),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          icon: Icons.task_alt,
          title: 'Acceptance of Terms',
          initiallyExpanded: true,
          child: _bodyText(
            'By downloading, accessing, or using MedVerify ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these Terms, please do not use the App.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.badge_outlined,
          title: 'Eligibility',
          child: _bodyText(
            'You must be at least 18 years old, or have the consent of a parent or legal guardian, to create an account or submit community contributions. Verifying a product does not require an account.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.rule_outlined,
          title: 'Intended Use',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText(
                'The App is intended to help you verify the registration status of pharmaceutical products against Food and Drugs Authority (FDA) Ghana records. By using the App, you agree to provide accurate information and use it only for that purpose. You may also voluntarily contribute pricing and location data to help the community.',
              ),
              const SizedBox(height: 12),
              _bodyText(
                'You must not attempt to bypass security protocols, spoof geolocation data, or submit false information regarding drug prices, images, or pharmacy locations.',
              ),
            ],
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.info_outline,
          title: 'Accuracy Disclaimer',
          child: _bodyText(
            'Verification results reflect registration data made available by FDA Ghana and community-submitted information. This data may change or contain errors beyond our control. A result on MedVerify is not a guarantee of a product\'s safety, efficacy, or quality, and is not a substitute for professional medical or pharmaceutical advice.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.campaign_outlined,
          title: 'Reporting Suspicious Medicines',
          child: _bodyText(
            'Counterfeit drug detection is a community effort. If a product is flagged as "Unregistered" or gives you cause for concern, you are encouraged to report it. Sharing accurate prices and pharmacy sources helps protect other users and strengthens the community\'s ability to spot counterfeit activity.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.storage_outlined,
          title: 'Data Collection',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText(
                'To provide verification, we collect the information described in our Privacy Policy, including:',
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Drug barcodes, search queries, and manual entries for verification.'),
              _buildBulletPoint('Optional user contributions: drug images, purchase prices, and pharmacy names/locations.'),
              _buildBulletPoint('Approximate location, collected only when you verify a product or submit community data.'),
              _buildBulletPoint('Device information: app version, operating system, device model, crash logs, and an anonymous device identifier.'),
            ],
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.copyright_outlined,
          title: 'Intellectual Property',
          child: _bodyText(
            'The App, including its design, branding, and underlying software, is the property of MedVerify and its developers. You may not copy, modify, reverse-engineer, or distribute any part of the App without prior written consent.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.shield_outlined,
          title: 'Limitation of Liability',
          child: _bodyText(
            'To the fullest extent permitted by law, MedVerify and its developers are not liable for any indirect, incidental, or consequential damages arising from your use of, or reliance on, the App, including decisions made based on verification results.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.block_outlined,
          title: 'Suspension of Accounts',
          child: _bodyText(
            'We may suspend or terminate access for anyone who violates these Terms, submits fraudulent data, or attempts to compromise the security or integrity of the App.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.account_balance_outlined,
          title: 'Governing Law (Ghana)',
          child: _bodyText(
            'These Terms are governed by the laws of the Republic of Ghana. Any disputes arising from these Terms are subject to the exclusive jurisdiction of the courts of Ghana.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.mail_outline,
          title: 'Contact',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText('Questions about these Terms? Reach out to our support team.'),
              const SizedBox(height: 12),
              _buildContactButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Privacy Policy ───────────────────────────────────────────────────────

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'LAST UPDATED: JULY 1, 2026',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF61896F),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPrivacyAtAGlance(),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          icon: Icons.description_outlined,
          title: 'Information We Collect',
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText(
                'To verify products and support public health reporting, we collect:',
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Verification data: barcode scans, search queries, and registration numbers you submit for verification.'),
              _buildBulletPoint('Optional community contributions: drug images, purchase prices, and pharmacy locations you choose to share.'),
              _buildBulletPoint('Approximate location: collected only when you perform a verification or voluntarily submit community data, to help identify regional counterfeit activity.'),
              _buildBulletPoint('Device information: app version, operating system, device model, crash logs, and an anonymous device identifier, used for security and performance monitoring.'),
            ],
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.tune,
          title: 'How We Use Information',
          child: _bodyText(
            'We use the information above to verify products against FDA Ghana registration records, identify patterns of counterfeit distribution, maintain and improve app performance and stability, and prepare aggregated reports that may be submitted to the appropriate regulatory authorities.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.gavel_outlined,
          title: 'Legal Basis',
          child: _bodyText(
            'We process your information based on your consent (for optional community contributions and location data), our legitimate interest in protecting public health and preventing counterfeit distribution, and compliance with Ghana\'s Data Protection Act, 2012 (Act 843).',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.share_outlined,
          title: 'Information Sharing',
          child: _bodyText(
            'We do not sell your personal information. We only share information when necessary to provide the service, comply with legal obligations, protect users from fraud, or when required by law.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.lock_outline,
          title: 'Data Security',
          child: _bodyText(
            'Your data is encrypted in transit and at rest using industry-standard protocols. Access to personal data is restricted to authorized personnel, and we regularly review our security practices.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.schedule_outlined,
          title: 'Data Retention',
          child: _bodyText(
            'We retain verification and community-contribution data for as long as necessary to support public health reporting and app functionality, or until you request deletion. Device and crash logs are retained for a limited period for security auditing.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.child_care_outlined,
          title: "Children's Privacy",
          child: _bodyText(
            'MedVerify is not directed at children under 13, and we do not knowingly collect personal information from them. If you believe a child has provided us with personal information, please contact us so we can remove it.',
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.verified_user_outlined,
          title: 'Your Rights',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText('You have the right to:'),
              const SizedBox(height: 12),
              _buildBulletPoint('Access the personal information we hold about you.'),
              _buildBulletPoint('Request correction or deletion of your data.'),
              _buildBulletPoint('Withdraw consent for optional community contributions or location sharing at any time.'),
              _buildBulletPoint('Contact us with any privacy-related request or concern.'),
            ],
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.mail_outline,
          title: 'Contact Information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyText('For privacy-related questions or requests, reach out to our support team.'),
              const SizedBox(height: 12),
              _buildContactButton(),
            ],
          ),
        ),
        _buildCollapsibleSection(
          icon: Icons.update,
          title: 'Changes to This Policy',
          child: _bodyText(
            'We may update this Privacy Policy from time to time. We will notify you of material changes within the App. Continued use of MedVerify after changes take effect constitutes acceptance of the revised policy.',
          ),
        ),
      ],
    );
  }

  // ── Shared building blocks ───────────────────────────────────────────────

  Widget _bodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.publicSans(fontSize: 14, color: _bodyColor, height: 1.5),
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
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
    );
  }

  Widget _buildPrivacyAtAGlance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'PRIVACY AT A GLANCE',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlanceBullet('We never sell your personal information.'),
          _buildGlanceBullet('Community contributions (photos, prices, locations) are optional.'),
          _buildGlanceBullet('Location is only collected during a verification and used to spot regional counterfeit activity.'),
          _buildGlanceBullet('You can request access to, correction of, or deletion of your data at any time.'),
          _buildGlanceBullet('You can reach us anytime through Contact Support.'),
        ],
      ),
    );
  }

  Widget _buildGlanceBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.publicSans(fontSize: 13, color: AppTheme.textLight, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        title: Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        children: [Align(alignment: Alignment.centerLeft, child: child)],
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
