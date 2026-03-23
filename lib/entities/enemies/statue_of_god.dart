import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/config.dart';
import '../player.dart';

class StatueOfGod extends PositionComponent with CollisionCallbacks {
  final Player player;
  int hp;
  final int maxHp;
  double _facingAngle = 0;
  bool _isDead = false;
  double _deathTimer = 0;
  double _hitFlash = 0;
  double _time = 0;

  int _phase = 1;

  double _fistCooldown = 2.0;
  double _fistWindup = 0;
  bool _fistSlamming = false;
  double _fistFlash = 0;
  double _fistTargetX = 0, _fistTargetY = 0;

  double _laserCooldown = 3.0;
  double _laserTimer = 0;
  bool _isLasering = false;
  double _laserAngle = 0;
  double _laserSweepDir = 1;

  void Function(StatueOfGod boss)? onDeath;
  void Function(double x, double y, double radius)? onSlam;
  void Function(double x, double y, double angle, double width, double length)? onLaser;

  StatueOfGod({required this.player, Vector2? spawnPos})
      : hp = Config.bossStatueHpTotal,
        maxHp = Config.bossStatueHpTotal,
        super(
          position: spawnPos ?? Vector2.zero(),
          size: Vector2.all(Config.bossStatueSize * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: Config.bossStatueSize * 0.7,
      anchor: Anchor.center,
      position: Vector2(Config.bossStatueSize, Config.bossStatueSize),
    )..collisionType = CollisionType.passive);
  }

  bool get isDead => _isDead;
  int get phase => _phase;
  double get healthFraction => (hp / maxHp).clamp(0.0, 1.0);

  void takeDamage(int damage) {
    if (_isDead) return;
    hp -= damage;
    _hitFlash = 0.15;
    // TODO(mastersam07): Play SFX — boss hit (massive stone impact)

    if (hp <= Config.bossStatueHpPhase1 && _phase == 1) {
      _phase = 2;
      _laserCooldown = 1.5;
      // TODO(mastersam07): Play SFX — phase transition (dramatic rumble, power surge)
    }

    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      _deathTimer = 0;
      onDeath?.call(this);
      // TODO(mastersam07): Play SFX — boss death (crumbling, explosion, dramatic)
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_isDead) {
      _deathTimer += dt;
      if (_deathTimer > 2.0) removeFromParent();
      return;
    }

    if (_hitFlash > 0) _hitFlash -= dt;

    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    _facingAngle = atan2(dy, dx);

    position.x += sin(_time * 0.3) * 20 * dt;
    position.y = position.y.clamp(Config.roomHeight * 0.15, Config.roomHeight * 0.35);

    _updateFistSlam(dt);
    if (_phase >= 2) _updateLaser(dt);
  }

  void _updateFistSlam(double dt) {
    if (_fistWindup > 0) {
      _fistWindup -= dt;
      if (_fistWindup <= 0) {
        _fistSlamming = true;
        _fistFlash = 0.35;
        _fistCooldown = _phase >= 2 ? Config.bossStatueFistCooldown * 0.7 : Config.bossStatueFistCooldown;
        onSlam?.call(_fistTargetX, _fistTargetY, Config.bossStatueFistRadius);
        // TODO(mastersam07): Play SFX — fist slam (enormous boom, screen shake)
      }
      return;
    }

    if (_fistSlamming) {
      _fistFlash -= dt;
      if (_fistFlash <= 0) _fistSlamming = false;
      return;
    }

    _fistCooldown -= dt;
    if (_fistCooldown <= 0 && !_isLasering) {
      _fistWindup = 0.8;
      _fistTargetX = player.position.x;
      _fistTargetY = player.position.y;
    }
  }

  void _updateLaser(double dt) {
    if (_isLasering) {
      _laserTimer -= dt;
      _laserAngle += _laserSweepDir * 0.8 * dt;
      onLaser?.call(position.x, position.y, _laserAngle, Config.bossStatueLaserWidth, 500);

      if (_laserTimer <= 0) {
        _isLasering = false;
        _laserCooldown = Config.bossStatueLaserCooldown;
      }
      return;
    }

    _laserCooldown -= dt;
    if (_laserCooldown <= 0 && _fistWindup <= 0 && !_fistSlamming) {
      _isLasering = true;
      _laserTimer = Config.bossStatueLaserDuration;
      _laserAngle = _facingAngle;
      _laserSweepDir = Random().nextBool() ? 1 : -1;
      // TODO(mastersam07): Play SFX — laser charge + fire (building energy, beam)
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AttackHitbox && !other.hasHit(hashCode)) {
      other.markHit(hashCode);
      takeDamage(other.damage);
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final s = Config.bossStatueSize;

    if (_isDead) {
      _drawDeathSequence(canvas, cx, cy, s);
      return;
    }

    final pulseS = 1.0 + 0.03 * sin(_time * 2);
    canvas.drawCircle(
        Offset(cx, cy),
        s * 1.8 * pulseS,
        Paint()
          ..color = Color.fromRGBO(255, 30, 30, _phase >= 2 ? 0.12 : 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 16), width: s * 2.5, height: s * 0.8),
        Paint()..color = const Color(0x50000000));

    if (_hitFlash > 0) {
      canvas.drawCircle(
          Offset(cx, cy),
          s * 1.5,
          Paint()
            ..color = const Color(0x40FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    if (_fistWindup > 0) {
      final progress = 1.0 - (_fistWindup / 0.8);
      final tx = _fistTargetX - position.x + cx;
      final ty = _fistTargetY - position.y + cy;
      canvas.drawCircle(
          Offset(tx, ty),
          Config.bossStatueFistRadius * progress,
          Paint()
            ..color = Color.fromRGBO(255, 50, 30, 0.2 * progress)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(
          Offset(tx, ty),
          Config.bossStatueFistRadius * progress,
          Paint()
            ..color = Color.fromRGBO(255, 80, 50, 0.4 * progress)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    if (_fistSlamming) {
      final tx = _fistTargetX - position.x + cx;
      final ty = _fistTargetY - position.y + cy;
      canvas.drawCircle(
          Offset(tx, ty),
          Config.bossStatueFistRadius * (1 + _fistFlash),
          Paint()
            ..color = Color.fromRGBO(255, 100, 50, _fistFlash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }

    canvas.save();
    canvas.translate(cx, cy);

    final bodyPath = Path()
      ..moveTo(0, -s * 0.8)
      ..lineTo(-s * 0.7, -s * 0.2)
      ..lineTo(-s * 0.9, s * 0.6)
      ..lineTo(s * 0.9, s * 0.6)
      ..lineTo(s * 0.7, -s * 0.2)
      ..close();
    canvas.drawPath(
        bodyPath,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, -s), Offset(0, s * 0.6), [const Color(0xFF4A4A5A), const Color(0xFF2A2A3A)], [0.0, 1.0]));
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = const Color(0x30FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -s * 0.6), width: s * 0.8, height: s * 0.7), const Radius.circular(4)),
        Paint()..color = const Color(0xFF3A3A4A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -s * 0.6), width: s * 0.8, height: s * 0.7), const Radius.circular(4)),
        Paint()
          ..color = const Color(0x20FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    final eyeGlow = _phase >= 2 ? 0.8 : 0.4;
    final eyeColor = _isLasering ? const Color(0xFFFF0000) : Color.fromRGBO(255, 60, 30, eyeGlow);
    canvas.drawCircle(
        Offset(0, -s * 0.6),
        10,
        Paint()
          ..color = eyeColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(0, -s * 0.6), 5, Paint()..color = eyeColor);
    canvas.drawCircle(Offset(0, -s * 0.6), 2.5, Paint()..color = Colors.white.withValues(alpha: 0.6));

    if (_isLasering) {
      final laserRot = _laserAngle - _facingAngle;
      canvas.save();
      canvas.rotate(laserRot);
      canvas.drawRect(
          Rect.fromLTWH(0, -Config.bossStatueLaserWidth / 2, 500, Config.bossStatueLaserWidth),
          Paint()
            ..color = const Color(0x40FF0000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawRect(Rect.fromLTWH(0, -Config.bossStatueLaserWidth / 4, 500, Config.bossStatueLaserWidth / 2),
          Paint()..color = const Color(0xCCFF3030));
      canvas.drawRect(Rect.fromLTWH(0, -2, 500, 4), Paint()..color = const Color(0xFFFFAAAA));
      canvas.restore();
    }

    canvas.restore();

    _drawBossHealthBar(canvas, cx, s);
  }

  void _drawBossHealthBar(Canvas canvas, double cx, double s) {
    final barW = s * 3;
    final barX = cx - barW / 2;
    final barY = 4.0;
    final frac = healthFraction;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
        Paint()..color = const Color(0x40FFFFFF));

    final barColor = frac > 0.5 ? Config.healthColor : const Color(0xFFFF6600);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * frac, 6), const Radius.circular(3)),
        Paint()..color = barColor);

    final phaseMark = barX + barW * (Config.bossStatueHpPhase1 / maxHp);
    canvas.drawLine(
        Offset(phaseMark, barY),
        Offset(phaseMark, barY + 6),
        Paint()
          ..color = const Color(0x80FFFFFF)
          ..strokeWidth = 1);

    final tp = TextPainter(
        text: TextSpan(
            text: 'STATUE OF GOD',
            style: TextStyle(fontSize: 8, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.5))),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, barY + 8));
  }

  void _drawDeathSequence(Canvas canvas, double cx, double cy, double s) {
    final alpha = (1 - _deathTimer / 2.0).clamp(0.0, 1.0);
    final shake = sin(_deathTimer * 30) * 3 * alpha;

    final rng = Random(hashCode);
    final pieces = 12 + (_deathTimer * 10).floor();
    for (int i = 0; i < pieces; i++) {
      final ox = (rng.nextDouble() - 0.5) * s * 2 * (1 + _deathTimer);
      final oy = (rng.nextDouble() - 0.5) * s * 2 * (1 + _deathTimer) + _deathTimer * 30;
      final ps = 4 + rng.nextDouble() * 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + ox + shake, cy + oy), width: ps, height: ps), const Radius.circular(2)),
        Paint()..color = const Color(0xFF3A3A4A).withValues(alpha: alpha * 0.6),
      );
    }

    if (_deathTimer < 0.5) {
      canvas.drawCircle(
          Offset(cx, cy),
          s * 2 * (1 - _deathTimer * 2),
          Paint()
            ..color = Color.fromRGBO(255, 200, 100, (0.5 - _deathTimer).clamp(0.0, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    }
  }
}
