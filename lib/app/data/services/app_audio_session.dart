import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:music_player/app/data/services/audio_service.dart' as svc;

class AppAudioSession extends GetxService {
  Future<void> configure() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Ducking / focus change handlers
    session.becomingNoisyEventStream.listen((_) {
      // Headphones unplugged: pause
      try {
        final player = Get.find<svc.AudioPlayerService>();
        player.pause();
      } catch (e) {
        debugPrint('Error pausing on becoming noisy: $e');
      }
    });

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // Phone call / other interruption: pause
        try {
          final player = Get.find<svc.AudioPlayerService>();
          player.pause();
        } catch (e) {
          debugPrint('Error pausing on interruption: $e');
        }
      } else {
        // Interruption ended resume
        try {
          final player = Get.find<svc.AudioPlayerService>();
          player.play();
        } catch (e) {
          debugPrint('Error resuming on interruption end: $e');
        }
      }
    });
  }
}
