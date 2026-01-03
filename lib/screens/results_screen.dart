import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/verification_result.dart';
import '../theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Color _getStatusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return AppTheme.primaryGreen;
      case VerificationStatus.near_expiry:
        return AppTheme.warningOrange;
      default:
        return AppTheme.warningRed;
    }
  }

  IconData _getStatusIcon(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return Icons.verified_user;
      case VerificationStatus.near_expiry:
        return Icons.warning_amber_rounded;
      default:
        return Icons.report_problem;
    }
  }

  String _getStatusTitle(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return 'Verified Safe';
      case VerificationStatus.near_expiry:
        return 'Nearing Expiry';
      case VerificationStatus.expired:
        return 'License Expired';
      case VerificationStatus.recalled:
        return 'Product Recalled';
      case VerificationStatus.unregistered:
        return 'Unregistered Product';
      default:
        return 'Unknown Status';
    }
  }

  String _getSubtitle(VerificationResult result) {
    if (result.status == VerificationStatus.verified || result.status == VerificationStatus.valid) {
      return 'Authenticity confirmed by FDA Ghana';
    }
    return result.message ?? 'No additional details available.';
  }

  bool _showReportButton(VerificationStatus? status) {
    return status != VerificationStatus.verified && status != VerificationStatus.valid && status != VerificationStatus.near_expiry;
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments;
    final List<VerificationResult> results;

    if (arguments is List<VerificationResult>) {
      if (arguments.isEmpty) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('No results found.')),
        );
      }
      results = arguments;
    } else if (arguments is VerificationResult) {
      results = [arguments];
    } else {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Invalid data provided to results screen.'),
        ),
      );
    }

    final result = results.first;
    final otherResults = results.skip(1).toList();

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
        child: Column(
          children: [
            _buildStatusHeader(context, result),
            const SizedBox(height: 24),
            _buildProductInfoCard(context, result),
            const SizedBox(height: 16),
            if (result.status == VerificationStatus.verified || result.status == VerificationStatus.valid)
              _buildLicenseDetailsCard(context, result),
            const SizedBox(height: 24),
            if (otherResults.isNotEmpty) _buildOtherMatches(context, otherResults),
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
    final color = _getStatusColor(result.status);
    final icon = _getStatusIcon(result.status);
    final title = _getStatusTitle(result.status);
    final subtitle = _getSubtitle(result);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 56, color: color)),
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

  Widget _buildProductInfoCard(BuildContext context, VerificationResult result) {
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

  Widget _buildLicenseDetailsCard(BuildContext context, VerificationResult result) {
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
              valueColor: _getStatusColor(result.status),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherMatches(BuildContext context, List<VerificationResult> otherResults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Other Possible Matches',
            style: GoogleFonts.publicSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherResults.length,
          itemBuilder: (context, index) {
            final otherResult = otherResults[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.white,
              child: ExpansionTile(
                title: Text(
                  otherResult.productName ?? 'Unknown Product',
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  otherResult.manufacturer ?? 'Unknown Manufacturer',
                  style: GoogleFonts.publicSans(color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 15),
                        _buildDetailRow(
                          context,
                          Icons.badge,
                          'Reg. Number',
                          otherResult.regNumber ?? 'N/A',
                        ),
                        if (otherResult.approvalDate != null)
                          _buildDetailRow(
                            context,
                            Icons.event_available,
                            'Approval Date',
                            DateFormat('dd MMM yyyy').format(otherResult.approvalDate!),
                          ),
                        if (otherResult.expiryDate != null)
                          _buildDetailRow(
                            context,
                            Icons.event_busy,
                            'Expiry Date',
                            DateFormat('dd MMM yyyy').format(otherResult.expiryDate!),
                            valueColor: _getStatusColor(otherResult.status),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
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

  Widget _buildImproveButton(BuildContext context, {required IconData icon, required String label}) {
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
    final showReport = _showReportButton(result.status);

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
                if (showReport) {
                  Navigator.pushNamed(context, '/info');
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(result.status),
                foregroundColor: showReport ? Colors.white : const Color(0xFF102216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(showReport ? Icons.report_problem : Icons.qr_code_scanner),
              label: Text(
                showReport ? 'Report to FDA' : 'Scan Another Product',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!showReport) ...[
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
}
