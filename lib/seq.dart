import 'package:flutter/material.dart';
import 'package:tactinho/football_field.dart';
import 'package:tactinho/goal.dart';
import 'dart:convert';

class SequenceBuilder extends StatefulWidget {
  const SequenceBuilder({super.key});

  @override
  _SequenceBuilderState createState() => _SequenceBuilderState();
}

class _SequenceBuilderState extends State<SequenceBuilder> {
  List<SceneData> scenes = [];
  int currentSceneIndex = 0;
  List<PlayerFormation> fieldPlayers = [];
  var has_Ball = false;
  int yellowPlayerCount = 0;
  int redPlayerCount = 0;
  int bluePlayerCount = 0;

  // Controllers for action input
  final TextEditingController _actionController = TextEditingController();

  // Add variables to track mouse position
  Offset? _mousePosition;
  List<double>? _transformedPosition;

  @override
  void initState() {
    super.initState();
    _addGoalkeeper();
    _createNewScene();
  }

  void _createNewScene() {
    scenes.add(SceneData(
      players: {},
      ball: {},
      action: 0,
      fieldPlayers: List.from(fieldPlayers),
    ));
    currentSceneIndex = scenes.length - 1;
  }

  void _addGoalkeeper() {
    setState(() {
      fieldPlayers.add(
        PlayerFormation(
          color: const Color.fromARGB(
              255, 27, 3, 249), // Blue color for goalkeeper
          number: 3, // Goalkeeper number
          position: const Offset(0.485, 0.02), // Fixed position near top goal
          playerId: "goalkeeper_1",
          team: 1,
        ),
      );
      bluePlayerCount++;
    });
  }

  void _undoLastPlayer() {
    if (fieldPlayers.isNotEmpty) {
      final lastPlayer = fieldPlayers.last;

      // Don't remove the goalkeeper
      if (lastPlayer.number == 3 && lastPlayer.playerId == "goalkeeper_1") {
        return;
      }

      if (lastPlayer.ballpossession) {
        has_Ball = false;
      }

      // Update player counts
      if (lastPlayer.number == 1) {
        yellowPlayerCount--;
      } else if (lastPlayer.number == 2) {
        redPlayerCount--;
      } else if (lastPlayer.number == 4) {
        bluePlayerCount--;
      }

      setState(() {
        fieldPlayers.removeLast();
      });
    }
  }

  void _clearPlayers() {
    has_Ball = false;
    yellowPlayerCount = 0;
    redPlayerCount = 0;
    bluePlayerCount = 1; // Keep goalkeeper count

    setState(() {
      // Remove all players except the goalkeeper
      fieldPlayers.removeWhere((player) =>
          !(player.number == 3 && player.playerId == "goalkeeper_1"));

      // If goalkeeper was somehow removed, add it back
      if (fieldPlayers.isEmpty) {
        _addGoalkeeper();
      }
    });
  }

  void _updatePlayerPosition(
      int playerIndex, Offset newPosition, Size fieldSize) {
    final dx = newPosition.dx.clamp(0.0, 1.0);
    final dy = newPosition.dy.clamp(0.0, 1.0);
    final dxx = ((dx * 90 * (2 / 3)) + 15.0);
    final positionTransformed = [60 - (dy * 60), dxx];

    setState(() {
      fieldPlayers[playerIndex] = fieldPlayers[playerIndex].copyWith(
        position: Offset(dx, dy),
      );
    });

    print(
        'Player ${fieldPlayers[playerIndex].number} moved to position: $positionTransformed');
  }

  void _saveCurrentScene() {
    if (scenes.isEmpty) return;

    final currentScene = scenes[currentSceneIndex];
    final players = <String, Map<String, dynamic>>{};
    final ball = <String, Map<String, dynamic>>{};

    fieldPlayers.removeWhere(
        (player) => player.playerId == "goalkeeper_1");
    // Convert field players to the required format
    for (int i = 0; i < fieldPlayers.length; i++) {
      final player = fieldPlayers[i];
      final dx = player.position.dx;
      final dy = player.position.dy;
      final dxx = ((dx * 90 * (2 / 3)) + 15.0);
      final positionTransformed = [60 - (dy * 60), dxx];

      // Calculate mock bbox and position (you can adjust these calculations)
      final mockX = (dx * 1000).round();
      final mockY = (dy * 700).round();

      players[i.toString()] = {
        "team": player.team,
        "position_transformed": positionTransformed,
        "has_ball": player.ballpossession,
        // "bbox": [mockX, mockY, mockX + 50, mockY + 80],
        // "position": [mockX + 25, mockY + 80],
      };

      // Add ball data if this player has the ball
      if (player.ballpossession) {
        ball["1"] = {
          "conf": 0.11,
          "position_transformed": positionTransformed,
          "bbox": [mockX + 10.0, mockY + 60.0, mockX + 20.0, mockY + 70.0],
          "position": [mockX + 15, mockY + 65],
        };
      }
    }

    // Update the current scene
    scenes[currentSceneIndex] = currentScene.copyWith(
      players: players,
      ball: ball,
      action: int.tryParse(_actionController.text) ?? 0,
      fieldPlayers: List.from(fieldPlayers),
    );
  }

  void _nextScene() {
    _saveCurrentScene();
    _createNewScene();
    setState(() {
      // Keep the same players for the next scene
      _actionController.clear();
    });
  }

  void _previousScene() {
    if (currentSceneIndex > 0) {
      _saveCurrentScene();
      setState(() {
        currentSceneIndex--;
        final scene = scenes[currentSceneIndex];
        fieldPlayers = List.from(scene.fieldPlayers);
        _actionController.text = scene.action.toString();

        // Update player counts
        _updatePlayerCounts();
      });
    }
  }

  void _updatePlayerCounts() {
    yellowPlayerCount = fieldPlayers.where((p) => p.number == 1).length;
    redPlayerCount = fieldPlayers.where((p) => p.number == 2).length;
    bluePlayerCount =
        fieldPlayers.where((p) => p.number == 3 || p.number == 4).length;
    has_Ball = fieldPlayers.any((p) => p.ballpossession);
  }

  void _endSequence() {
    _saveCurrentScene();
    // if           playerId: "goalkeeper_1", delete goalkeeper from the fieldPlayers list

    // Convert scenes to the required JSON format
    final List<Map<String, dynamic>> jsonScenes = scenes
        .map((scene) => {
              "players": scene.players,
              "action": scene.action,
            })
        .toList();

    final jsonData = [jsonScenes];
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Show the JSON in a dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generated Sequence JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E6C41),
      body: Column(
        children: [
          // Scene Info Bar
          Container(
            color: const Color.fromARGB(255, 100, 100, 100),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            height: 60,
            child: Row(
              children: [
                Text(
                  'Scene ${currentSceneIndex + 1} of ${scenes.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _actionController,
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),

          // Top Controls
          Container(
            color: const Color.fromARGB(255, 216, 206, 206),
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: 60,
            child: Row(
              children: [
                // Undo Button
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6C41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onPressed: _undoLastPlayer,
                      child: const Text('Undo', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                // Bench Players
                Expanded(
                  flex: 2,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      // Yellow players (Team 1)
                      ...List.generate(1, (index) {
                        final player = PlayerFormation(
                          color: const Color.fromARGB(255, 255, 255, 0),
                          number: 1,
                          team: 1,
                          playerId: "yellow_${yellowPlayerCount + 1}",
                        );
                        return yellowPlayerCount >= 4
                            ? Opacity(
                                opacity: 0.4,
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              )
                            : Draggable<PlayerFormation>(
                                data: player,
                                feedback: PlayerCircle(
                                    color: player.color, number: player.number),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: PlayerCircle(
                                      color: player.color,
                                      number: player.number),
                                ),
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              );
                      }),
                      // Red players (Team 0)
                      ...List.generate(1, (index) {
                        final player = PlayerFormation(
                          color: const Color.fromARGB(255, 255, 55, 0),
                          number: 2,
                          team: 0,
                          playerId: "red_${redPlayerCount + 1}",
                        );
                        return redPlayerCount >= 4
                            ? Opacity(
                                opacity: 0.4,
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              )
                            : Draggable<PlayerFormation>(
                                data: player,
                                feedback: PlayerCircle(
                                    color: player.color, number: player.number),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: PlayerCircle(
                                      color: player.color,
                                      number: player.number),
                                ),
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              );
                      }),
                      // Blue players (Team 1)
                      ...List.generate(0, (index) {
                        final player = PlayerFormation(
                          color: const Color.fromARGB(255, 27, 3, 249),
                          number: 4,
                          team: 1,
                          playerId: "blue_${bluePlayerCount + 1}",
                        );
                        return bluePlayerCount >= 3
                            ? Opacity(
                                opacity: 0.4,
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              )
                            : Draggable<PlayerFormation>(
                                data: player,
                                feedback: PlayerCircle(
                                    color: player.color, number: player.number),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: PlayerCircle(
                                      color: player.color,
                                      number: player.number),
                                ),
                                child: PlayerCircle(
                                    color: player.color, number: player.number),
                              );
                      }),
                    ],
                  ),
                ),
                // Clear Button
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6C41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onPressed: _clearPlayers,
                      child:
                          const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Goal Area
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldSize = constraints.biggest;
                return Stack(
                  children: [
                    CustomPaint(
                      size: fieldSize,
                      painter: Goal(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Football Field
          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldSize = constraints.biggest;
                return Stack(
                  children: [
                    // Mouse listener and drag target
                    MouseRegion(
                      onHover: (event) {
                        final localOffset = event.localPosition;
                        final dx =
                            (localOffset.dx / fieldSize.width).clamp(0.0, 1.0);
                        final dy =
                            (localOffset.dy / fieldSize.height).clamp(0.0, 1.0);

                        if (mounted) {
                          setState(() {
                            _mousePosition = localOffset;
                            _transformedPosition = [
                              60 - (dy * 60),
                              dx * 90,
                            ];
                          });
                        }
                      },
                      onExit: (event) {
                        if (mounted) {
                          setState(() {
                            _mousePosition = null;
                            _transformedPosition = null;
                          });
                        }
                      },
                      child: DragTarget<PlayerFormation>(
                        onAcceptWithDetails: (details) {
                          final localOffset = details.offset -
                              Offset(
                                0,
                                AppBar().preferredSize.height +
                                    MediaQuery.of(context).padding.top +
                                    60 +
                                    MediaQuery.of(context).size.height * 0.2,
                              );
                          var dx = (localOffset.dx / fieldSize.width)
                              .clamp(0.0, 1.0);
                          final dy = (localOffset.dy / fieldSize.height)
                              .clamp(0.0, 1.0);

                          setState(() {
                            // Update player counts
                            if (details.data.number == 1) {
                              yellowPlayerCount++;
                            } else if (details.data.number == 2) {
                              redPlayerCount++;
                            } else if (details.data.number == 4) {
                              bluePlayerCount++;
                            }

                            fieldPlayers.add(
                              details.data.copyWith(
                                position: Offset(dx, dy),
                                playerId:
                                    "${details.data.playerId}_${fieldPlayers.length}",
                              ),
                            );
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return CustomPaint(
                            size: fieldSize,
                            painter: HalfFootballFieldPainter(),
                          );
                        },
                      ),
                    ),

                    // Draw Players
                    ...fieldPlayers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      final position = Offset(
                        player.position.dx * fieldSize.width,
                        player.position.dy * fieldSize.height,
                      );

                      return Positioned(
                        left: position.dx,
                        top: position.dy,
                        child: Draggable<PlayerRepositionData>(
                          data: PlayerRepositionData(
                            player: player,
                            playerIndex: index,
                          ),
                          feedback: Transform.scale(
                            scale: 1.2,
                            child: PlayerCircle(
                              color: player.color,
                              number: player.number,
                              highlight: player.ballpossession,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: PlayerCircle(
                              color: player.color,
                              number: player.number,
                              highlight: player.ballpossession,
                            ),
                          ),
                          onDragEnd: (details) {
                            final localOffset = details.offset -
                                Offset(
                                  0,
                                  AppBar().preferredSize.height +
                                      60 +
                                      MediaQuery.of(context).padding.top +
                                      MediaQuery.of(context).size.height * 0.2,
                                );

                            var dx = (localOffset.dx / fieldSize.width)
                                .clamp(0.0, 1.0);
                            final dy = (localOffset.dy / fieldSize.height)
                                .clamp(0.0, 1.0);

                            if (dx >= 0.0 &&
                                dx <= 1.0 &&
                                dy >= 0.0 &&
                                dy <= 1.0) {
                              _updatePlayerPosition(
                                  index, Offset(dx, dy), fieldSize);
                            }
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (player.ballpossession) {
                                  has_Ball = false;
                                  fieldPlayers[index] =
                                      player.copyWith(ballpossession: false);
                                } else {
                                  // Remove ball from all players
                                  for (int i = 0;
                                      i < fieldPlayers.length;
                                      i++) {
                                    fieldPlayers[i] = fieldPlayers[i]
                                        .copyWith(ballpossession: false);
                                  }
                                  // Give ball to this player
                                  has_Ball = true;
                                  fieldPlayers[index] =
                                      player.copyWith(ballpossession: true);
                                }
                              });
                            },
                            child: PlayerCircle(
                              color: player.color,
                              number: player.number,
                              highlight: player.ballpossession,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Position tooltip
                    if (_mousePosition != null && _transformedPosition != null)
                      Positioned(
                        left: _mousePosition!.dx + 10,
                        top: _mousePosition!.dy - 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'X: ${_transformedPosition![0].toStringAsFixed(1)}, Y: ${_transformedPosition![1].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Bottom Controls
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentSceneIndex > 0
                        ? const Color(0xFF1E6C41)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: currentSceneIndex > 0 ? _previousScene : null,
                  child: const Text('Previous Scene'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6C41),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _nextScene,
                  child: const Text('Next Scene'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _endSequence,
                  child: const Text('End Sequence'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes
class SceneData {
  final Map<String, Map<String, dynamic>> players;
  final Map<String, Map<String, dynamic>> ball;
  final int action;
  final List<PlayerFormation> fieldPlayers;

  SceneData({
    required this.players,
    required this.ball,
    required this.action,
    required this.fieldPlayers,
  });

  SceneData copyWith({
    Map<String, Map<String, dynamic>>? players,
    Map<String, Map<String, dynamic>>? ball,
    int? action,
    List<PlayerFormation>? fieldPlayers,
  }) {
    return SceneData(
      players: players ?? this.players,
      ball: ball ?? this.ball,
      action: action ?? this.action,
      fieldPlayers: fieldPlayers ?? this.fieldPlayers,
    );
  }
}

class PlayerRepositionData {
  final PlayerFormation player;
  final int playerIndex;

  PlayerRepositionData({
    required this.player,
    required this.playerIndex,
  });
}

class PlayerFormation {
  final Color color;
  final int number;
  final Offset position;
  final bool ballpossession;
  final String playerId;
  final int team;

  PlayerFormation({
    required this.color,
    required this.number,
    this.position = Offset.zero,
    this.ballpossession = false,
    required this.playerId,
    required this.team,
  });

  PlayerFormation copyWith({
    Color? color,
    int? number,
    Offset? position,
    bool? ballpossession,
    String? playerId,
    int? team,
  }) {
    return PlayerFormation(
      color: color ?? this.color,
      number: number ?? this.number,
      position: position ?? this.position,
      ballpossession: ballpossession ?? this.ballpossession,
      playerId: playerId ?? this.playerId,
      team: team ?? this.team,
    );
  }
}

class PlayerCircle extends StatelessWidget {
  final Color color;
  final int number;
  final bool highlight;

  const PlayerCircle({
    required this.color,
    required this.number,
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.03,
      height: MediaQuery.sizeOf(context).height * 0.03,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? Colors.red : Colors.white,
          width: 3,
        ),
      ),
    );
  }
}
