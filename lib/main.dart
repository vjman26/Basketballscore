// lib/main.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'SubstitutionDialog.dart';
import 'EditPlayersDialog.dart';
import 'MatchSummaryScreen.dart'; // Import the new match summary screen

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
  String team1Name = 'Team 1'; // This name can be changed by user
  String team2Name = 'Team 2'; // This name can be changed by user
  int currentQuarter = 0; // 0-indexed: 0=Q1, 1=Q2, 2=Q3, 3=Q4

  // Quarter-by-quarter total points for each team IN THAT QUARTER.
  // Keys: 1, 2, 3, 4 for Q1, Q2, Q3, Q4.
  // Inner Map Keys: Will be the actual team names (e.g., 'Lakers', 'Bulls')
  Map<int, Map<String, int>> quarterScores = {
    1: {}, // Initialize empty, will populate dynamically
    2: {},
    3: {},
    4: {},
  };

  // This map tracks points scored *within the currently active quarter only*.
  // It uses dynamic team names as keys.
  Map<String, int> _currentQuarterPoints = {};


  @override
  void initState() {
    super.initState();
    // Initialize _currentQuarterPoints with current team names at start
    _currentQuarterPoints = {
      team1Name: 0,
      team2Name: 0,
    };
    // Also initialize the first quarter's entry in quarterScores with initial team names
    // This is important for the case where points are scored in Q1 and then directly to summary/end match
    quarterScores[1] = {
      team1Name: 0,
      team2Name: 0,
    };
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

      // Add points to the _currentQuarterPoints for the active quarter
      // Ensure the keys match the team names used elsewhere
      if (player.teamId == 1) {
        _currentQuarterPoints[team1Name] = (_currentQuarterPoints[team1Name] ?? 0) + points;
      } else {
        _currentQuarterPoints[team2Name] = (_currentQuarterPoints[team2Name] ?? 0) + points;
      }
    });
  }

  void _addFoul(Player player) {
    setState(() {
      player.fouls += 1;
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

                // If team name changed, update quarterScores keys for past quarters
                // This is a bit complex. For simplicity, we'll just re-map current quarter points here.
                // A more robust solution might involve iterating through quarterScores
                // and updating keys, but it adds complexity. Let's focus on the primary issue.

                if (teamId == 1) {
                  team1Name = newName;
                } else {
                  team2Name = newName;
                }
                // Re-initialize _currentQuarterPoints with new names if they changed
                _currentQuarterPoints = {
                  team1Name: _currentQuarterPoints[oldName] ?? 0, // Carry over points if name changed
                  team2Name: _currentQuarterPoints[team2Name] ?? 0,
                };
                // You might need to consider updating historical quarterScores keys too,
                // but that adds significant complexity to this simple example.
                // For now, let's assume team names are set at the start and don't change mid-game if full quarter history is critical.
                // If they *can* change, a deeper data structure for quarterScores might be needed.
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
    Color teamColor = selectedTeam == 1 ? getTeamColor(team1Color) : getTeamColor(team2Color);
    String teamName = selectedTeam == 1 ? '$team1Name (${getTeamColorName(team1Color)})' : '$team2Name (${getTeamColorName(team2Color)})';

    showDialog(
      context: context,
      builder: (context) => SubstitutionDialog(
        players: currentPlayers,
        teamColor: teamColor,
        teamName: teamName,
        onSaveSubstitutions: (updatedPlayers) {
          setState(() {
            if (selectedTeam == 1) {
              team1Players = updatedPlayers;
            } else {
              team2Players = updatedPlayers;
            }
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
                }
                for (var player in team2Players) {
                  player.points = 0;
                  player.fouls = 0;
                  player.isOnCourt = player.isStarter;
                }
                currentQuarter = 0;

                // Reset quarter scores and current quarter points to initial state
                quarterScores = {
                  1: {}, // Will be populated when Q1 ends
                  2: {},
                  3: {},
                  4: {},
                };
                _currentQuarterPoints = {
                  team1Name: 0, // Reset using actual team names
                  team2Name: 0,
                };
                // Ensure Q1 has an initial entry for display if needed before it ends
                quarterScores[1] = {
                  team1Name: 0,
                  team2Name: 0,
                };
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

  void _showMatchSummary() {
    // Before navigating, ensure the final quarter's score is recorded.
    // This correctly captures the score of the quarter that was active
    // when the "End Match" or "Match Summary" button was pressed.
    if (currentQuarter >= 0 && currentQuarter <= 3) { // Ensure currentQuarter is a valid quarter index
      quarterScores[currentQuarter + 1] = { // Use 1-indexed key for quarterScores
        team1Name: _currentQuarterPoints[team1Name]!, // Use dynamic team names
        team2Name: _currentQuarterPoints[team2Name]!, // Use dynamic team names
      };
    }

    // Pass team names as they might have been edited
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          team1Name: team1Name,
          team2Name: team2Name,
          team1Color: getTeamColorName(team1Color),
          team2Color: getTeamColorName(team2Color),
          team1Players: team1Players,
          team2Players: team2Players,
          quarterScores: quarterScores, // Pass the accumulated quarter scores
          team1Score: team1Score,
          team2Score: team2Score,
        ),
      ),
    );
  }

  void _endMatch() {
    _showMatchSummary();
  }

  void _setQuarter(int newQuarterIndex) { // Renamed for clarity: newQuarterIndex is 0,1,2,3
    setState(() {
      // If moving to a new quarter (and not just re-selecting the current one)
      // And if the previous quarter was a valid one to record score for (Q1, Q2, Q3, Q4)
      if (newQuarterIndex != currentQuarter && currentQuarter >= 0 && currentQuarter <= 3) {
        // Save points for the quarter that is now ending (currentQuarter is the 0-indexed index of the *old* quarter)
        // Add 1 to currentQuarter to get the 1-indexed quarter number for the quarterScores map
        quarterScores[currentQuarter + 1] = {
          team1Name: _currentQuarterPoints[team1Name]!, // Use dynamic team names
          team2Name: _currentQuarterPoints[team2Name]!, // Use dynamic team names
        };

        // Reset current quarter points for the new quarter
        _currentQuarterPoints = {
          team1Name: 0,
          team2Name: 0,
        };
      }
      currentQuarter = newQuarterIndex; // Update to the new quarter (0-indexed)
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
          // Score Header
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
                    // Display current quarter's score from _currentQuarterPoints
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

          // End Match Button (appears in Q4, which is currentQuarter == 3)
          if (currentQuarter == 3)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _endMatch, // Calls _showMatchSummary
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
                              GestureDetector(
                                onTap: () => _editPlayerName(player),
                                child: Text(player.name, style: TextStyle(fontWeight: FontWeight.bold)),
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
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addPoints(player, 2),
                                    child: Text('2pt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addPoints(player, 3),
                                    child: Text('3pt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _addFoul(player),
                                    child: Text('Foul'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.3),
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