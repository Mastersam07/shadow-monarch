import 'dart:async';
import 'package:gamepads/gamepads.dart';
import 'input_manager.dart';

/// Maps PS5 DualSense (and standard gamepad) input to the unified InputState.
///
/// Button mappings (DualSense → game action):
///   Cross (X) / button 0  → attack
///   Circle / button 1     → dash
///   Square / button 2     → ability1 (future)
///   Triangle / button 3   → interact
///   L1 / button 4         → ability2 (future)
///   R1 / button 5         → ability3 (future)
///   Options / button 9    → pause
///   Left stick             → movement
///   Right stick            → aim direction
///   R2 trigger             → dash (alternative)
class GamepadHandler {
  final InputState state;
  StreamSubscription<GamepadEvent>? _subscription;

  double _leftStickX = 0;
  double _leftStickY = 0;
  double _rightStickX = 0;
  double _rightStickY = 0;

  bool _prevAttack = false;
  bool _prevDash = false;

  static const _deadZone = 0.15;

  GamepadHandler(this.state);

  void start() {
    _subscription = Gamepads.events.listen(_onEvent);
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _onEvent(GamepadEvent event) {
    final key = event.key.toLowerCase();
    final value = event.value;

    switch (event.type) {
      case KeyType.analog:
        _handleAnalog(key, value);
      case KeyType.button:
        _handleButton(key, value);
    }
  }

  void _handleAnalog(String key, double value) {
    final v = value.abs() < _deadZone ? 0.0 : value;

    switch (_classifyAnalog(key)) {
      case _Analog.leftX:
        _leftStickX = v;
      case _Analog.leftY:
        _leftStickY = v;
      case _Analog.rightX:
        _rightStickX = v;
      case _Analog.rightY:
        _rightStickY = v;
      case _Analog.dpadX:
        _leftStickX = v;
      case _Analog.dpadY:
        _leftStickY = v;
      case _Analog.r2Trigger:
        if (v > 0.5 && !_prevDash) state.dashJustPressed = true;
        _prevDash = v > 0.5;
      case null:
        break;
    }
  }

  void _handleButton(String key, double value) {
    if (_isDpad(key)) {
      if (_isXAxis(key)) {
        _leftStickX = value;
      } else if (_isYAxis(key)) {
        _leftStickY = -value;
      }
      return;
    }

    final pressed = value > 0.5;

    switch (_classifyButton(key)) {
      case _Button.attack:
        if (pressed && !_prevAttack) state.attackJustPressed = true;
        state.attack = pressed;
        _prevAttack = pressed;
      case _Button.dash:
        if (pressed && !_prevDash) state.dashJustPressed = true;
        state.dash = pressed;
        _prevDash = pressed;
      case _Button.ability1:
        break; // Reserved for Ruler's Hand
      case _Button.interact:
        state.interact = pressed;
      case _Button.pause:
        state.pause = pressed;
      case null:
        break;
    }
  }

  void update() {
    if (_leftStickX.abs() > _deadZone || _leftStickY.abs() > _deadZone) {
      state.moveX = _leftStickX;
      state.moveY = _leftStickY;
    }

    if (_rightStickX.abs() > _deadZone || _rightStickY.abs() > _deadZone) {
      state.aimX = _rightStickX;
      state.aimY = _rightStickY;
    }
  }
}

enum _Button { attack, dash, ability1, interact, pause }

enum _Analog { leftX, leftY, rightX, rightY, dpadX, dpadY, r2Trigger }

/// Classifies a button key string across platforms:
/// - macOS/iOS (SF Symbols): "xmark.circle", "circle.circle", etc.
/// - Linux/Windows/Web: "button 0", "button 1", etc.
/// - Generic: "a", "cross", "b", "circle", etc.
_Button? _classifyButton(String key) {
  if (key.contains('xmark') || key == 'cross' || key == 'a' || key == 'button 0') return _Button.attack;

  if ((key.contains('circle') && !key.contains('xmark')) || key == 'b' || key == 'button 1') return _Button.dash;

  if (key.contains('square') || key == 'x' || key == 'button 2') return _Button.ability1;

  if (key.contains('triangle') || key == 'y' || key == 'button 3') return _Button.interact;

  if (key.contains('option') || key.contains('start') || key == 'button 9') return _Button.pause;

  return null;
}

/// Classifies an analog key string across platforms:
/// - macOS/iOS (SF Symbols): "l.joystick - xaxis", "r2.rectangle.roundedtop", etc.
/// - Linux/Windows/Web: "analog 0", "analog 1", "axis 0", etc.
/// - Generic: "leftstickx", "left.x", "leftx", etc.
_Analog? _classifyAnalog(String key) {
  if (_isLeftStick(key) && _isXAxis(key)) return _Analog.leftX;
  if (key == 'analog 0' || key == 'axis 0' || key == 'leftx') return _Analog.leftX;

  if (_isLeftStick(key) && _isYAxis(key)) return _Analog.leftY;
  if (key == 'analog 1' || key == 'axis 1' || key == 'lefty') return _Analog.leftY;

  if (_isRightStick(key) && _isXAxis(key)) return _Analog.rightX;
  if (key == 'analog 2' || key == 'axis 2' || key == 'rightx') return _Analog.rightX;

  if (_isRightStick(key) && _isYAxis(key)) return _Analog.rightY;
  if (key == 'analog 3' || key == 'axis 3' || key == 'righty') return _Analog.rightY;

  if (_isDpad(key) && _isXAxis(key)) return _Analog.dpadX;
  if (_isDpad(key) && _isYAxis(key)) return _Analog.dpadY;

  if (key.contains('r2') || key.contains('righttrigger') || key == 'axis 5') return _Analog.r2Trigger;

  return null;
}

bool _isLeftStick(String key) => key.contains('l.joystick') || key.contains('leftstick') || key.contains('left.');
bool _isRightStick(String key) => key.contains('r.joystick') || key.contains('rightstick') || key.contains('right.');
bool _isXAxis(String key) => key.contains('xaxis') || key.contains('.x');
bool _isYAxis(String key) => key.contains('yaxis') || key.contains('.y');
bool _isDpad(String key) => key.contains('dpad') || key.contains('d-pad') || key.contains('direction');
