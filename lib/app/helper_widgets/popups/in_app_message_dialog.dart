import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../data/services/notification_handler_service.dart';
import '../../ui/theme/app_colors.dart';

class InAppMessageDialog extends StatelessWidget {
  final InAppMessage message;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;

  InAppMessageDialog({
    super.key,
    required this.message,
    this.onActionPressed,
    this.onDismiss,
  });

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: MediaQuery.of(context).size.width * 0.5,
          minHeight: MediaQuery.of(context).size.height * 0.2,
        ),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0x30FFFFFF),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildTitle(),
                ),
                // Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildContent(),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _buildActions(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TpsColors.musicPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message.title,
            style: themeCtrl.activeTheme.textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!message.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: TpsColors.musicAccent,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message body
          Text(
            message.body,
            style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
              height: 1.4,
            ),
          ),

          // Image if available
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: LoadingWidget(
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],

          // Custom data if available
          if (message.customData != null && message.customData!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Information:',
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...message.customData!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: themeCtrl.activeTheme.textTheme.bodySmall!
                              .copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Timestamp
          const SizedBox(height: 12),
          Text(
            _formatTimestamp(message.createdAt),
            style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Action button if available
    if (message.actionTitle != null &&
        message.actionTitle!.isNotEmpty &&
        message.actionUrl != null &&
        message.actionUrl!.isNotEmpty) {
      actions.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ElevatedButton(
              onPressed: () {
                _handleAction(context);
                onActionPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TpsColors.musicPrimary.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(
                    color: TpsColors.musicPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                message.actionTitle!,
                style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Mark as read button if unread
    if (!message.isRead) {
      actions.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ElevatedButton(
              onPressed: () {
                _markAsRead();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TpsColors.musicSecondary.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(
                    color: TpsColors.musicSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                'Mark as Read',
                style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Close button
    actions.add(
      ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'Close',
              style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    return actions;
  }

  void _handleAction(BuildContext context) {
    if (message.actionUrl != null && message.actionUrl!.isNotEmpty) {
      // Handle different types of actions
      if (message.actionUrl!.startsWith('http')) {
        // Open external URL
        debugPrint('Opening external URL: ${message.actionUrl}');
        // You can use url_launcher here if needed
      } else {
        // Navigate within app
        debugPrint('Navigating to: ${message.actionUrl}');
        // Add navigation logic based on the URL
        // Example: Get.toNamed(message.actionUrl!);
      }
    }
  }

  void _markAsRead() {
    try {
      final notificationService = Get.find<NotificationHandlerService>();
      notificationService.markMessageAsRead(message.id);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
