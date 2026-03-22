import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class ScreenEffects extends Component {
  double _shakeMag = 0;
  double _shakeX = 0, _shakeY = 0;
  double _flashAlpha = 0;
  Color _flashColor = const Color(0xFFFFFFFF);
  double _time = 0;

  double get shakeX => _shakeX;
  double get shakeY => _shakeY;

  void shake(double magnitude) {
    _shakeMag = max(_shakeMag, magnitude);
  }

  void flash(Color color, {double intensity = 0.3}) {
    _flashColor = color;
    _flashAlpha = intensity;
  }

  @override
  void update(double dt) {
    _time += dt;

    if (_shakeMag > 0.1) {
      _shakeX = sin(_time * 80) * _shakeMag;
      _shakeY = cos(_time * 90) * _shakeMag;
      _shakeMag *= pow(0.88, dt * 60);
    } else {
      _shakeX = 0;
      _shakeY = 0;
      _shakeMag = 0;
    }

    if (_flashAlpha > 0.01) {
      _flashAlpha *= pow(0.85, dt * 60);
    } else {
      _flashAlpha = 0;
    }
  }

  void renderFlash(Canvas canvas, Size sz) {
    if (_flashAlpha > 0.01) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, sz.width, sz.height),
        Paint()..color = _flashColor.withValues(alpha: _flashAlpha.clamp(0.0, 1.0)),
      );
    }
  }

  void renderVignette(Canvas canvas, Size sz) {
    final cx = sz.width / 2;
    final cy = sz.height / 2;
    final r = max(sz.width, sz.height) * 0.6;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = Gradient.radial(
          Offset(cx, cy),
          r,
          [const Color(0x00000000), const Color(0x00000000), const Color(0x50000000)],
          [0.0, 0.6, 1.0],
        ),
    );
  }
}
