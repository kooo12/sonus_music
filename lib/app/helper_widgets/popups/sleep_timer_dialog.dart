import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import '../../controllers/home_controller.dart';
import '../../ui/theme/app_colors.dart';

class SleepTimerDialog extends StatelessWidget {
  SleepTimerDialog({super.key});

  final HomeController controller = Get.find<HomeController>();
  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF), // translucent white
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x30FFFFFF), // translucent white border
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sleep Timer'.tr,
                        style: themeCtrl.activeTheme.textTheme.headlineMedium!
                            .copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current timer status
                  Obx(() {
                    if (controller.isSleepTimerActive) {
                      return _buildActiveTimer();
                    } else {
                      return _buildTimerOptions();
                    }
                  }),

                  const SizedBox(height: 20),

                  // Action buttons
                  Obx(() {
                    if (controller.isSleepTimerActive) {
                      return _buildActiveTimerButtons();
                    } else {
                      return _buildInactiveTimerButtons(context);
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTimer() {
    return Column(
      children: [
        // Timer display
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TpsColors.musicPrimary.withOpacity(0.8),
                TpsColors.musicSecondary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: TpsColors.musicPrimary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress circle
              Center(
                child: Obx(() => SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: controller.sleepTimerProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )),
              ),
              // Time text
              Center(
                child: Obx(() => Text(
                      controller.sleepTimerFormattedTime,
                      style: themeCtrl.activeTheme.textTheme.headlineMedium!
                          .copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Music will stop when timer ends'.tr,
          style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerOptions() {
    final presetMinutes = [5, 10, 15, 30, 45, 60, 90, 120];

    return Column(
      children: [
        Text(
          'Select sleep timer duration'.tr,
          style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: TpsSizes.spaceBtwItems),
        if (!controller.audioService.isPlaying.value)
          Text(
            'Music is not currently playing'.tr,
            style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
              color: Colors.white70,
            ),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presetMinutes.map((minutes) {
            return _buildTimeOption(minutes);
          }).toList(),
        ),
        // const SizedBox(height: 20),
        // const Text(
        //   'Or set custom time',
        //   style: TextStyle(
        //     color: Colors.white70,
        //     fontSize: 14,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildTimeOption(int minutes) {
    return Obx(() {
      final isLastSelected =
          controller.sleepTimerService.lastSelectedMinutes == minutes;

      return GestureDetector(
        onTap: () {
          controller.startSleepTimer(minutes);
          Navigator.pop(Get.context!);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isLastSelected
                    ? TpsColors.musicPrimary.withOpacity(0.4)
                    : TpsColors.musicPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isLastSelected
                      ? TpsColors.musicPrimary.withOpacity(0.8)
                      : TpsColors.musicPrimary.withOpacity(0.3),
                  width: isLastSelected ? 2 : 1,
                ),
                boxShadow: isLastSelected
                    ? [
                        BoxShadow(
                          color: TpsColors.musicPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${minutes}m'.tr,
                    style:
                        themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(),
                  ),
                  if (isLastSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActiveTimerButtons() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ElevatedButton(
                onPressed: () {
                  controller.addTimeToSleepTimer(15);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TpsColors.musicSecondary.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                  '+15 min'.tr,
                  style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ElevatedButton(
                onPressed: () {
                  controller.stopSleepTimer();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Stop Timer'.tr,
                  style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveTimerButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                  'Cancel'.tr,
                  style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
