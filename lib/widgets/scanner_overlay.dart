import 'package:flutter/material.dart';
import '../theme.dart';

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({super.key});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: OverlayPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class OverlayPainter extends CustomPainter {
  final double animationValue;

  OverlayPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Define scan area
    final scanAreaSize = size.width * 0.7;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize * 0.7, // Rectangular aspect ratio
    );

    // Draw background with hole
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanPath = Path()..addRect(scanAreaRect);
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanPath,
    );

    canvas.drawPath(finalPath, paint);

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaRect.left, scanAreaRect.top + cornerLength)
        ..lineTo(scanAreaRect.left, scanAreaRect.top)
        ..lineTo(scanAreaRect.left + cornerLength, scanAreaRect.top),
      cornerPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaRect.right - cornerLength, scanAreaRect.top)
        ..lineTo(scanAreaRect.right, scanAreaRect.top)
        ..lineTo(scanAreaRect.right, scanAreaRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaRect.left, scanAreaRect.bottom - cornerLength)
        ..lineTo(scanAreaRect.left, scanAreaRect.bottom)
        ..lineTo(scanAreaRect.left + cornerLength, scanAreaRect.bottom),
      cornerPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaRect.right - cornerLength, scanAreaRect.bottom)
        ..lineTo(scanAreaRect.right, scanAreaRect.bottom)
        ..lineTo(scanAreaRect.right, scanAreaRect.bottom - cornerLength),
      cornerPaint,
    );

    // Draw scanning line
    final linePaint = Paint()
      ..color = AppTheme.primaryGreen.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    // Calculate line position based on animation
    final lineY = scanAreaRect.top + (scanAreaRect.height * animationValue);
    
    canvas.drawLine(
      Offset(scanAreaRect.left + 10, lineY),
      Offset(scanAreaRect.right - 10, lineY),
      linePaint,
    );
    
    // Add glow to line
    final glowPaint = Paint()
      ..color = AppTheme.primaryGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    canvas.drawLine(
      Offset(scanAreaRect.left + 10, lineY),
      Offset(scanAreaRect.right - 10, lineY),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
