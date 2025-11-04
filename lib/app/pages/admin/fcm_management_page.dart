import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import 'controllers/fcm_cleanup_controller.dart';
import '../../ui/theme/app_colors.dart';

class FCMManagementPage extends StatelessWidget {
  const FCMManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FCMCleanupController>();
    return Scaffold(
      backgroundColor: TpsColors.musicBackgroundDark,
      appBar: AppBar(
        title: const Text('FCM Token Management'),
        backgroundColor: TpsColors.musicBackgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget()
              // CircularProgressIndicator(
              //   color: TpsColors.musicPrimary,
              // ),
              );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(controller),
              const SizedBox(height: 20),
              _buildCleanupCard(controller),
              const SizedBox(height: 20),
              _buildRecommendationCard(controller),
              const SizedBox(height: 20),
              _buildLastCleanupCard(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard(FCMCleanupController controller) {
    final stats = controller.tokenStats.value;

    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Token Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (stats != null) ...[
              _buildStatRow('Total Tokens', stats.totalTokens.toString()),
              _buildStatRow('Active Tokens', stats.activeTokens.toString()),
              _buildStatRow('Inactive Tokens', stats.inactiveTokens.toString()),
              _buildStatRow('Recent Tokens', stats.recentTokens.toString()),
              _buildStatRow('Old Tokens', stats.oldTokens.toString()),
              const SizedBox(height: 12),
              _buildStatRow('Active Percentage',
                  '${stats.activePercentage.toStringAsFixed(1)}%'),
              _buildStatRow('Recent Percentage',
                  '${stats.recentPercentage.toStringAsFixed(1)}%'),
            ] else ...[
              const Text(
                'No statistics available',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupCard(FCMCleanupController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Token Cleanup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Clean up expired, inactive, or invalid FCM tokens.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoadingCleanUp.value
                        ? null
                        : controller.performCleanup,
                    icon: const Icon(Icons.cleaning_services),
                    label: controller.isLoadingCleanUp.value
                        ? const CircularProgressIndicator()
                        : const Text('Run Cleanup'),
                    style: ElevatedButton.styleFrom(
                      enableFeedback: true,
                      shape: const StadiumBorder(),
                      backgroundColor: TpsColors.musicPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoadingInactive.value
                        ? null
                        : controller.cleanupInactiveTokens,
                    icon: const Icon(Icons.delete_forever),
                    label: controller.isLoadingInactive.value
                        ? const LoadingWidget()
                        // const CircularProgressIndicator()
                        : const Text('Clean Inactive'),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.loadTokenStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Stats'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(FCMCleanupController controller) {
    final recommendation = controller.getCleanupRecommendation();
    final isRecommended = controller.isCleanupRecommended;

    return Card(
      color: isRecommended
          ? Colors.orange.withOpacity(0.1)
          : TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRecommended ? Icons.warning : Icons.check_circle,
                  color: isRecommended ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isRecommended ? 'Cleanup Recommended' : 'System Healthy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastCleanupCard(FCMCleanupController controller) {
    final result = controller.lastCleanupResult.value;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Cleanup Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Processed', result.totalProcessed.toString()),
            _buildStatRow('Expired Tokens', result.expiredCount.toString()),
            _buildStatRow('Inactive Tokens', result.inactiveCount.toString()),
            _buildStatRow('Invalid Tokens', result.invalidCount.toString()),
            _buildStatRow('Total Cleaned', result.totalCleaned.toString()),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  result.success ? 'Cleanup Successful' : 'Cleanup Failed',
                  style: TextStyle(
                    color: result.success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (result.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${result.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
