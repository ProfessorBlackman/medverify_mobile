import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medverify_mobile/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/about_stats.dart';
import '../services/about_service.dart';
import 'privacy_policy_screen.dart';

const _fdaWebsite = 'https://fdaghana.gov.gh/';
const _companyWebsite = 'https://versatechq,com/';
const _supportEmail = 'medverify@versatechq.com';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            surfaceTintColor: Colors.transparent,
            floating: false,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'About',
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textLight,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey[100], height: 1.0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildFeaturesCard(),
                  const SizedBox(height: 24),
                  _buildDataSourceCard(),
                  const SizedBox(height: 24),
                  _buildDisclaimerCard(),
                  const SizedBox(height: 24),
                  _buildDeveloperCard(),
                  const SizedBox(height: 24),
                  _buildStatisticsCard(),
                  const SizedBox(height: 24),
                  _buildSupportCard(),
                  const SizedBox(height: 24),
                  _buildUsefulLinksCard(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.logoColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        Text(
          'MedVerify',
          style: GoogleFonts.publicSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<PackageInfo>(
          future: _packageInfoFuture,
          builder: (context, snapshot) {
            final versionText = snapshot.hasData
                ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                : (snapshot.hasError ? 'Unknown Version' : 'Loading version…');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$versionText • Beta',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondGreen,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'MedVerify helps you verify whether medicines are registered with the '
      'Ghana Food and Drugs Authority (FDA). You can search teh name, scan a barcode or medicine '
      'package to compare it against official FDA registration records and '
      'make more informed decisions about your medication.',
      textAlign: TextAlign.center,
      style: GoogleFonts.publicSans(
        fontSize: 15,
        height: 1.6,
        color: Colors.grey[600],
      ),
    );
  }

  // ── What MedVerify Does ──────────────────────────────────────────────────

  Widget _buildFeaturesCard() {
    const features = [
      (Icons.qr_code_scanner, 'Scan medicine barcodes'),
      (Icons.camera_alt_outlined, 'Scan medicine packaging'),
      (Icons.verified_outlined, 'Verify FDA registration'),
      (Icons.description_outlined, 'View registration details'),
      (Icons.warning_amber_outlined, 'Identify potential issues'),
      (Icons.fact_check_outlined, 'Access official registration information'),
    ];

    return _buildCard(
      title: 'What MedVerify Does',
      child: Column(
        children: [
          for (final (icon, label) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Official Data Source ─────────────────────────────────────────────────

  Widget _buildDataSourceCard() {
    return _buildCard(
      title: 'Official Data Source',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.handshake_outlined, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ghana Food and Drugs Authority (FDA)',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Verification results are matched against publicly available FDA registration records.',
            style: GoogleFonts.publicSans(fontSize: 13, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Source: Official FDA Medicine Registration Database',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchUrl(_fdaWebsite),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Visit FDA Website'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.secondGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Important Disclaimer ─────────────────────────────────────────────────

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: GoogleFonts.publicSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'MedVerify checks whether a medicine appears in official FDA registration records. '
                'A successful match does NOT guarantee that the physical product is genuine, counterfeit medicines may imitate legitimate packaging. '
                'Always purchase medicines from licensed pharmacies and consult a healthcare professional when in doubt.',
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: const Color(0xFF92400E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Developer Information ────────────────────────────────────────────────

  Widget _buildDeveloperCard() {
    return _buildCard(
      title: 'Developer Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.code, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developed by Versatech Enterprise',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    'Created by Methuselah Nwodobeh',
                    style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
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
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl('mailto:$_supportEmail'),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  Widget _buildStatisticsCard() {
    return _buildCard(
      title: 'Database Information',
      child: FutureBuilder<AboutStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return Column(
            children: [
              _buildStatRow('Registered Medicines', stats != null ? '${stats.registeredMedicines}+' : '—'),
              _buildStatRow('Verification Source', stats?.verificationSource ?? '—'),
              _buildStatRow('Database Status', stats?.databaseStatus ?? '—'),
              _buildStatRow(
                'Last Updated',
                stats != null ? _formatMonthYear(stats.lastUpdated) : '—',
                showDivider: false,
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStatRow(String label, String value, {bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.publicSans(fontSize: 13, color: Colors.grey[600]),
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
        if (showDivider) Divider(height: 1, color: Colors.grey[100]),
      ],
    );
  }

  // ── Support ───────────────────────────────────────────────────────────────

  Widget _buildSupportCard() {
    return _buildCard(
      title: 'Need Help?',
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
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/feedback'),
                  icon: const Icon(Icons.contact_support_outlined, size: 16),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/feedback'),
                  icon: const Icon(Icons.bug_report_outlined, size: 16),
                  label: const Text('Report an Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textLight,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Useful Links ──────────────────────────────────────────────────────────

  Widget _buildUsefulLinksCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _buildLinkRow(
            icon: Icons.language,
            label: 'Visit Website',
            onTap: () => _launchUrl(_companyWebsite),
          ),
          _divider(),
          _buildLinkRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen(initialTabIndex: 1)),
            ),
          ),
          _divider(),
          _buildLinkRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen(initialTabIndex: 0)),
            ),
          ),
          _divider(),
          _buildLinkRow(
            icon: Icons.badge_outlined,
            label: 'Licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'MedVerify',
            ),
            showChevron: false,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[100]);

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

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: Column(
        children: [
          Text(
            'Built in Ghana 🇬🇭',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '© $year MedVerify. All rights reserved.',
            style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Made with ❤️ to help combat counterfeit medicines.',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card shell ────────────────────────────────────────────────────

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.publicSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
