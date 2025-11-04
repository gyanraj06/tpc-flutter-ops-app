import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/scanner_provider.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allHistory = ref.watch(scanHistoryProvider);
    final stats = ref.watch(statsProvider);

    // Filter history based on search query
    final history = _searchQuery.isEmpty
        ? allHistory
        : allHistory.where((scan) {
            final query = _searchQuery.toLowerCase();
            final attendeeName = scan.attendeeName?.toLowerCase() ?? '';
            final ticketCode = scan.ticketCode?.toLowerCase() ?? '';
            return attendeeName.contains(query) || ticketCode.contains(query);
          }).toList();

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
        child: allHistory.isEmpty
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

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or ticket number',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.grey500),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Results count
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Found ${history.length} result${history.length == 1 ? '' : 's'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),

                  // History List
                  if (history.isEmpty && _searchQuery.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No results found for "$_searchQuery"',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                scan.attendeeName ?? 'Invalid Code',
                style: AppTextStyles.titleMedium,
              ),
            ),
            // Scan method badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scan.scanMethod == ScanMethod.manual
                    ? AppColors.info.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: scan.scanMethod == ScanMethod.manual
                      ? AppColors.info
                      : AppColors.primary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    scan.scanMethod == ScanMethod.manual
                        ? Icons.keyboard
                        : Icons.qr_code_scanner,
                    size: 12,
                    color: scan.scanMethod == ScanMethod.manual
                        ? AppColors.info
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scan.scanMethod == ScanMethod.manual ? 'MANUAL' : 'QR',
                    style: AppTextStyles.caption.copyWith(
                      color: scan.scanMethod == ScanMethod.manual
                          ? AppColors.info
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            // Show error reason for invalid scans
            if (scan.status == ScanStatus.invalid && scan.errorReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  scan.errorReason!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
