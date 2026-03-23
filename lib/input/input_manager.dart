import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';

class InputState {
  double moveX = 0;
  double moveY = 0;
  double aimX = 0;
  double aimY = 0;
  bool attack = false;
  bool attackJustPressed = false;
  bool dash = false;
  bool dashJustPressed = false;
  bool interact = false;
  bool ability1 = false;
  bool ability1JustPressed = false;
  bool pause = false;

  bool debugKill = false;
  bool debugHeal = false;

  double get aimAngle => atan2(aimY, aimX);

  bool get isMoving => moveX.abs() > 0.1 || moveY.abs() > 0.1;

  Vector2 get moveDir {
    final v = Vector2(moveX, moveY);
    if (v.length > 1) v.normalize();
    return v;
  }

  void reset() {
    attackJustPressed = false;
    dashJustPressed = false;
    ability1JustPressed = false;
    debugKill = false;
    debugHeal = false;
  }
}

class KeyboardInputHandler {
  final InputState state;
  final _keys = <LogicalKeyboardKey>{};

  double mouseWorldX = 0;
  double mouseWorldY = 0;
  double playerWorldX = 0;
  double playerWorldY = 0;

  KeyboardInputHandler(this.state);

  bool onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final wasAttack = _keys.contains(LogicalKeyboardKey.space);
      final wasDash = _keys.contains(LogicalKeyboardKey.shiftLeft) || _keys.contains(LogicalKeyboardKey.shiftRight);
      _keys.add(event.logicalKey);

      if (!wasAttack && (event.logicalKey == LogicalKeyboardKey.space)) {
        state.attackJustPressed = true;
      }
      if (!wasDash &&
          (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight)) {
        state.dashJustPressed = true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        state.ability1JustPressed = true;
      }

      final ctrlHeld = _keys.contains(LogicalKeyboardKey.controlLeft) ||
          _keys.contains(LogicalKeyboardKey.controlRight) ||
          _keys.contains(LogicalKeyboardKey.metaLeft); // Cmd on macOS
      if (ctrlHeld && event.logicalKey == LogicalKeyboardKey.keyK) {
        state.debugKill = true;
      }
      if (ctrlHeld && event.logicalKey == LogicalKeyboardKey.keyH) {
        state.debugHeal = true;
      }
    } else if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    }
    return true;
  }

  void update() {
    double dx = 0, dy = 0;
    if (_keys.contains(LogicalKeyboardKey.keyA) || _keys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyD) || _keys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyW) || _keys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyS) || _keys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    state.moveX = dx;
    state.moveY = dy;

    state.attack = _keys.contains(LogicalKeyboardKey.space);
    state.dash = _keys.contains(LogicalKeyboardKey.shiftLeft) || _keys.contains(LogicalKeyboardKey.shiftRight);
    state.ability1 = _keys.contains(LogicalKeyboardKey.keyE);
    state.interact = _keys.contains(LogicalKeyboardKey.keyF);
    state.pause = _keys.contains(LogicalKeyboardKey.escape);

    final dx2 = mouseWorldX - playerWorldX;
    final dy2 = mouseWorldY - playerWorldY;
    final d = sqrt(dx2 * dx2 + dy2 * dy2);
    if (d > 1) {
      state.aimX = dx2 / d;
      state.aimY = dy2 / d;
    } else if (state.isMoving) {
      state.aimX = state.moveX;
      state.aimY = state.moveY;
    }
  }
}
