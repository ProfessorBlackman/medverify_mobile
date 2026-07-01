import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../models/multi_evidence_verification.dart';
import '../models/verification_result.dart';
import '../providers/app_provider.dart';
import '../providers/verification_session_provider.dart';
import '../services/analytics_service.dart';
import '../theme.dart';
import '../widgets/confidence_card.dart';
import '../widgets/evidence_summary_card.dart';
import '../widgets/location_input_dialog.dart';
import '../widgets/verification_warnings_widget.dart';

// Mirrors the status parsing in VerificationResult.fromJson.
VerificationStatus _parseProductStatus(String statusStr) {
  final statusMap = {
    for (final e in VerificationStatus.values) e.name: e,
  };

  final resolvedStatus = statusMap[statusStr.toLowerCase()];
  if (resolvedStatus == null) {
    Sentry.captureMessage('Unknown drug status received: "$statusStr"');
  }
  return resolvedStatus ?? VerificationStatus.unregistered;
}

// Same green/orange/red grouping used across the app (see results_screen.dart).
class _ProductStatusStyle {
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final String label;

  const _ProductStatusStyle({
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.label,
  });
}

_ProductStatusStyle _productStatusStyle(VerificationStatus status) {
  switch (status) {
    case VerificationStatus.verified:
    case VerificationStatus.valid:
      return const _ProductStatusStyle(
        color: AppTheme.secondGreen,
        bgColor: Color(0xFFECFDF5),
        borderColor: Color(0xFF6EE7B7),
        icon: Icons.verified,
        label: 'VERIFIED',
      );
    case VerificationStatus.nearExpiry:
      return const _ProductStatusStyle(
        color: AppTheme.warningOrange,
        bgColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        icon: Icons.warning_amber_outlined,
        label: 'NEAR EXPIRY',
      );
    case VerificationStatus.pending:
      return const _ProductStatusStyle(
        color: AppTheme.warningOrange,
        bgColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        icon: Icons.hourglass_empty,
        label: 'PENDING',
      );
    case VerificationStatus.expired:
      return const _ProductStatusStyle(
        color: AppTheme.warningRed,
        bgColor: Color(0xFFFEF2F2),
        borderColor: Color(0xFFFECACA),
        icon: Icons.event_busy,
        label: 'EXPIRED',
      );
    case VerificationStatus.recalled:
      return const _ProductStatusStyle(
        color: AppTheme.warningRed,
        bgColor: Color(0xFFFEF2F2),
        borderColor: Color(0xFFFECACA),
        icon: Icons.report_problem_outlined,
        label: 'RECALLED',
      );
    case VerificationStatus.unregistered:
      return const _ProductStatusStyle(
        color: AppTheme.warningRed,
        bgColor: Color(0xFFFEF2F2),
        borderColor: Color(0xFFFECACA),
        icon: Icons.block,
        label: 'UNREGISTERED',
      );
    case VerificationStatus.invalid:
      return const _ProductStatusStyle(
        color: AppTheme.warningRed,
        bgColor: Color(0xFFFEF2F2),
        borderColor: Color(0xFFFECACA),
        icon: Icons.cancel_outlined,
        label: 'INVALID',
      );
  }
}

class VerificationResultV2Screen extends StatefulWidget {
  const VerificationResultV2Screen({super.key});

  @override
  State<VerificationResultV2Screen> createState() =>
      _VerificationResultV2ScreenState();
}

class _VerificationResultV2ScreenState
    extends State<VerificationResultV2Screen> {
  @override
  void initState() {
    super.initState();
    // Wait one frame so the widget tree is fully mounted before calling
    // context.read and showing dialogs.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _saveAndPromptLocation(),
    );
  }

  // ── Conversion helpers ──────────────────────────────────────────────────────

  static VerificationResult _toVerificationResult(
    MultiVerificationResult result,
  ) {
    // Use the product with the highest confidence score — matches are already
    // ranked best-first, so bestMatch is correct. Fall back to unregistered
    // when the engine found no candidates at all.
    final product = result.bestMatch?.product;
    final status = product != null
        ? _parseProductStatus(product.status)
        : VerificationStatus.unregistered;
    return VerificationResult(
      status: status,
      productName: product?.productName ?? 'Unknown Product',
      manufacturer: product?.manufacturer ?? 'Unknown Manufacturer',
      regNumber: product?.registrationNumber ?? 'N/A',
      category: product?.category,
      barcode: product?.barcode,
      activeIngredient: product?.activeIngredient,
      countryOrigin: product?.countryOrigin,
      region: product?.region,
      expiryDate: product?.expiryDate,
      approvalDate: product?.registrationDate,
      scannedAt: DateTime.now(),
    );
  }

  // ── Save to history + location prompt ──────────────────────────────────────

  Future<void> _saveAndPromptLocation() async {
    if (!mounted) return;
    final result = context.read<VerificationSessionProvider>().result;
    if (result == null) return;

    final entry = _toVerificationResult(result);

    // Persist to scan history; capture the ID-stamped copy for updateResult.
    final savedEntry = await context.read<AppProvider>().addScan(entry);
    if (!mounted) return;

    final location = await showDialog<String>(
      context: context,
      builder: (_) => const LocationInputDialog(),
    );

    if (!mounted) return;
    if (location != null && location.isNotEmpty) {
      await context.read<AppProvider>().updateResult(savedEntry, location);
    }
    AnalyticsService.instance
        .logDrugScan(
          drugName: entry.productName ?? 'N/A',
          regNumber: entry.regNumber ?? 'N/A',
          status: entry.status.toString(),
          source: location,
        )
        .catchError((Object e) async => Sentry.captureException(e));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
            if (result.matches.length > 1) ...[
              _OtherMatchesSection(matches: result.matches.skip(1).toList()),
              const SizedBox(height: 16),
            ],
            if (result.warnings.isNotEmpty) ...[
              VerificationWarningsWidget(warnings: result.warnings),
              const SizedBox(height: 16),
            ],
            if (result.bestMatch != null)
              EvidenceSummaryCard(evidence: result.bestMatch!.evidence),
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
    final status = _parseProductStatus(product.status);
    final style = _productStatusStyle(status);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Product Information',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: style.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, color: style.color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      style.label,
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: style.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: style.borderColor),
          const SizedBox(height: 12),
          _InfoRow(label: 'Manufacturer', value: product.manufacturer),
          if (product.registrationNumber.isNotEmpty)
            _InfoRow(label: 'Reg. Number', value: product.registrationNumber),
          if (product.strength != null)
            _InfoRow(label: 'Strength', value: product.strength!),
          if (product.dosageForm != null)
            _InfoRow(label: 'Dosage Form', value: product.dosageForm!),
          if (product.category != null)
            _InfoRow(label: 'Category', value: product.category!),
          if (product.barcode != null)
            _InfoRow(label: 'Barcode', value: product.barcode!),
          if (product.countryOrigin != null)
            _InfoRow(label: 'Origin', value: product.countryOrigin!),
          if (product.region != null)
            _InfoRow(label: 'Region', value: product.region!),
          if (product.activeIngredient != null)
            _InfoRow(
              label: 'Active Ingredient',
              value: product.activeIngredient!,
            ),
          if (product.registrationDate != null)
            _InfoRow(
              label: 'Registered On',
              value: dateFormat.format(product.registrationDate!),
            ),
          if (product.expiryDate != null)
            _InfoRow(
              label: 'Expires On',
              value: dateFormat.format(product.expiryDate!),
            ),
        ],
      ),
    );
  }
}

class _OtherMatchesSection extends StatelessWidget {
  final List<VerificationMatch> matches;

  const _OtherMatchesSection({required this.matches});

  @override
  Widget build(BuildContext context) {
    final sorted = [...matches]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          'Other Possible Matches (${sorted.length})',
          style: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        children: [
          for (final match in sorted) ...[
            _OtherMatchTile(match: match),
            if (match != sorted.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _OtherMatchTile extends StatelessWidget {
  final VerificationMatch match;

  const _OtherMatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final product = match.product;
    final style = _productStatusStyle(_parseProductStatus(product.status));
    final dateFormat = DateFormat('dd MMM yyyy');
    final regDate = product.registrationDate != null
        ? dateFormat.format(product.registrationDate!)
        : 'N/A';
    final expiryDate = product.expiryDate != null
        ? dateFormat.format(product.expiryDate!)
        : 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showProductDetailModal(context, product),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: style.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: style.borderColor),
        ),
        child: Row(
          children: [
            Icon(style.icon, color: style.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.manufacturer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reg: $regDate  •  Exp: $expiryDate',
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: style.color, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showProductDetailModal(BuildContext context, MatchedProduct product) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _ProductCard(product: product),
            ],
          ),
        ),
      ),
    ),
  );
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
                fontSize: 13,
                color: Colors.grey[500],
              ),
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
              fontSize: 13,
              color: Colors.orange[700],
            ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (r) => false,
            ),
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
