
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class LocationInputDialog extends StatefulWidget {
  const LocationInputDialog({super.key});

  @override
  State<LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<LocationInputDialog> {
  final TextEditingController _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Where did you buy this?',
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help others find reliable drug sources',
              style: GoogleFonts.publicSans(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Search Pharmacy, Hospital, or Clinic',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_locationController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Save Location',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.publicSans(
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

