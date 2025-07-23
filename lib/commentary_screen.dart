// lib/commentary_screen.dart
import 'package:flutter/material.dart';
import 'models.dart'; // Import your shared models

class CommentaryScreen extends StatelessWidget {
  final List<GameEvent> events;
  final String team1Name; // To correctly display "Team 1" or "Team A" in events
  final String team2Name; // To correctly display "Team 2" or "Team B" in events

  const CommentaryScreen({
    Key? key,
    required this.events,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  // Helper method to convert a GameEvent into a human-readable commentary string
  String _getCommentaryText(GameEvent event) {
    switch (event.type) {
      case EventType.gameStart:
        return 'The game has started!';
      case EventType.point:
        final team = event.teamName;
        final playerName = event.playerName;
        final points = event.value;
        String pointType;
        if (points == 1) {
          pointType = 'a Free Throw';
        } else if (points == 2) {
          pointType = 'a 2-pointer';
        } else {
          pointType = 'a 3-pointer';
        }
        return '$playerName shoots $pointType for $team (+${points} points).';
      case EventType.foul:
        return '${event.playerName} commits a foul for ${event.teamName}.';
      case EventType.substitution:
        final team = event.teamName;
        final playersOut = event.playersOutNames?.join(', ') ?? 'N/A';
        final playersIn = event.playersInNames?.join(', ') ?? 'N/A';
        return 'Substitution for $team: $playersOut out, $playersIn in.';
      case EventType.quarterEnd:
        return 'End of Quarter ${event.quarter}.';
      default:
        return 'Unknown event.';
    }
  }

  // Helper to determine background color for the event card
  Color _getEventCardColor(EventType type) {
    switch (type) {
      case EventType.point:
        return Colors.green.withOpacity(0.1);
      case EventType.foul:
        return Colors.red.withOpacity(0.1);
      case EventType.substitution:
        return Colors.blue.withOpacity(0.1);
      case EventType.quarterEnd:
        return Colors.orange.withOpacity(0.1);
      case EventType.gameStart:
        return Colors.grey.withOpacity(0.1);
      default:
        return Colors.white;
    }
  }

  // Helper to determine icon for the event
  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.point: return Icons.sports_basketball;
      case EventType.foul: return Icons.warning_rounded;
      case EventType.substitution: return Icons.swap_horiz;
      case EventType.quarterEnd: return Icons.timelapse;
      case EventType.gameStart: return Icons.flag;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reverse the list to show the most recent events at the top
    final reversedEvents = List<GameEvent>.from(events.reversed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Commentary'),
        backgroundColor: Colors.orange,
      ),
      body: reversedEvents.isEmpty
          ? const Center(
        child: Text(
          'No events recorded yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: reversedEvents.length,
        itemBuilder: (context, index) {
          final event = reversedEvents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: _getEventCardColor(event.type),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getEventIcon(event.type),
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCommentaryText(event),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.timestamp.toLocal().toString().substring(11, 19), // HH:MM:SS
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}