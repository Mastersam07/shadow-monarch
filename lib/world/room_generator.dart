import 'dart:math';
import 'package:flame/components.dart';
import '../game/config.dart';
import 'gate.dart';

/// A pillar obstacle in the room
class Pillar {
  final double x, y, size;
  Pillar(this.x, this.y, this.size);
}

/// Generated room layout data
class RoomLayout {
  final RoomType type;
  final List<Pillar> pillars;
  final List<Vector2> enemySpawnPoints;
  final Vector2 playerSpawn;

  RoomLayout({
    required this.type,
    required this.pillars,
    required this.enemySpawnPoints,
    required this.playerSpawn,
  });
}

class RoomGenerator {
  static final _rng = Random();

  static RoomLayout generate(RoomData data) {
    switch (data.type) {
      case RoomType.combat:
        return _generateCombatRoom(data);
      case RoomType.elite:
        return _generateEliteRoom(data);
      case RoomType.boss:
        return _generateBossRoom();
      case RoomType.rest:
        return _generateRestRoom();
      case RoomType.treasure:
        return _generateTreasureRoom();
    }
  }

  static RoomLayout _generateCombatRoom(RoomData data) {
    final pillars = <Pillar>[];
    final spawns = <Vector2>[];

    // Random pillar clusters (2-4 pillars)
    final pillarCount = 2 + _rng.nextInt(3);
    for (int i = 0; i < pillarCount; i++) {
      final x = Config.wallThickness + 80 + _rng.nextDouble() * (Config.roomWidth - Config.wallThickness * 2 - 160);
      final y = Config.wallThickness + 60 + _rng.nextDouble() * (Config.roomHeight - Config.wallThickness * 2 - 160);
      // Don't place too close to doors
      if (y < 50 || y > Config.roomHeight - 50) continue;
      if ((x - Config.roomWidth / 2).abs() < 40 && (y < 50 || y > Config.roomHeight - 50)) continue;
      pillars.add(Pillar(x, y, Config.pillarSize));
    }

    // Enemy spawn points (upper half of room)
    for (int i = 0; i < data.enemyCount; i++) {
      spawns.add(Vector2(
        Config.wallThickness + 50 + _rng.nextDouble() * (Config.roomWidth - Config.wallThickness * 2 - 100),
        Config.wallThickness + 40 + _rng.nextDouble() * (Config.roomHeight * 0.45),
      ));
    }

    return RoomLayout(
      type: data.type,
      pillars: pillars,
      enemySpawnPoints: spawns,
      playerSpawn: Vector2(Config.roomWidth / 2, Config.roomHeight * 0.8),
    );
  }

  static RoomLayout _generateEliteRoom(RoomData data) {
    // Symmetrical pillar layout for elite fights
    final pillars = <Pillar>[];
    final cx = Config.roomWidth / 2;

    // Four corner pillars
    pillars.add(Pillar(cx - 120, 150, Config.pillarSize));
    pillars.add(Pillar(cx + 120, 150, Config.pillarSize));
    pillars.add(Pillar(cx - 120, Config.roomHeight - 180, Config.pillarSize));
    pillars.add(Pillar(cx + 120, Config.roomHeight - 180, Config.pillarSize));

    final spawns = <Vector2>[];
    for (int i = 0; i < data.enemyCount; i++) {
      spawns.add(Vector2(
        cx + (_rng.nextDouble() - 0.5) * 200,
        100 + _rng.nextDouble() * 150,
      ));
    }

    return RoomLayout(
      type: data.type,
      pillars: pillars,
      enemySpawnPoints: spawns,
      playerSpawn: Vector2(cx, Config.roomHeight * 0.8),
    );
  }

  static RoomLayout _generateBossRoom() {
    // Open arena with minimal cover
    final cx = Config.roomWidth / 2;
    return RoomLayout(
      type: RoomType.boss,
      pillars: [
        Pillar(cx - 180, Config.roomHeight * 0.5, Config.pillarSize),
        Pillar(cx + 180, Config.roomHeight * 0.5, Config.pillarSize),
      ],
      enemySpawnPoints: [Vector2(cx, Config.roomHeight * 0.2)],
      playerSpawn: Vector2(cx, Config.roomHeight * 0.8),
    );
  }

  static RoomLayout _generateRestRoom() => RoomLayout(
        type: RoomType.rest,
        pillars: [],
        enemySpawnPoints: [],
        playerSpawn: Vector2(Config.roomWidth / 2, Config.roomHeight * 0.6),
      );

  static RoomLayout _generateTreasureRoom() => RoomLayout(
        type: RoomType.treasure,
        pillars: [],
        enemySpawnPoints: [],
        playerSpawn: Vector2(Config.roomWidth / 2, Config.roomHeight * 0.7),
      );
}
