import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

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
          'How MedVerify Works',
          style: GoogleFonts.publicSans(
            color: AppTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset('assets/images/how_it_works.png'),
              ),
            ),
            Text(
              'Three ways to verify, instantly',
              style: GoogleFonts.publicSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the method that suits you to ensure your\nmedication is genuine and approved by FDA Ghana.',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a verification method',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              icon: Icons.search,
              iconColor: AppTheme.primaryGreen,
              title: 'Search',
              subtitle:
                  'Type the drug\'s name into the search bar on the dashboard to look it up in the FDA Ghana database.',
            ),
            _buildMethodCard(
              icon: Icons.qr_code_scanner,
              iconColor: const Color(0xFF047857),
              title: 'Scan Barcode',
              subtitle:
                  'Point your camera at the drug\'s barcode for a quick, automatic lookup.',
            ),
            _buildMethodCard(
              icon: Icons.verified_outlined,
              iconColor: const Color(0xFF1D4ED8),
              title: 'Multi-Evidence Verify',
              subtitle:
                  'Upload photos of the packaging, scan the barcode, and enter the registration number together for a confidence-scored result backed by multiple signals.',
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What happens next',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStep(
              icon: Icons.verified_user,
              title: '1. Instant Verification',
              subtitle:
                  'Receive a green \'Verified\' check or a red \'Warning\' alert if the product is unregistered or expired.',
            ),
            _buildStep(
              icon: Icons.local_pharmacy,
              title: '2. Provide Details',
              subtitle:
                  'On the results page, you will be prompted to enter the pharmacy where you bought the drug.',
            ),
            _buildStep(
              icon: Icons.volunteer_activism,
              title: '3. Help the Community',
              subtitle:
                  'Help others by providing an image of the drug, scanning its barcode, and adding the price you bought it at.',
              isLast: true,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sourced from FDA Ghana Database',
                    style: GoogleFonts.publicSans(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
              ),
              if (!isLast)
                Container(width: 2, height: 60, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
