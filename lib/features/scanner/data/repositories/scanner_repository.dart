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

  ScannerRepository(this._prefs) {
    _loadScanHistory();
  }

  /// Load scan history from SharedPreferences
  void _loadScanHistory() {
    try {
      final historyJson = _prefs.getString(StorageKeys.scanHistory);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _scanHistory.clear();
        _scanHistory.addAll(
          decoded.map((item) => ScanResult.fromJson(item as Map<String, dynamic>)),
        );
        AppLogger.info('Loaded ${_scanHistory.length} scans from storage');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading scan history', error: e, stackTrace: stackTrace);
    }
  }

  /// Save scan history to SharedPreferences
  Future<void> _saveScanHistory() async {
    try {
      final encoded = jsonEncode(_scanHistory.map((scan) => scan.toJson()).toList());
      await _prefs.setString(StorageKeys.scanHistory, encoded);
      AppLogger.info('Saved ${_scanHistory.length} scans to storage');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving scan history', error: e, stackTrace: stackTrace);
    }
  }

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

      // Save to persistent storage
      await _saveScanHistory();

      AppLogger.info('Scan result: ${scanResult.status}');
      return scanResult;

    } catch (e, stackTrace) {
      AppLogger.error('Error validating ticket', error: e, stackTrace: stackTrace);

      final scanResult = ScanResult.invalid(
        ticketCode: qrCode,
        errorReason: 'Error: ${e.toString()}',
      );

      _scanHistory.insert(0, scanResult);

      // Save to persistent storage
      await _saveScanHistory();

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

  /// Validate ticket manually by ticket number (no QR signature verification)
  Future<ScanResult> validateTicketManually(String ticketNumber) async {
    AppLogger.info('Validating ticket manually: $ticketNumber');

    try {
      // Get vendor_id from session
      final vendorId = _prefs.getString(StorageKeys.vendorId);
      final scannerId = _prefs.getString(StorageKeys.userId) ?? 'flutter-scanner-01';

      AppLogger.info('Manual scan with vendor_id: $vendorId, scanner_id: $scannerId');

      // Call Supabase function for manual verification
      final response = await _supabase.rpc('verify_ticket_by_number', params: {
        'p_ticket_number': ticketNumber.toUpperCase(), // Convert to uppercase for consistency
        'p_scanner_id': scannerId,
        'p_scan_notes': 'Manual entry via Flutter app',
        'p_vendor_id': vendorId,
      });

      AppLogger.info('Supabase manual verification response: $response');

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
            scanMethod: ScanMethod.manual,
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
            scanMethod: ScanMethod.manual,
          );
          break;

        case 'invalid':
        default:
          scanResult = ScanResult.invalid(
            ticketCode: result['ticketCode'] ?? ticketNumber,
            errorReason: result['errorReason'] ?? result['message'] ?? 'Invalid ticket',
            scanMethod: ScanMethod.manual,
          );
          break;
      }

      // Add to history
      _scanHistory.insert(0, scanResult);

      // Save to persistent storage
      await _saveScanHistory();

      AppLogger.info('Manual scan result: ${scanResult.status}');
      return scanResult;

    } catch (e, stackTrace) {
      AppLogger.error('Error validating ticket manually', error: e, stackTrace: stackTrace);

      final scanResult = ScanResult.invalid(
        ticketCode: ticketNumber,
        errorReason: 'Error: ${e.toString()}',
        scanMethod: ScanMethod.manual,
      );

      _scanHistory.insert(0, scanResult);

      // Save to persistent storage
      await _saveScanHistory();

      return scanResult;
    }
  }
}
