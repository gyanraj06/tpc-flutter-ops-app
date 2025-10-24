import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/scan_result.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/constants/storage_keys.dart';

class ScannerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SharedPreferences _prefs;
  final List<ScanResult> _scanHistory = [];

  ScannerRepository(this._prefs);

  /// Validate ticket by calling Supabase function
  Future<ScanResult> validateTicket(String qrCode) async {
    AppLogger.info('Validating ticket: $qrCode');

    try {
      String data;
      String signature;

      // Parse QR code
      Map<String, dynamic> qrData = jsonDecode(qrCode);

      // Extract signature and remove it from data
      signature = qrData['signature'] ?? '';
      qrData.remove('signature');

      // The rest is the ticket data
      data = jsonEncode(qrData);

      // Get vendor_id from session
      final vendorId = _prefs.getString(StorageKeys.vendorId);
      final scannerId = _prefs.getString(StorageKeys.userId) ?? 'flutter-scanner-01';

      AppLogger.info('Scanning with vendor_id: $vendorId, scanner_id: $scannerId');

      // Call Supabase function with vendor_id
      final response = await _supabase.rpc('verify_and_use_ticket', params: {
        'p_qr_data': data,
        'p_signature': signature,
        'p_scanner_id': scannerId,
        'p_scan_notes': 'Scanned via Flutter app',
        'p_vendor_id': vendorId,
      });

      AppLogger.info('Supabase response: $response');

      // Parse response
      final result = response as Map<String, dynamic>;
      final status = result['status'] as String;

      ScanResult scanResult;

      switch (status) {
        case 'valid':
          scanResult = ScanResult.valid(
            ticketCode: result['ticketCode'] ?? 'Unknown',
            attendeeName: result['attendeeName'] ?? 'Unknown',
            ticketType: result['ticketType'] ?? 'Unknown',
            eventName: result['eventName'] ?? 'Unknown Event',
          );
          break;

        case 'already_scanned':
          scanResult = ScanResult.alreadyScanned(
            ticketCode: result['ticketCode'] ?? 'Unknown',
            attendeeName: result['attendeeName'] ?? 'Unknown',
            ticketType: result['ticketType'] ?? 'Unknown',
            eventName: result['eventName'] ?? 'Unknown Event',
            previousScanTime: result['previousScanTime'] != null
                ? DateTime.parse(result['previousScanTime'])
                : DateTime.now(),
            scannedBy: result['scannedBy'] ?? 'Unknown',
          );
          break;

        case 'invalid':
        case 'signature_mismatch':
        default:
          scanResult = ScanResult.invalid(
            ticketCode: result['ticketCode'] ?? qrCode,
            errorReason: result['errorReason'] ?? result['message'] ?? 'Invalid ticket',
          );
          break;
      }

      // Add to history
      _scanHistory.insert(0, scanResult);

      AppLogger.info('Scan result: ${scanResult.status}');
      return scanResult;

    } catch (e, stackTrace) {
      AppLogger.error('Error validating ticket', error: e, stackTrace: stackTrace);

      final scanResult = ScanResult.invalid(
        ticketCode: qrCode,
        errorReason: 'Error: ${e.toString()}',
      );

      _scanHistory.insert(0, scanResult);
      return scanResult;
    }
  }

  List<ScanResult> getScanHistory() {
    return List.unmodifiable(_scanHistory);
  }

  Map<String, int> getStats() {
    final validScans = _scanHistory.where((s) => s.status == ScanStatus.valid).length;
    final invalidScans = _scanHistory.where((s) => s.status == ScanStatus.invalid).length;
    final duplicateScans = _scanHistory.where((s) => s.status == ScanStatus.alreadyScanned).length;

    return {
      'total': _scanHistory.length,
      'valid': validScans,
      'invalid': invalidScans,
      'duplicate': duplicateScans,
    };
  }

  int getTodayScansCount() {
    final today = DateTime.now();
    return _scanHistory.where((s) {
      return s.scannedAt.year == today.year &&
          s.scannedAt.month == today.month &&
          s.scannedAt.day == today.day;
    }).length;
  }
}
