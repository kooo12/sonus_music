import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/pages/authentication/auth_controller.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  // Password visibility
  static final RxBool _obscurePassword = true.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Determine layout based on screen size and orientation
    final isTablet = screenWidth >= 768; // Tablet breakpoint
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                    // keyboardDismissBehavior:
                    //     ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              width: MediaQuery.of(context).size.width *
                                  (isTabletLandscape
                                      ? 0.4
                                      : isTablet
                                          ? 0.6
                                          : 0.9),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Create Account',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: controller.nameCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _decor('Display name'),
                                    cursorColor: TpsColors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: controller.emailCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _decor('Email'),
                                    cursorColor: TpsColors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(() => TextField(
                                        controller: controller.passwordCtrl,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        obscureText: _obscurePassword.value,
                                        cursorColor: TpsColors.white,
                                        decoration: _decor('Password').copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword.value
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.white70,
                                            ),
                                            onPressed: () =>
                                                _obscurePassword.value =
                                                    !_obscurePassword.value,
                                          ),
                                        ),
                                      )),
                                  const SizedBox(height: 20),
                                  Obx(() => SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: controller.isLoading.value
                                              ? null
                                              : controller.signup,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                TpsColors.musicPrimary,
                                            disabledBackgroundColor: TpsColors
                                                .musicPrimary
                                                .withOpacity(0.5),
                                            side: BorderSide.none,
                                            shape: const StadiumBorder(),
                                          ),
                                          child: controller.isLoading.value
                                              ? const LoadingWidget()
                                              : const Text('Sign up'),
                                        ),
                                      )),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      controller.clearTextField();
                                      Get.back();
                                    },
                                    child: const Text('Back to login',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ));
              }),
            )
          ],
        ),
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
