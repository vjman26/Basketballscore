// lib/main.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'Substitutiondialog.dart';
import 'EditPlayersDialog.dart';
import 'MatchSummaryScreen.dart';
import 'commentary_screen.dart'; // Import the Commentary Screen

void main() {
  runApp(BasketballApp());
}

class BasketballApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basketball Scorer',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BasketballScoreScreen(),
    );
  }
}

class BasketballScoreScreen extends StatefulWidget {
  @override
  _BasketballScoreScreenState createState() => _BasketballScoreScreenState();
}

class _BasketballScoreScreenState extends State<BasketballScoreScreen> {
  List<Player> team1Players = List.generate(
    15,
        (index) => Player(
      name: 'Player ${index + 1}',
      jerseyNumber: index + 1,
      teamId: 1,
      isOnCourt: index < 5,
      isStarter: index < 5,
    ),
  );

  List<Player> team2Players = List.generate(
    15,
        (index) => Player(
      name: 'Player ${index + 16}',
      jerseyNumber: index + 16,
      teamId: 2,
      isOnCourt: index < 5,
      isStarter: index < 5,
    ),
  );

  int selectedTeam = 1;
  TeamColor team1Color = TeamColor.red;
  TeamColor team2Color = TeamColor.blue;
  String team1Name = 'Team 1';
  String team2Name = 'Team 2';
  int currentQuarter = 0; // 0-indexed: 0=Q1, 1=Q2, 2=Q3, 3=Q4

  Map<int, Map<String, int>> quarterScores = {
    1: {},
    2: {},
    3: {},
    4: {},
  };

  Map<String, int> _currentQuarterPoints = {};

  List<GameEvent> gameCommentary = [];


  @override
  void initState() {
    super.initState();
    _currentQuarterPoints = {
      team1Name: 0,
      team2Name: 0,
    };
    quarterScores[1] = {
      team1Name: 0,
      team2Name: 0,
    };
    gameCommentary.add(GameEvent.gameStart());
  }


  Color getTeamColor(TeamColor teamColor) {
    switch (teamColor) {
      case TeamColor.red:
        return Colors.red;
      case TeamColor.green:
        return Colors.green;
      case TeamColor.blue:
        return Colors.blue;
      case TeamColor.yellow:
        return Colors.yellow[700]!;
    }
  }

  String getTeamColorName(TeamColor teamColor) {
    switch (teamColor) {
      case TeamColor.red:
        return 'Red';
      case TeamColor.green:
        return 'Green';
      case TeamColor.blue:
        return 'Blue';
      case TeamColor.yellow:
        return 'Yellow';
    }
  }

  int get team1Score => team1Players.fold(0, (sum, player) => sum + player.points);
  int get team2Score => team2Players.fold(0, (sum, player) => sum + player.points);

  void _addPoints(Player player, int points) {
    setState(() {
      player.points += points;
      player.actionHistory.add(points);

      final String currentTeamName = (player.teamId == 1) ? team1Name : team2Name;
      _currentQuarterPoints[currentTeamName] = (_currentQuarterPoints[currentTeamName] ?? 0) + points;

      gameCommentary.add(GameEvent.point(
        playerName: player.name,
        teamName: currentTeamName,
        value: points,
      ));
    });
  }

  void _addFoul(Player player) {
    setState(() {
      player.fouls += 1;
      player.actionHistory.add(-1);

      final String currentTeamName = (player.teamId == 1) ? team1Name : team2Name;
      gameCommentary.add(GameEvent.foul(
        playerName: player.name,
        teamName: currentTeamName,
      ));
    });
  }

  void _undoLastAction(Player player) {
    setState(() {
      if (player.actionHistory.isNotEmpty) {
        int lastAction = player.actionHistory.removeLast();

        if (lastAction > 0) { // It was points
          player.points -= lastAction;
          final String currentTeamName = (player.teamId == 1) ? team1Name : team2Name;
          _currentQuarterPoints[currentTeamName] = (_currentQuarterPoints[currentTeamName] ?? 0) - lastAction;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Undid ${lastAction}pt for ${player.name}'),
              duration: Duration(milliseconds: 800),
            ),
          );
          // For simplicity, remove the last matching point event.
          // A more robust undo would use event IDs or a deeper undo stack.
          int eventIndexToRemove = gameCommentary.lastIndexWhere((event) =>
          event.type == EventType.point &&
              event.playerName == player.name &&
              event.value == lastAction);
          if (eventIndexToRemove != -1) {
            gameCommentary.removeAt(eventIndexToRemove);
          }

        } else if (lastAction == -1) { // It was a foul
          player.fouls = (player.fouls - 1).clamp(0, player.fouls);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Undid foul for ${player.name}'),
              duration: Duration(milliseconds: 800),
            ),
          );
          // For simplicity, remove the last matching foul event.
          int eventIndexToRemove = gameCommentary.lastIndexWhere((event) =>
          event.type == EventType.foul &&
              event.playerName == player.name);
          if (eventIndexToRemove != -1) {
            gameCommentary.removeAt(eventIndexToRemove);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} has no actions to undo.'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    });
  }


  void _editTeamName(int teamId) {
    String currentName = teamId == 1 ? team1Name : team2Name;
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Team $teamId Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                String oldName = (teamId == 1) ? team1Name : team2Name;
                String newName = controller.text.trim().isEmpty ? 'Team $teamId' : controller.text.trim();

                // If team name changed, update the primary team names
                if (teamId == 1) {
                  team1Name = newName;
                } else {
                  team2Name = newName;
                }

                // Update _currentQuarterPoints keys
                Map<String, int> tempCurrentQuarterPoints = {};
                if (_currentQuarterPoints.containsKey(oldName)) {
                  tempCurrentQuarterPoints[newName] = _currentQuarterPoints[oldName]!;
                } else {
                  tempCurrentQuarterPoints[newName] = 0;
                }
                // Ensure the other team's name is also carried over/initialized
                if (teamId == 1) { // If team 1 changed, ensure team 2 is copied
                  tempCurrentQuarterPoints[team2Name] = _currentQuarterPoints[team2Name] ?? 0;
                } else { // If team 2 changed, ensure team 1 is copied
                  tempCurrentQuarterPoints[team1Name] = _currentQuarterPoints[team1Name] ?? 0;
                }
                _currentQuarterPoints = tempCurrentQuarterPoints;


                // Also update keys in historical quarterScores
                quarterScores.forEach((quarterNum, scoresMap) {
                  Map<String, int> tempScoresMap = {};
                  if (scoresMap.containsKey(oldName)) {
                    tempScoresMap[newName] = scoresMap[oldName]!;
                  } else {
                    tempScoresMap[newName] = 0;
                  }
                  // Ensure the other team's score is also copied
                  if (teamId == 1) {
                    tempScoresMap[team2Name] = scoresMap[team2Name] ?? 0;
                  } else {
                    tempScoresMap[team1Name] = scoresMap[team1Name] ?? 0;
                  }
                  quarterScores[quarterNum] = tempScoresMap;
                });

                // Update team names in all existing game commentary events
                for (var event in gameCommentary) {
                  if (event.teamName == oldName) {
                    // Note: This relies on GameEvent having mutable properties or a copyWith
                    // Since it's final, we'd ideally recreate the event.
                    // For simplicity in this example, and assuming commentary is a log,
                    // we'll leave past events as is or need to redesign GameEvent.
                    // If strict historical team names in commentary are required,
                    // GameEvent would need to store original team names OR you'd deep copy the list and modify.
                  }
                }

              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPlayerName(Player player) {
    TextEditingController controller = TextEditingController(text: player.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Player Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                player.name = controller.text.trim().isEmpty ? 'Player ${player.jerseyNumber}' : controller.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editNames() {
    List<Player> allTeamPlayers = selectedTeam == 1 ? team1Players : team2Players;
    Color teamColor = selectedTeam == 1 ? getTeamColor(team1Color) : getTeamColor(team2Color);
    String teamName = selectedTeam == 1 ? '$team1Name (${getTeamColorName(team1Color)})' : '$team2Name (${getTeamColorName(team2Color)})';

    showDialog(
      context: context,
      builder: (context) => EditPlayersDialog(
        players: allTeamPlayers,
        teamColor: teamColor,
        teamName: teamName,
        onSave: (updated) {
          setState(() {
            if (selectedTeam == 1) {
              team1Players = updated;
            } else {
              team2Players = updated;
            }
          });
        },
      ),
    );
  }

  void _changeTeamColor(int teamId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Team $teamId Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TeamColor.values.map((color) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: getTeamColor(color),
                radius: 12,
              ),
              title: Text(getTeamColorName(color)),
              onTap: () {
                setState(() {
                  if (teamId == 1) {
                    team1Color = color;
                  } else {
                    team2Color = color;
                  }
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubstitutionDialog() {
    List<Player> currentPlayers = selectedTeam == 1 ? team1Players : team2Players;
    String teamNameForSub = selectedTeam == 1 ? team1Name : team2Name; // Use the actual team name
    Color teamColor = selectedTeam == 1 ? getTeamColor(team1Color) : getTeamColor(team2Color);


    showDialog(
      context: context,
      builder: (context) => SubstitutionDialog(
        players: currentPlayers,
        teamColor: teamColor,
        teamName: teamNameForSub,
        onSaveSubstitutions: (updatedPlayers, playersOutNames, playersInNames) {
          setState(() {
            if (selectedTeam == 1) {
              team1Players = updatedPlayers;
            } else {
              team2Players = updatedPlayers;
            }
            gameCommentary.add(GameEvent.substitution(
              teamName: teamNameForSub,
              playersOutNames: playersOutNames,
              playersInNames: playersInNames,
            ));
          });
        },
      ),
    );
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Game'),
        content: Text('Are you sure you want to reset the entire game? This will clear all scores and fouls.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var player in team1Players) {
                  player.points = 0;
                  player.fouls = 0;
                  player.isOnCourt = player.isStarter;
                  player.actionHistory.clear();
                }
                for (var player in team2Players) {
                  player.points = 0;
                  player.fouls = 0;
                  player.isOnCourt = player.isStarter;
                  player.actionHistory.clear();
                }
                currentQuarter = 0;

                quarterScores = {
                  1: {},
                  2: {},
                  3: {},
                  4: {},
                };
                _currentQuarterPoints = {
                  team1Name: 0,
                  team2Name: 0,
                };
                quarterScores[1] = {
                  team1Name: 0,
                  team2Name: 0,
                };
                gameCommentary.clear();
                gameCommentary.add(GameEvent.gameStart());
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCommentaryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentaryScreen(
          events: List.from(gameCommentary),
          team1Name: team1Name,
          team2Name: team2Name,
        ),
      ),
    );
  }

  void _showMatchSummary() {
    if (currentQuarter >= 0 && currentQuarter <= 3) {
      quarterScores[currentQuarter + 1] = {
        team1Name: _currentQuarterPoints[team1Name]!,
        team2Name: _currentQuarterPoints[team2Name]!,
      };
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          team1Name: team1Name,
          team2Name: team2Name,
          team1Color: getTeamColorName(team1Color),
          team2Color: getTeamColorName(team2Color),
          team1Players: team1Players,
          team2Players: team2Players,
          quarterScores: quarterScores,
          team1Score: team1Score,
          team2Score: team2Score,
        ),
      ),
    );
  }

  void _endMatch() {
    _showMatchSummary();
  }

  void _setQuarter(int newQuarterIndex) {
    setState(() {
      if (newQuarterIndex != currentQuarter && currentQuarter >= 0 && currentQuarter <= 3) {
        quarterScores[currentQuarter + 1] = {
          team1Name: _currentQuarterPoints[team1Name]!,
          team2Name: _currentQuarterPoints[team2Name]!,
        };
        gameCommentary.add(GameEvent.quarterEnd(quarter: currentQuarter + 1));

        _currentQuarterPoints = {
          team1Name: 0,
          team2Name: 0,
        };
      }
      currentQuarter = newQuarterIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Player> currentPlayers = selectedTeam == 1 ? team1Players : team2Players;
    List<Player> currentPlayersOnCourt = currentPlayers.where((p) => p.isOnCourt).toList();
    Color currentTeamColor = selectedTeam == 1 ? getTeamColor(team1Color) : getTeamColor(team2Color);

    return Scaffold(
      appBar: AppBar(
        title: Text('Basketball Scorer'),
        actions: [
          IconButton(
            icon: Icon(Icons.comment),
            onPressed: _showCommentaryScreen,
            tooltip: 'View Commentary',
          ),
          IconButton(
            icon: Icon(Icons.assessment),
            onPressed: _showMatchSummary,
            tooltip: 'Match Summary',
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editNames,
          ),
          IconButton(
            icon: Icon(Icons.drive_file_rename_outline),
            onPressed: () => _editTeamName(selectedTeam),
          ),
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: _showSubstitutionDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Score Header - START
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [getTeamColor(team1Color), Colors.grey[800]!, getTeamColor(team2Color)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _changeTeamColor(1),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: getTeamColor(team1Color).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _editTeamName(1),
                              child: Text('$team1Name (${getTeamColorName(team1Color)})', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.color_lens, color: Colors.white, size: 16),
                          ],
                        ),
                        Text('$team1Score', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text('Quarter ${currentQuarter + 1}', style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text('VS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Q${currentQuarter + 1} Points: ${_currentQuarterPoints[team1Name] ?? 0} - ${_currentQuarterPoints[team2Name] ?? 0}',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _changeTeamColor(2),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: getTeamColor(team2Color).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _editTeamName(2),
                              child: Text('$team2Name (${getTeamColorName(team2Color)})', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.color_lens, color: Colors.white, size: 16),
                          ],
                        ),
                        Text('$team2Score', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Score Header - END

          // Quarter Selection
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _setQuarter(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentQuarter == i ? Colors.orange : Colors.grey[300],
                      foregroundColor: currentQuarter == i ? Colors.white : Colors.black,
                    ),
                    child: Text('Q${i + 1}'),
                  ),
                );
              }),
            ),
          ),

          // End Match Button (appears in Q4)
          if (currentQuarter == 3)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _endMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('End Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

          // Team Selection Tabs
          Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTeam = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedTeam == 1 ? getTeamColor(team1Color) : Colors.grey[200],
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTeam == 1 ? getTeamColor(team1Color) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '$team1Name (${getTeamColorName(team1Color)})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTeam == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTeam = 2),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedTeam == 2 ? getTeamColor(team2Color) : Colors.grey[200],
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTeam == 2 ? getTeamColor(team2Color) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '$team2Name (${getTeamColorName(team2Color)})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTeam == 2 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // On Court Players Section
          Container(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Players On Court (${currentPlayersOnCourt.length}/5)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showSubstitutionDialog,
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Substitute'),
                  style: ElevatedButton.styleFrom(backgroundColor: currentTeamColor),
                ),
              ],
            ),
          ),

          // Players List (Only showing players on court)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: currentPlayersOnCourt.length,
              itemBuilder: (context, index) {
                final player = currentPlayersOnCourt[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: currentTeamColor,
                          child: Text('${player.jerseyNumber}', style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _editPlayerName(player),
                                    child: Text(player.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  if (player.actionHistory.isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.undo, size: 18, color: Colors.grey[600]),
                                      onPressed: () => _undoLastAction(player),
                                      tooltip: 'Undo Last Action',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text('Points: ${player.points} | Fouls: ${player.fouls}'),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _addPoints(player, 1),
                                    child: Text('1pt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      foregroundColor: Colors.black, // Ensure text color is set
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addPoints(player, 2),
                                    child: Text('2pt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addPoints(player, 3),
                                    child: Text('3pt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addFoul(player),
                                    child: Text('Foul'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}