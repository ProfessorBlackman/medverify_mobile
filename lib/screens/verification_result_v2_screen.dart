import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/multi_evidence_verification.dart';
import '../providers/verification_session_provider.dart';
import '../theme.dart';
import '../widgets/confidence_card.dart';
import '../widgets/evidence_summary_card.dart';
import '../widgets/verification_warnings_widget.dart';

class VerificationResultV2Screen extends StatelessWidget {
  const VerificationResultV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<VerificationSessionProvider>().result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Verification Result',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: Text(
          'Verification Result',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConfidenceCard(result: result),
            const SizedBox(height: 16),
            if (result.bestMatch != null) ...[
              _ProductCard(product: result.bestMatch!.product),
              const SizedBox(height: 16),
            ],
            if (result.warnings.isNotEmpty) ...[
              VerificationWarningsWidget(warnings: result.warnings),
              const SizedBox(height: 16),
            ],
            if (result.bestMatch != null)
              EvidenceSummaryCard(
                  evidence: result.bestMatch!.evidence),
            if (result.bestMatch != null) const SizedBox(height: 16),
            if (!result.hasMatches ||
                result.manualSearch ||
                result.overallState ==
                    MultiVerificationState.noReliableMatch) ...[
              _ManualSearchCard(),
              const SizedBox(height: 16),
            ],
            _ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MatchedProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.productName,
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          if (product.genericName != null) ...[
            const SizedBox(height: 4),
            Text(
              product.genericName!,
              style: GoogleFonts.publicSans(
                  fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoRow(label: 'Manufacturer', value: product.manufacturer),
          if (product.registrationNumber.isNotEmpty)
            _InfoRow(
                label: 'Reg. Number', value: product.registrationNumber),
          if (product.strength != null)
            _InfoRow(label: 'Strength', value: product.strength!),
          if (product.dosageForm != null)
            _InfoRow(label: 'Dosage Form', value: product.dosageForm!),
          if (product.category != null)
            _InfoRow(label: 'Category', value: product.category!),
          if (product.countryOrigin != null)
            _InfoRow(label: 'Origin', value: product.countryOrigin!),
          if (product.activeIngredient != null)
            _InfoRow(
                label: 'Active Ingredient',
                value: product.activeIngredient!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.publicSans(
                  fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualSearchCard extends StatelessWidget {
  const _ManualSearchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Could not identify this product',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching by product name or scan the registration number printed on the packaging.',
            style: GoogleFonts.publicSans(
                fontSize: 13, color: Colors.orange[700]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/manual'),
              icon: const Icon(Icons.search),
              label: Text(
                'Search Manually',
                style: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange[800],
                side: BorderSide(color: Colors.orange[400]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              'Add More Evidence & Retry',
              style: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondGreen,
              side: const BorderSide(color: AppTheme.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/dashboard', (r) => false),
            child: Text(
              'Return to Dashboard',
              style: GoogleFonts.publicSans(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
