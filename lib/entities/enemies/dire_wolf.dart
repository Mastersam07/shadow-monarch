import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../game/config.dart';
import '../player.dart';

class DireWolf extends PositionComponent with CollisionCallbacks {
  final Player player;
  int hp;
  final int maxHp;
  double _lungeTimer = 0;
  double _stunTimer = 0;
  double _facingAngle = 0;
  bool _isLunging = false;
  double _lungeVx = 0, _lungeVy = 0;
  bool _isDead = false;
  double _deathTimer = 0;
  double _hitFlash = 0;

  void Function(DireWolf wolf)? onDeath;

  DireWolf({required this.player, Vector2? spawnPos})
      : hp = Config.wolfHp,
        maxHp = Config.wolfHp,
        super(
          position: spawnPos ?? Vector2.zero(),
          size: Vector2.all(Config.wolfSize * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: Config.wolfSize * 0.8,
      anchor: Anchor.center,
      position: Vector2(Config.wolfSize, Config.wolfSize),
    )..collisionType = CollisionType.passive);
  }

  bool get isDead => _isDead;

  void takeDamage(int damage) {
    if (_isDead) return;
    hp -= damage;
    _hitFlash = 0.12;
    _stunTimer = 0.15;
    // TODO(mastersam07): Play SFX — enemy hit (meaty thud, crunch)
    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      _deathTimer = 0;
      onDeath?.call(this);
      // TODO(mastersam07): Play SFX — enemy death (dissolving growl, shatter)
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) {
      _deathTimer += dt;
      if (_deathTimer > 0.5) removeFromParent();
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

    _facingAngle = atan2(dy, dx);

    if (_isLunging) {
      position.x += _lungeVx * dt;
      position.y += _lungeVy * dt;
      _lungeTimer -= dt;
      if (_lungeTimer <= 0) {
        _isLunging = false;
        _lungeTimer = Config.wolfLungeCooldown;
      }
      _clampToRoom();
      return;
    }

    _lungeTimer -= dt;

    if (dist < Config.wolfAggroRange) {
      if (dist < Config.wolfLungeRange && _lungeTimer <= 0) {
        _isLunging = true;
        _lungeTimer = 0.2; // lunge duration
        final a = atan2(dy, dx);
        _lungeVx = cos(a) * Config.wolfLungeSpeed;
        _lungeVy = sin(a) * Config.wolfLungeSpeed;
        // TODO(mastersam07): Play SFX — wolf lunge (snarl, quick rush)
        return;
      }

      if (dist > 30) {
        position.x += (dx / dist) * Config.wolfSpeed * dt;
        position.y += (dy / dist) * Config.wolfSpeed * dt;
      }
    }

    _clampToRoom();
  }

  void _clampToRoom() {
    position.x = position.x.clamp(
      Config.wallThickness + Config.wolfSize,
      Config.roomWidth - Config.wallThickness - Config.wolfSize,
    );
    position.y = position.y.clamp(
      Config.wallThickness + Config.wolfSize,
      Config.roomHeight - Config.wallThickness - Config.wolfSize,
    );
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
      final alpha = (1 - _deathTimer / 0.5).clamp(0.0, 1.0);
      final cx = size.x / 2, cy = size.y / 2;
      canvas.drawCircle(
        Offset(cx, cy),
        Config.wolfSize * (1 + _deathTimer),
        Paint()
          ..color = Config.enemyColor.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      return;
    }

    final cx = size.x / 2, cy = size.y / 2;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: 20, height: 8),
      Paint()..color = const Color(0x40000000),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_facingAngle);

    if (_hitFlash > 0) {
      canvas.drawCircle(
          Offset.zero,
          Config.wolfSize * 1.5,
          Paint()
            ..color = const Color(0x40FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    final bodyPath = Path()
      ..moveTo(Config.wolfSize, 0) // nose
      ..quadraticBezierTo(
          Config.wolfSize * 0.3, -Config.wolfSize * 0.7, -Config.wolfSize * 0.8, -Config.wolfSize * 0.3) // top curve
      ..lineTo(-Config.wolfSize, 0)
      ..lineTo(-Config.wolfSize * 0.8, Config.wolfSize * 0.3) // bottom
      ..quadraticBezierTo(Config.wolfSize * 0.3, Config.wolfSize * 0.7, Config.wolfSize, 0)
      ..close();

    final healthFrac = hp / maxHp;
    final bodyColor =
        healthFrac > 0.5 ? Config.enemyColor : Color.lerp(Config.healthColor, Config.enemyColor, healthFrac * 2)!;

    canvas.drawPath(bodyPath, Paint()..color = bodyColor);
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = const Color(0xFFFF9E40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    canvas.drawCircle(
      Offset(Config.wolfSize * 0.4, -Config.wolfSize * 0.2),
      2.5,
      Paint()..color = const Color(0xFFFF0000),
    );
    canvas.drawCircle(
      Offset(Config.wolfSize * 0.4, Config.wolfSize * 0.2),
      2.5,
      Paint()..color = const Color(0xFFFF0000),
    );

    canvas.restore();

    if (hp < maxHp) {
      final barW = 28.0;
      final barH = 3.0;
      final barX = cx - barW / 2;
      final barY = cy - Config.wolfSize - 8;
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW, barH), Paint()..color = const Color(0x40FFFFFF));
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW * healthFrac, barH), Paint()..color = Config.healthColor);
    }

    if (_isLunging) {
      canvas.drawCircle(
        Offset(cx, cy),
        Config.wolfSize + 4,
        Paint()
          ..color = Config.enemyColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }
}
