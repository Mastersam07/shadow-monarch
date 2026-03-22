import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import '../game/config.dart';

class _MenuParticle {
  double x, y, speed, size, phase;
  Color color;
  _MenuParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.phase,
    required this.color,
  });
}

class MenuRenderer {
  final _rng = Random();
  final List<_MenuParticle> _particles = [];
  double _time = 0;
  ui.Image? _bgImage;
  late Vector2 _lastSize;

  MenuRenderer() {
    _initParticles();
    _loadBgImage();
  }

  void _initParticles() {
    for (int i = 0; i < Config.menuParticleCount; i++) {
      _particles.add(_makeParticle(randomY: true));
    }
  }

  _MenuParticle _makeParticle({bool randomY = false, double w = 1200, double h = 800}) {
    final isPurple = _rng.nextBool();
    return _MenuParticle(
      x: _rng.nextDouble() * w,
      y: randomY ? _rng.nextDouble() * h : h + _rng.nextDouble() * 30,
      speed: Config.menuParticleSpeed * (0.3 + _rng.nextDouble()),
      size: 1 + _rng.nextDouble() * 4,
      phase: _rng.nextDouble() * pi * 2,
      color: isPurple ? Config.menuParticleColor : const Color(0xFF1A1A4E),
    );
  }

  Future<void> _loadBgImage() async {
    final data = await rootBundle.load('assets/images/bg.jpg');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _bgImage = frame.image;
  }

  void update(double dt) {
    _time += dt;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed * dt;
      p.x += sin(_time * 0.5 + p.phase) * 12 * dt;

      if (p.y < -10) {
        _particles[i] = _makeParticle(w: _lastSize.x, h: _lastSize.y);
      }
    }
  }

  void render(Canvas canvas, Vector2 sz) {
    _lastSize = sz;
    _renderBackground(canvas, sz);
    _renderParticles(canvas, sz);
    _renderTitle(canvas, sz);
    _renderDivider(canvas, sz);
    _renderAriseTagline(canvas, sz);
    _renderStartPrompt(canvas, sz);
    _renderVignette(canvas, sz);
  }

  void _renderBackground(Canvas canvas, Vector2 sz) {
    if (_bgImage case final ui.Image img) {
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, sz.x, sz.y);
      canvas.drawImageRect(img, src, dst, Paint());

      canvas.drawRect(
        dst,
        Paint()..color = const Color(0x60000000),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, sz.x * 0.45, sz.y),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(sz.x * 0.45, 0),
            [const Color(0xD0000000), const Color(0x00000000)],
            [0.0, 1.0],
          ),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, sz.x, sz.y),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(sz.x / 2, sz.y * 0.4),
            max(sz.x, sz.y) * 0.7,
            [const Color(0xFF0A0A1A), const Color(0xFF050510), const Color(0xFF000000)],
            [0.0, 0.5, 1.0],
          ),
      );
    }
  }

  void _renderParticles(Canvas canvas, Vector2 sz) {
    for (final p in _particles) {
      final verticalFrac = 1 - (p.y / sz.y).clamp(0.0, 1.0);
      final edgeFade = (verticalFrac < 0.1 ? verticalFrac / 0.1 : (verticalFrac > 0.9 ? (1 - verticalFrac) / 0.1 : 1.0))
          .clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * 2,
        Paint()
          ..color = p.color.withValues(alpha: edgeFade * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size,
        Paint()..color = p.color.withValues(alpha: edgeFade * 0.6),
      );
    }
  }

  void _renderTitle(Canvas canvas, Vector2 sz) {
    final pulseAlpha = 0.3 + sin(_time * Config.menuPulseSpeed) * 0.15;
    final leftX = sz.x * 0.04;

    _drawGlowText(canvas, sz, 'SHADOW', leftX, sz.y * 0.20, 42, Config.menuGlowColor, FontWeight.w900,
        letterSpacing: 18, glowAlpha: pulseAlpha, glowRadius: 12);

    _drawGlowText(canvas, sz, 'MONARCH', leftX, sz.y * 0.29, 42, const Color(0xFFFFFFFF), FontWeight.w900,
        letterSpacing: 18, glowAlpha: pulseAlpha * 0.6, glowRadius: 8, glowColor: Config.menuGlowColor);
  }

  void _renderAriseTagline(Canvas canvas, Vector2 sz) {
    final ariseAlpha = 0.3 + sin(_time * 1.2) * 0.25;
    final leftX = sz.x * 0.04;

    _drawGlowText(canvas, sz, 'A R I S E', leftX, sz.y * 0.42, 16, Config.menuGlowColor.withValues(alpha: ariseAlpha),
        FontWeight.w700,
        letterSpacing: 10, glowAlpha: ariseAlpha * 0.5, glowRadius: 6);
  }

  void _renderDivider(Canvas canvas, Vector2 sz) {
    final divY = sz.y * 0.39;
    final leftX = sz.x * 0.04;
    final divW = 200.0;

    canvas.drawLine(
      Offset(leftX, divY),
      Offset(leftX + divW, divY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(leftX, divY),
          Offset(leftX + divW, divY),
          [Config.menuGlowColor.withValues(alpha: 0.5), const Color(0x00000000)],
          [0.0, 1.0],
        )
        ..strokeWidth = 1,
    );
  }

  void _renderStartPrompt(Canvas canvas, Vector2 sz) {
    final promptAlpha = 0.3 + sin(_time * 2.5) * 0.3;
    final leftX = sz.x * 0.04;

    _drawLeftText(canvas, 'Press Space or X to begin', leftX, sz.y * 0.92, 13,
        Color.fromRGBO(255, 255, 255, promptAlpha), FontWeight.w400,
        letterSpacing: 2);
  }

  void _renderVignette(Canvas canvas, Vector2 sz) {
    final cx = sz.x / 2;
    final cy = sz.y / 2;
    final r = max(sz.x, sz.y) * 0.6;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.x, sz.y),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          r,
          [const Color(0x00000000), const Color(0x00000000), const Color(0x80000000)],
          [0.0, 0.5, 1.0],
        ),
    );
  }

  void _drawGlowText(
      Canvas canvas, Vector2 sz, String text, double x, double y, double fontSize, Color color, FontWeight weight,
      {double letterSpacing = 0, double glowAlpha = 0.3, double glowRadius = 8, Color? glowColor}) {
    final gc = glowColor ?? color;

    final baseStyle = GoogleFonts.cinzelDecorative(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );

    final glowTp = TextPainter(
      text: TextSpan(
        text: text,
        style: baseStyle.copyWith(
          color: gc.withValues(alpha: glowAlpha),
          shadows: [Shadow(color: gc.withValues(alpha: glowAlpha), blurRadius: glowRadius)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glowTp.paint(canvas, Offset(x, y));

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: baseStyle.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawLeftText(Canvas canvas, String text, double x, double y, double fontSize, Color color, FontWeight weight,
      {double letterSpacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color, letterSpacing: letterSpacing),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }
}
