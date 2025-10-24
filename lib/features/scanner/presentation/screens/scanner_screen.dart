import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/scanner_provider.dart';
import 'dart:async';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  String? _lastScannedCode;
  DateTime? _lastScanTime;
  Timer? _debounceTimer;
  ScanResult? _currentResult;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan QR codes'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    // Prevent duplicate scans within 5 seconds
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) < const Duration(seconds: 5)) {
      return;
    }

    // Debounce rapid scans
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _lastScannedCode = code;
      _lastScanTime = DateTime.now();
      _processQRCode(code);
    });
  }

  Future<void> _processQRCode(String code) async {
    final result = await ref.read(scannerActionsProvider).scanTicket(code);

    setState(() {
      _currentResult = result;
      _showResult = true;
    });

    // Haptic feedback
    switch (result.status) {
      case ScanStatus.valid:
        AppHapticFeedback.success();
        break;
      case ScanStatus.alreadyScanned:
        AppHapticFeedback.warning();
        break;
      case ScanStatus.invalid:
        AppHapticFeedback.error();
        break;
    }

    // Auto-dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showResult = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scanner',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: AppColors.white,
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instruction text
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at QR code',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),

          // Result card
          if (_showResult && _currentResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showResult ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _buildResultCard(_currentResult!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ScanResult result) {
    Color headerColor;
    IconData icon;
    String title;

    switch (result.status) {
      case ScanStatus.valid:
        headerColor = AppColors.success;
        icon = Icons.check_circle;
        title = 'VALID TICKET';
        break;
      case ScanStatus.alreadyScanned:
        headerColor = AppColors.warning;
        icon = Icons.warning;
        title = 'ALREADY SCANNED';
        break;
      case ScanStatus.invalid:
        headerColor = AppColors.error;
        icon = Icons.error;
        title = 'INVALID TICKET';
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.status != ScanStatus.invalid) ...[
                  Text(
                    result.attendeeName ?? 'Unknown',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.ticketCode ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (result.ticketType != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      result.ticketType!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
                if (result.status == ScanStatus.invalid) ...[
                  Text(
                    result.ticketCode ?? 'Unknown Code',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.errorReason ?? 'Invalid ticket',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;

    // Draw overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 40.0;

    // Top-left
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop + 20),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + 20),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + 20),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + 20),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + 20),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + 20),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - 20),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - 20),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize - 20),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize - 20),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - 20),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - 20),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
