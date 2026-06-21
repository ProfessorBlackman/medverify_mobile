import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/multi_evidence_verification.dart';
import '../providers/verification_session_provider.dart';
import '../services/file_upload_service.dart';
import '../services/multi_evidence_verification_service.dart';
import '../theme.dart';
import '../widgets/barcode_scanner_modal.dart';
import 'verification_result_v2_screen.dart';

class VerificationSessionScreen extends StatefulWidget {
  const VerificationSessionScreen({super.key});

  @override
  State<VerificationSessionScreen> createState() =>
      _VerificationSessionScreenState();
}

class _VerificationSessionScreenState
    extends State<VerificationSessionScreen> {
  final _regNumberController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationSessionProvider>().reset();
      _regNumberController.clear();
    });
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    super.dispose();
  }

  Future<void> _addImageFromCamera() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    context.read<VerificationSessionProvider>().addImage(File(picked.path));
  }

  Future<void> _addImageFromGallery() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    context.read<VerificationSessionProvider>().addImage(File(picked.path));
  }

  Future<void> _scanBarcode() async {
    final String? code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScannerModal(),
    );
    if (code != null && mounted) {
      context.read<VerificationSessionProvider>().setBarcode(code);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Take Photo',
                  style:
                      GoogleFonts.publicSans(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _addImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from Gallery',
                  style:
                      GoogleFonts.publicSans(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _addImageFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<VerificationSessionProvider>();
    final verificationService = context.read<MultiEvidenceVerificationService>();
    final uploadService = context.read<FileUploadService>();
    await provider.submitVerification(verificationService, uploadService);

    if (!mounted) return;
    if (provider.session.status == VerificationUploadStatus.success &&
        provider.result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VerificationResultV2Screen(),
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
        title: Text(
          'Verify Product',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<VerificationSessionProvider>(
        builder: (context, provider, _) {
          final sessionStatus = provider.session.status;
          final isSubmitting =
              sessionStatus == VerificationUploadStatus.uploading ||
                  sessionStatus == VerificationUploadStatus.processing;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Product Images',
                      subtitle:
                          'Add photos of the front, back, and sides of the packaging.',
                    ),
                    const SizedBox(height: 12),
                    _ImageGalleryGrid(
                      images: provider.session.images,
                      onAdd: isSubmitting ? null : _showImageOptions,
                      onRemove: isSubmitting
                          ? null
                          : (i) => provider.removeImage(i),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Barcode',
                      subtitle:
                          'Scan the barcode printed on the packaging.',
                    ),
                    const SizedBox(height: 12),
                    _BarcodeSection(
                      barcode: provider.session.barcode,
                      onScan: isSubmitting ? null : _scanBarcode,
                      onClear: isSubmitting
                          ? null
                          : () => provider.clearBarcode(),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Registration Number',
                      subtitle:
                          'Optional — enter the FDA registration number if visible.',
                    ),
                    const SizedBox(height: 12),
                    _RegNumberField(
                      controller: _regNumberController,
                      enabled: !isSubmitting,
                      onChanged: (val) =>
                          provider.setRegistrationNumber(val),
                    ),
                    const SizedBox(height: 24),
                    _EvidenceSummaryChips(session: provider.session),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: provider.errorMessage!),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _VerifyButton(
                  hasEvidence: provider.hasEvidence,
                  sessionStatus: sessionStatus,
                  imageUploadProgress: provider.imageUploadProgress,
                  onVerify: _submit,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.publicSans(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _ImageGalleryGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;

  const _ImageGalleryGrid(
      {required this.images, this.onAdd, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...images.asMap().entries.map(
              (entry) => _ImageThumbnail(
                file: entry.value,
                onRemove:
                    onRemove != null ? () => onRemove!(entry.key) : null,
              ),
            ),
        _AddImageButton(onTap: onAdd),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback? onRemove;

  const _ImageThumbnail({required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddImageButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryGreen, size: 28),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: GoogleFonts.publicSans(
                  fontSize: 10, color: AppTheme.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeSection extends StatelessWidget {
  final String? barcode;
  final VoidCallback? onScan;
  final VoidCallback? onClear;

  const _BarcodeSection({this.barcode, this.onScan, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: barcode != null
                  ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              barcode != null
                  ? Icons.check_circle_outline
                  : Icons.qr_code_scanner,
              color: barcode != null ? AppTheme.secondGreen : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: barcode != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode Scanned',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondGreen,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        barcode!,
                        style: GoogleFonts.publicSans(
                            fontSize: 12, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Text(
                    'No barcode scanned',
                    style: GoogleFonts.publicSans(
                        fontSize: 14, color: Colors.grey[500]),
                  ),
          ),
          if (barcode != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            TextButton(
              onPressed: onScan,
              child: Text(
                'Scan',
                style: GoogleFonts.publicSans(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegNumberField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _RegNumberField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_RegNumberField> createState() => _RegNumberFieldState();
}

class _RegNumberFieldState extends State<_RegNumberField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              onChanged: widget.onChanged,
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. FD1234567',
                hintStyle: GoogleFonts.publicSans(
                    color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

class _EvidenceSummaryChips extends StatelessWidget {
  final VerificationSession session;

  const _EvidenceSummaryChips({required this.session});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          icon: Icons.image_outlined,
          label: session.images.isEmpty
              ? 'No Images'
              : '${session.images.length} Image${session.images.length == 1 ? '' : 's'}',
          hasValue: session.images.isNotEmpty,
        ),
        _Chip(
          icon: Icons.qr_code,
          label: session.barcode != null ? 'Barcode' : 'No Barcode',
          hasValue: session.barcode != null,
        ),
        _Chip(
          icon: Icons.numbers,
          label: session.registrationNumber != null
              ? 'Reg. Number'
              : 'No Reg. Number',
          hasValue: session.registrationNumber != null,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;

  const _Chip(
      {required this.icon, required this.label, required this.hasValue});

  @override
  Widget build(BuildContext context) {
    final color = hasValue ? AppTheme.secondGreen : Colors.grey[400]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue
            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasValue
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.warningRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.warningRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.publicSans(
                  color: AppTheme.warningRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool hasEvidence;
  final VerificationUploadStatus sessionStatus;
  final double imageUploadProgress;
  final VoidCallback onVerify;

  const _VerifyButton({
    required this.hasEvidence,
    required this.sessionStatus,
    required this.imageUploadProgress,
    required this.onVerify,
  });

  bool get _isSubmitting =>
      sessionStatus == VerificationUploadStatus.uploading ||
      sessionStatus == VerificationUploadStatus.processing;

  @override
  Widget build(BuildContext context) {
    final isUploading = sessionStatus == VerificationUploadStatus.uploading;
    final isProcessing = sessionStatus == VerificationUploadStatus.processing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: imageUploadProgress > 0 ? imageUploadProgress : null,
                backgroundColor:
                    AppTheme.primaryGreen.withValues(alpha: 0.2),
                color: AppTheme.primaryGreen,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Uploading images... ${(imageUploadProgress * 100).round()}%',
              style: GoogleFonts.publicSans(
                  fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ] else if (isProcessing) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                backgroundColor:
                    AppTheme.primaryGreen.withValues(alpha: 0.2),
                color: AppTheme.primaryGreen,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analyzing product information...',
              style: GoogleFonts.publicSans(
                  fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  (!hasEvidence || _isSubmitting) ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.backgroundDark,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify Product',
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
