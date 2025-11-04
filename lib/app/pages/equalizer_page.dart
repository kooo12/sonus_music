import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import 'dart:ui' as ui;
import '../controllers/equalizer_controller.dart';
import '../ui/theme/app_colors.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EqualizerController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: IgnorePointer(
                ignoring: true,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 25),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Professional Equalizer'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.enabled
                                  ? TpsColors.musicPrimary
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: controller.enabled
                                    ? TpsColors.musicPrimary
                                    : Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => controller.toggleEqualizer(),
                              child: Text(
                                controller.enabled ? 'ON' : 'OFF',
                                style: TextStyle(
                                  color: controller.enabled
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // Frequency Response Graph
                        Obx(() => Container(
                              height: 200,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
                                  child: CustomPaint(
                                    painter: FrequencyGraphPainter(
                                      bands: controller.bands,
                                      enabled: controller.enabled,
                                    ),
                                    size: Size.infinite,
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 20),

                        // Preset Selectors
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Obx(() => _buildPresetSelector(
                                      'Mode',
                                      controller.selectedPreset,
                                      controller.availablePresets,
                                      (value) => controller.applyPreset(value),
                                    )),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Obx(() => _buildPresetSelector(
                                      'Effect',
                                      controller.selectedEffect,
                                      const ['None', 'Live', 'Studio', 'Club'],
                                      (value) => controller.applyEffect(value),
                                    )),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Frequency Band Sliders
                        Obx(() {
                          if (controller.bands.isEmpty) {
                            return const Center(
                              child: Text(
                                'Equalizer not available',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return Container(
                            height: 200,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children:
                                  controller.bands.asMap().entries.map((entry) {
                                final index = entry.key;
                                final band = entry.value;
                                return _buildBandSlider(
                                    controller, index, band);
                              }).toList(),
                            ),
                          );
                        }),

                        const SizedBox(height: TpsSizes.spaceBtwSections * 1.5),

                        // Rotary Knobs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Obx(() => _buildRotaryKnob(
                                    'Bass Boost',
                                    controller.bassBoost,
                                    (value) => controller.setBassBoost(value),
                                  )),
                              Obx(() => _buildRotaryKnob(
                                    'Virtualizer',
                                    controller.virtualizer,
                                    (value) => controller.setVirtualizer(value),
                                  )),
                            ],
                          ),
                        ),

                        // Removed Spacer to allow scrollable layout

                        // Reset Button
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: GestureDetector(
                            onTap: () => controller.resetToFlat(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Text(
                                'Reset to Flat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(String label, String value, List<String> options,
      Function(String) onChanged) {
    return GestureDetector(
      onTap: () => _showPresetMenu(label, options, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.tune, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }

  void _showPresetMenu(
      String label, List<String> options, Function(String) onChanged) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) => ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    onChanged(option);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBandSlider(
      EqualizerController controller, int index, EqBand band) {
    final min = band.minLevel.toDouble();
    final max = band.maxLevel.toDouble();
    final normalizedValue = (band.level - min) / (max - min);

    return Column(
      children: [
        // Frequency label
        Text(
          _formatFrequency(band.center),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                trackHeight: 3,
                activeTrackColor: controller.enabled
                    ? TpsColors.musicPrimary
                    : Colors.white.withOpacity(0.3),
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: controller.enabled
                    ? TpsColors.musicPrimary
                    : Colors.white.withOpacity(0.5),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: normalizedValue,
                onChanged: !controller.enabled
                    ? null
                    : (v) {
                        final newLevel = (min + v * (max - min)).round();
                        controller.setBandLevel(index, newLevel);
                      },
              ),
            ),
          ),
        ),

        // Level indicator
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: controller.enabled
                ? TpsColors.musicPrimary
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildRotaryKnob(
      String label, double value, Function(double) onChanged) {
    final double minVal = label == 'Bass Boost' ? -12.0 : 0.0;
    final double maxVal = label == 'Bass Boost' ? 12.0 : 100.0;
    final double step = label == 'Bass Boost' ? 1.0 : 5.0;

    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            // Drag up/down to adjust
            const sensitivity = 0.15;
            final delta = -details.delta.dy * sensitivity; // up increases
            final newValue = (value + delta).clamp(minVal, maxVal);
            onChanged(newValue);
          },
          onDoubleTap: () => onChanged(label == 'Bass Boost' ? 0.0 : 50.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: RotaryKnobPainter(
                      value: ((value - minVal) / (maxVal - minVal)) * 100.0),
                  size: const Size(80, 80),
                ),
                Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: TpsColors.musicPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniIconButton(Icons.remove, () {
              onChanged((value - step).clamp(minVal, maxVal));
            }),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Text(
                label == 'Bass Boost'
                    ? '${value.toStringAsFixed(1)} dB'
                    : '${value.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            _miniIconButton(Icons.add, () {
              onChanged((value + step).clamp(minVal, maxVal));
            }),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 180,
          child: SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              trackHeight: 3,
              activeTrackColor: TpsColors.musicPrimary,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: TpsColors.musicPrimary,
              overlayColor: TpsColors.musicPrimary.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: minVal,
              max: maxVal,
              divisions: label == 'Bass Boost' ? 24 : 20,
              value: value.clamp(minVal, maxVal),
              onChanged: (v) => onChanged(v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: TpsColors.musicPrimary.withOpacity(0.2),
        child: Ink(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  String _formatFrequency(int frequency) {
    if (frequency >= 1000) {
      return '${(frequency / 1000).toStringAsFixed(0)}k';
    }
    return frequency.toString();
  }
}

class FrequencyGraphPainter extends CustomPainter {
  final List<EqBand> bands;
  final bool enabled;

  FrequencyGraphPainter({required this.bands, required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color =
          enabled ? TpsColors.musicPrimary : Colors.white.withOpacity(0.3);

    final path = Path();
    final centerY = size.height / 2;
    final bandWidth = size.width / (bands.length - 1);

    for (int i = 0; i < bands.length; i++) {
      final x = i * bandWidth;
      final normalizedLevel = (bands[i].level - bands[i].minLevel) /
          (bands[i].maxLevel - bands[i].minLevel);
      final y = centerY - (normalizedLevel - 0.5) * size.height * 0.8;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withOpacity(0.1);

    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = centerY + (i - 2) * size.height * 0.2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical lines
    for (int i = 0; i < bands.length; i++) {
      final x = i * bandWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FrequencyGraphPainter oldDelegate) {
    return oldDelegate.bands != bands || oldDelegate.enabled != enabled;
  }
}

class RotaryKnobPainter extends CustomPainter {
  final double value;

  RotaryKnobPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw dotted arc
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = TpsColors.musicPrimary.withOpacity(0.3);

    const sweepAngle = 2 * 3.14159 * 0.75; // 270 degrees
    const startAngle = -3.14159 * 0.625; // Start from top-left

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw active arc
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = TpsColors.musicPrimary;

    final activeSweepAngle = sweepAngle * (value / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(RotaryKnobPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
