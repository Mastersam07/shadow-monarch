import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../world/gate.dart';

class RoomTransition extends Component {
  double _alpha = 0;
  double _timer = 0;
  bool _active = false;
  String _text = '';
  String _subText = '';

  // 0-0.4: fade to black, 0.4-0.6: hold (room loads), 0.6-1.0: fade in
  static const _duration = 1.2;
  static const _fadeOutEnd = 0.4;
  static const _fadeInStart = 0.6;

  bool get isActive => _active;
  bool get isAtPeak => _active && _timer >= _fadeOutEnd * _duration && _timer < _fadeInStart * _duration;

  void start(int roomIndex, int totalRooms, RoomType type) {
    _active = true;
    _timer = 0;

    switch (type) {
      case RoomType.combat:
        _text = 'ROOM ${roomIndex + 1} / $totalRooms';
        _subText = 'Clear all enemies';
      case RoomType.elite:
        _text = 'ELITE ROOM';
        _subText = 'Powerful foe ahead';
      case RoomType.boss:
        _text = 'BOSS ROOM';
        _subText = 'Statue of God awaits';
      case RoomType.rest:
        _text = 'REST ROOM';
        _subText = 'Recover your strength';
      case RoomType.treasure:
        _text = 'TREASURE ROOM';
        _subText = 'A reward awaits';
    }
  }

  @override
  void update(double dt) {
    if (!_active) return;
    _timer += dt;
    if (_timer >= _duration) {
      _active = false;
      _alpha = 0;
    } else if (_timer < _fadeOutEnd * _duration) {
      _alpha = (_timer / (_fadeOutEnd * _duration)).clamp(0.0, 1.0);
    } else if (_timer < _fadeInStart * _duration) {
      _alpha = 1.0;
    } else {
      _alpha = 1.0 - ((_timer - _fadeInStart * _duration) / ((1.0 - _fadeInStart) * _duration)).clamp(0.0, 1.0);
    }
  }

  void renderOverlay(Canvas canvas, Size sz) {
    if (!_active && _alpha < 0.01) return;

    // Black overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()..color = Color.fromRGBO(0, 0, 0, _alpha.clamp(0.0, 1.0)),
    );

    // Text (only during hold phase)
    if (_timer > _fadeOutEnd * _duration && _timer < (_fadeInStart + 0.15) * _duration) {
      final textAlpha = _alpha.clamp(0.0, 1.0);

      final tp = TextPainter(
          text: TextSpan(
              text: _text,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: Color.fromRGBO(255, 255, 255, textAlpha * 0.9))),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(sz.width / 2 - tp.width / 2, sz.height * 0.42));

      final stp = TextPainter(
          text: TextSpan(
              text: _subText,
              style: TextStyle(fontSize: 14, letterSpacing: 2, color: Color.fromRGBO(155, 109, 215, textAlpha * 0.6))),
          textDirection: TextDirection.ltr)
        ..layout();
      stp.paint(canvas, Offset(sz.width / 2 - stp.width / 2, sz.height * 0.50));
    }
  }
}
