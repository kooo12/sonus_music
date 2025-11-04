// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:music_player/app/routes/app_routes.dart';

class DeveloperModeController extends GetxController {
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  final RxBool _isAuthenticated = false.obs;
  final RxBool _isDevelopmentServer = false.obs;
  final RxInt _remainingAttempts = 3.obs;
  final RxBool _isLocked = false.obs;
  final RxInt _lockoutEndTime = 0.obs;

  static const String PROD_API_URL = 'api.htunpauk.com';
  static const String DEV_API_URL = 'uat-api.htunpauk.com';
  static const String PIN_STORAGE_KEY = 'dev_mode_pin';
  static const String DEFAULT_PIN = '1234';
  static const int MAX_ATTEMPTS = 3;
  static const int LOCKOUT_DURATION = 300;

  final _storage = const FlutterSecureStorage();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isDevelopmentServer => _isDevelopmentServer.value;
  int get remainingAttempts => _remainingAttempts.value;
  bool get isLocked => _isLocked.value;
  int get lockoutEndTime => _lockoutEndTime.value;

  @override
  void onInit() {
    super.onInit();
    _initializePin();
  }

  Future<void> _initializePin() async {
    try {
      final storedPin = await _storage.read(key: PIN_STORAGE_KEY);
      if (storedPin == null) {
        final hashedPin = _hashPin(DEFAULT_PIN);
        await _storage.write(key: PIN_STORAGE_KEY, value: hashedPin);
      }
    } on PlatformException catch (e) {
      final errorString = '${e.code} ${e.message} ${e.details}';
      if (errorString.contains('BAD_DECRYPT')) {
        await _storage.delete(key: PIN_STORAGE_KEY);
        final hashedPin = _hashPin(DEFAULT_PIN);
        await _storage.write(key: PIN_STORAGE_KEY, value: hashedPin);
      } else {
        rethrow;
      }
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> verifyPin() async {
    if (_isLocked.value) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now < _lockoutEndTime.value) {
        final remainingTime = _lockoutEndTime.value - now;
        Get.snackbar(
          'Locked'.tr,
          'Too many attempts. Try again in $remainingTime seconds'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.bottom,
        );
        return;
      } else {
        _isLocked.value = false;
        _remainingAttempts.value = MAX_ATTEMPTS;
      }
    }

    final storedPin = await _storage.read(key: PIN_STORAGE_KEY);
    final hashedInputPin = _hashPin(pinController.text);

    if (hashedInputPin == storedPin) {
      _isAuthenticated.value = true;
      _remainingAttempts.value = MAX_ATTEMPTS;
      pinController.clear();
    } else {
      _remainingAttempts.value--;

      if (_remainingAttempts.value <= 0) {
        _isLocked.value = true;
        _lockoutEndTime.value =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) + LOCKOUT_DURATION;
        Get.snackbar(
          'Locked'.tr,
          'Too many attempts. Try again in $LOCKOUT_DURATION seconds'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.bottom,
        );
      } else {
        Get.snackbar(
          'Error'.tr,
          'Invalid PIN. ${_remainingAttempts.value} attempts remaining'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.bottom,
        );
      }
      pinController.clear();
    }
  }

  void toFCMStatus() {
    Get.toNamed(Routes.FCMMANAGEMENTPAGE);
  }

  void toSendNotification() {
    Get.toNamed(Routes.NOTIFICATIONSENDERPAGE);
  }

  @override
  void onClose() {
    pinController.dispose();
    pinFocusNode.dispose();
    pinFocusNode.unfocus();
    super.onClose();
  }
}
