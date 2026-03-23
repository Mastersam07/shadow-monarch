import 'dart:ui';
import 'package:flutter/material.dart';
import 'shadow_soldier.dart';

class Igris extends ShadowSoldier {
  Igris({required super.player})
      : super(
          name: 'IGRIS',
          accentColor: const Color(0xFFDC143C), // crimson
          speed: 130.0,
          attackRange: 38.0,
          attackCooldown: 0.9,
          attackDamage: 2,
          soldierSize: 16.0,
        );

  @override
  void renderSoldier(Canvas canvas, double s) {
    final bodyPath = Path()
      ..moveTo(0, -s * 0.9)
      ..lineTo(-s * 0.55, s * 0.5)
      ..lineTo(s * 0.55, s * 0.5)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF1A0A0A));
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = const Color(0xFFDC143C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    canvas.drawLine(
        Offset(-s * 0.3, -s * 0.7),
        Offset(-s * 0.5, -s * 1.1),
        Paint()
          ..color = const Color(0xFFDC143C)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(s * 0.3, -s * 0.7),
        Offset(s * 0.5, -s * 1.1),
        Paint()
          ..color = const Color(0xFFDC143C)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);

    canvas.drawLine(
        Offset(-s * 0.2, -s * 0.5),
        Offset(s * 0.2, -s * 0.5),
        Paint()
          ..color = const Color(0xFFFF3030)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(-s * 0.2, -s * 0.5),
        Offset(s * 0.2, -s * 0.5),
        Paint()
          ..color = const Color(0x40FF3030)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawLine(
        Offset(s * 0.3, -s * 0.2),
        Offset(s * 0.3, -s * 1.3),
        Paint()
          ..color = const Color(0xFF808080)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(s * 0.3, -s * 0.2),
        Offset(s * 0.3, -s * 1.3),
        Paint()
          ..color = const Color(0x20FF3030)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    final capePath = Path()
      ..moveTo(-s * 0.4, s * 0.3)
      ..quadraticBezierTo(-s * 0.6, s * 0.8, -s * 0.3, s * 1.1)
      ..lineTo(s * 0.3, s * 1.1)
      ..quadraticBezierTo(s * 0.6, s * 0.8, s * 0.4, s * 0.3)
      ..close();
    canvas.drawPath(capePath, Paint()..color = const Color(0xFF2A0808));
    canvas.drawPath(
        capePath,
        Paint()
          ..color = const Color(0x30DC143C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }
}
