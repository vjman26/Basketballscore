// lib/models.dart
class Player {
  String name;
  int jerseyNumber;
  final int teamId;
  int points;
  int fouls;
  bool isOnCourt;
  bool isStarter;

  Player({
    required this.name,
    required this.jerseyNumber,
    required this.teamId,
    this.points = 0,
    this.fouls = 0,
    this.isOnCourt = false,
    this.isStarter = false,
  });

  // This copyWith method is crucial for creating proper copies
  Player copyWith({
    String? name,
    int? jerseyNumber,
    int? points,
    int? fouls,
    bool? isOnCourt,
    bool? isStarter,
  }) {
    return Player(
      name: name ?? this.name,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: this.teamId,
      points: points ?? this.points,
      fouls: fouls ?? this.fouls,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      isStarter: isStarter ?? this.isStarter,
    );
  }

  // Override equality operators for proper Set operations in substitution dialog
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.jerseyNumber == jerseyNumber &&
        other.teamId == teamId;
  }

  @override
  int get hashCode => jerseyNumber.hashCode ^ teamId.hashCode;
}

enum TeamColor { red, green, blue, yellow }