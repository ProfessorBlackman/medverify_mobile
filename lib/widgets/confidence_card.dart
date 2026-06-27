import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/multi_evidence_verification.dart';
import '../theme.dart';

class ConfidenceCard extends StatelessWidget {
  final MultiVerificationResult result;
  const ConfidenceCard({super.key, required this.result});

  _StateStyle _stateStyle(MultiVerificationState state) {
    switch (state) {
      case MultiVerificationState.verifiedMatch:
        return _StateStyle(
          color: AppTheme.secondGreen,
          bgColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFF6EE7B7),
          icon: Icons.verified,
          label: 'VERIFIED MATCH',
          description: 'High confidence this product is in the FDA record.',
        );
      case MultiVerificationState.probableMatch:
        return _StateStyle(
          color: AppTheme.warningOrange,
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.check_circle_outline,
          label: 'PROBABLE MATCH',
          description: 'Likely a product variation or incomplete FDA data.',
        );
      case MultiVerificationState.insufficientInformation:
        return _StateStyle(
          color: const Color(0xFFC2610C),
          bgColor: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFED7AA),
          icon: Icons.info_outline,
          label: 'INSUFFICIENT INFORMATION',
          description: 'Partial evidence — consider adding more images.',
        );
      case MultiVerificationState.noReliableMatch:
        return _StateStyle(
          color: AppTheme.warningRed,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          icon: Icons.warning_amber_outlined,
          label: 'NO RELIABLE MATCH',
          description: 'No reliable regulatory match found.',
        );
      case MultiVerificationState.noResult:
        return _StateStyle(
          color: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF9FAFB),
          borderColor: const Color(0xFFD1D5DB),
          icon: Icons.help_outline,
          label: 'NO RESULT',
          description: 'No candidate could be identified.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _stateStyle(result.overallState);
    final confidencePct = result.overallConfidence.round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(style.icon, color: style.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: style.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.description,
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: style.color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '$confidencePct%',
                    style: GoogleFonts.publicSans(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: style.color,
                    ),
                  ),
                  Text(
                    'confidence',
                    style: GoogleFonts.publicSans(
                        fontSize: 10, color: style.color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.overallConfidence / 100,
              backgroundColor: style.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(style.color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateStyle {
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final String label;
  final String description;

  const _StateStyle({
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.label,
    required this.description,
  });
}
