import 'dart:math';

/// Room types within a gate
enum RoomType { combat, elite, rest, treasure, boss }

/// Data for a single room in the gate sequence
class RoomData {
  final RoomType type;
  final int enemyCount;
  final int roomIndex;
  bool cleared;

  RoomData({required this.type, required this.enemyCount, required this.roomIndex, this.cleared = false});
}

/// A Gate is a sequence of rooms the player must clear
class Gate {
  final int gateNumber;
  final List<RoomData> rooms;
  int currentRoomIndex = 0;

  Gate({required this.gateNumber, required this.rooms});

  RoomData get currentRoom => rooms[currentRoomIndex];
  bool get isComplete => currentRoomIndex >= rooms.length;
  bool get isBossRoom => currentRoom.type == RoomType.boss;
  int get totalRooms => rooms.length;

  /// Advance to next room. Returns true if gate is complete.
  bool advanceRoom() {
    rooms[currentRoomIndex].cleared = true;
    currentRoomIndex++;
    return currentRoomIndex >= rooms.length;
  }

  /// Generate a gate with the given number of rooms
  static Gate generate(int gateNumber) {
    final rng = Random();
    final roomCount = 5 + (gateNumber ~/ 3); // scales with gate level
    final rooms = <RoomData>[];

    for (int i = 0; i < roomCount; i++) {
      RoomType type;
      if (i == roomCount - 1) {
        type = RoomType.boss;
      } else if (i == 0) {
        type = RoomType.combat; // first room is always combat
      } else if (i == roomCount - 2) {
        // Room before boss: rest to heal up
        type = RoomType.rest;
      } else if (i == (roomCount ~/ 2)) {
        // Mid-gate elite
        type = RoomType.elite;
      } else {
        // Random: 60% combat, 15% treasure, 25% combat
        final roll = rng.nextDouble();
        if (roll < 0.15 && i > 1) {
          type = RoomType.treasure;
        } else {
          type = RoomType.combat;
        }
      }

      int enemyCount;
      switch (type) {
        case RoomType.combat:
          enemyCount = 3 + gateNumber + rng.nextInt(3);
        case RoomType.elite:
          enemyCount = 2 + gateNumber; // fewer but tougher
        case RoomType.boss:
          enemyCount = 1;
        case RoomType.rest:
        case RoomType.treasure:
          enemyCount = 0;
      }

      rooms.add(RoomData(type: type, enemyCount: enemyCount, roomIndex: i));
    }

    return Gate(gateNumber: gateNumber, rooms: rooms);
  }
}
