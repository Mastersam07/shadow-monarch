import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import '../entities/player.dart';
import '../entities/enemies/dire_wolf.dart';
import '../entities/enemies/stone_golem.dart';
import '../entities/enemies/armored_knight.dart';
import '../entities/enemies/statue_of_god.dart';
import '../world/room.dart';
import '../world/gate.dart';
import '../world/room_generator.dart';
import '../ui/hud.dart';
import '../ui/room_transition.dart';
import '../effects/particle_system.dart';
import '../effects/screen_effects.dart';
import '../combat/damage_numbers.dart';
import '../input/input_manager.dart';
import '../input/gamepad_handler.dart';
import '../audio/audio_manager.dart';
import '../ui/menu_renderer.dart';

enum GamePhase { menu, playing, roomClear, transitioning, gateComplete, gameOver }

class ShadowMonarchGame extends FlameGame with HasCollisionDetection, KeyboardEvents, MouseMovementDetector {
  final _rng = Random();
  final inputState = InputState();
  late KeyboardInputHandler _keyboard;
  late GamepadHandler _gamepad;
  late Player player;
  late ParticleSystem particles;
  ScreenEffects? screenFx;
  late Hud hud;
  late RoomTransition roomTransition;
  Room? room;
  final _menuRenderer = MenuRenderer();
  final _audio = AudioManager();

  GamePhase phase = GamePhase.menu;

  // Gate management
  Gate? _currentGate;
  int _gateNumber = 1;
  int _enemiesAlive = 0;
  int _score = 0;
  bool _pendingRoomLoad = false;

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

    roomTransition = RoomTransition();
    add(roomTransition);

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
    _gateNumber = 1;
    _score = 0;
    _startGate();
  }

  void _startGate() {
    world.removeAll(world.children);

    _currentGate = Gate.generate(_gateNumber);

    particles = ParticleSystem();
    world.add(particles);

    screenFx = ScreenEffects();
    if (screenFx case final ScreenEffects fx) world.add(fx);

    player = Player(input: inputState)..position = Vector2(Config.roomWidth / 2, Config.roomHeight * 0.8);
    player.hp = Config.playerMaxHp;
    player.mp = Config.playerMaxMp;
    player.onAttack = _onPlayerAttack;
    player.onDeath = _onPlayerDeath;
    world.add(player);

    hud = Hud(player: player, wave: 0, score: _score, gateNumber: _gateNumber);
    world.add(hud);

    _loadCurrentRoom();
  }

  void _loadCurrentRoom() {
    final gate = _currentGate!;
    if (gate.isComplete) {
      _onGateComplete();
      return;
    }

    final roomData = gate.currentRoom;
    final layout = RoomGenerator.generate(roomData);

    // Remove old room
    if (room case final room?) room.removeFromParent();

    // Create new room
    room = Room(
      layout: layout,
      exitOpen: roomData.type == RoomType.rest || roomData.type == RoomType.treasure,
    );
    world.add(room!);
    room!.priority = -10;

    // Position player at spawn
    player.position = layout.playerSpawn.clone();

    // Update HUD
    hud.wave = gate.currentRoomIndex + 1;
    hud.enemiesLeft = roomData.enemyCount;

    // Spawn enemies
    _enemiesAlive = 0;
    if (roomData.type == RoomType.combat || roomData.type == RoomType.elite) {
      _spawnEnemies(roomData, layout);
    } else if (roomData.type == RoomType.boss) {
      _spawnBoss(layout);
    } else if (roomData.type == RoomType.rest) {
      _handleRestRoom();
    }

    phase = (roomData.type == RoomType.rest || roomData.type == RoomType.treasure)
        ? GamePhase.roomClear
        : GamePhase.playing;
    _pendingRoomLoad = false;
  }

  void _spawnEnemies(RoomData roomData, RoomLayout layout) {
    _enemiesAlive = layout.enemySpawnPoints.length;

    for (int i = 0; i < layout.enemySpawnPoints.length; i++) {
      final pos = layout.enemySpawnPoints[i];
      final roll = _rng.nextDouble();

      if (roomData.type == RoomType.elite || (_gateNumber >= 2 && roll < 0.2)) {
        final knight = ArmoredKnight(player: player, spawnPos: pos.clone());
        knight.onDeath = (k) => _onGenericEnemyDeath(k.position, 50);
        world.add(knight);
      } else if (_gateNumber >= 1 && roll < 0.45) {
        final golem = StoneGolem(player: player, spawnPos: pos.clone());
        golem.onDeath = (g) => _onGenericEnemyDeath(g.position, 40);
        golem.onSlam = _onGolemSlam;
        world.add(golem);
      } else {
        final wolf = DireWolf(player: player, spawnPos: pos.clone());
        wolf.onDeath = (w) => _onGenericEnemyDeath(w.position, 25);
        world.add(wolf);
      }
    }
  }

  void _spawnBoss(RoomLayout layout) {
    _enemiesAlive = 1;
    final boss = StatueOfGod(player: player, spawnPos: layout.enemySpawnPoints.first.clone());
    boss.onDeath = _onBossDeath;
    boss.onSlam = _onBossSlam;
    boss.onLaser = _onBossLaser;
    world.add(boss);
    // TODO(mastersam07): Play SFX — boss entrance (dramatic horn, rumble)
  }

  void _handleRestRoom() {
    player.hp = Config.playerMaxHp;
    player.mp = Config.playerMaxMp;
    particles.spawn(player.position.x, player.position.y, 20, Config.healColor,
        speed: 50, maxLife: 0.8, minSize: 1, maxSize: 3);
    // TODO(mastersam07): Play SFX — heal (gentle chime, warmth)
  }

  void _onGenericEnemyDeath(Vector2 pos, int points) {
    _enemiesAlive--;
    _score += points;
    hud.score = _score;
    hud.enemiesLeft = _enemiesAlive;

    particles.spawn(pos.x, pos.y, 15, Config.enemyColor, speed: 80, maxLife: 0.4);
    player.addShadow(Config.shadowGainPerKill);
    world.add(DamageNumber(pos.x, pos.y - 20, points, color: Config.goldColor));
    screenFx?.shake(2);

    if (_enemiesAlive <= 0) _onRoomCleared();
  }

  void _onBossDeath(StatueOfGod boss) {
    _enemiesAlive = 0;
    _score += 500;
    hud.score = _score;
    hud.enemiesLeft = 0;

    particles.spawn(boss.position.x, boss.position.y, 40, Config.bossColor, speed: 150, maxLife: 0.8);
    player.addShadow(Config.shadowGainPerEliteKill);
    world.add(DamageNumber(boss.position.x, boss.position.y - 30, 500, color: Config.goldColor));
    screenFx?.shake(15);
    screenFx?.flash(Config.goldColor, intensity: 0.2);
    // TODO(mastersam07): Play SFX — boss defeated (victory fanfare)

    _onRoomCleared();
  }

  void _onRoomCleared() {
    phase = GamePhase.roomClear;
    room?.exitOpen = true;
    // TODO(mastersam07): Play SFX — room cleared (door unlock, chime)
  }

  void _onGolemSlam(double x, double y, double radius) {
    final dx = player.position.x - x, dy = player.position.y - y;
    if (dx * dx + dy * dy < radius * radius) {
      player.takeDamage(Config.golemDamage);
      screenFx?.shake(6);
      screenFx?.flash(Config.enemyColor, intensity: 0.1);
    }
    particles.spawn(x, y, 12, Config.golemCoreColor, speed: 60, maxLife: 0.3);
    screenFx?.shake(3);
  }

  void _onBossSlam(double x, double y, double radius) {
    final dx = player.position.x - x, dy = player.position.y - y;
    if (dx * dx + dy * dy < radius * radius) {
      player.takeDamage(2);
      screenFx?.shake(10);
      screenFx?.flash(Config.bossColor, intensity: 0.15);
    }
    particles.spawn(x, y, 20, Config.bossColor, speed: 100, maxLife: 0.5);
    screenFx?.shake(6);
  }

  void _onBossLaser(double x, double y, double angle, double width, double length) {
    final px = player.position.x - x, py = player.position.y - y;
    final dirX = cos(angle), dirY = sin(angle);
    final dot = px * dirX + py * dirY;
    if (dot > 0 && dot < length) {
      final perpDist = (px * dirY - py * dirX).abs();
      if (perpDist < width / 2 + Config.playerSize * 0.5) {
        player.takeDamage(1);
        screenFx?.shake(3);
      }
    }
  }

  void _onPlayerAttack(double x, double y, double angle, int damage) {
    particles.spawnDirectional(x, y, angle, 8, Config.playerColor, spread: 0.8, speed: 120);
    if (damage >= Config.comboFinisherDamage) {
      screenFx?.shake(4);
      screenFx?.flash(Config.goldColor, intensity: 0.1);
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
    if (player.isDead || player.isInvincible || player.isDashing) return;

    bool checkCollision(PositionComponent enemy, double enemySize) {
      final dx = enemy.position.x - player.position.x;
      final dy = enemy.position.y - player.position.y;
      final dist = dx * dx + dy * dy;
      final minDist = (Config.playerSize + enemySize) * 0.8;
      return dist < minDist * minDist;
    }

    for (final wolf in world.children.whereType<DireWolf>()) {
      if (!wolf.isDead && checkCollision(wolf, Config.wolfSize)) {
        player.takeDamage(1);
        _hitEffects();
        return;
      }
    }
    for (final golem in world.children.whereType<StoneGolem>()) {
      if (!golem.isDead && checkCollision(golem, Config.golemSize)) {
        player.takeDamage(Config.golemDamage);
        _hitEffects();
        return;
      }
    }
    for (final knight in world.children.whereType<ArmoredKnight>()) {
      if (!knight.isDead && checkCollision(knight, Config.knightSize)) {
        player.takeDamage(Config.knightDamage);
        _hitEffects();
        return;
      }
    }
    for (final boss in world.children.whereType<StatueOfGod>()) {
      if (!boss.isDead && checkCollision(boss, Config.bossStatueSize)) {
        player.takeDamage(2);
        _hitEffects();
        return;
      }
    }
  }

  void _hitEffects() {
    screenFx?.shake(5);
    screenFx?.flash(Config.healthColor, intensity: 0.15);
    particles.spawn(player.position.x, player.position.y, 10, Config.healthColor, speed: 80, maxLife: 0.3);
  }

  bool _isPlayerAtExit() {
    final doorX = Config.roomWidth / 2;
    return (player.position.x - doorX).abs() < Config.doorWidth / 2 && player.position.y < Config.wallThickness + 25;
  }

  void _advanceToNextRoom() {
    final gate = _currentGate!;
    final gateComplete = gate.advanceRoom();

    if (gateComplete) {
      _onGateComplete();
    } else {
      phase = GamePhase.transitioning;
      roomTransition.start(gate.currentRoomIndex, gate.totalRooms, gate.currentRoom.type);
      _pendingRoomLoad = true;
    }
  }

  void _onGateComplete() {
    phase = GamePhase.gateComplete;
    _gateNumber++;
    screenFx?.flash(Config.goldColor, intensity: 0.15);
    // TODO(mastersam07): Play SFX — gate complete (triumph, level up)
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

      case GamePhase.roomClear:
        _keyboard.playerWorldX = player.position.x;
        _keyboard.playerWorldY = player.position.y;
        if (_isPlayerAtExit() && room?.exitOpen == true) {
          _advanceToNextRoom();
        }

      case GamePhase.transitioning:
        if (roomTransition.isAtPeak && _pendingRoomLoad) {
          _loadCurrentRoom();
        }

      case GamePhase.gateComplete:
        if (inputState.attackJustPressed) _startGate();

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

    roomTransition.renderOverlay(canvas, Size(sz.x, sz.y));

    switch (phase) {
      case GamePhase.menu:
        _menuRenderer.render(canvas, sz);
      case GamePhase.gameOver:
        _renderGameOver(canvas, sz);
      case GamePhase.gateComplete:
        _renderGateComplete(canvas, sz);
      case _:
    }
  }

  void _renderGameOver(Canvas canvas, Vector2 sz) {
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), _menuPaint..color = const Color(0xD0000000));
    _text(canvas, sz, 'DEFEATED', sz.y * 0.30, 38, Config.healthColor, FontWeight.w900, spacing: 10);
    _text(canvas, sz, 'Score: $_score  |  Gate: $_gateNumber', sz.y * 0.42, 16, Colors.white, FontWeight.w400,
        spacing: 2);
    _text(canvas, sz, 'Room: ${_currentGate?.currentRoomIndex ?? 0} / ${_currentGate?.totalRooms ?? 0}', sz.y * 0.48,
        13, const Color(0x80FFFFFF), FontWeight.w400,
        spacing: 1);
    _text(canvas, sz, 'Press Space to retry', sz.y * 0.56, 14, const Color(0x80FFFFFF), FontWeight.w400, spacing: 1);
  }

  void _renderGateComplete(Canvas canvas, Vector2 sz) {
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), _menuPaint..color = const Color(0xD0000008));
    _text(canvas, sz, 'GATE ${_gateNumber - 1} CLEARED', sz.y * 0.28, 34, Config.goldColor, FontWeight.w900,
        spacing: 8);
    _text(canvas, sz, 'Score: $_score', sz.y * 0.40, 20, Colors.white, FontWeight.w400, spacing: 2);
    _text(canvas, sz, 'Entering Gate $_gateNumber...', sz.y * 0.50, 16, Config.playerColor, FontWeight.w400,
        spacing: 2);
    _text(canvas, sz, 'Press Space to continue', sz.y * 0.60, 14, const Color(0x80FFFFFF), FontWeight.w400, spacing: 1);
  }

  void _text(Canvas canvas, Vector2 sz, String text, double y, double fontSize, Color color, FontWeight weight,
      {double spacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color, letterSpacing: spacing)),
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
