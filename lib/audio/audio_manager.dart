import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  bool _bgmPlaying = false;

  Future<void> init() async => await FlameAudio.audioCache.loadAll([]);

  void playBgm(String filename, {double volume = 0.6}) {
    if (_bgmPlaying) return;
    FlameAudio.bgm.play(filename, volume: volume);
    _bgmPlaying = true;
  }

  void stopBgm() {
    if (!_bgmPlaying) return;
    FlameAudio.bgm.stop();
    _bgmPlaying = false;
  }

  void playSfx(String filename, {double volume = 1.0}) => FlameAudio.play(filename, volume: volume);

  void dispose() => FlameAudio.bgm.dispose();
}
