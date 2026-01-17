import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medverify_mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
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
                      const SizedBox(height: 32),
                      _buildMissionCard(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                      const SizedBox(height: 40),
                      _buildActionButtons(context),
                      const SizedBox(height: 32),
                      _buildFooterPattern(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Text(
        'Empowering Ghanaians with instant drug authenticity verification through the Ghana FDA database to ensure medication safety across the nation. We are committed to eradicating counterfeit pharmaceuticals.',
        textAlign: TextAlign.center,
        style: GoogleFonts.publicSans(
          fontSize: 16,
          height: 1.6,
          color: AppTheme.textLight,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    String errorMsg = '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          sectionTitle: 'DEVELOPER INFORMATION',
          icon: Icons.code,
          title: 'The Laughing Chicken',
          subtitle: 'Solo Developer',
        ),
        const SizedBox(height: 16),
        GestureDetector(
          child: _buildInfoItem(
            sectionTitle: 'SOURCE OF TRUTH',
            icon: Icons.handshake,
            title: 'Ghana Food & Drugs Authority',
            subtitle: 'Official Database',
          ),
          onTap: () async {
            final Uri url = Uri.parse('https://fdaghana.gov.gh/');
            if (!await launchUrl(url)) {
              //     show snackbar
              errorMsg = 'Could not launch $url';
            }
          },
        ),
        const SizedBox(height: 8),
        if (errorMsg.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text('Error: $errorMsg', style: const TextStyle(color: AppTheme.warningRed),textAlign: TextAlign.left,),
          ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String sectionTitle,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            sectionTitle,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    String errorMsg = '';
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.language,
          text: 'Visit Website',
          onTap: () async {
            final Uri url = Uri.parse('https://methuselah.site/');
            if (!await launchUrl(url)) {
              //     show snackbar
              errorMsg = 'Could not launch $url';
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text(errorMsg)),
              // );
            }
          },
        ),
        // const SizedBox(height: 8),
        // _buildActionButton(
        //   icon: Icons.description,
        //   text: 'Open Source Licenses',
        //   onTap: () {
        //      showLicensePage(context: context);
        //   },
        // ),
        const SizedBox(height: 8),
        if (errorMsg.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              'Error: $errorMsg',
              style: const TextStyle(color: AppTheme.warningRed),
              textAlign: TextAlign.left,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[100]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterPattern() {
    return Container(
      width: double.infinity,
      height: 100,
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
      child: Center(
        child: Text(
          '© 2025 MedVerify. All rights reserved.',
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
