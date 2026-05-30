import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/verification_result.dart';
import '../providers/app_provider.dart';
import '../services/verification_service.dart';
import '../theme.dart';

class ManualEntryScreen extends StatefulWidget {
  final bool fromScanningError;

  const ManualEntryScreen({super.key, this.fromScanningError = false});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _noResults = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noResults = false;
    });

    try {
      final service = context.read<VerificationService>();
      final results = await service.verifyFuzzySearch(query);

      if (!mounted) return;

      if (results.isNotEmpty) {
        setState(() => _isLoading = false);
        final bestMatch = results.first;
        final resultWithTimestamp = VerificationResult(
          status: bestMatch.status,
          productName: bestMatch.productName,
          manufacturer: bestMatch.manufacturer,
          countryOrigin: bestMatch.countryOrigin,
          region: bestMatch.region,
          regNumber: bestMatch.regNumber,
          expiryDate: bestMatch.expiryDate,
          activeIngredient: bestMatch.activeIngredient,
          email: bestMatch.email,
          approvalDate: bestMatch.approvalDate,
          postalAddress: bestMatch.postalAddress,
          registrationType: bestMatch.registrationType,
          imageUrl: bestMatch.imageUrl,
          barcode: bestMatch.barcode,
          category: bestMatch.category,
          message: bestMatch.message,
          scannedAt: DateTime.now(),
        );
        context.read<AppProvider>().addScan(resultWithTimestamp);
        Navigator.pushNamed(context, '/results', arguments: results.toList());
      } else {
        setState(() {
          _isLoading = false;
          _noResults = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'An error occurred. Please check your connection and try again.';
      });
    }
  }

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
          'Manual Search',
          style: GoogleFonts.publicSans(
            color: AppTheme.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.fromScanningError) _buildWarningBanner(),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildExamplesCard(),
            const SizedBox(height: 24),
            _buildHelpLink(),
            const SizedBox(height: 24),
            _buildStatusCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSearchButton(),
    );
  }

  Widget _buildStatusCard() {
    if (_errorMessage != null) {
      return Card(
        color: AppTheme.warningRed.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.warningRed.withValues(alpha: 0.2)),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.warningRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_noResults) {
      return Card(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        elevation: 0,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No matching drug found. Please check your spelling or try a different search term.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningRed.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warningRed),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scanning didn\'t work? Don\'t worry. You can verify the drug manually by entering its details below.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.fromBorderSide(
              BorderSide(color: AppTheme.secondGreen, width: 2),
            ),
          ),
          child: const Icon(
            Icons.keyboard,
            size: 40,
            color: AppTheme.secondGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter Drug Details',
          style: GoogleFonts.publicSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Type the drug name (brand or generic) or the FDA Registration number found on the packaging.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _textController,
      maxLength: 100,
      decoration: InputDecoration(
        hintStyle: const TextStyle(color: AppTheme.secondGreen),
        hintText: 'e.g., Paracetamol or FDA/SD.123-12',
        prefixIcon: const Icon(Icons.search, color: AppTheme.secondGreen),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: AppTheme.secondGreen),
          onPressed: () => _textController.clear(),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildExamplesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXAMPLES',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildExampleRow('Generic Name: "Amoxicillin"'),
          _buildExampleRow('Brand Name: "Panadol"'),
          _buildExampleRow('FDA Number: "FDA/SD.20-1234"'),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildHelpLink() {
    return TextButton.icon(
      onPressed: _showFdaNumberHelp,
      icon: const Icon(Icons.help_outline, color: AppTheme.secondGreen),
      label: const Text(
        'Where can I find the FDA Registration number?',
        style: TextStyle(
          color: AppTheme.secondGreen,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showFdaNumberHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Finding the FDA Number',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The FDA Registration number is printed on the drug packaging. Look for:',
              style: GoogleFonts.publicSans(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildHelpRow('1.', 'The label on the box or bottle'),
            _buildHelpRow('2.', 'Text starting with "FDA/" or "REG NO."'),
            _buildHelpRow('3.', 'Format example: FDA/SD.20-1234'),
            const SizedBox(height: 12),
            Text(
              'If the number is missing or unclear, try searching by the drug\'s brand or generic name instead.',
              style: GoogleFonts.publicSans(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.publicSans(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.publicSans(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: const Color(0xFF102216),
          ),
          icon: _isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : const Icon(Icons.search),
          label: Text(
            _isLoading ? 'Searching...' : 'Search Drug',
            style: GoogleFonts.publicSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
