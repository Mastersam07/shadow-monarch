import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  bool _bgmPlaying = false;

  Future<void> init() async => await FlameAudio.audioCache.loadAll([]);

  Future<void> playBgm(String filename, {double volume = 0.6}) async {
    if (_bgmPlaying) return;
    _ensureBgmAlive();
    await FlameAudio.bgm.play(filename, volume: volume);
    _bgmPlaying = true;
  }

  Future<void> stopBgm() async {
    if (!_bgmPlaying) return;
    await FlameAudio.bgm.stop();
    _bgmPlaying = false;
  }

  void playSfx(String filename, {double volume = 1.0}) => FlameAudio.play(filename, volume: volume);

  void dispose() {
    if (_bgmPlaying) FlameAudio.bgm.stop();
    _bgmPlaying = false;
  }

  void _ensureBgmAlive() {
    if (FlameAudio.bgm.audioPlayer.state == PlayerState.disposed) {
      FlameAudio.bgm.audioPlayer = AudioPlayer()..audioCache = FlameAudio.audioCache;
    }
  }
}
