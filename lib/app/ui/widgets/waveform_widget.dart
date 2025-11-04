import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../ui/theme/app_colors.dart';

class WaveformWidget extends StatefulWidget {
  final String? audioPath;
  final double progress; // 0.0 to 1.0
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const WaveformWidget({
    super.key,
    this.audioPath,
    this.progress = 0.0,
    this.activeColor,
    this.inactiveColor,
    this.height = 60.0,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  late PlayerController _playerController;
  bool _isPreparing = false;
  String? _preparedPath;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final path = widget.audioPath;
    if (path == null || path.isEmpty) return;

    if (_preparedPath == path) return;

    _isPreparing = true;
    if (mounted) setState(() {});
    try {
      await _playerController.stopPlayer();
      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 120,
      );
      _preparedPath = path;
    } catch (_) {
      // ignore
    } finally {
      _isPreparing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreparing) {
      return _buildLoadingWaveform();
    }
    if (widget.audioPath == null || widget.audioPath!.isEmpty) {
      return _buildEmptyWaveform();
    }

    return SizedBox(
      height: widget.height,
      child: AudioFileWaveforms(
        playerController: _playerController,
        size: Size(MediaQuery.of(context).size.width, widget.height),
        playerWaveStyle: PlayerWaveStyle(
          showSeekLine: true,
          seekLineColor: widget.activeColor ?? TpsColors.musicPrimary,
          seekLineThickness: 2,
          fixedWaveColor:
              (widget.inactiveColor ?? Colors.white.withOpacity(0.15)),
          liveWaveGradient: LinearGradient(
            colors: [
              (widget.activeColor ?? TpsColors.musicPrimary).withOpacity(0.9),
              (widget.activeColor ?? TpsColors.musicPrimary).withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(
              0, 0, MediaQuery.of(context).size.width, widget.height)),
          waveCap: StrokeCap.round,
          waveThickness: 1,
          spacing: 3,
          scaleFactor: 60,
        ),
      ),
    );
  }

  Widget _buildEmptyWaveform() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Center(
        child: Icon(Icons.graphic_eq,
            color: Colors.white.withOpacity(0.5), size: 40),
      ),
    );
  }

  Widget _buildLoadingWaveform() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.activeColor ?? TpsColors.musicPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
