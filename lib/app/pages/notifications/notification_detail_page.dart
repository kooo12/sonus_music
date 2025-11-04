import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/notification_handler_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../helper_widgets/popups/loaders.dart';

class NotificationDetailPage extends StatelessWidget {
  final InAppMessage message;
  final NotificationHandlerService notificationHandler;

  NotificationDetailPage({
    super.key,
    required this.message,
    required this.notificationHandler,
  });

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Scaffold(
      backgroundColor: TpsColors.musicBackgroundDark,
      appBar: AppBar(
        title: Text('Message Details',
            style: themeCtrl.activeTheme.textTheme.headlineMedium!
                .copyWith(color: TpsColors.white)),
        backgroundColor: TpsColors.musicBackgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
              color: TpsColors.white,
            )),
        actions: [
          IconButton(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Message',
            color: TpsColors.error,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Status Badge
            _buildStatusBadge(),
            const SizedBox(height: 16),

            // Message Title
            _buildTitle(),
            const SizedBox(height: 12),

            // Timestamp
            _buildTimestamp(),
            const SizedBox(height: 20),

            // Message Image (if available)
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              _buildImage(message.imageUrl ?? ''),
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              const SizedBox(height: 20),

            // Message Body
            _buildBody(),
            const SizedBox(height: 24),

            // Custom Data (if available)
            if (message.customData != null && message.customData!.isNotEmpty)
              _buildCustomData(),
            if (message.customData != null && message.customData!.isNotEmpty)
              const SizedBox(height: 24),

            // Action Button (if available)
            if (message.actionUrl != null && message.actionUrl!.isNotEmpty)
              _buildActionButton(),
            if (message.actionUrl != null && message.actionUrl!.isNotEmpty)
              const SizedBox(height: 24),

            // Message Metadata
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: message.isRead
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: message.isRead ? Colors.green : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                message.isRead
                    ? Icons.mark_email_read
                    : Icons.mark_email_unread,
                size: 16,
                color: message.isRead ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                message.isRead ? 'Read' : 'Unread',
                style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
                  color: message.isRead ? Colors.green : Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      message.title,
      style: themeCtrl.activeTheme.textTheme.headlineMedium!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 16,
          color: Colors.white54,
        ),
        const SizedBox(width: 6),
        Text(
          _formatTimeAgo(message.createdAt),
          style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '•',
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(width: 12),
        Text(
          _formatDateTime(message.createdAt),
          style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: TpsColors.musicCardDark,
            child: const Center(child: LoadingWidget()
                //  CircularProgressIndicator(
                //   color: Colors.white,
                // ),
                ),
          ),
          errorWidget: (context, url, error) => Container(
            color: TpsColors.musicCardDark,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TpsColors.musicCardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        message.body,
        style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCustomData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.data_object,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Data',
                style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...message.customData!.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style:
                          themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: themeCtrl.activeTheme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleAction(),
        icon: Icon(
          message.actionUrl!.startsWith('http')
              ? Icons.open_in_new
              : Icons.arrow_forward,
        ),
        label: Text(
          message.actionTitle ?? 'Take Action',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TpsColors.musicCardDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Message Information',
                style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('Message ID', message.id),
          if (message.createdBy != null)
            _buildMetadataRow('Sent by', message.createdBy!),
          _buildMetadataRow('Created', _formatDateTime(message.createdAt)),
          _buildMetadataRow('Status', message.isRead ? 'Read' : 'Unread'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction() async {
    if (message.actionUrl == null || message.actionUrl!.isEmpty) return;

    debugPrint(
        'Handling message action: ${message.actionTitle} -> ${message.actionUrl}');

    if (message.actionUrl!.startsWith('http')) {
      try {
        final uri = Uri.parse(message.actionUrl ?? '');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          debugPrint('Opening external URL: ${message.actionUrl}');
        } else {
          debugPrint('Could not launch URL: ${message.actionUrl}');
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
    } else {
      Get.toNamed(message.actionUrl ?? Routes.HOME);
      debugPrint('Navigating to URL: ${message.actionUrl}');
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GlassAlertDialog(
        // backgroundColor: TpsColors.darkGrey.withOpacity(0.1),
        textColor: Colors.white,
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: themeCtrl.activeTheme.textTheme.bodyMedium!
                  .copyWith(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMessage();
            },
            child: Text(
              'Delete',
              style: themeCtrl.activeTheme.textTheme.bodyMedium!
                  .copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage() async {
    try {
      TpsLoader.customToast(message: 'Deleting message...');

      await notificationHandler.deleteMessage(message.id);

      TpsLoader.customToast(message: 'Message Deleted');

      Get.back(); // Go back to messages list
    } catch (e) {
      TpsLoader.customToast(message: 'Failed to delete message: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
