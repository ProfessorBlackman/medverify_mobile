import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:medverify_mobile/screens/privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/about_stats.dart';
import '../services/about_service.dart';
import '../theme.dart';

const _fdaWebsite = 'https://fdaghana.gov.gh/';
const _fdaRegistrationDatabase =
    'https://fdaghana.gov.gh/services-2/product-registration/';
const _fdaComplaintForm = 'https://fdaghana.gov.gh/submit-a-complaint/';
const _companyWebsite = 'https://versatechq.com/';
const _supportEmail = 'medverify@versatechq.com';

class InfoHubScreen extends StatefulWidget {
  const InfoHubScreen({super.key});

  @override
  State<InfoHubScreen> createState() => _InfoHubScreenState();
}

class _InfoHubScreenState extends State<InfoHubScreen> {
  final AboutService _aboutService = AboutService();
  late final Future<PackageInfo> _packageInfoFuture;
  late final Future<AboutStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _statsFuture = _aboutService.fetchStats();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (!mounted) return;
    if (canLaunch) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Information Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            const SizedBox(height: 32),

            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 32),

            _buildSectionHeader('Medicine Safety Guide'),
            const SizedBox(height: 16),
            _buildSafetyCategory(
              title: 'Before Buying',
              color: Colors.blue,
              items: const [
                (
                  Icons.local_pharmacy,
                  'Buy From Licensed Pharmacies',
                  'Only purchase medicines from registered pharmacies or licensed chemical shops.',
                ),
                (
                  Icons.event_busy,
                  'Check Expiry Date',
                  'Never buy or use a medicine that is close to, or past, its expiry date.',
                ),
                (
                  Icons.inventory_2,
                  'Inspect Packaging',
                  'Look for breaks in the seal, unusual fonts, or faded colors on the box.',
                ),
                (
                  Icons.verified_user,
                  'Verify FDA Registration Number',
                  'Confirm the packaging carries a valid FDA registration number, e.g. FDA/CE 24-669.',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSafetyCategory(
              title: 'Before Using',
              color: AppTheme.secondGreen,
              items: const [
                (
                  Icons.qr_code_scanner,
                  'Scan Barcode',
                  'Scan the drug\'s barcode in MedVerify to confirm it matches FDA registration records.',
                ),
                (
                  Icons.compare,
                  'Compare Packaging',
                  'Compare the packaging, color, and print quality against a known genuine sample.',
                ),
                (
                  Icons.menu_book,
                  'Read Dosage Instructions',
                  'Check that dosage instructions and warnings are printed clearly and make sense.',
                ),
                (
                  Icons.fact_check,
                  'Check Registration Details',
                  'Review the registration details returned by MedVerify before taking the medicine.',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSafetyCategory(
              title: 'If You Suspect a Counterfeit',
              color: AppTheme.warningRed,
              items: const [
                (
                  Icons.front_hand,
                  'Stop Using The Medicine',
                  'Your life is worth more than your wallet. Do not use a suspected counterfeit drug.',
                ),
                (
                  Icons.inventory,
                  'Keep The Packaging',
                  'Hold on to the box, blister pack, and any receipt as evidence for a report.',
                ),
                (
                  Icons.campaign,
                  'Contact The FDA',
                  'Report the product to the FDA so it can be investigated and removed from circulation.',
                ),
                (
                  Icons.medical_services,
                  'Consult A Healthcare Professional',
                  'Speak to a doctor or pharmacist, especially if you have already taken the medicine.',
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('What MedVerify Can & Cannot Do'),
            const SizedBox(height: 16),
            _buildCapabilitiesCard(),
            const SizedBox(height: 32),

            _buildSectionHeader('Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFAQItem(
              'What if my barcode won\'t scan?',
              'Try cleaning your camera lens or moving to a brighter, well-lit area. You can also fall back to Search or Multi-Evidence Verify to enter the drug\'s name or registration number instead.',
              null,
            ),
            _buildFAQItem(
              'Why can\'t I find my medicine?',
              'The medicine may not yet be registered with FDA Ghana, or its name may be spelled differently in the database. Try searching by generic name, or use Multi-Evidence Verify to submit a photo, barcode, and registration number together for a more thorough check.',
              null,
            ),
            _buildFAQItem(
              'Can a counterfeit medicine have a valid FDA registration number?',
              'Yes. Counterfeiters sometimes copy a genuine registration number onto fake packaging. A matching number is a good sign, but it does not guarantee the physical product is authentic, always inspect the packaging too and use Multi-Evidence Verify when in doubt.',
              null,
            ),
            _buildFAQItem(
              'Is MedVerify an official FDA application?',
              'No, this is a personal project built by a concerned Ghanaian, \n'
                  'this app relies on data from the official database of FDA Ghana.\n'
                  'Find out more about him here:',
              'https://methuselah.site',
            ),
            _buildFAQItem(
              'Does MedVerify collect personal data?',
              'The main data collected from you is the photo you take, the barcode you scan, and any feedback you give us. We also collect analytics data to fix bugs and improve the app.',
              null,
            ),
            _buildFAQItem(
              'Can I use MedVerify outside Ghana?',
              'MedVerify checks products against the FDA Ghana registration database, so results are only reliable for medicines sold in Ghana. Medicines registered in other countries will not return accurate results.',
              null,
            ),
            _buildFAQItem(
              'How often is the database updated?',
              'The FDA registration data MedVerify uses is refreshed periodically. You can see the current database status and last update date at the bottom of this page.',
              null,
            ),
            _buildFAQItem(
              'Can MedVerify guarantee a medicine is genuine?',
              'No. MedVerify checks whether a product appears in official FDA registration records, it does not physically inspect the medicine. A match is a strong positive signal, not a guarantee of authenticity, safety, or quality.',
              null,
            ),
            _buildFAQItem(
              'How can I help improve MedVerify?',
              'After verifying a drug, you can voluntarily submit the pharmacy name where you bought it, take a picture of the drug, and provide the price you paid. This helps map authentic medicine availability and average prices for everyone. You can also send feedback or report issues at any time.',
              null,
            ),
            const SizedBox(height: 32),

            _buildEmergencyCard(),
            const SizedBox(height: 32),

            _buildSectionHeader('Official FDA Resources'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildLinkRow(
                    icon: Icons.language,
                    label: 'Visit FDA Website',
                    onTap: () => _launchUrl(_fdaWebsite),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.storage_outlined,
                    label: 'Medicine Registration Database',
                    onTap: () => _launchUrl(_fdaRegistrationDatabase),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.report_problem_outlined,
                    label: 'Report Counterfeit Medicine',
                    onTap: () => _launchUrl(_fdaComplaintForm),
                    showChevron: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FDA Contact Information',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactButton(
                    Icons.phone,
                    'Tel',
                    'tel:0302235100',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactButton(
                    Icons.email,
                    'Email',
                    'mailto:fda@fda.gov.gh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Learn More'),
            const SizedBox(height: 16),
            _buildLearnMoreItem(
              'Understanding FDA Registration Numbers',
              'A valid Ghana FDA registration number usually looks like "FDA/CE 24-669", combining a product category code and a year of approval. It confirms the product was assessed by the FDA, but you should still check it against MedVerify and inspect the packaging.',
            ),
            _buildLearnMoreItem(
              'How Counterfeit Medicines Are Made',
              'Counterfeiters copy packaging, labels, and even registration numbers from genuine products, sometimes using little or none of the active ingredient. This is why packaging alone is not proof of authenticity.',
            ),
            _buildLearnMoreItem(
              'Reading Medicine Labels',
              'Genuine labels clearly show the product name, active ingredients, dosage instructions, batch number, expiry date, manufacturer, and FDA registration number, usually printed with sharp, consistent fonts.',
            ),
            _buildLearnMoreItem(
              'Safe Medicine Storage',
              'Store medicines in a cool, dry place away from direct sunlight, out of reach of children, and always in their original packaging so dosage and expiry information stays visible.',
            ),
            _buildLearnMoreItem(
              'Buying Medicines Online Safely',
              'Only buy from licensed online pharmacies, avoid sellers who offer prescription medicines without one, and verify the product with MedVerify as soon as it arrives.',
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('MedVerify Support'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _launchUrl('mailto:$_supportEmail'),
                    child: Text(
                      _supportEmail,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(_companyWebsite),
                          icon: const Icon(Icons.language, size: 16),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondGreen,
                            side: const BorderSide(
                              color: AppTheme.primaryGreen,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/feedback'),
                          icon: const Icon(Icons.bug_report_outlined, size: 16),
                          label: const Text('Report Issue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Legal'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildLinkRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PrivacyPolicyScreen(initialTabIndex: 0),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PrivacyPolicyScreen(initialTabIndex: 1),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.info_outline,
                    label: 'Disclaimer',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PrivacyPolicyScreen(initialTabIndex: 0),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.info,
                    label: 'About MedVerify',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                  _divider(),
                  _buildLinkRow(
                    icon: Icons.badge_outlined,
                    label: 'Open Source Licenses',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'MedVerify',
                    ),
                    showChevron: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildAppInfoFooter(),
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: Image.asset('assets/images/info_hub.png').image,
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Medicine Safety Tips',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Medicine Safety Center',
          style: GoogleFonts.publicSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Learn how to identify suspicious medicines, understand FDA registration, and use MedVerify safely.',
          style: GoogleFonts.publicSans(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildQuickAction(
          icon: Icons.qr_code_scanner,
          label: 'Scan Medicine',
          color: AppTheme.secondGreen,
          onTap: () => Navigator.pushNamed(context, '/scanner'),
        ),
        _buildQuickAction(
          icon: Icons.search,
          label: 'Search Medicine',
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/manual'),
        ),
        _buildQuickAction(
          icon: Icons.language,
          label: 'Visit FDA Website',
          color: Colors.indigo,
          onTap: () => _launchUrl(_fdaWebsite),
        ),
        _buildQuickAction(
          icon: Icons.report_problem_outlined,
          label: 'Report Counterfeit',
          color: AppTheme.warningRed,
          onTap: () => _launchUrl(_fdaComplaintForm),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medicine Safety Guide ─────────────────────────────────────────────────

  Widget _buildSafetyCategory({
    required String title,
    required Color color,
    required List<(IconData, String, String)> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 12),
        for (final (icon, itemTitle, description) in items) ...[
          _buildInfoCard(
            icon: icon,
            title: itemTitle,
            description: description,
            color: color.withValues(alpha: 0.1),
            iconColor: color,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Capabilities ──────────────────────────────────────────────────────────

  Widget _buildCapabilitiesCard() {
    const canDo = [
      'Verify FDA registration',
      'Scan barcodes',
      'Read medicine labels',
      'Display registration information',
      'Search medicines',
    ];
    const cannotDo = [
      'Guarantee authenticity',
      'Detect fake ingredients',
      'Replace healthcare professionals',
      'Diagnose illnesses',
      'Verify medicines not registered with the Ghana FDA',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MedVerify CAN',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondGreen,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in canDo)
            _buildCapabilityRow(Icons.check_circle, item, AppTheme.secondGreen),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 20),
          Text(
            'MedVerify CANNOT',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.warningOrange,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in cannotDo)
            _buildCapabilityRow(Icons.cancel, item, AppTheme.warningOrange),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────

  Widget _buildFAQItem(String question, String answer, String? url) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer, style: TextStyle(color: Colors.grey[600])),
          ),
          if (url != null)
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextButton(
                onPressed: () => _launchUrl(url),
                child: Text(
                  url,
                  style: TextStyle(
                    color: Colors.blue[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Emergency Advice ──────────────────────────────────────────────────────

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: AppTheme.warningRed, size: 22),
              const SizedBox(width: 8),
              Text(
                'Medical Emergency',
                style: GoogleFonts.publicSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If someone experiences a serious reaction after taking medicine, seek immediate medical attention or visit the nearest healthcare facility.\n\n'
            'MedVerify cannot provide emergency medical assistance.',
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: const Color(0xFF991B1B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Learn More ────────────────────────────────────────────────────────────

  Widget _buildLearnMoreItem(String title, String content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(
          Icons.menu_book_outlined,
          color: AppTheme.secondGreen,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.publicSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textLight,
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[100]);

  Widget _buildLinkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
            ),
            if (showChevron) Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── App Information footer ───────────────────────────────────────────────

  Widget _buildAppInfoFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: FutureBuilder(
        future: Future.wait([_packageInfoFuture, _statsFuture]),
        builder: (context, snapshot) {
          final results = snapshot.data;
          final packageInfo = results?[0] as PackageInfo?;
          final stats = results?[1] as AboutStats?;

          return Column(
            children: [
              _buildAppInfoRow(
                'Version',
                packageInfo != null
                    ? '${packageInfo.version} (${packageInfo.buildNumber})'
                    : '—',
              ),
              _buildAppInfoRow(
                'Database Source',
                stats?.verificationSource ?? '—',
              ),
              _buildAppInfoRow('Database Status', stats?.databaseStatus ?? '—'),
              _buildAppInfoRow(
                'Last Database Update',
                stats != null ? _formatMonthYear(stats.lastUpdated) : '—',
                showDivider: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Built in Ghana 🇬🇭',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildAppInfoRow(
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey[300]),
      ],
    );
  }
}
