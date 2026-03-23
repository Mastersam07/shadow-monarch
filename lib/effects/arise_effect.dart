import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/config.dart';

enum ArisePhase { idle, poolForming, arise, particleErupt, forming, reveal, done }

class AriseEffect extends Component {
  ArisePhase phase = ArisePhase.idle;
  double _totalTime = 0;
  double _targetX = 0, _targetY = 0;
  String _soldierName = '';
  Color _soldierColor = Config.playerColor;
  final _rng = Random();
  final _particles = <_AriseParticle>[];

  void Function()? onComplete;

  bool get isActive => phase != ArisePhase.idle && phase != ArisePhase.done;

  void trigger(double x, double y, String name, Color color) {
    _targetX = x;
    _targetY = y;
    _soldierName = name;
    _soldierColor = color;
    _totalTime = 0;
    phase = ArisePhase.poolForming;
    _particles.clear();
    _spawnParticles();
    // TODO(mastersam07): Play SFX — ARISE trigger (deep bass rumble, building energy)
  }

  void _spawnParticles() {
    for (int i = 0; i < 120; i++) {
      _particles.add(_AriseParticle(
        x: _targetX + (_rng.nextDouble() - 0.5) * 80,
        y: _targetY + 20 + _rng.nextDouble() * 15,
        targetX: _targetX + (_rng.nextDouble() - 0.5) * 30,
        targetY: _targetY - 20 - _rng.nextDouble() * 60,
        vx: (_rng.nextDouble() - 0.5) * 150,
        vy: -80 - _rng.nextDouble() * 200,
        size: 1.5 + _rng.nextDouble() * 2.5,
        color: _rng.nextDouble() < 0.3
            ? _soldierColor
            : (_rng.nextDouble() < 0.2 ? Config.playerGlow : const Color(0xFF0A0A12)),
      ));
    }
  }

  @override
  void update(double dt) {
    if (phase == ArisePhase.idle || phase == ArisePhase.done) return;

    _totalTime += dt;

    switch (_totalTime) {
      case < 0.8:
        phase = ArisePhase.poolForming;
      case < 1.6:
        phase = ArisePhase.arise;
      case < 3.0:
        phase = ArisePhase.particleErupt;
        _updateParticlesErupt(dt);
      case < 4.5:
        phase = ArisePhase.forming;
        _updateParticlesConverge(dt);
      case < 5.5:
        phase = ArisePhase.reveal;
        _updateParticlesHold(dt);
      case _:
        phase = ArisePhase.done;
        onComplete?.call();
    }
  }

  void _updateParticlesErupt(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 40 * dt; // slight gravity
      p.vx *= 0.98;
    }
  }

  void _updateParticlesConverge(double dt) {
    final progress = ((_totalTime - 3.0) / 1.5).clamp(0.0, 1.0);
    final spring = 2.0 + progress * 10;
    final damp = 0.88 + progress * 0.06;

    for (final p in _particles) {
      p.vx += (p.targetX - p.x) * spring * dt;
      p.vy += (p.targetY - p.y) * spring * dt;
      p.vx *= damp;
      p.vy *= damp;
      p.x += p.vx;
      p.y += p.vy;
    }
  }

  void _updateParticlesHold(double dt) {
    for (final p in _particles) {
      p.vx += (p.targetX - p.x) * 12 * dt;
      p.vy += (p.targetY - p.y) * 12 * dt;
      p.vx *= 0.92;
      p.vy *= 0.92;
      p.x += p.vx + sin(_totalTime * 5 + p.phase) * 0.3;
      p.y += p.vy + cos(_totalTime * 4 + p.phase * 1.2) * 0.3;
    }
  }

  void renderOverlay(Canvas canvas, Size sz) {
    if (phase == ArisePhase.idle || phase == ArisePhase.done) return;

    if (_totalTime > 0.5 && _totalTime < 4.0) {
      final tintAlpha =
          (_totalTime < 1.6) ? ((_totalTime - 0.5) / 1.1).clamp(0.0, 0.2) : ((4.0 - _totalTime) / 2.4).clamp(0.0, 0.2);
      canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height), Paint()..color = Color.fromRGBO(40, 15, 80, tintAlpha));
    }

    _drawPool(canvas);
    _drawParticles(canvas);

    if (_totalTime > 0.8 && _totalTime < 2.5) {
      _drawAriseText(canvas, sz);
    }

    if (phase == ArisePhase.reveal) {
      _drawReveal(canvas);
    }

    if (_totalTime > 4.8 && _totalTime < 5.5) {
      _drawSoldierName(canvas, sz);
    }

    if (_totalTime > 0.9 && _totalTime < 1.3) {
      final flash = (1 - ((_totalTime - 0.9) / 0.4)).clamp(0.0, 1.0) * 0.15;
      canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height), Paint()..color = Color.fromRGBO(155, 109, 215, flash));
    }
  }

  void _drawPool(Canvas canvas) {
    if (_totalTime > 5.0) return;

    final poolAlpha = switch (_totalTime) {
      < 0.8 => (_totalTime / 0.8).clamp(0.0, 1.0),
      < 3.5 => 1.0,
      _ => ((5.0 - _totalTime) / 1.5).clamp(0.0, 1.0),
    };
    final poolScale = poolAlpha;

    final poolW = 100 * poolScale;
    final poolH = 20 * poolScale;

    canvas.drawOval(
        Rect.fromCenter(center: Offset(_targetX, _targetY + 20), width: poolW * 1.4, height: poolH * 3),
        Paint()
          ..color = Color.fromRGBO(60, 0, 100, 0.15 * poolAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    canvas.drawOval(
        Rect.fromCenter(center: Offset(_targetX, _targetY + 20), width: poolW, height: poolH),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.9 * poolAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawOval(
        Rect.fromCenter(center: Offset(_targetX, _targetY + 20), width: poolW + 6, height: poolH + 4),
        Paint()
          ..color = Color.fromRGBO(120, 40, 180, 0.4 * poolAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    if (_totalTime > 0.3 && _totalTime < 4.0) {
      for (int i = 0; i < 2; i++) {
        final rPhase = (_totalTime * 2 + i * 1.5) % 1.0;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(_targetX, _targetY + 20),
                width: poolW * (0.4 + rPhase * 0.6),
                height: poolH * (0.3 + rPhase * 0.7)),
            Paint()
              ..color = Color.fromRGBO(100, 30, 160, (1 - rPhase) * 0.25 * poolAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    if (_totalTime < 1.6) return;

    for (final p in _particles) {
      final isColored = p.color != const Color(0xFF0A0A12);

      if (isColored) {
        canvas.drawCircle(
            Offset(p.x, p.y),
            p.size * 2.5,
            Paint()
              ..color = p.color.withValues(alpha: 0.15)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }

      canvas.drawCircle(Offset(p.x, p.y), p.size, Paint()..color = p.color.withValues(alpha: 0.8));
    }
  }

  void _drawAriseText(Canvas canvas, Size sz) {
    final alpha = switch (_totalTime) {
      < 1.1 => ((_totalTime - 0.8) / 0.3).clamp(0.0, 1.0),
      < 1.8 => 1.0,
      _ => ((2.5 - _totalTime) / 0.7).clamp(0.0, 1.0),
    };

    canvas.drawCircle(
        Offset(sz.width / 2, sz.height * 0.4),
        50,
        Paint()
          ..color = Color.fromRGBO(120, 40, 200, 0.12 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));

    final tp = TextPainter(
      text: TextSpan(
        text: 'ARISE',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 16,
          color: Color.fromRGBO(180, 80, 255, alpha),
          shadows: [
            Shadow(color: Color.fromRGBO(120, 40, 200, alpha * 0.8), blurRadius: 16),
            Shadow(color: Color.fromRGBO(80, 20, 140, alpha * 0.4), blurRadius: 32),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sz.width / 2 - tp.width / 2, sz.height * 0.4 - tp.height / 2));

    // TODO(mastersam07): Play SFX — "ARISE" voice/text hit (deep reverb, iconic)
  }

  void _drawReveal(Canvas canvas) {
    final revealProgress = ((_totalTime - 4.5) / 1.0).clamp(0.0, 1.0);

    final ringR = 60 * revealProgress;
    canvas.drawCircle(
        Offset(_targetX, _targetY - 20),
        ringR,
        Paint()
          ..color = Color.fromRGBO(120, 40, 200, (1 - revealProgress) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    canvas.drawCircle(
        Offset(_targetX, _targetY - 20),
        30,
        Paint()
          ..color = _soldierColor.withValues(alpha: 0.2 * (1 - revealProgress * 0.5))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    if (revealProgress > 0.3) {
      final eyeAlpha = ((revealProgress - 0.3) / 0.7).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(_targetX - 6, _targetY - 30),
          4,
          Paint()
            ..color = Color.fromRGBO(255, 30, 30, eyeAlpha * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(
          Offset(_targetX + 6, _targetY - 30),
          4,
          Paint()
            ..color = Color.fromRGBO(255, 30, 30, eyeAlpha * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(Offset(_targetX - 6, _targetY - 30), 2, Paint()..color = Color.fromRGBO(255, 50, 30, eyeAlpha));
      canvas.drawCircle(Offset(_targetX + 6, _targetY - 30), 2, Paint()..color = Color.fromRGBO(255, 50, 30, eyeAlpha));
    }
  }

  void _drawSoldierName(Canvas canvas, Size sz) {
    final alpha = ((_totalTime - 4.8) / 0.3).clamp(0.0, 1.0) * ((5.5 - _totalTime) / 0.4).clamp(0.0, 1.0);

    final tp = TextPainter(
      text: TextSpan(
        text: _soldierName.toUpperCase(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
          color: _soldierColor.withValues(alpha: alpha),
          shadows: [Shadow(color: _soldierColor.withValues(alpha: alpha * 0.5), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sz.width / 2 - tp.width / 2, sz.height * 0.6));

    final stp = TextPainter(
      text: TextSpan(
        text: 'HAS JOINED YOUR SHADOW ARMY',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 3,
          color: Color.fromRGBO(255, 255, 255, alpha * 0.4),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stp.paint(canvas, Offset(sz.width / 2 - stp.width / 2, sz.height * 0.6 + 28));
  }
}

class _AriseParticle {
  double x, y, vx, vy, targetX, targetY, size, phase;
  Color color;
  _AriseParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.targetX,
    required this.targetY,
    required this.size,
    required this.color,
  }) : phase = Random().nextDouble() * 3.14 * 2;
}
