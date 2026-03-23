import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../game/config.dart';
import '../player.dart';

class StoneGolem extends PositionComponent with CollisionCallbacks {
  final Player player;
  int hp;
  final int maxHp;
  double _slamCooldown = 2.0;
  double _slamWindup = 0; // >0 means winding up
  bool _isSlamming = false;
  double _slamFlash = 0;
  bool _isDead = false;
  double _deathTimer = 0;
  double _hitFlash = 0;
  double _stunTimer = 0;

  void Function(StoneGolem golem)? onDeath;
  void Function(double x, double y, double radius)? onSlam;

  StoneGolem({required this.player, Vector2? spawnPos})
      : hp = Config.golemHp,
        maxHp = Config.golemHp,
        super(
          position: spawnPos ?? Vector2.zero(),
          size: Vector2.all(Config.golemSize * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: Config.golemSize * 0.8,
      anchor: Anchor.center,
      position: Vector2(Config.golemSize, Config.golemSize),
    )..collisionType = CollisionType.passive);
  }

  bool get isDead => _isDead;

  void takeDamage(int damage) {
    if (_isDead) return;
    hp -= damage;
    _hitFlash = 0.12;
    _stunTimer = 0.08; // barely stunned — golems are tough
    // TODO(mastersam07): Play SFX — golem hit (stone crack, heavy thud)
    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      _deathTimer = 0;
      onDeath?.call(this);
      // TODO(mastersam07): Play SFX — golem death (crumbling stone, collapse)
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) {
      _deathTimer += dt;
      if (_deathTimer > 0.6) removeFromParent();
      return;
    }

    if (_hitFlash > 0) _hitFlash -= dt;
    if (_stunTimer > 0) {
      _stunTimer -= dt;
      return;
    }

    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (_slamWindup > 0) {
      _slamWindup -= dt;
      if (_slamWindup <= 0) {
        _isSlamming = true;
        _slamFlash = 0.3;
        _slamCooldown = Config.golemSlamCooldown;
        onSlam?.call(position.x, position.y, Config.golemSlamRadius);
        // TODO(mastersam07): Play SFX — ground slam (deep boom, earth shake)
      }
      return; // Don't move during windup
    }

    if (_slamFlash > 0) {
      _slamFlash -= dt;
      if (_slamFlash <= 0) _isSlamming = false;
      return;
    }

    _slamCooldown -= dt;

    if (dist < Config.golemAggroRange) {
      if (dist < Config.golemSlamRange && _slamCooldown <= 0) {
        _slamWindup = Config.golemSlamWindup;
        return;
      }

      if (dist > 35) {
        position.x += (dx / dist) * Config.golemSpeed * dt;
        position.y += (dy / dist) * Config.golemSpeed * dt;
      }
    }

    _clampToRoom();
  }

  void _clampToRoom() {
    position.x = position.x
        .clamp(Config.wallThickness + Config.golemSize, Config.roomWidth - Config.wallThickness - Config.golemSize);
    position.y = position.y
        .clamp(Config.wallThickness + Config.golemSize, Config.roomHeight - Config.wallThickness - Config.golemSize);
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
    if (_isDead) {
      final alpha = (1 - _deathTimer / 0.6).clamp(0.0, 1.0);
      final cx = size.x / 2, cy = size.y / 2;
      final rng = Random(hashCode);
      for (int i = 0; i < 6; i++) {
        final ox = (rng.nextDouble() - 0.5) * Config.golemSize * 2 * _deathTimer;
        final oy = (rng.nextDouble() - 0.5) * Config.golemSize * 2 * _deathTimer;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + ox, cy + oy), width: 8, height: 8), const Radius.circular(2)),
          Paint()..color = Config.golemColor.withValues(alpha: alpha * 0.6),
        );
      }
      return;
    }

    final cx = size.x / 2, cy = size.y / 2;
    final s = Config.golemSize;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8), width: s * 2, height: s * 0.8),
        Paint()..color = const Color(0x40000000));

    if (_hitFlash > 0) {
      canvas.drawCircle(
          Offset(cx, cy),
          s * 1.5,
          Paint()
            ..color = const Color(0x30FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    if (_slamWindup > 0) {
      final progress = 1.0 - (_slamWindup / Config.golemSlamWindup);
      canvas.drawCircle(
          Offset(cx, cy),
          Config.golemSlamRadius * progress,
          Paint()
            ..color = Color.fromRGBO(255, 50, 50, 0.15 * progress)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(
          Offset(cx, cy),
          Config.golemSlamRadius * progress,
          Paint()
            ..color = Color.fromRGBO(255, 80, 50, 0.3 * progress)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    if (_isSlamming) {
      canvas.drawCircle(
          Offset(cx, cy),
          Config.golemSlamRadius,
          Paint()
            ..color = Color.fromRGBO(255, 100, 50, _slamFlash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    canvas.save();
    canvas.translate(cx, cy);

    final bodyRect = Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s * 1.8);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(6)), Paint()..color = Config.golemColor);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFF607D8B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    canvas.drawCircle(
        Offset(0, -2),
        6,
        Paint()
          ..color = Config.golemCoreColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(0, -2), 3, Paint()..color = Config.golemCoreColor);

    canvas.drawLine(
        Offset(-s * 0.5, -s * 0.3),
        Offset(s * 0.3, -s * 0.6),
        Paint()
          ..color = const Color(0x20000000)
          ..strokeWidth = 1);
    canvas.drawLine(
        Offset(-s * 0.3, s * 0.2),
        Offset(s * 0.5, s * 0.4),
        Paint()
          ..color = const Color(0x20000000)
          ..strokeWidth = 1);

    canvas.restore();

    if (hp < maxHp) {
      final barW = 32.0, barH = 3.0;
      final barX = cx - barW / 2, barY = cy - s - 10;
      final frac = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW, barH), Paint()..color = const Color(0x40FFFFFF));
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW * frac, barH), Paint()..color = Config.healthColor);
    }
  }
}
