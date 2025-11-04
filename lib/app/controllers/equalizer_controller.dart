import 'package:get/get.dart';
import 'home_controller.dart';

class EqualizerController extends GetxController {
  final HomeController _homeController = Get.find<HomeController>();

  // Observable variables
  final RxBool _enabled = false.obs;
  final RxList<EqBand> _bands = <EqBand>[].obs;
  final RxString _selectedPreset = 'Custom'.obs;
  final RxString _selectedEffect = 'None'.obs;
  final RxDouble _bassBoost = 0.0.obs;
  final RxDouble _virtualizer = 0.0.obs;

  // Preset configurations
  final Map<String, List<int>> _presetConfigurations = {
    'Custom': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'None': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Pop': [2, 1, 0, -1, -1, 0, 1, 2, 3, 2],
    'Rock': [4, 3, 2, 1, 0, 0, 1, 2, 3, 4],
    'Jazz': [2, 1, 0, 1, 2, 2, 1, 0, 1, 2],
    'Classical': [3, 2, 1, 0, 0, 0, 1, 2, 3, 4],
    'Vocal': [1, 0, -1, -2, -1, 0, 1, 2, 3, 2],
  };

  // Getters
  bool get enabled => _enabled.value;
  List<EqBand> get bands => _bands;
  String get selectedPreset => _selectedPreset.value;
  String get selectedEffect => _selectedEffect.value;
  double get bassBoost => _bassBoost.value;
  double get virtualizer => _virtualizer.value;

  @override
  void onInit() {
    super.onInit();
    _initializeEqualizer();
  }

  Future<void> _initializeEqualizer() async {
    try {
      final available = await _homeController.isEqualizerAvailable();
      _enabled.value = available;

      final raw = await _homeController.getEqualizerBands();
      _bands.assignAll(raw
          .map((e) => EqBand(
                band: e['band'] as int,
                center: e['center'] as int,
                minLevel: e['min'] as int,
                maxLevel: e['max'] as int,
                level: 0,
              ))
          .toList());
    } catch (e) {
      print('Equalizer initialization failed: $e');
    }
  }

  // Toggle equalizer on/off
  Future<void> toggleEqualizer() async {
    _enabled.value = !_enabled.value;
    await _homeController.setEqualizerEnabled(_enabled.value);

    if (_enabled.value) {
      await _applyCurrentSettings();
    } else {
      await _resetAllBands();
    }
  }

  // Set band level
  Future<void> setBandLevel(int bandIndex, int level) async {
    if (bandIndex >= 0 && bandIndex < _bands.length) {
      _bands[bandIndex] = _bands[bandIndex].copyWith(level: level);
      await _homeController.setBandLevel(bandIndex, level);
    }
  }

  // Apply preset
  Future<void> applyPreset(String preset) async {
    _selectedPreset.value = preset;

    if (preset == 'Custom') return;
    final configuration = _presetConfigurations[preset];
    if (configuration != null) {
      for (int i = 0; i < _bands.length && i < configuration.length; i++) {
        await setBandLevel(i, configuration[i]);
      }
    }
  }

  // Apply sound effect presets (macro controls that tweak bass/virtualizer and a few bands)
  Future<void> applyEffect(String effect) async {
    _selectedEffect.value = effect;
    if (!_enabled.value) return;

    switch (effect) {
      case 'Live':
        await setBassBoost(2.0); // +2 dB
        await setVirtualizer(60.0); // 60%
        // Lift presence region a bit (2k-4k)
        if (_bands.length >= 8) {
          await setBandLevel(
              6,
              (_bands[6].level + 2)
                  .clamp(_bands[6].minLevel, _bands[6].maxLevel));
          await setBandLevel(
              7,
              (_bands[7].level + 2)
                  .clamp(_bands[7].minLevel, _bands[7].maxLevel));
        }
        break;
      case 'Studio':
        // Balanced with clarity
        await setBassBoost(1.0);
        await setVirtualizer(30.0);
        // Gentle mid lift
        if (_bands.length >= 6) {
          await setBandLevel(
              4,
              (_bands[4].level + 1)
                  .clamp(_bands[4].minLevel, _bands[4].maxLevel));
          await setBandLevel(
              5,
              (_bands[5].level + 1)
                  .clamp(_bands[5].minLevel, _bands[5].maxLevel));
        }
        break;
      case 'Club':
        // Powerful bass and airy highs
        await setBassBoost(6.0);
        await setVirtualizer(80.0);
        if (_bands.isNotEmpty) {
          // Slight dip in low-mids to avoid muddiness
          final idx = _bands.length >= 4 ? 3 : _bands.length - 1;
          if (idx >= 0) {
            await setBandLevel(
                idx,
                (_bands[idx].level - 2)
                    .clamp(_bands[idx].minLevel, _bands[idx].maxLevel));
          }
        }
        break;
      case 'None':
      default:
        await resetToFlat();
        break;
    }
  }

  // Bass boost control (-12dB to +12dB)
  Future<void> setBassBoost(double value) async {
    _bassBoost.value = value.clamp(-12.0, 12.0);
    await _applyBassBoost();
  }

  // Virtualizer control (0% to 100%)
  Future<void> setVirtualizer(double value) async {
    _virtualizer.value = value.clamp(0.0, 100.0);
    await _applyVirtualizer();
  }

  // Apply bass boost to low frequencies (31Hz, 62Hz, 125Hz)
  Future<void> _applyBassBoost() async {
    if (!_enabled.value) return;

    final boostValue = _bassBoost.value.round();

    // Apply to first 3 bands (low frequencies)
    for (int i = 0; i < 3 && i < _bands.length; i++) {
      final currentLevel = _bands[i].level;
      final newLevel = (currentLevel + boostValue)
          .clamp(_bands[i].minLevel, _bands[i].maxLevel);
      await setBandLevel(i, newLevel);
    }
  }

  // Apply virtualizer effect to high frequencies (4kHz, 8kHz, 16kHz)
  Future<void> _applyVirtualizer() async {
    if (!_enabled.value) return;

    final virtualizerValue =
        (_virtualizer.value / 100.0 * 6.0).round(); // Scale to ±6dB

    // Apply to last 3 bands (high frequencies)
    for (int i = _bands.length - 3; i < _bands.length; i++) {
      if (i >= 0) {
        final currentLevel = _bands[i].level;
        final newLevel = (currentLevel + virtualizerValue)
            .clamp(_bands[i].minLevel, _bands[i].maxLevel);
        await setBandLevel(i, newLevel);
      }
    }
  }

  // Apply all current settings
  Future<void> _applyCurrentSettings() async {
    for (int i = 0; i < _bands.length; i++) {
      await _homeController.setBandLevel(i, _bands[i].level);
    }
    await _applyBassBoost();
    await _applyVirtualizer();
  }

  // Reset all bands to 0
  Future<void> _resetAllBands() async {
    for (int i = 0; i < _bands.length; i++) {
      _bands[i] = _bands[i].copyWith(level: 0);
      await _homeController.setBandLevel(i, 0);
    }
    _bassBoost.value = 0.0;
    _virtualizer.value = 0.0;
  }

  // Reset to flat response
  Future<void> resetToFlat() async {
    await _resetAllBands();
    _selectedPreset.value = 'None';
  }

  // Get available presets
  List<String> get availablePresets => _presetConfigurations.keys.toList();

  // Check if current settings match a preset
  bool isCurrentSettingsPreset() {
    final currentLevels = _bands.map((band) => band.level).toList();

    for (final entry in _presetConfigurations.entries) {
      if (entry.key == 'Custom') continue;

      bool matches = true;
      for (int i = 0; i < currentLevels.length && i < entry.value.length; i++) {
        if (currentLevels[i] != entry.value[i]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        _selectedPreset.value = entry.key;
        return true;
      }
    }

    _selectedPreset.value = 'Custom';
    return false;
  }
}

class EqBand {
  final int band;
  final int center;
  final int minLevel;
  final int maxLevel;
  final int level;

  const EqBand({
    required this.band,
    required this.center,
    required this.minLevel,
    required this.maxLevel,
    required this.level,
  });

  EqBand copyWith({int? level}) => EqBand(
        band: band,
        center: center,
        minLevel: minLevel,
        maxLevel: maxLevel,
        level: level ?? this.level,
      );
}
