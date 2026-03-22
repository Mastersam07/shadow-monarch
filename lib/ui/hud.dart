import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../game/config.dart';
import '../entities/player.dart';

class Hud extends PositionComponent {
  final Player player;
  int wave;
  int score;
  int enemiesLeft;

  Hud({required this.player, this.wave = 0, this.score = 0, this.enemiesLeft = 0});

  @override
  void render(Canvas canvas) {
    _drawHealthBar(canvas);
    _drawMpBar(canvas);
    _drawShadowGauge(canvas);
    _drawComboIndicator(canvas);
    _drawWaveInfo(canvas);
    _drawDashCooldown(canvas);
  }

  void _drawHealthBar(Canvas canvas) {
    const x = 16.0, y = 16.0;
    for (int i = 0; i < Config.playerMaxHp; i++) {
      final filled = i < player.hp;
      final ox = x + i * 26;

      canvas.drawCircle(
          Offset(ox + 10, y + 10),
          10,
          Paint()
            ..color = filled ? Config.healthColor : const Color(0x30FFFFFF)
            ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1.5);

      if (filled) {
        canvas.drawCircle(
            Offset(ox + 10, y + 10),
            10,
            Paint()
              ..color = const Color(0x30FF6666)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(ox + 8, y + 7), 3, Paint()..color = const Color(0x40FFFFFF));
      }
    }
  }

  void _drawMpBar(Canvas canvas) {
    const x = 16.0, y = 42.0, w = 100.0, h = 6.0;
    final frac = (player.mp / Config.playerMaxMp).clamp(0.0, 1.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()..color = const Color(0x20FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * frac, h), const Radius.circular(3)),
      Paint()..color = Config.mpColor,
    );

    _drawLabel(canvas, 'MP', x, y + h + 2, 8);
  }

  void _drawShadowGauge(Canvas canvas) {
    const x = 16.0, y = 62.0, w = 100.0, h = 6.0;
    final frac = (player.shadowGauge / Config.shadowGaugeMax).clamp(0.0, 1.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()..color = const Color(0x20FFFFFF),
    );
    if (frac > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * frac, h), const Radius.circular(3)),
        Paint()..color = Config.shadowGaugeColor,
      );
      if (frac >= 1.0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y - 2, w + 4, h + 4), const Radius.circular(5)),
          Paint()
            ..color = Config.shadowGaugeColor.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    _drawLabel(canvas, 'SHADOW', x, y + h + 2, 8);
  }

  void _drawComboIndicator(Canvas canvas) {
    if (player.comboCount <= 0) return;

    final text = player.comboCount >= 2 ? 'FINISHER!' : 'COMBO x${player.comboCount + 1}';
    final color = player.comboCount >= 2 ? Config.goldColor : Config.playerColor;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: color,
          shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(Config.roomWidth / 2 - tp.width / 2, Config.roomHeight - 50));
  }

  void _drawWaveInfo(Canvas canvas) {
    final waveText = 'GATE 1 — ROOM $wave';
    _drawLabel(canvas, waveText, Config.roomWidth - 160, 16, 11, color: const Color(0x80FFFFFF));

    if (enemiesLeft > 0) {
      _drawLabel(canvas, 'Enemies: $enemiesLeft', Config.roomWidth - 160, 32, 10,
          color: Config.enemyColor.withValues(alpha: 0.6));
    }

    final stp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stp.paint(canvas, Offset(Config.roomWidth - stp.width - 16, 48));
  }

  void _drawDashCooldown(Canvas canvas) {
    const x = 16.0, y2 = -20.0; // relative to bottom
    final y = Config.roomHeight + y2;

    _drawLabel(canvas, '[SHIFT] Dash', x, y, 9, color: const Color(0x50FFFFFF));
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, double fontSize,
      {Color color = const Color(0x60FFFFFF)}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, letterSpacing: 1.5, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }
}
