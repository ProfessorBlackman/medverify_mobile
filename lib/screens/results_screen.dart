import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medverify_mobile/services/analytics_service.dart';
import 'package:medverify_mobile/services/device_auth_service.dart';
import 'package:medverify_mobile/widgets/location_input_dialog.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/verification_result.dart';
import '../services/file_upload_service.dart';
import '../theme.dart';
import '../widgets/barcode_scanner_modal.dart';

import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingPhoto = false;
  bool _isSendingBarcode = false;
  bool _isAddingPrice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is VerificationResult) {
         if (arguments.source == null) {
           _showLocationDialog(arguments);
         }
      } else if (arguments is List<VerificationResult> && arguments.isNotEmpty) {
        if (arguments.first.source == null) {
           _showLocationDialog(arguments.first);
        }
      }
    });
  }

  Future<void> _showLocationDialog(VerificationResult result) async {
    final location = await showDialog<String>(
      context: context,
      builder: (context) => const LocationInputDialog(),
    );

    if (location != null && location.isNotEmpty) {
      if (mounted) {
        await context.read<AppProvider>().updateResult(result, location);
      }
      
      AnalyticsService.instance.logDrugScan(
        drugName: result.productName ?? 'N/A',
        regNumber: result.regNumber ?? 'N/A',
        status: result.status.toString(),
        source: location,
      );
    }
  }


  Color _getStatusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
      case VerificationStatus.valid:
        return AppTheme.primaryGreen;
      case VerificationStatus.nearExpiry:
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
      case VerificationStatus.nearExpiry:
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
      case VerificationStatus.nearExpiry:
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
    if (result.status == VerificationStatus.verified ||
        result.status == VerificationStatus.valid) {
      return 'Authenticity confirmed by FDA Ghana';
    }
    return result.message ?? 'No additional details available.';
  }

  bool _showReportButton(VerificationStatus? status) {
    return status != VerificationStatus.verified &&
        status != VerificationStatus.valid &&
        status != VerificationStatus.nearExpiry;
  }

  Future<void> _takeAndUploadPhoto(VerificationResult result) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppTheme.primaryGreen,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    final uploadResult = await _fileUploadService.uploadFile(
      File(croppedFile.path),
      FilePurpose.improve,
    );
    final response = await _uploadProductImprovements(
      null,
      uploadResult.url,
      null,
      result.regNumber!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadResult.isSuccess && response == 200
                ? 'Thank you for helping improve our data!'
                : uploadResult.error ?? 'Photo upload failed.',
          ),
          backgroundColor:
              uploadResult.isSuccess && response == 200
                  ? AppTheme.primaryGreen
                  : AppTheme.warningRed,
        ),
      );
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  // Returns the HTTP status code, or null on network/auth error.
  Future<int?> _uploadProductImprovements(
    String? barcode,
    String? imageUrl,
    String? price,
    String regNumber,
  ) async {
    if (barcode == null && imageUrl == null && price == null) return null;

    final Map<String, dynamic> body = {'registration_number': regNumber};
    if (barcode != null && barcode.isNotEmpty) body['barcode'] = barcode;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    if (price != null && price.isNotEmpty) body['price'] = price;

    try {
      final bodyBytes =
          Uint8List.fromList(utf8.encode(jsonEncode(body)));
      final response = await DeviceAuthService.instance
          .authenticatedPost('/v1/update_product', bodyBytes);
      return response.statusCode;
    } catch (e) {
      await Sentry.captureException(e);
      return null;
    }
  }

  Future<void> _scanAndAddBarcode(VerificationResult result) async {
    if (result.regNumber == null ||
        result.regNumber!.isEmpty ||
        result.regNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add barcode without a registration number.'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
      return;
    }

    final barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScannerModal(),
    );

    if (barcode == null || barcode.isEmpty) {
      return; // User cancelled or failed to scan.
    }

    setState(() {
      _isSendingBarcode = true;
    });

    final response = await _uploadProductImprovements(
      barcode,
      null,
      null,
      result.regNumber!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 200
                ? 'Barcode added successfully! Thank you.'
                : 'Failed to add barcode. Please try again.',
          ),
          backgroundColor: response == 200
              ? AppTheme.primaryGreen
              : AppTheme.warningRed,
        ),
      );
    }

    setState(() {
      _isSendingBarcode = false;
    });
  }

  Future<void> _showPriceInputDialog(VerificationResult result) async {
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final price = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  'Contribute Price',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prices are shared with the community to help others find affordable medicine in Ghana.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Drug Price (Retail)',
                    prefixText: 'GHS ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Please enter a valid number';
                    }
                    if (parsed <= 0) {
                      return 'Price must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(context).pop(priceController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit Price',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textLight)),
                ),
                const SizedBox(height: 29),
              ],
            ), 
          ),
        );
      },
    );

    if (price != null && price.isNotEmpty) {
      await _uploadPrice(result, price);
    }
  }

  Future<void> _uploadPrice(VerificationResult result, String price) async {
    if (result.regNumber == null ||
        result.regNumber!.isEmpty ||
        result.regNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add price without a registration number.'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
      return;
    }

    setState(() {
      _isAddingPrice = true;
    });

    final response = await _uploadProductImprovements(
      null,
      null,
      price,
      result.regNumber!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 200
                ? 'Price added successfully! Thank you.'
                : 'Failed to add price. Please try again.',
          ),
          backgroundColor: response == 200
              ? AppTheme.primaryGreen
              : AppTheme.warningRed,
        ),
      );
    }

    setState(() {
      _isAddingPrice = false;
    });
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
            if (result.status == VerificationStatus.verified ||
                result.status == VerificationStatus.valid)
              _buildLicenseDetailsCard(context, result),
            const SizedBox(height: 24),
            if (otherResults.isNotEmpty)
              _buildOtherMatches(context, otherResults),
            const SizedBox(height: 16),
            _buildImproveCard(context, result),
            const SizedBox(height: 16),
            Text(
              'Scan results are based on data from the Food and Drugs Authority (FDA) Ghana.',
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
              GestureDetector(
                onLongPress: () {
                  if (result.imageUrl != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              InteractiveViewer(
                                child: Image.network(
                                  result.imageUrl!,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (
                                        BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
                child: Container(
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
                      ? const Icon(
                          Icons.medication,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
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
          if (result.price != null)
            _buildDetailRow(
              context,
              Icons.event_busy,
              'Price',
              'GH₵ ${result.price}',
              valueColor: AppTheme.textLight,
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

  Widget _buildOtherMatches(
    BuildContext context,
    List<VerificationResult> otherResults,
  ) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(otherResult.approvalDate!),
                          ),
                        if (otherResult.expiryDate != null)
                          _buildDetailRow(
                            context,
                            Icons.event_busy,
                            'Expiry Date',
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(otherResult.expiryDate!),
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

  Widget _buildImproveCard(BuildContext context, VerificationResult result) {
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
            'Help us improve the database!',
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contribute missing information to improve our data.',
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
                  isLoading: _isSendingBarcode,
                  onTap: () => _scanAndAddBarcode(result),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImproveButton(
                  context,
                  icon: Icons.photo_camera,
                  label: 'Take Photo of Front',
                  isLoading: _isUploadingPhoto,
                  onTap: () => _takeAndUploadPhoto(result),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isAddingPrice ? null : () => _showPriceInputDialog(result),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isAddingPrice)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Container(
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBackground,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Icon(
                            Icons.price_change,
                            color: AppTheme.textLight,
                            size: 28,
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Price',
                        style: GoogleFonts.publicSans(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Report current market price',
                        style: GoogleFonts.publicSans(fontWeight: FontWeight.normal, color: AppTheme.secondaryText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_forward_ios_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImproveButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: AppTheme.textLight, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.publicSans(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext buildContext, VerificationResult result) {
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
              onPressed: () async {
                if (showReport) {
                  final url = Uri.parse(
                    'https://fdaghana.gov.gh/submit-a-complaint/',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch complaint form'),
                      ),
                    );
                  }
                } else {
                  if (!mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(result.status),
                foregroundColor: showReport
                    ? Colors.white
                    : const Color(0xFF102216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                showReport ? Icons.report_problem : Icons.qr_code_scanner,
              ),
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
