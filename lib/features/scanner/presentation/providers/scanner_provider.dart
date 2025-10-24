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
  return [];
});

// Stats Provider
final statsProvider = StateProvider<Map<String, int>>((ref) {
  return {
    'total': 0,
    'valid': 0,
    'invalid': 0,
    'duplicate': 0,
  };
});

// Today Scans Count Provider
final todayScansCountProvider = StateProvider<int>((ref) {
  return 0;
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

  void refreshHistory() {
    final repository = ref.read(scannerRepositoryProvider);
    ref.read(scanHistoryProvider.notifier).state = repository.getScanHistory();
    ref.read(statsProvider.notifier).state = repository.getStats();
  }
}

final scannerActionsProvider = Provider<ScannerActions>((ref) {
  return ScannerActions(ref);
});
