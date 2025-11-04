import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../data/services/notification_handler_service.dart';
import '../../ui/theme/app_colors.dart';

class InAppMessagesPage extends StatelessWidget {
  InAppMessagesPage({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final notificationHandler = Get.find<NotificationHandlerService>();
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: TpsColors.musicBackgroundDark,
      appBar: AppBar(
        title: Text(
          'In-App Messages',
          style: themeCtrl.activeTheme.textTheme.headlineMedium!
              .copyWith(color: TpsColors.white),
        ),
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
          Obx(() {
            if (notificationHandler.hasUnread) {
              return IconButton(
                onPressed: () => notificationHandler.markAllMessagesAsRead(),
                icon: const Icon(Icons.mark_email_read),
                tooltip: 'Mark all as read',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        final messages = notificationHandler.inAppMessages;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll receive in-app messages here',
                  style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageCard(message, notificationHandler);
          },
        );
      }),
    );
  }

  Widget _buildMessageCard(
      InAppMessage message, NotificationHandlerService handler) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: message.isRead
          ? TpsColors.musicCardDark.withOpacity(0.7)
          : TpsColors.musicCardDark,
      child: InkWell(
        onTap: () => _handleMessageTap(message, handler),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.title,
                      style:
                          themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                        fontWeight: message.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!message.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: TpsColors.musicPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.body,
                style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                  color: message.isRead ? Colors.white60 : Colors.white70,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[800],
                      child: const Center(child: LoadingWidget()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ],
              if (message.actionTitle != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TpsColors.musicPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: TpsColors.musicPrimary.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        color: TpsColors.musicPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        message.actionTitle!,
                        style:
                            themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
                          color: TpsColors.musicPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(message.createdAt),
                    style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  const Spacer(),
                  if (!message.isRead)
                    TextButton(
                      onPressed: () => handler.markMessageAsRead(message.id),
                      child: Text(
                        'Mark as read',
                        style:
                            themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
                          color: TpsColors.musicPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageTap(
      InAppMessage message, NotificationHandlerService handler) {
    if (!message.isRead) {
      handler.markMessageAsRead(message.id);
    }
    Get.toNamed(Routes.NOTIFICATIONDETAILSPAGE, arguments: {
      'message': message,
      'notificationHandler': handler,
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
