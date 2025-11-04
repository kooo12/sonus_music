import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'audio_service.dart' as svc;

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final svc.AudioPlayerService _player;
  late final StreamSubscription _songSub;
  late final StreamSubscription _playingSub;
  late final StreamSubscription _positionSub;

  AppAudioHandler() {
    _player = Get.find<svc.AudioPlayerService>();

    // Initialize playback state immediately for Android 10+ compatibility
    _emitPlaybackState(playing: _player.isPlaying.value);

    // Mirror current media item when index changes
    _songSub = _player.currentIndex.listen((_) async {
      final song = _player.currentSong;
      if (song == null) return;
      Uri? artUri;
      try {
        final Uint8List? bytes = await _player.getAlbumArtwork(song.id);
        if (bytes != null && bytes.isNotEmpty) {
          artUri = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg');
        } else if ((song.albumArtwork ?? '').isNotEmpty) {
          artUri = Uri.file(song.albumArtwork!);
        }
      } catch (_) {}
      mediaItem.add(MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: artUri,
        extras: {'path': song.data},
      ));
    });

    // Mirror playback state
    _playingSub = _player.isPlaying.listen((bool playing) {
      _emitPlaybackState(playing: playing);
      if (!playing) {
        // Do not auto-stop here; pausing should keep notification.
      }
    });

    _positionSub = _player.currentPosition.listen((double posMs) {
      final d = Duration(milliseconds: posMs.floor());
      final curr = playbackState.value;
      playbackState.add(curr.copyWith(updatePosition: d));
    });
  }

  // Expose current queue to the system UI
  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    queue.add(newQueue);
  }

  void _emitPlaybackState({required bool playing}) {
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      playing: playing,
      processingState: AudioProcessingState.ready,
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      updatePosition:
          Duration(milliseconds: _player.currentPosition.value.floor()),
      bufferedPosition: Duration.zero,
      shuffleMode: _player.shuffleEnabled.value
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: () {
        switch (_player.repeatMode.value) {
          case svc.RepeatModeAS.one:
            return AudioServiceRepeatMode.one;
          case svc.RepeatModeAS.all:
            return AudioServiceRepeatMode.all;
          case svc.RepeatModeAS.off:
          default:
            return AudioServiceRepeatMode.none;
        }
      }(),
    ));
  }

  // External call to fully remove the notification
  Future<void> removeNotification() async {
    await stop();
  }

  // ================= Controls mapping =================
  @override
  Future<void> play() async {
    if (!_player.isPlaying.value) {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_player.isPlaying.value) {
      await _player.pause();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seekTo(position);
  }

  @override
  Future<void> skipToNext() async {
    await _player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.previous();
  }

  void close() {
    _songSub.cancel();
    _playingSub.cancel();
    _positionSub.cancel();
  }
}
