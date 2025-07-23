// lib/EditPlayersDialog.dart
import 'package:flutter/material.dart';
import 'models.dart';

class EditPlayersDialog extends StatefulWidget {
  final List<Player> players;
  final Function(List<Player>) onSave;
  final Color teamColor;
  final String teamName;

  EditPlayersDialog({
    required this.players,
    required this.onSave,
    required this.teamColor,
    required this.teamName,
  });

  @override
  _EditPlayersDialogState createState() => _EditPlayersDialogState();
}

class _EditPlayersDialogState extends State<EditPlayersDialog> {
  late List<TextEditingController> nameControllers;
  late List<TextEditingController> jerseyControllers;

  // Create a working copy of players for the dialog
  late List<Player> dialogPlayers;

  @override
  void initState() {
    super.initState();
    // Create deep copies for safe editing within the dialog
    dialogPlayers = widget.players.map((player) => player.copyWith()).toList();

    nameControllers = dialogPlayers
        .map((p) => TextEditingController(text: p.name))
        .toList();
    jerseyControllers = dialogPlayers
        .map((p) => TextEditingController(text: p.jerseyNumber.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in jerseyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePlayerFromControllers(int index) {
    final player = dialogPlayers[index];
    player.name = nameControllers[index].text.trim().isEmpty
        ? 'Player ${player.jerseyNumber}'
        : nameControllers[index].text.trim();

    int? newJerseyNumber = int.tryParse(jerseyControllers[index].text);
    if (newJerseyNumber != null && newJerseyNumber > 0) {
      player.jerseyNumber = newJerseyNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.teamName} Players (${dialogPlayers.length} total)'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.builder(
          itemCount: dialogPlayers.length,
          itemBuilder: (context, index) {
            final player = dialogPlayers[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: player.isOnCourt
                          ? widget.teamColor
                          : widget.teamColor.withOpacity(0.6),
                      child: Text('${player.jerseyNumber}',
                          style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          dialogPlayers[index].name = value.trim().isEmpty
                              ? 'Player ${player.jerseyNumber}'
                              : value.trim();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: jerseyControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Jersey #',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          int? newNumber = int.tryParse(value);
                          if (newNumber != null && newNumber > 0) {
                            setState(() {
                              dialogPlayers[index].jerseyNumber = newNumber;
                            });
                          }
                        },
                      ),
                    ),
                    if (player.isOnCourt)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: Text('On Court', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Ensure all changes from text controllers are applied
            for (int i = 0; i < dialogPlayers.length; i++) {
              _updatePlayerFromControllers(i);
            }

            // Pass the updated list back to the parent widget
            widget.onSave(dialogPlayers);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.teamColor,
            foregroundColor: Colors.white,
          ),
          child: Text('Save Changes'),
        ),
      ],
    );
  }
}