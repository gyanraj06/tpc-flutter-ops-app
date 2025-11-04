import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/scanner_provider.dart';
import '../widgets/manual_entry_dialog.dart';
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

    // Haptic feedback and sound
    switch (result.status) {
      case ScanStatus.valid:
        AppHapticFeedback.success();
        AudioService().playSuccessSound();
        break;
      case ScanStatus.alreadyScanned:
        AppHapticFeedback.warning();
        AudioService().playInvalidSound();
        break;
      case ScanStatus.invalid:
        AppHapticFeedback.error();
        AudioService().playInvalidSound();
        break;
    }

    // Show result dialog
    _showResultDialog(result);
  }

  Future<void> _processManualEntry(String ticketNumber) async {
    final result = await ref.read(scannerActionsProvider).scanTicketManually(ticketNumber);

    // Haptic feedback and sound
    switch (result.status) {
      case ScanStatus.valid:
        AppHapticFeedback.success();
        AudioService().playSuccessSound();
        break;
      case ScanStatus.alreadyScanned:
        AppHapticFeedback.warning();
        AudioService().playInvalidSound();
        break;
      case ScanStatus.invalid:
        AppHapticFeedback.error();
        AudioService().playInvalidSound();
        break;
    }

    // Show result dialog
    _showResultDialog(result);
  }

  void _showResultDialog(ScanResult result) {
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    switch (result.status) {
      case ScanStatus.valid:
        bgColor = AppColors.success;
        iconColor = AppColors.white;
        icon = Icons.check_circle;
        title = 'Ticket Valid';
        subtitle = 'Entry Allowed';
        break;
      case ScanStatus.alreadyScanned:
        bgColor = AppColors.warning;
        iconColor = AppColors.white;
        icon = Icons.warning;
        title = 'Already Scanned';
        subtitle = 'This ticket was already used';
        break;
      case ScanStatus.invalid:
        bgColor = AppColors.error;
        iconColor = AppColors.white;
        icon = Icons.error;
        title = 'Invalid Ticket';
        subtitle = result.errorReason ?? 'Ticket not found';
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 48),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Details (only for valid and already scanned)
              if (result.status != ScanStatus.invalid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result.attendeeName != null) ...[
                        Text(
                          'Name',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.attendeeName!,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (result.ticketCode != null) ...[
                        Text(
                          'Ticket Number',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.ticketCode!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.grey900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(
        onSubmit: _processManualEntry,
      ),
    );
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

          // Instruction text and manual entry button
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Point camera at QR code',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard, size: 20),
                  label: const Text('Manual Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
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
