import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  Future<void> _performSearch() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final service = context.read<VerificationService>();
    try {
      final results = await service.verifyFuzzySearch(
        _textController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (results.isNotEmpty) {
        Navigator.pushNamed(context, '/results', arguments: results.first);
      } else {
        // Handle no results found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('No matching drug found.')));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _performSearch,
          ),
        ),
      );
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
          ],
        ),
      ),
      bottomNavigationBar: _buildSearchButton(),
    );
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
      onPressed: () {},
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
