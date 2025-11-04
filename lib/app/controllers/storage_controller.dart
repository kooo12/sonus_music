import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../data/services/storage_service.dart';

class StorageController extends GetxController {
  StorageController(this._storageService);

  final StorageService _storageService;
  final RxList<String> scanFolders = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storageService.loadScanFolders();
    if (saved.isEmpty) {
      // Detect available default folders dynamically
      final defaults = await _getDefaultFolders();
      scanFolders.assignAll(defaults);
      await _storageService.saveScanFolders(defaults);
    } else {
      scanFolders.assignAll(saved);
    }
  }

  /// Dynamically detect default storage folders that exist on the device
  Future<List<String>> _getDefaultFolders() async {
    final defaults = <String>[];

    // Common Android storage paths to check
    final pathsToCheck = <String>[
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/sdcard/Music',
      '/sdcard/Download',
      '/storage/emulated/0/Android/media',
    ];

    // Check each path and add if it exists
    for (final path in pathsToCheck) {
      if (await _directoryExists(path)) {
        defaults.add(path);
      }
    }

    // If no defaults found, try to detect storage locations dynamically
    if (defaults.isEmpty) {
      defaults.addAll(await _detectStoragePaths());
    }

    return defaults;
  }

  /// Check if a directory exists
  Future<bool> _directoryExists(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  /// Detect storage paths by checking common locations
  Future<List<String>> _detectStoragePaths() async {
    final detected = <String>[];

    try {
      // Try to find external storage root
      final externalStorage = await _findExternalStorageRoot();
      if (externalStorage != null) {
        // Check for Music folder
        final musicPath = '$externalStorage/Music';
        if (await _directoryExists(musicPath)) {
          detected.add(musicPath);
        }

        // Check for Download folder
        final downloadPath = '$externalStorage/Download';
        if (await _directoryExists(downloadPath)) {
          detected.add(downloadPath);
        }
      }
    } catch (e) {
      debugPrint('Error detecting storage paths: $e');
    }

    return detected;
  }

  /// Find external storage root directory
  Future<String?> _findExternalStorageRoot() async {
    // Common external storage root paths
    final possibleRoots = [
      '/storage/emulated/0',
      '/sdcard',
      '/storage/sdcard0',
    ];

    for (final root in possibleRoots) {
      if (await _directoryExists(root)) {
        return root;
      }
    }

    return null;
  }

  Future<void> addFolder() async {
    final path = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select music folder');
    if (path != null && path.isNotEmpty && !scanFolders.contains(path)) {
      scanFolders.add(path);
      await _storageService.saveScanFolders(scanFolders);
    }
  }

  Future<void> removeFolder(String path) async {
    scanFolders.remove(path);
    await _storageService.saveScanFolders(scanFolders);
  }

  Future<void> save() async {
    await _storageService.saveScanFolders(scanFolders);
  }
}
