import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/scanner_repository.dart';
import '../../domain/entities/scan_result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Repository Provider
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScannerRepository(prefs);
});

// Scan History Provider
final scanHistoryProvider = StateProvider<List<ScanResult>>((ref) {
  // Load initial history from repository
  final repository = ref.watch(scannerRepositoryProvider);
  return repository.getScanHistory();
});

// Stats Provider
final statsProvider = StateProvider<Map<String, int>>((ref) {
  // Load initial stats from repository
  final repository = ref.watch(scannerRepositoryProvider);
  return repository.getStats();
});

// Today Scans Count Provider
final todayScansCountProvider = StateProvider<int>((ref) {
  // Load initial count from repository
  final repository = ref.watch(scannerRepositoryProvider);
  return repository.getTodayScansCount();
});

// Scanner Actions
class ScannerActions {
  final Ref ref;

  ScannerActions(this.ref);

  Future<ScanResult> scanTicket(String qrCode) async {
    final repository = ref.read(scannerRepositoryProvider);
    final result = await repository.validateTicket(qrCode);

    // Update history
    final currentHistory = ref.read(scanHistoryProvider);
    ref.read(scanHistoryProvider.notifier).state = [result, ...currentHistory];

    // Update stats
    ref.read(statsProvider.notifier).state = repository.getStats();

    // Update today count
    ref.read(todayScansCountProvider.notifier).state = repository.getTodayScansCount();

    return result;
  }

  Future<ScanResult> scanTicketManually(String ticketNumber) async {
    final repository = ref.read(scannerRepositoryProvider);
    final result = await repository.validateTicketManually(ticketNumber);

    // Update history
    final currentHistory = ref.read(scanHistoryProvider);
    ref.read(scanHistoryProvider.notifier).state = [result, ...currentHistory];

    // Update stats
    ref.read(statsProvider.notifier).state = repository.getStats();

    // Update today count
    ref.read(todayScansCountProvider.notifier).state = repository.getTodayScansCount();

    return result;
  }

  void refreshHistory() {
    final repository = ref.read(scannerRepositoryProvider);
    ref.read(scanHistoryProvider.notifier).state = repository.getScanHistory();
    ref.read(statsProvider.notifier).state = repository.getStats();
  }
}

final scannerActionsProvider = Provider<ScannerActions>((ref) {
  return ScannerActions(ref);
});
