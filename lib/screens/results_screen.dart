import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/verification_result.dart';
import '../theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)!.settings.arguments as VerificationResult;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Result',
          style: GoogleFonts.publicSans(
            color: AppTheme.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
        // Padding at bottom for floating buttons
        child: Column(
          children: [
            _buildStatusHeader(context, result),
            const SizedBox(height: 24),
            _buildProductInfoCard(context, result),
            const SizedBox(height: 16),
            if (result.status == VerificationStatus.verified)
              _buildLicenseDetailsCard(context, result),
            const SizedBox(height: 16),
            _buildImproveCard(context),
            const SizedBox(height: 16),
            Text(
              'Scan results are based on the latest data from the Food and Drugs Authority (FDA) Ghana.',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, result),
    );
  }

  Widget _buildStatusHeader(BuildContext context, VerificationResult result) {
    final isVerified = result.status == VerificationStatus.verified;
    final primaryColor = isVerified
        ? AppTheme.primaryGreen
        : AppTheme.warningRed;
    final title = _getStatusTitle(result.status);
    final subtitle = isVerified
        ? 'Authenticity confirmed by FDA Ghana'
        : (result.message ?? '');
    final icon = isVerified ? Icons.verified_user : Icons.warning_amber_rounded;

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 56, color: primaryColor)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.publicSans(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProductInfoCard(
    BuildContext context,
    VerificationResult result,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: result.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(result.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: result.imageUrl == null
                    ? const Icon(Icons.medication, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (result.category != null)
                          _buildTag(
                            result.category!,
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                            AppTheme.primaryGreen,
                          ),
                        const SizedBox(width: 8),
                        // _buildTag('500MG', Colors.grey.shade200, Colors.grey.shade700),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.productName ?? 'N/A',
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.manufacturer ?? 'N/A',
                      style: GoogleFonts.publicSans(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLicenseDetailsCard(
    BuildContext context,
    VerificationResult result,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            Icons.badge,
            'Reg. Number',
            result.regNumber ?? 'N/A',
          ),
          const Divider(height: 1, color: Colors.transparent),
          if (result.approvalDate != null)
            _buildDetailRow(
              context,
              Icons.event_available,
              'Approval Date',
              DateFormat('dd MMM yyyy').format(result.approvalDate!),
            ),
          const Divider(height: 1, color: Colors.transparent),
          if (result.expiryDate != null)
            _buildDetailRow(
              context,
              Icons.event_busy,
              'Expiry Date',
              DateFormat('dd MMM yyyy').format(result.expiryDate!),
              valueColor: result.status == VerificationStatus.expired
                  ? AppTheme.expiredOrange
                  : AppTheme.primaryGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.publicSans(
              color: AppTheme.secondGreen,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImproveCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Text(
            'Does this box have a barcode?',
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Help us improve!',
            style: GoogleFonts.publicSans(
              color: AppTheme.secondGreen,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImproveButton(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImproveButton(
                  context,
                  icon: Icons.photo_camera,
                  label: 'Take Photo of Front',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImproveButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textLight, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.publicSans(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, VerificationResult result) {
    final isWarning = result.status != VerificationStatus.verified;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      color: Colors.white.withValues(alpha: 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isWarning) {
                  Navigator.pushNamed(context, '/info');
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isWarning
                    ? AppTheme.warningRed
                    : AppTheme.primaryGreen,
                foregroundColor: isWarning
                    ? Colors.white
                    : const Color(0xFF102216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                isWarning ? Icons.report_problem : Icons.qr_code_scanner,
              ),
              label: Text(
                isWarning ? 'Report to FDA' : 'Scan Another Product',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!isWarning) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/feedback');
              },
              icon: const Icon(Icons.flag, color: Colors.grey),
              label: Text(
                'Report an Issue',
                style: GoogleFonts.publicSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusTitle(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified Safe';
      case VerificationStatus.unregistered:
        return 'Unregistered Product';
      case VerificationStatus.expired:
        return 'License Expired';
      case VerificationStatus.recalled:
        return 'Product Recalled';
      case VerificationStatus.nearExpired:
        return 'Product Near Expired';
      default:
        return 'Unknown Status';
    }
  }
}
