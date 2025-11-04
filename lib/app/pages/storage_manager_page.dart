import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/storage_controller.dart';
import '../helper_widgets/popups/glass_dialog.dart';
import '../data/services/storage_service.dart';

class StorageManagerPage extends StatelessWidget {
  const StorageManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService());
    }
    final controller = Get.put(StorageController(Get.find<StorageService>()));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Storage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.folder_special,
                                    color: Colors.white70),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Scan Folders',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: controller.addFolder,
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text('Add',
                                      style: TextStyle(color: Colors.white)),
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final items = controller.scanFolders;
                              if (items.isEmpty) {
                                return const Text(
                                  'No folders selected. Add folders to scan for music.',
                                  style: TextStyle(color: Colors.white70),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                    color: Colors.white.withOpacity(0.1)),
                                itemBuilder: (context, index) {
                                  final path = items[index];
                                  return Row(
                                    children: [
                                      const Icon(Icons.folder,
                                          color: Colors.white70, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          path,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.white70),
                                        onPressed: () async {
                                          await controller.removeFolder(path);
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            })
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await controller.save();
                        Get.dialog(GlassAlertDialog(
                          title: const Text('Saved'),
                          content:
                              const Text('Scan folders updated successfully'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('OK'),
                            )
                          ],
                        ));
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
