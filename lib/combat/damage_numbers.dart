import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class DamageNumber extends PositionComponent {
  final int amount;
  final Color color;
  double _life = 0;
  static const _duration = 0.8;

  DamageNumber(double x, double y, this.amount, {this.color = const Color(0xFFFFFFFF)})
      : super(position: Vector2(x, y));

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 40 * dt; // float upward
    if (_life >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / _duration).clamp(0.0, 1.0);
    final alpha = (1 - t).clamp(0.0, 1.0);
    final scale = 1.0 + t * 0.3;

    final tp = TextPainter(
      text: TextSpan(
        text: '$amount',
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: alpha),
          shadows: [
            Shadow(color: Color.fromRGBO(0, 0, 0, alpha * 0.8), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
