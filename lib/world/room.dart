import 'dart:ui';
import 'package:flame/components.dart';
import '../game/config.dart';

class Room extends PositionComponent {
  final bool exitOpen;

  Room({this.exitOpen = false})
      : super(
          size: Vector2(Config.roomWidth, Config.roomHeight),
          position: Vector2.zero(),
        );

  @override
  void render(Canvas canvas) {
    final w = Config.roomWidth;
    final h = Config.roomHeight;
    final wt = Config.wallThickness;
    final ts = Config.tileSize;

    for (double x = wt; x < w - wt; x += ts) {
      for (double y = wt; y < h - wt; y += ts) {
        final ix = (x / ts).floor();
        final iy = (y / ts).floor();
        final dark = (ix + iy) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, ts, ts),
          Paint()..color = dark ? Config.floorColor : const Color(0xFF111118),
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(wt, wt, w - wt * 2, h - wt * 2),
      Paint()
        ..color = const Color(0x08FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final wallPaint = Paint()..color = Config.wallColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, wt), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, h - wt, w, wt), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, wt, h), wallPaint);
    canvas.drawRect(Rect.fromLTWH(w - wt, 0, wt, h), wallPaint);

    canvas.drawLine(
      Offset(wt, wt),
      Offset(w - wt, wt),
      Paint()
        ..color = const Color(0x15FFFFFF)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(wt, wt),
      Offset(wt, h - wt),
      Paint()
        ..color = const Color(0x10FFFFFF)
        ..strokeWidth = 1,
    );

    final doorW = 48.0;
    final entryX = w / 2 - doorW / 2;
    canvas.drawRect(
      Rect.fromLTWH(entryX, h - wt, doorW, wt),
      Paint()..color = const Color(0xFF2A2A3E),
    );

    final exitColor = exitOpen ? const Color(0xFF2A6A3E) : const Color(0xFF4A1A1E);
    canvas.drawRect(
      Rect.fromLTWH(entryX, 0, doorW, wt),
      Paint()..color = exitColor,
    );
    if (exitOpen) {
      canvas.drawRect(
        Rect.fromLTWH(entryX - 2, 0, doorW + 4, wt + 2),
        Paint()
          ..color = const Color(0x304CAF50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

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
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      Offset(x, y),
      3,
      Paint()..color = const Color(0xFFFFAA30),
    );
    canvas.drawCircle(
      Offset(x, y),
      1.5,
      Paint()..color = const Color(0xFFFFDD80),
    );
  }
}
