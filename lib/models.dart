// lib/models.dart
import 'package:flutter/material.dart';

class Player {
  String name;
  int jerseyNumber;
  final int teamId;
  int points;
  int fouls;
  bool isOnCourt;
  bool isStarter;
  List<int> actionHistory; // Stores points (positive) or fouls (-1)

  Player({
    required this.name,
    required this.jerseyNumber,
    required this.teamId,
    this.points = 0,
    this.fouls = 0,
    this.isOnCourt = false,
    this.isStarter = false,
    List<int>? actionHistory,
  }) : this.actionHistory = actionHistory ?? [];


  Player copyWith({
    String? name,
    int? jerseyNumber,
    int? points,
    int? fouls,
    bool? isOnCourt,
    bool? isStarter,
    List<int>? actionHistory,
  }) {
    return Player(
      name: name ?? this.name,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: this.teamId,
      points: points ?? this.points,
      fouls: fouls ?? this.fouls,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      isStarter: isStarter ?? this.isStarter,
      actionHistory: actionHistory ?? List.from(this.actionHistory), // Deep copy history
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.runtimeType == runtimeType &&
        other.jerseyNumber == jerseyNumber &&
        other.teamId == teamId;
  }

  @override
  int get hashCode => Object.hash(jerseyNumber, teamId);
}

enum TeamColor { red, green, blue, yellow }

// NEW: EventType enum
enum EventType {
  point,
  foul,
  substitution,
  quarterEnd,
  gameStart,
}

// NEW: GameEvent class to log game actions
class GameEvent {
  final EventType type;
  final DateTime timestamp;
  final String? playerName; // For points/fouls
  final String? teamName;   // For points/fouls
  final int? value;         // Points added (1, 2, 3)
  final int? quarter;       // Quarter number (1-4)
  final List<String>? playersOutNames; // For substitutions
  final List<String>? playersInNames;  // For substitutions

  GameEvent.point({
    required this.playerName,
    required this.teamName,
    required this.value,
  }) : type = EventType.point,
        timestamp = DateTime.now(),
        quarter = null,
        playersOutNames = null,
        playersInNames = null;

  GameEvent.foul({
    required this.playerName,
    required this.teamName,
  }) : type = EventType.foul,
        timestamp = DateTime.now(),
        value = null,
        quarter = null,
        playersOutNames = null,
        playersInNames = null;

  GameEvent.substitution({
    required this.teamName, // Team that made the substitution
    required this.playersOutNames,
    required this.playersInNames,
  }) : type = EventType.substitution,
        timestamp = DateTime.now(),
        playerName = null,
        value = null,
        quarter = null;

  GameEvent.quarterEnd({
    required this.quarter,
  }) : type = EventType.quarterEnd,
        timestamp = DateTime.now(),
        playerName = null,
        teamName = null,
        value = null,
        playersOutNames = null,
        playersInNames = null;

  GameEvent.gameStart()
      : type = EventType.gameStart,
        timestamp = DateTime.now(),
        playerName = null,
        teamName = null,
        value = null,
        quarter = null,
        playersOutNames = null,
        playersInNames = null;
}