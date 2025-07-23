// lib/substitution_dialog.dart
import 'package:flutter/material.dart';
import 'models.dart'; // Import your shared models

class SubstitutionDialog extends StatefulWidget {
  final List<Player> players; // All players for the selected team
  // NEW: onSaveSubstitutions callback now returns the names of players substituted
  final Function(List<Player> updatedPlayers, List<String> playersOutNames, List<String> playersInNames) onSaveSubstitutions;
  final Color teamColor;
  final String teamName;

  SubstitutionDialog({
    Key? key, // Add Key
    required this.players,
    required this.onSaveSubstitutions,
    required this.teamColor,
    required this.teamName,
  }) : super(key: key); // Pass key to super

  @override
  _SubstitutionDialogState createState() => _SubstitutionDialogState();
}

class _SubstitutionDialogState extends State<SubstitutionDialog> {
  Set<Player> selectedPlayersOut = {};
  Set<Player> selectedPlayersIn = {};

  late List<Player> dialogPlayers;

  @override
  void initState() {
    super.initState();
    dialogPlayers = widget.players.map((player) => player.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Player> playersOnCourt = dialogPlayers.where((p) => p.isOnCourt).toList();
    List<Player> playersOnBench = dialogPlayers.where((p) => !p.isOnCourt).toList();

    playersOnCourt.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
    playersOnBench.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));

    return AlertDialog(
      title: Text('Manage Substitutions - ${widget.teamName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
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
                  return CheckboxListTile(
                    title: Text('${player.name} (#${player.jerseyNumber})'),
                    subtitle: Text('Points: ${player.points} | Fouls: ${player.fouls}'),
                    value: selectedPlayersOut.contains(player),
                    activeColor: widget.teamColor,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedPlayersOut.add(player);
                        } else {
                          selectedPlayersOut.remove(player);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            Divider(thickness: 2, height: 24),

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
                  return CheckboxListTile(
                    title: Text('${player.name} (#${player.jerseyNumber})'),
                    subtitle: Text('Points: ${player.points} | Fouls: ${player.fouls}'),
                    value: selectedPlayersIn.contains(player),
                    activeColor: widget.teamColor,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedPlayersIn.add(player);
                        } else {
                          selectedPlayersIn.remove(player);
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
            if (selectedPlayersOut.length != selectedPlayersIn.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please select an equal number of players to sub in and out.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Apply substitutions to the dialogPlayers list
            for (var playerOut in selectedPlayersOut) {
              final originalPlayerInDialogList = dialogPlayers.firstWhere((p) => p == playerOut);
              originalPlayerInDialogList.isOnCourt = false;
            }
            for (var playerIn in selectedPlayersIn) {
              final originalPlayerInDialogList = dialogPlayers.firstWhere((p) => p == playerIn);
              originalPlayerInDialogList.isOnCourt = true;
            }

            // NEW: Get names of players for commentary before passing them back
            final List<String> namesOut = selectedPlayersOut.map((p) => p.name).toList();
            final List<String> namesIn = selectedPlayersIn.map((p) => p.name).toList();

            widget.onSaveSubstitutions(dialogPlayers, namesOut, namesIn); // Pass names back
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