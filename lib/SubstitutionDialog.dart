// lib/SubstitutionDialog.dart
import 'package:flutter/material.dart';
import 'models.dart';

class SubstitutionDialog extends StatefulWidget {
  final List<Player> players; // All players for the selected team
  final Function(List<Player>) onSaveSubstitutions; // Callback to save changes
  final Color teamColor;
  final String teamName;

  SubstitutionDialog({
    required this.players,
    required this.onSaveSubstitutions,
    required this.teamColor,
    required this.teamName,
  });

  @override
  _SubstitutionDialogState createState() => _SubstitutionDialogState();
}

class _SubstitutionDialogState extends State<SubstitutionDialog> {
  // Use lists to store indices instead of player objects
  List<int> selectedPlayersOutIndices = [];
  List<int> selectedPlayersInIndices = [];

  // Create a working copy of players to modify within the dialog
  late List<Player> dialogPlayers;

  @override
  void initState() {
    super.initState();
    // Create deep copies to avoid modifying the original list directly
    dialogPlayers = widget.players.map((player) => player.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Player> playersOnCourt = dialogPlayers.where((p) => p.isOnCourt).toList();
    List<Player> playersOnBench = dialogPlayers.where((p) => !p.isOnCourt).toList();

    // Sort players by jersey number for better readability
    playersOnCourt.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
    playersOnBench.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));

    return AlertDialog(
      title: Text('Manage Substitutions - ${widget.teamName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Players Coming Out Section
            Text(
              'Players to Sub Out (On Court):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.teamColor),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: playersOnCourt.length,
                itemBuilder: (context, index) {
                  final player = playersOnCourt[index];
                  final playerIndex = dialogPlayers.indexWhere((p) =>
                  p.jerseyNumber == player.jerseyNumber && p.teamId == player.teamId);

                  return CheckboxListTile(
                    title: Text('${player.name} (#${player.jerseyNumber})'),
                    subtitle: Text('Points: ${player.points} | Fouls: ${player.fouls}'),
                    value: selectedPlayersOutIndices.contains(playerIndex),
                    activeColor: widget.teamColor,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedPlayersOutIndices.add(playerIndex);
                        } else {
                          selectedPlayersOutIndices.remove(playerIndex);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            Divider(thickness: 2, height: 24),

            // Players Coming In Section
            Text(
              'Players to Sub In (On Bench):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.teamColor),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: playersOnBench.length,
                itemBuilder: (context, index) {
                  final player = playersOnBench[index];
                  final playerIndex = dialogPlayers.indexWhere((p) =>
                  p.jerseyNumber == player.jerseyNumber && p.teamId == player.teamId);

                  return CheckboxListTile(
                    title: Text('${player.name} (#${player.jerseyNumber})'),
                    subtitle: Text('Points: ${player.points} | Fouls: ${player.fouls}'),
                    value: selectedPlayersInIndices.contains(playerIndex),
                    activeColor: widget.teamColor,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedPlayersInIndices.add(playerIndex);
                        } else {
                          selectedPlayersInIndices.remove(playerIndex);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Check if the number of players to sub out matches players to sub in
            if (selectedPlayersOutIndices.length != selectedPlayersInIndices.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please select an equal number of players to sub in and out.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Apply substitutions using indices
            for (var index in selectedPlayersOutIndices) {
              dialogPlayers[index].isOnCourt = false;
            }
            for (var index in selectedPlayersInIndices) {
              dialogPlayers[index].isOnCourt = true;
            }

            // Pass the updated list back to the parent widget
            widget.onSaveSubstitutions(dialogPlayers);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.teamColor,
            foregroundColor: Colors.white,
          ),
          child: Text('Confirm Substitutions'),
        ),
      ],
    );
  }
}