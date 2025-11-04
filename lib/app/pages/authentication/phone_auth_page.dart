import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import 'auth_controller.dart';

class PhoneAuthPage extends StatelessWidget {
  const PhoneAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
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
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Phone Sign In',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: controller.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: _decor('Phone number (+959...)'),
                            cursorColor: TpsColors.white,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller.codeCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _decor('SMS Code'),
                                  cursorColor: TpsColors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Obx(() => ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.requestPhoneCode,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: TpsColors.musicPrimary,
                                        disabledBackgroundColor: TpsColors
                                            .musicPrimary
                                            .withOpacity(0.5),
                                        side: BorderSide.none,
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                TpsSizes.spaceBtwItems)),
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Text('Send Code'),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(() => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.verifySmsCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TpsColors.musicPrimary,
                                    disabledBackgroundColor:
                                        TpsColors.musicPrimary.withOpacity(0.5),
                                    side: BorderSide.none,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Verify & Sign In'),
                                ),
                              )),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: TpsColors.white,
                              size: 10,
                            ),
                            onPressed: () => Navigator.pop(Get.context!),
                            label: const Text('Back',
                                style: TextStyle(color: Colors.white70)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _decor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
    );
  }
}
