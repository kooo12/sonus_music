import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static const String _prefsKey = 'scan_folders_v1';

  Future<StorageService> init() async {
    return this;
  }

  Future<List<String>> loadScanFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null || jsonStr.isEmpty) return <String>[];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.cast<String>();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveScanFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(folders));
  }
}
