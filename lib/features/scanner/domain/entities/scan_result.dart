enum ScanStatus { valid, alreadyScanned, invalid }
enum ScanMethod { qr, manual }

class ScanResult {
  final ScanStatus status;
  final String? ticketCode;
  final String? attendeeName;
  final String? ticketType;
  final String? eventName;
  final DateTime? previousScanTime;
  final String? scannedBy;
  final String? errorReason;
  final DateTime scannedAt;
  final ScanMethod scanMethod;

  const ScanResult({
    required this.status,
    this.ticketCode,
    this.attendeeName,
    this.ticketType,
    this.eventName,
    this.previousScanTime,
    this.scannedBy,
    this.errorReason,
    required this.scannedAt,
    this.scanMethod = ScanMethod.qr,
  });

  factory ScanResult.valid({
    required String ticketCode,
    required String attendeeName,
    required String ticketType,
    required String eventName,
    ScanMethod scanMethod = ScanMethod.qr,
  }) {
    return ScanResult(
      status: ScanStatus.valid,
      ticketCode: ticketCode,
      attendeeName: attendeeName,
      ticketType: ticketType,
      eventName: eventName,
      scannedAt: DateTime.now(),
      scanMethod: scanMethod,
    );
  }

  factory ScanResult.alreadyScanned({
    required String ticketCode,
    required String attendeeName,
    required String ticketType,
    required String eventName,
    required DateTime previousScanTime,
    String? scannedBy,
    ScanMethod scanMethod = ScanMethod.qr,
  }) {
    return ScanResult(
      status: ScanStatus.alreadyScanned,
      ticketCode: ticketCode,
      attendeeName: attendeeName,
      ticketType: ticketType,
      eventName: eventName,
      previousScanTime: previousScanTime,
      scannedBy: scannedBy,
      scannedAt: DateTime.now(),
      scanMethod: scanMethod,
    );
  }

  factory ScanResult.invalid({
    required String ticketCode,
    String? errorReason,
    ScanMethod scanMethod = ScanMethod.qr,
  }) {
    return ScanResult(
      status: ScanStatus.invalid,
      ticketCode: ticketCode,
      errorReason: errorReason ?? 'Ticket not found in database',
      scannedAt: DateTime.now(),
      scanMethod: scanMethod,
    );
  }
}
