import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../game/config.dart';
import '../player.dart';

class ArmoredKnight extends PositionComponent with CollisionCallbacks {
  final Player player;
  int hp;
  final int maxHp;
  double _facingAngle = 0;
  double _slashCooldown = 1.0;
  double _slashTimer = 0;
  bool _isSlashing = false;
  bool _isDead = false;
  double _deathTimer = 0;
  double _hitFlash = 0;
  double _stunTimer = 0;

  void Function(ArmoredKnight knight)? onDeath;

  ArmoredKnight({required this.player, Vector2? spawnPos})
      : hp = Config.knightHp,
        maxHp = Config.knightHp,
        super(
          position: spawnPos ?? Vector2.zero(),
          size: Vector2.all(Config.knightSize * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: Config.knightSize * 0.75,
      anchor: Anchor.center,
      position: Vector2(Config.knightSize, Config.knightSize),
    )..collisionType = CollisionType.passive);
  }

  bool get isDead => _isDead;

  void takeDamage(int damage, {double? fromAngle}) {
    if (_isDead) return;

    if (fromAngle != null) {
      var angleDiff = (fromAngle - _facingAngle + pi) % (2 * pi) - pi;
      if (angleDiff.abs() < Config.knightBlockArc / 2) {
        damage = (damage * 0.3).ceil();
        _stunTimer = 0.05;
        // TODO(mastersam07): Play SFX — shield block (metallic clang)
        _hitFlash = 0.08;
        return;
      }
    }

    hp -= damage;
    _hitFlash = 0.12;
    _stunTimer = 0.12;
    // TODO(mastersam07): Play SFX — knight hit (armor impact, metal scrape)
    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      _deathTimer = 0;
      onDeath?.call(this);
      // TODO(mastersam07): Play SFX — knight death (armor collapse, clatter)
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

    if (_isSlashing) {
      _slashTimer -= dt;
      if (_slashTimer <= 0) _isSlashing = false;
      return;
    }

    _slashCooldown -= dt;

    if (dist < Config.knightAggroRange) {
      if (dist < Config.knightSlashRange && _slashCooldown <= 0) {
        _isSlashing = true;
        _slashTimer = 0.25;
        _slashCooldown = Config.knightSlashCooldown;
        // TODO(mastersam07): Play SFX — sword slash (whoosh, blade)
        return;
      }

      if (dist > 30) {
        position.x += (dx / dist) * Config.knightSpeed * dt;
        position.y += (dy / dist) * Config.knightSpeed * dt;
      }
    }

    _clampToRoom();
  }

  void _clampToRoom() {
    position.x = position.x
        .clamp(Config.wallThickness + Config.knightSize, Config.roomWidth - Config.wallThickness - Config.knightSize);
    position.y = position.y
        .clamp(Config.wallThickness + Config.knightSize, Config.roomHeight - Config.wallThickness - Config.knightSize);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AttackHitbox && !other.hasHit(hashCode)) {
      other.markHit(hashCode);
      final p = parent;
      double? attackAngle;
      if (p is PositionComponent) {
        attackAngle = atan2(
          position.y - player.position.y,
          position.x - player.position.x,
        );
      }
      takeDamage(other.damage, fromAngle: attackAngle);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isDead) {
      final alpha = (1 - _deathTimer / 0.5).clamp(0.0, 1.0);
      final cx = size.x / 2, cy = size.y / 2;
      canvas.drawCircle(
          Offset(cx, cy),
          Config.knightSize * (1 + _deathTimer),
          Paint()
            ..color = Config.knightColor.withValues(alpha: alpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      return;
    }

    final cx = size.x / 2, cy = size.y / 2;
    final s = Config.knightSize;

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 6), width: 22, height: 9), Paint()..color = const Color(0x40000000));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_facingAngle + pi / 2);

    if (_hitFlash > 0) {
      canvas.drawCircle(
          Offset.zero,
          s * 1.5,
          Paint()
            ..color = const Color(0x30FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    final shieldPath = Path()
      ..moveTo(-s * 0.6, -s * 0.2)
      ..quadraticBezierTo(-s * 0.8, -s * 0.8, 0, -s * 1.1)
      ..quadraticBezierTo(s * 0.8, -s * 0.8, s * 0.6, -s * 0.2)
      ..close();
    canvas.drawPath(shieldPath, Paint()..color = Config.knightShieldColor);
    canvas.drawPath(
        shieldPath,
        Paint()
          ..color = const Color(0x40FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    final bodyPath = Path()
      ..moveTo(0, -s * 0.7)
      ..lineTo(-s * 0.5, s * 0.4)
      ..lineTo(s * 0.5, s * 0.4)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = Config.knightColor);
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = const Color(0xFFB0BEC5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    canvas.drawLine(
        Offset(-4, -s * 0.3),
        Offset(4, -s * 0.3),
        Paint()
          ..color = const Color(0xFFFF3030)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);

    if (_isSlashing) {
      final arcAlpha = (_slashTimer / 0.25).clamp(0.0, 1.0);
      final arcPath = Path()
        ..moveTo(0, 0)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: Config.knightSlashRange), -pi / 2 - 0.5, 1.0, false)
        ..close();
      canvas.drawPath(arcPath, Paint()..color = Color.fromRGBO(200, 200, 220, arcAlpha * 0.3));
    }

    canvas.restore();

    if (hp < maxHp) {
      final barW = 28.0, barH = 3.0;
      final barX = cx - barW / 2, barY = cy - s - 8;
      final frac = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW, barH), Paint()..color = const Color(0x40FFFFFF));
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW * frac, barH), Paint()..color = Config.healthColor);
    }
  }
}
