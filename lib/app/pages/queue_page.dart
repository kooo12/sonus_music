import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/queue_controller.dart';
import '../ui/theme/app_colors.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = Get.put(QueueController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _glassButton(
                          icon: Icons.keyboard_arrow_down,
                          onTap: () => Get.back()),
                      const SizedBox(width: 12),
                      Text('Now Playing Queue'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: q.clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Text('Clear All'.tr,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (q.queue.isEmpty) {
                      return Center(
                        child: Text('Queue is empty'.tr,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7))),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      itemCount: q.queue.length,
                      onReorder: q.move,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                            color: Colors.transparent, child: child);
                      },
                      itemBuilder: (context, index) {
                        final song = q.queue[index];
                        final isCurrent = index == q.currentIndex.value;
                        return Container(
                          key: ValueKey(song.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.14)),
                          ),
                          child: ListTile(
                            onTap: () => q.playAt(index),
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? TpsColors.musicPrimary
                                  : Colors.white.withOpacity(0.2),
                              child: Icon(
                                  isCurrent
                                      ? Icons.equalizer
                                      : Icons.music_note,
                                  color: Colors.white),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70),
                                  onPressed: () => q.removeAt(index),
                                ),
                                const Icon(Icons.drag_handle,
                                    color: Colors.white60),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
