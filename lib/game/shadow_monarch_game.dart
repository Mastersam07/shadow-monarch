import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import '../entities/player.dart';
import '../entities/enemies/dire_wolf.dart';
import '../world/room.dart';
import '../ui/hud.dart';
import '../effects/particle_system.dart';
import '../effects/screen_effects.dart';
import '../combat/damage_numbers.dart';
import '../input/input_manager.dart';
import '../input/gamepad_handler.dart';
import '../audio/audio_manager.dart';
import '../ui/menu_renderer.dart';

enum GamePhase { menu, playing, waveBreak, gameOver }

class ShadowMonarchGame extends FlameGame with HasCollisionDetection, KeyboardEvents, MouseMovementDetector {
  final _rng = Random();
  final inputState = InputState();
  late KeyboardInputHandler _keyboard;
  late GamepadHandler _gamepad;
  late Player player;
  late ParticleSystem particles;
  ScreenEffects? screenFx;
  late Hud hud;
  late Room room;
  final _menuRenderer = MenuRenderer();
  final _audio = AudioManager();

  GamePhase phase = GamePhase.menu;

  int _currentWave = 0;
  int _enemiesAlive = 0;
  double _waveBreakTimer = 0;
  int _score = 0;

  final _menuPaint = Paint();

  @override
  Color backgroundColor() => Config.bgColor;

  @override
  Future<void> onLoad() async {
    _keyboard = KeyboardInputHandler(inputState);
    _gamepad = GamepadHandler(inputState)..start();

    camera.viewfinder.visibleGameSize = Vector2(Config.roomWidth, Config.roomHeight);
    camera.viewfinder.position = Vector2(Config.roomWidth / 2, Config.roomHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    await _audio.init();
    _audio.playBgm(Config.menuBgmFile, volume: Config.menuBgmVolume);
  }

  @override
  void onRemove() {
    _gamepad.dispose();
    _audio.dispose();
    super.onRemove();
  }

  void startGame() {
    _audio.stopBgm();
    world.removeAll(world.children);

    room = Room();
    world.add(room);

    particles = ParticleSystem();
    world.add(particles);

    screenFx = ScreenEffects();
    if (screenFx case final ScreenEffects fx) world.add(fx);

    player = Player(input: inputState)..position = Vector2(Config.roomWidth / 2, Config.roomHeight * 0.7);
    player.onAttack = _onPlayerAttack;
    player.onDeath = _onPlayerDeath;
    world.add(player);

    hud = Hud(player: player);
    world.add(hud);

    _currentWave = 0;
    _enemiesAlive = 0;
    _score = 0;
    _waveBreakTimer = 1.5;
    phase = GamePhase.waveBreak;
  }

  void _spawnWave() {
    _currentWave++;
    final count = 2 + _currentWave;
    _enemiesAlive = count;
    hud.wave = _currentWave;
    hud.enemiesLeft = _enemiesAlive;

    for (int i = 0; i < count; i++) {
      final x = Config.wallThickness + 40 + _rng.nextDouble() * (Config.roomWidth - Config.wallThickness * 2 - 80);
      final y = Config.wallThickness + 40 + _rng.nextDouble() * (Config.roomHeight * 0.4);

      final wolf = DireWolf(
        player: player,
        spawnPos: Vector2(x, y),
      );
      wolf.onDeath = _onEnemyDeath;
      world.add(wolf);
    }

    // TODO(mastersam07): Play SFX — wave start (rumble, gate opening sound)
  }

  void _onPlayerAttack(double x, double y, double angle, int damage) {
    particles.spawnDirectional(x, y, angle, 8, Config.playerColor, spread: 0.8, speed: 120);

    if (damage >= Config.comboFinisherDamage) {
      screenFx?.shake(4);
      screenFx?.flash(Config.goldColor, intensity: 0.1);
    }
  }

  void _onEnemyDeath(DireWolf wolf) {
    _enemiesAlive--;
    _score += 25;
    hud.score = _score;
    hud.enemiesLeft = _enemiesAlive;

    particles.spawn(wolf.position.x, wolf.position.y, 15, Config.enemyColor, speed: 80, maxLife: 0.4);

    player.addShadow(Config.shadowGainPerKill);

    world.add(DamageNumber(wolf.position.x, wolf.position.y - 20, 25, color: Config.goldColor));

    screenFx?.shake(2);

    if (_enemiesAlive <= 0) {
      _waveBreakTimer = 2.0;
      phase = GamePhase.waveBreak;
      // TODO(mastersam07): Play SFX — wave cleared (satisfying chime, room echo)
    }
  }

  void _onPlayerDeath() {
    phase = GamePhase.gameOver;
    screenFx?.shake(10);
    screenFx?.flash(Config.healthColor, intensity: 0.2);
    particles.spawn(player.position.x, player.position.y, 30, Config.healthColor, speed: 150, maxLife: 0.6);
    // TODO(mastersam07): Play SFX — game over (dramatic low rumble, defeat sound)
  }

  void _checkEnemyPlayerCollision() {
    if (player.isDead) return;
    final wolves = world.children.whereType<DireWolf>();
    for (final wolf in wolves) {
      if (wolf.isDead) continue;
      final dx = wolf.position.x - player.position.x;
      final dy = wolf.position.y - player.position.y;
      final dist = dx * dx + dy * dy;
      final minDist = (Config.playerSize + Config.wolfSize) * 0.8;
      if (dist < minDist * minDist) {
        player.takeDamage(1);
        screenFx?.shake(5);
        screenFx?.flash(Config.healthColor, intensity: 0.15);
        particles.spawn(player.position.x, player.position.y, 10, Config.healthColor, speed: 80, maxLife: 0.3);
        break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _keyboard.update();
    _gamepad.update();

    switch (phase) {
      case GamePhase.menu:
        _menuRenderer.update(dt);
        if (inputState.attackJustPressed) startGame();
      case GamePhase.playing:
        _checkEnemyPlayerCollision();
        _keyboard.playerWorldX = player.position.x;
        _keyboard.playerWorldY = player.position.y;
      case GamePhase.waveBreak:
        _waveBreakTimer -= dt;
        if (_waveBreakTimer <= 0) {
          _spawnWave();
          phase = GamePhase.playing;
        }
      case GamePhase.gameOver:
        if (inputState.attackJustPressed) startGame();
    }

    inputState.reset();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sz = canvasSize;

    canvas.save();
    if (screenFx case final ScreenEffects fx) {
      canvas.translate(fx.shakeX, fx.shakeY);
      canvas.restore();
      fx.renderFlash(canvas, Size(sz.x, sz.y));
      fx.renderVignette(canvas, Size(sz.x, sz.y));
    } else {
      canvas.restore();
    }

    switch (phase) {
      case GamePhase.menu:
        _menuRenderer.render(canvas, sz);
      case GamePhase.gameOver:
        _renderGameOver(canvas, sz);
      case GamePhase.waveBreak when _currentWave > 0:
        _renderWaveClear(canvas, sz);
      case _:
    }
  }

  void _renderGameOver(Canvas canvas, Vector2 sz) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.x, sz.y),
      _menuPaint..color = const Color(0xD0000000),
    );

    _drawCenteredText(canvas, sz, 'DEFEATED', sz.y * 0.30, 38, Config.healthColor, FontWeight.w900, letterSpacing: 10);
    _drawCenteredText(
        canvas, sz, 'Score: $_score  |  Wave: $_currentWave', sz.y * 0.42, 16, Colors.white, FontWeight.w400,
        letterSpacing: 2);
    _drawCenteredText(canvas, sz, 'Press Space to retry', sz.y * 0.52, 14, const Color(0x80FFFFFF), FontWeight.w400,
        letterSpacing: 1);
  }

  void _renderWaveClear(Canvas canvas, Vector2 sz) {
    if (_waveBreakTimer > 1.5) return;
    final alpha = (_waveBreakTimer / 1.5).clamp(0.0, 1.0);
    _drawCenteredText(
        canvas, sz, 'WAVE ${_currentWave + 1}', sz.y * 0.45, 28, Colors.white.withValues(alpha: alpha), FontWeight.w700,
        letterSpacing: 8);
  }

  void _drawCenteredText(
      Canvas canvas, Vector2 sz, String text, double y, double fontSize, Color color, FontWeight weight,
      {double letterSpacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sz.x / 2 - tp.width / 2, y));
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboard.onKeyEvent(event);
    return KeyEventResult.handled;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    final worldPos = camera.viewfinder.transform.globalToLocal(info.eventPosition.global);
    _keyboard.mouseWorldX = worldPos.x;
    _keyboard.mouseWorldY = worldPos.y;
  }
}
