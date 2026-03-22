import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class Particle {
  double x, y, vx, vy;
  double life, maxLife, size;
  Color color;
  Particle(this.x, this.y, this.vx, this.vy, this.maxLife, this.size, this.color) : life = 0;
}

class ParticleSystem extends Component {
  final _particles = <Particle>[];
  final _rng = Random();

  void spawn(double x, double y, int count, Color color,
      {double speed = 100, double maxLife = 0.5, double minSize = 1, double maxSize = 3}) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final s = speed * (0.3 + _rng.nextDouble() * 0.7);
      _particles.add(Particle(
        x,
        y,
        cos(a) * s,
        sin(a) * s,
        maxLife * (0.5 + _rng.nextDouble() * 0.5),
        minSize + _rng.nextDouble() * (maxSize - minSize),
        color,
      ));
    }
  }

  void spawnDirectional(double x, double y, double angle, int count, Color color,
      {double spread = 0.5, double speed = 150, double maxLife = 0.3}) {
    for (int i = 0; i < count; i++) {
      final a = angle + ((_rng.nextDouble() - 0.5) * spread);
      final s = speed * (0.5 + _rng.nextDouble() * 0.5);
      _particles.add(Particle(
        x,
        y,
        cos(a) * s,
        sin(a) * s,
        maxLife * (0.6 + _rng.nextDouble() * 0.4),
        1 + _rng.nextDouble() * 2,
        color,
      ));
    }
  }

  void spawnTrail(double x, double y, Color color, {double size = 3}) {
    _particles.add(Particle(
      x + (_rng.nextDouble() - 0.5) * 4,
      y + (_rng.nextDouble() - 0.5) * 4,
      (_rng.nextDouble() - 0.5) * 20,
      (_rng.nextDouble() - 0.5) * 20,
      0.3 + _rng.nextDouble() * 0.2,
      size,
      color,
    ));
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.96;
      p.vy *= 0.96;
      p.life += dt;
    }
    _particles.removeWhere((p) => p.life >= p.maxLife);
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final s = p.size * (1 - t * 0.5);

      canvas.drawCircle(
        Offset(p.x, p.y),
        s * 2,
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(p.x, p.y),
        s,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }
}
