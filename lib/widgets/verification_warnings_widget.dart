import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class VerificationWarningsWidget extends StatelessWidget {
  final List<String> warnings;
  const VerificationWarningsWidget({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Notes',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningOrange,
                ),
              ),
            ],
          ),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(top: 4, left: 22),
              child: Text(
                '• $w',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
