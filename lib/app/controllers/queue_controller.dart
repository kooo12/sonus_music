import 'package:get/get.dart';
import '../data/models/song_model.dart';
import '../data/services/audio_service.dart';
import '../data/services/audio_service.dart' show AudioPlayerService;

class QueueController extends GetxController {
  final AudioPlayerService _audioService = Get.find<AudioPlayerService>();

  RxList<SongModel> get queue => _audioService.currentPlaylist;
  RxInt get currentIndex => _audioService.currentIndex;

  void playAt(int index) async {
    if (index < 0 || index >= queue.length) return;
    await _audioService.playAtIndex(queue, index);
  }

  void removeAt(int index) {
    _audioService.removeFromQueue(index);
  }

  void clearAll() {
    _audioService.clearQueue();
  }

  void move(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    _audioService.moveInQueue(oldIndex, newIndex);
  }
}
