import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/config.dart';
import 'gate.dart';
import 'room_generator.dart';

class Room extends PositionComponent {
  final RoomLayout layout;
  bool exitOpen;
  bool entryOpen;

  Room({required this.layout, this.exitOpen = false, this.entryOpen = true})
      : super(size: Vector2(Config.roomWidth, Config.roomHeight));

  @override
  void render(Canvas canvas) {
    _drawFloor(canvas);
    _drawPillars(canvas);
    _drawWalls(canvas);
    _drawDoors(canvas);
    _drawRoomTypeOverlay(canvas);
    _drawTorches(canvas);
  }

  void _drawFloor(Canvas canvas) {
    final w = Config.roomWidth, h = Config.roomHeight;
    final wt = Config.wallThickness, ts = Config.tileSize;

    for (double x = wt; x < w - wt; x += ts) {
      for (double y = wt; y < h - wt; y += ts) {
        final ix = (x / ts).floor(), iy = (y / ts).floor();
        final dark = (ix + iy) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, ts, ts),
          Paint()..color = dark ? Config.floorColor : const Color(0xFF111118),
        );
      }
    }
  }

  void _drawPillars(Canvas canvas) {
    for (final p in layout.pillars) {
      // Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(p.x + 2, p.y + 4), width: p.size * 1.2, height: p.size * 0.6),
        Paint()..color = const Color(0x40000000),
      );
      // Pillar body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(p.x, p.y), width: p.size, height: p.size),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF2A2A3E),
      );
      // Highlight
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(p.x, p.y), width: p.size, height: p.size),
          const Radius.circular(4),
        ),
        Paint()
          ..color = const Color(0x15FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawWalls(Canvas canvas) {
    final w = Config.roomWidth, h = Config.roomHeight, wt = Config.wallThickness;
    final wallPaint = Paint()..color = Config.wallColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, wt), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, h - wt, w, wt), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, wt, h), wallPaint);
    canvas.drawRect(Rect.fromLTWH(w - wt, 0, wt, h), wallPaint);

    // Wall edge highlights
    canvas.drawLine(
        Offset(wt, wt),
        Offset(w - wt, wt),
        Paint()
          ..color = const Color(0x15FFFFFF)
          ..strokeWidth = 1);
    canvas.drawLine(
        Offset(wt, wt),
        Offset(wt, h - wt),
        Paint()
          ..color = const Color(0x10FFFFFF)
          ..strokeWidth = 1);
  }

  void _drawDoors(Canvas canvas) {
    final w = Config.roomWidth, h = Config.roomHeight;
    final wt = Config.wallThickness, dw = Config.doorWidth;
    final dx = w / 2 - dw / 2;

    // Entry door (bottom)
    if (entryOpen) {
      canvas.drawRect(Rect.fromLTWH(dx, h - wt, dw, wt), Paint()..color = const Color(0xFF2A2A3E));
    }

    // Exit door (top)
    final exitColor = exitOpen ? Config.doorOpenColor : Config.doorLockedColor;
    canvas.drawRect(Rect.fromLTWH(dx, 0, dw, wt), Paint()..color = exitColor);

    if (exitOpen) {
      // Green glow
      canvas.drawRect(
        Rect.fromLTWH(dx - 3, 0, dw + 6, wt + 3),
        Paint()
          ..color = const Color(0x304CAF50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Arrow indicator
      final arrowPath = Path()
        ..moveTo(w / 2, wt + 8)
        ..lineTo(w / 2 - 8, wt + 18)
        ..lineTo(w / 2 + 8, wt + 18)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = Config.doorOpenColor.withValues(alpha: 0.6));
    } else {
      // Lock icon (red X)
      final lockCx = w / 2, lockCy = wt / 2;
      canvas.drawLine(
          Offset(lockCx - 4, lockCy - 4),
          Offset(lockCx + 4, lockCy + 4),
          Paint()
            ..color = const Color(0x80FF3030)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          Offset(lockCx + 4, lockCy - 4),
          Offset(lockCx - 4, lockCy + 4),
          Paint()
            ..color = const Color(0x80FF3030)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawRoomTypeOverlay(Canvas canvas) {
    final w = Config.roomWidth, h = Config.roomHeight;

    if (layout.type == RoomType.rest) {
      // Soft green tint
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Config.healColor.withValues(alpha: 0.04));
      // Heal circle in center
      final cx = w / 2, cy = h / 2;
      canvas.drawCircle(
          Offset(cx, cy),
          30,
          Paint()
            ..color = Config.healColor.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = Config.healColor.withValues(alpha: 0.4));
      // Cross
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 16), Paint()..color = Config.healColor);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 4), Paint()..color = Config.healColor);
    }

    if (layout.type == RoomType.treasure) {
      // Gold tint
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Config.goldColor.withValues(alpha: 0.03));
      // Treasure indicator
      final cx = w / 2, cy = h / 2;
      canvas.drawCircle(
          Offset(cx, cy),
          25,
          Paint()
            ..color = Config.goldColor.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawCircle(Offset(cx, cy), 10, Paint()..color = Config.goldColor.withValues(alpha: 0.5));
    }

    if (layout.type == RoomType.boss) {
      // Red tint
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Config.bossColor.withValues(alpha: 0.03));
    }
  }

  void _drawTorches(Canvas canvas) {
    final w = Config.roomWidth, h = Config.roomHeight, wt = Config.wallThickness;
    _drawTorch(canvas, wt + 8, wt + 8);
    _drawTorch(canvas, w - wt - 8, wt + 8);
    _drawTorch(canvas, wt + 8, h - wt - 8);
    _drawTorch(canvas, w - wt - 8, h - wt - 8);
  }

  void _drawTorch(Canvas canvas, double x, double y) {
    canvas.drawCircle(
        Offset(x, y),
        12,
        Paint()
          ..color = const Color(0x15FFAA30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFFFFAA30));
    canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = const Color(0xFFFFDD80));
  }

  /// Check if a position collides with any pillar
  bool collidesWithPillar(double x, double y, double radius) {
    for (final p in layout.pillars) {
      final dx = x - p.x, dy = y - p.y;
      final minDist = radius + p.size / 2;
      if (dx * dx + dy * dy < minDist * minDist) return true;
    }
    return false;
  }
}
