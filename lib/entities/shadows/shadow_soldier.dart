import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../game/config.dart';
import '../player.dart';

/// Base class for shadow soldiers extracted via ARISE
abstract class ShadowSoldier extends PositionComponent {
  final Player player;
  final String name;
  final Color accentColor;
  final double speed;
  final double attackRange;
  final double attackCooldown;
  final int attackDamage;
  final double soldierSize;

  double _attackTimer = 0;
  double _facingAngle = 0;
  bool _isAttacking = false;
  double _attackFlash = 0;
  double _time = 0;
  PositionComponent? _target;

  void Function(PositionComponent enemy, int damage)? onAttackEnemy;

  ShadowSoldier({
    required this.player,
    required this.name,
    required this.accentColor,
    this.speed = 120.0,
    this.attackRange = 35.0,
    this.attackCooldown = 1.0,
    this.attackDamage = 1,
    this.soldierSize = 14.0,
  }) : super(
          size: Vector2.all(soldierSize * 2),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _attackTimer -= dt;
    if (_attackFlash > 0) _attackFlash -= dt;

    _findTarget();
    _updateBehavior(dt);
  }

  void _findTarget() {
    final parentComp = parent;
    if (parentComp == null) return;

    double bestDist = double.infinity;
    _target = null;

    for (final child in parentComp.children) {
      if (child == this || child == player) continue;
      if (child is! PositionComponent) continue;
      final typeName = child.runtimeType.toString();
      if (!typeName.contains('Wolf') &&
          !typeName.contains('Golem') &&
          !typeName.contains('Knight') &&
          !typeName.contains('Statue')) {
        continue;
      }

      final dx = child.position.x - position.x;
      final dy = child.position.y - position.y;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        _target = child;
      }
    }
  }

  void _updateBehavior(double dt) {
    if (_isAttacking) {
      _isAttacking = false;
      return;
    }

    if (_target != null) {
      final dx = _target!.position.x - position.x;
      final dy = _target!.position.y - position.y;
      final dist = sqrt(dx * dx + dy * dy);
      _facingAngle = atan2(dy, dx);

      if (dist < attackRange && _attackTimer <= 0) {
        // Attack!
        _isAttacking = true;
        _attackTimer = attackCooldown;
        _attackFlash = 0.15;
        onAttackEnemy?.call(_target!, attackDamage);
        // TODO(mastersam07): Play SFX — shadow soldier attack (varies by type)
      } else if (dist > attackRange * 0.8) {
        position.x += (dx / dist) * speed * dt;
        position.y += (dy / dist) * speed * dt;
      }
    } else {
      final dx = player.position.x - position.x;
      final dy = player.position.y - position.y;
      final dist = sqrt(dx * dx + dy * dy);
      _facingAngle = atan2(dy, dx);

      final followDist = 50.0; // stay this far behind player
      if (dist > followDist) {
        final moveSpeed = dist > 150 ? speed * 1.5 : speed * 0.8;
        position.x += (dx / dist) * moveSpeed * dt;
        position.y += (dy / dist) * moveSpeed * dt;
      }
    }

    position.x =
        position.x.clamp(Config.wallThickness + soldierSize, Config.roomWidth - Config.wallThickness - soldierSize);
    position.y =
        position.y.clamp(Config.wallThickness + soldierSize, Config.roomHeight - Config.wallThickness - soldierSize);
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 6), width: soldierSize * 1.5, height: soldierSize * 0.5),
        Paint()..color = const Color(0x40000000));

    for (int i = 0; i < 3; i++) {
      final angle = _time * 1.5 + i * 2.1;
      final ox = sin(angle) * soldierSize * 0.8;
      final oy = cos(angle * 0.7) * soldierSize * 0.5;
      canvas.drawCircle(
          Offset(cx + ox, cy + oy),
          2,
          Paint()
            ..color = Config.shadowColor.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    canvas.drawCircle(
        Offset(cx, cy),
        soldierSize * 1.3,
        Paint()
          ..color = accentColor.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    if (_attackFlash > 0) {
      canvas.drawCircle(
          Offset(cx, cy),
          soldierSize * 2,
          Paint()
            ..color = accentColor.withValues(alpha: _attackFlash * 2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_facingAngle + pi / 2);
    renderSoldier(canvas, soldierSize);
    canvas.restore();

    final tp = TextPainter(
        text: TextSpan(
            text: name, style: TextStyle(fontSize: 7, color: accentColor.withValues(alpha: 0.5), letterSpacing: 1)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + soldierSize + 4));
  }

  /// Override in subclasses to draw the specific soldier shape
  void renderSoldier(Canvas canvas, double s);
}
