class Ticket {
  final String id;
  final String ticketCode;
  final String attendeeName;
  final String ticketType;
  final String eventName;
  final bool isScanned;
  final DateTime? scannedAt;
  final String? scannedBy;

  const Ticket({
    required this.id,
    required this.ticketCode,
    required this.attendeeName,
    required this.ticketType,
    required this.eventName,
    this.isScanned = false,
    this.scannedAt,
    this.scannedBy,
  });
}
