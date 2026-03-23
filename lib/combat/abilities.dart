import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Ruler's Hand — telekinesis pull. Pulls nearest enemy toward player.
class RulersHand extends Component {
  double _cooldown = 0;
  double _activeTimer = 0;
  bool _isActive = false;
  double _targetX = 0, _targetY = 0;
  double _originX = 0, _originY = 0;

  static const double cooldownTime = 3.0;
  static const double duration = 0.4;
  static const double range = 200.0;
  static const double pullSpeed = 400.0;
  static const double mpCost = 20.0;

  bool get isActive => _isActive;
  bool get isReady => _cooldown <= 0;
  double get cooldownFraction => (_cooldown / cooldownTime).clamp(0.0, 1.0);

  /// Activate — returns target position if enemy found, null otherwise
  (double, double)? activate(
      double playerX, double playerY, double aimAngle, List<(double x, double y, PositionComponent enemy)> enemies) {
    if (_cooldown > 0) return null;

    double bestDist = double.infinity;
    (double, double, PositionComponent)? bestTarget;

    for (final (ex, ey, enemy) in enemies) {
      final dx = ex - playerX, dy = ey - playerY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > range) continue;

      final enemyAngle = atan2(dy, dx);
      var angleDiff = (enemyAngle - aimAngle + pi) % (2 * pi) - pi;
      if (angleDiff.abs() > 0.52) continue; // ~30° half-cone

      if (dist < bestDist) {
        bestDist = dist;
        bestTarget = (ex, ey, enemy);
      }
    }

    if (bestTarget == null) return null;

    _isActive = true;
    _activeTimer = duration;
    _cooldown = cooldownTime;
    _targetX = bestTarget.$1;
    _targetY = bestTarget.$2;
    _originX = playerX;
    _originY = playerY;

    // TODO(mastersam07): Play SFX — Ruler's Hand (telekinetic whoosh, pull)
    return (bestTarget.$1, bestTarget.$2);
  }

  @override
  void update(double dt) {
    if (_cooldown > 0) _cooldown -= dt;
    if (_isActive) {
      _activeTimer -= dt;
      if (_activeTimer <= 0) _isActive = false;
    }
  }

  void renderEffect(Canvas canvas) {
    if (!_isActive) return;

    final progress = (1 - _activeTimer / duration).clamp(0.0, 1.0);
    final alpha = (1 - progress) * 0.4;

    canvas.drawLine(
        Offset(_originX, _originY),
        Offset(_targetX, _targetY),
        Paint()
          ..color = Color.fromRGBO(155, 109, 215, alpha)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    final ringR = 20.0 * (1 - progress);
    canvas.drawCircle(
        Offset(_targetX, _targetY),
        ringR,
        Paint()
          ..color = Color.fromRGBO(155, 109, 215, alpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }
}
