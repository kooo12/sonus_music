import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audio_service.dart' as svc;
import 'app_audio_handler.dart';

/// Manages app lifecycle and optimizes battery usage
/// Stops audio service when not playing and app is in background
class AppLifecycleManager extends GetxService with WidgetsBindingObserver {
  final svc.AudioPlayerService _audioPlayerService;
  final AppAudioHandler _audioHandler;

  // Background tracking
  bool _isInBackground = false;
  DateTime? _backgroundTime;
  Timer? _backgroundCheckTimer;

  // Configuration
  static const Duration _backgroundIdleTimeout = Duration(minutes: 5);

  AppLifecycleManager(this._audioPlayerService, this._audioHandler);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundMonitoring();
    debugPrint('AppLifecycleManager initialized');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopBackgroundMonitoring();
    _backgroundCheckTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (Platform.isAndroid) {
      switch (state) {
        case AppLifecycleState.inactive:
          // App is transitioning
          break;
        case AppLifecycleState.paused:
          _handleAppPaused();
          break;
        case AppLifecycleState.detached:
          _handleAppDetached();
          break;
        case AppLifecycleState.resumed:
          _handleAppResumed();
          break;
        case AppLifecycleState.hidden:
          // New state in Flutter 3.16+
          _handleAppPaused();
          break;
      }
    }
  }

  void _handleAppPaused() {
    _isInBackground = true;
    _backgroundTime = DateTime.now();
    debugPrint('App moved to background at $_backgroundTime');

    // Start monitoring if not playing
    if (!_audioPlayerService.isPlaying.value) {
      _scheduleIdleCheck();
    }
  }

  void _handleAppResumed() {
    _isInBackground = false;
    _backgroundTime = null;
    _backgroundCheckTimer?.cancel();
    debugPrint('App resumed from background');
  }

  void _handleAppDetached() {
    debugPrint('App detached');
    _cleanupResources();
  }

  void _startBackgroundMonitoring() {
    // Monitor playback state to schedule idle checks
    _audioPlayerService.isPlaying.listen((isPlaying) {
      if (isPlaying) {
        // Cancel any pending idle checks when playing
        _backgroundCheckTimer?.cancel();
      } else {
        // Schedule check when paused
        _scheduleIdleCheck();
      }
    });
  }

  void _stopBackgroundMonitoring() {
    _backgroundCheckTimer?.cancel();
  }

  void _scheduleIdleCheck() {
    _backgroundCheckTimer?.cancel();

    // Only check if in background
    if (!_isInBackground) return;

    _backgroundCheckTimer = Timer(_backgroundIdleTimeout, () {
      if (_isInBackground && !_audioPlayerService.isPlaying.value) {
        _handleIdleTimeout();
      }
    });

    debugPrint(
        'Scheduled idle check in ${_backgroundIdleTimeout.inMinutes} minutes');
  }

  void _handleIdleTimeout() {
    if (_audioPlayerService.isPlaying.value) {
      // Still playing, don't stop
      return;
    }

    debugPrint('Idle timeout reached. Cleaning up audio service...');
    _cleanupAudioService();
  }

  Future<void> _cleanupAudioService() async {
    try {
      // Stop the audio service to save battery
      await _audioHandler.stop();
      debugPrint('Audio service stopped');
    } catch (e) {
      debugPrint('Error stopping audio service: $e');
    }
  }

  void _cleanupResources() {
    _backgroundCheckTimer?.cancel();
  }

  /// Public method to manually trigger cleanup (can be called from UI)
  Future<void> forceCleanup() async {
    debugPrint('Force cleanup requested');
    await _cleanupAudioService();
  }
}
