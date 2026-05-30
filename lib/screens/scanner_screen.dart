import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/verification_result.dart';
import '../providers/app_provider.dart';
import '../services/verification_service.dart';
import '../theme.dart';
import 'manual_entry_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  double _zoom = 0.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final service = context.read<VerificationService>();
        Set<VerificationResult> results =
            await service.verifyBarcode(barcodes.first.rawValue!);

        if (!mounted) return;
        if (results.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const ManualEntryScreen(fromScanningError: true),
            ),
          );
        }

        final bestResult = results.first;

        final resultWithTimestamp = VerificationResult(
          status: bestResult.status,
          productName: bestResult.productName,
          manufacturer: bestResult.manufacturer,
          countryOrigin: bestResult.countryOrigin,
          region: bestResult.region,
          regNumber: bestResult.regNumber,
          expiryDate: bestResult.expiryDate,
          activeIngredient: bestResult.activeIngredient,
          email: bestResult.email,
          approvalDate: bestResult.approvalDate,
          postalAddress: bestResult.postalAddress,
          registrationType: bestResult.registrationType,
          imageUrl: bestResult.imageUrl,
          barcode: bestResult.barcode,
          category: bestResult.category,
          message: bestResult.message,
          scannedAt: DateTime.now(),
        );

        if (resultWithTimestamp.status == VerificationStatus.unregistered) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ManualEntryScreen(fromScanningError: true),
            ),
          );
        } else {
          context.read<AppProvider>().addScan(resultWithTimestamp);
          await Navigator.pushNamed(context, '/results',
              arguments: resultWithTimestamp);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ManualEntryScreen(fromScanningError: true),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<void> _pickImageAndScan() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final capture = await _controller.analyzeImage(pickedFile.path);
      if (!mounted) return;

      if (capture == null || capture.barcodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No barcode found in the selected image.')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      await _handleBarcode(capture);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the image. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: _buildAppBarButton(Icons.home_outlined, () {
          Navigator.pushNamed(context, '/dashboard');
        }),
        title: Text(
          'Drug Scanner',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _buildAppBarButton(Icons.info_outline, () {
            Navigator.pushNamed(context, '/how_it_works');
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              'Align the barcode or QR code within the frame',
              style: GoogleFonts.publicSans(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildScannerView()),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildTrustBadge(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: Icon(icon, color: AppTheme.textLight),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            // zoomScale: _zoom,
          ),
          _buildScannerOverlay(),
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Scanning...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          Positioned(bottom: 24, child: _buildZoomControls()),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.width * 0.6,
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(1, '1x'),
          const SizedBox(width: 8),
          _zoomButton(2, '2x'),
        ],
      ),
    );
  }

  Widget _zoomButton(double zoomFactor, String label) {
    final bool isSelected = _zoom == (zoomFactor - 1);
    return GestureDetector(
      onTap: () => setState(() => _zoom = zoomFactor - 1),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.image,
          label: 'Upload Image',
          onPressed: _pickImageAndScan,
        ),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Enter Code',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManualEntryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      icon: Icon(icon, color: AppTheme.primaryGreen),
      label: Text(label),
    );
  }

  Widget _buildTrustBadge() {
    return Column(
      children: [
        const CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Icon(Icons.shield, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Powered by FDA Ghana',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        Text(
          'Verifying drug authenticity for your safety',
          style: GoogleFonts.publicSans(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
