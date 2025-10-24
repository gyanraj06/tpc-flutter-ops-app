import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/scanner_provider.dart';
import '../../domain/entities/scan_result.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(statsProvider);
    final history = ref.watch(scanHistoryProvider);
    final recentScans = history.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TPC Ops'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push(RouteConstants.profile),
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, user?.name ?? 'User'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(scannerActionsProvider).refreshHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                _getGreeting(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: 4),
              Text(
                user?.name ?? 'User',
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 24),

              // Stats Card
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Stats",
                        style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.check_circle,
                            value: stats['valid'].toString(),
                            label: 'Scanned',
                            color: AppColors.successLight,
                          ),
                          _buildStatItem(
                            icon: Icons.pending,
                            value: stats['duplicate'].toString(),
                            label: 'Pending',
                            color: AppColors.warningLight,
                          ),
                          _buildStatItem(
                            icon: Icons.error,
                            value: stats['invalid'].toString(),
                            label: 'Invalid',
                            color: AppColors.errorLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scan Button
              GestureDetector(
                onTap: () => context.push(RouteConstants.scanner),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 72,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'START SCAN',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to scan ticket',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Recent Scans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Scans', style: AppTextStyles.titleLarge),
                  TextButton(
                    onPressed: () => context.push(RouteConstants.history),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (recentScans.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No scans yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentScans.length,
                  itemBuilder: (context, index) {
                    final scan = recentScans[index];
                    return _buildHistoryItem(scan);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(scan) {
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
      default:
        icon = Icons.error;
        color = AppColors.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          scan.attendeeName ?? 'Invalid Code',
          style: AppTextStyles.titleMedium,
        ),
        subtitle: Text(
          _formatTime(scan.scannedAt),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return DateFormat('MMM dd, HH:mm').format(dateTime);
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, String userName) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.white,
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
                ),
                Text(
                  ref.watch(authProvider).user?.email ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteConstants.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Scan History'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteConstants.history);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteConstants.profile);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                        context.go(RouteConstants.login);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
