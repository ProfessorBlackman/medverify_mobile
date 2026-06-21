import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/multi_evidence_verification.dart';
import '../theme.dart';

class EvidenceSummaryCard extends StatefulWidget {
  final List<VerificationEvidence> evidence;
  const EvidenceSummaryCard({super.key, required this.evidence});

  @override
  State<EvidenceSummaryCard> createState() => _EvidenceSummaryCardState();
}

class _EvidenceSummaryCardState extends State<EvidenceSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined,
                      color: AppTheme.secondGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'How was this score calculated?',
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: widget.evidence
                    .map((e) => _EvidenceRow(evidence: e))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  final VerificationEvidence evidence;
  const _EvidenceRow({required this.evidence});

  _RowStyle _rowStyle(EvidenceStatus status) {
    switch (status) {
      case EvidenceStatus.match:
        return _RowStyle(
          icon: Icons.check_circle_outline,
          color: AppTheme.secondGreen,
          label: 'Matched',
        );
      case EvidenceStatus.partialMatch:
        return _RowStyle(
          icon: Icons.remove_circle_outline,
          color: AppTheme.warningOrange,
          label: 'Similar Match',
        );
      case EvidenceStatus.mismatch:
        return _RowStyle(
          icon: Icons.cancel_outlined,
          color: AppTheme.warningRed,
          label: 'Mismatch',
        );
      case EvidenceStatus.notAvailable:
        return _RowStyle(
          icon: Icons.remove,
          color: const Color(0xFF9CA3AF),
          label: 'Unavailable',
        );
    }
  }

  String _formatType(String type) {
    return type
        .split('_')
        .map((w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final style = _rowStyle(evidence.status);
    final scoreInt = evidence.score.round();
    final similarityText = evidence.similarity != null
        ? ' (${(evidence.similarity! * 100).round()}%)'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatType(evidence.type),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                Text(
                  '${style.label}$similarityText',
                  style: GoogleFonts.publicSans(
                      fontSize: 11, color: style.color),
                ),
              ],
            ),
          ),
          Text(
            '$scoreInt/${evidence.weight}',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowStyle {
  final IconData icon;
  final Color color;
  final String label;

  const _RowStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}
