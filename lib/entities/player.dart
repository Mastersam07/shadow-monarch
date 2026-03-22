import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/config.dart';
import '../input/input_manager.dart';

class Player extends PositionComponent with CollisionCallbacks {
  final InputState input;

  int hp;
  double mp;
  double shadowGauge = 0;
  int comboCount = 0;

  double _invTimer = 0;
  double _attackTimer = 0;
  double _attackCooldown = 0;
  double _comboTimer = 0;
  double _dashTimer = 0;
  double _dashCooldown = 0;

  bool _isAttacking = false;
  bool _isDashing = false;
  double _facingAngle = -pi / 2;
  bool _isDead = false;

  AttackHitbox? _attackHitbox;

  void Function(double x, double y, double angle, int damage)? onAttack;
  void Function()? onDeath;

  Player({required this.input})
      : hp = Config.playerMaxHp,
        mp = Config.playerMaxMp,
        super(
          size: Vector2.all(Config.playerSize * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
        radius: Config.playerSize * 0.7,
        anchor: Anchor.center,
        position: Vector2(Config.playerSize, Config.playerSize)));
  }

  bool get isInvincible => _invTimer > 0;
  bool get isDashing => _isDashing;
  bool get isDead => _isDead;
  double get facingAngle => _facingAngle;

  void takeDamage(int damage) {
    if (_invTimer > 0 || _isDashing || _isDead) return;
    hp -= damage;
    _invTimer = Config.invincibleDuration;
    // TODO(mastersam07): Play SFX — player hurt (sharp impact, grunt)
    if (hp <= 0) {
      hp = 0;
      _isDead = true;
      onDeath?.call();
      // TODO(mastersam07): Play SFX — player death (low rumble, dramatic)
    }
  }

  void addShadow(double amount) {
    shadowGauge = (shadowGauge + amount).clamp(0, Config.shadowGaugeMax);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) return;

    _updateTimers(dt);
    _updateMovement(dt);
    _updateCombat(dt);
    _updateMp(dt);
  }

  void _updateTimers(double dt) {
    if (_invTimer > 0) _invTimer -= dt;
    if (_attackCooldown > 0) _attackCooldown -= dt;
    if (_dashCooldown > 0) _dashCooldown -= dt;
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) comboCount = 0;
    }
    if (_isAttacking) {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        _isAttacking = false;
        _attackHitbox?.removeFromParent();
        _attackHitbox = null;
      }
    }
  }

  void _updateMovement(double dt) {
    if (_isAttacking) return;

    if (_isDashing) {
      _dashTimer -= dt;
      final dx = cos(_facingAngle) * Config.dashSpeed * dt;
      final dy = sin(_facingAngle) * Config.dashSpeed * dt;
      position.x += dx;
      position.y += dy;
      if (_dashTimer <= 0) _isDashing = false;
      return;
    }

    if (input.isMoving) {
      final dir = input.moveDir;
      position.x += dir.x * Config.playerSpeed * dt;
      position.y += dir.y * Config.playerSpeed * dt;
    }

    if (input.aimX.abs() > 0.1 || input.aimY.abs() > 0.1) {
      _facingAngle = atan2(input.aimY, input.aimX);
    } else if (input.isMoving) {
      _facingAngle = atan2(input.moveY, input.moveX);
    }

    position.x = position.x
        .clamp(Config.wallThickness + Config.playerSize, Config.roomWidth - Config.wallThickness - Config.playerSize);
    position.y = position.y
        .clamp(Config.wallThickness + Config.playerSize, Config.roomHeight - Config.wallThickness - Config.playerSize);

    if (input.dashJustPressed && _dashCooldown <= 0 && !_isDashing) {
      _isDashing = true;
      _dashTimer = Config.dashDuration;
      _dashCooldown = Config.dashCooldown;
      // TODO(mastersam07): Play SFX — dash (whoosh, short wind burst)
    }
  }

  void _updateCombat(double dt) {
    if (_isDashing) return;

    if (input.attackJustPressed && _attackCooldown <= 0 && !_isAttacking) {
      _isAttacking = true;
      _attackTimer = Config.attackDuration;
      _attackCooldown = Config.attackCooldown;

      if (_comboTimer > 0) {
        comboCount = (comboCount + 1).clamp(0, 2);
      } else {
        comboCount = 0;
      }
      _comboTimer = Config.comboWindow;

      final damage = comboCount >= 2 ? Config.comboFinisherDamage : Config.attackDamage;

      final hbX = cos(_facingAngle) * Config.attackRange;
      final hbY = sin(_facingAngle) * Config.attackRange;
      _attackHitbox = AttackHitbox(
        damage: damage,
        comboHit: comboCount,
      )
        ..position = Vector2(Config.playerSize + hbX, Config.playerSize + hbY)
        ..size = Vector2(Config.attackWidth, Config.attackWidth)
        ..anchor = Anchor.center;
      add(_attackHitbox!);

      onAttack?.call(
        position.x + hbX,
        position.y + hbY,
        _facingAngle,
        damage,
      );

      // TODO(mastersam07): Play SFX — dagger slash (sharp metallic swipe, varies by combo count)
    }
  }

  void _updateMp(double dt) {
    mp = (mp + Config.mpRegen * dt).clamp(0, Config.playerMaxMp);
  }

  @override
  void render(Canvas canvas) {
    if (_isDead) return;

    if (_invTimer > 0 && (_invTimer * 10).floor() % 2 == 0) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 24, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      Config.playerSize * 1.3,
      Paint()
        ..color = Config.playerGlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_facingAngle + pi / 2);

    final bodyPath = Path()
      ..moveTo(0, -Config.playerSize)
      ..lineTo(-Config.playerSize * 0.6, Config.playerSize * 0.5)
      ..lineTo(Config.playerSize * 0.6, Config.playerSize * 0.5)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -Config.playerSize),
          Offset(0, Config.playerSize * 0.5),
          [const Color(0xFFB088E0), Config.playerColor, Config.playerGlow],
          [0.0, 0.5, 1.0],
        ),
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFB088E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      const Offset(0, -6),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      const Offset(0, -6),
      1.5,
      Paint()..color = const Color(0xFFE0D0FF),
    );

    canvas.restore();

    if (_isAttacking) {
      final arcPath = Path();
      final arcR = Config.attackRange + 5;
      final startAngle = _facingAngle - 0.5;
      final sweepAngle = 1.0;

      canvas.save();
      canvas.translate(cx, cy);

      arcPath.moveTo(0, 0);
      arcPath.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: arcR),
        startAngle,
        sweepAngle,
        false,
      );
      arcPath.close();

      final flashAlpha = (_attackTimer / Config.attackDuration).clamp(0.0, 1.0);
      canvas.drawPath(
        arcPath,
        Paint()
          ..color =
              (comboCount >= 2 ? const Color(0xFFFFD700) : Config.playerColor).withValues(alpha: flashAlpha * 0.3),
      );
      canvas.restore();
    }

    if (_isDashing) {
      canvas.drawCircle(
        Offset(cx, cy),
        Config.playerSize * 0.8,
        Paint()
          ..color = Config.playerGlow.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }
}

class AttackHitbox extends PositionComponent with CollisionCallbacks {
  final int damage;
  final int comboHit;
  final _hitEntities = <int>{};

  AttackHitbox({required this.damage, required this.comboHit}) : super();

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  bool hasHit(int entityHash) => _hitEntities.contains(entityHash);
  void markHit(int entityHash) => _hitEntities.add(entityHash);
}
