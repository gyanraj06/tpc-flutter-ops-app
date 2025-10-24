import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/scanner_provider.dart';

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(scannerActionsProvider).refreshHistory();
        },
        child: history.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text('Summary', style: AppTextStyles.titleLarge),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Total', stats['total'].toString()),
                              _buildStatColumn('Valid', stats['valid'].toString()),
                              _buildStatColumn('Invalid', stats['invalid'].toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History List
                  ...history.map((scan) => _buildHistoryItem(scan)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Scans Yet',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to see history here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(ScanResult scan) {
    IconData icon;
    Color color;

    switch (scan.status) {
      case ScanStatus.valid:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case ScanStatus.alreadyScanned:
        icon = Icons.warning;
        color = AppColors.warning;
        break;
      case ScanStatus.invalid:
        icon = Icons.error;
        color = AppColors.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          scan.attendeeName ?? 'Invalid Code',
          style: AppTextStyles.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scan.ticketCode != null)
              Text(
                scan.ticketCode!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                  fontFamily: 'monospace',
                ),
              ),
            Text(
              DateFormat('MMM dd, HH:mm').format(scan.scannedAt),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      ),
    );
  }
}
