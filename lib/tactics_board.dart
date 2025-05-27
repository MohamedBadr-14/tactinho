import 'package:flutter/material.dart';
import 'package:tactinho/football_field.dart';
import 'package:tactinho/tactics_generation.dart';

class TacticsBoard extends StatefulWidget {
  const TacticsBoard({super.key});

  @override
  _TacticsBoardState createState() => _TacticsBoardState();
}

class _TacticsBoardState extends State<TacticsBoard> {
  List<PlayerFormation> fieldPlayers = [];
  var has_Ball = false;
  var goalkeeper_selected = false;
  // Add variables to track mouse position
  Offset? _mousePosition;
  List<double>? _transformedPosition;

  void _undoLastPlayer() {
    if (fieldPlayers.isNotEmpty) {
      final lastPlayer = fieldPlayers.last;
      if (lastPlayer.ballpossession) {
        has_Ball = false; // Reset ball possession if last player had it
      }
      if (lastPlayer.number == 3) {
        goalkeeper_selected =
            false; // Reset goalkeeper selection if last player was the goalkeeper
      }
      setState(() {
        fieldPlayers.removeLast();
      });
    }
  }

  void _clearPlayers() {
    has_Ball = false;
    goalkeeper_selected = false; // Reset goalkeeper selection
    setState(() {
      fieldPlayers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Column(
        children: [
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
                        backgroundColor: Color(0xFF1E6C41),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _undoLastPlayer,
                      child: const Text(
                        'Undo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                // Bench Players
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: List.generate(3, (index) {
                          final player = PlayerFormation(
                            color: Colors.primaries[index],
                            number: index + 1,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: player.number == 3 && goalkeeper_selected
                                ? Opacity(
                                    opacity: 0.4,
                                    child: PlayerCircle(
                                      color: player.color,
                                      number: player.number,
                                    ),
                                  )
                                : Draggable<PlayerFormation>(
                                    data: player,
                                    feedback: PlayerCircle(
                                      color: player.color,
                                      number: player.number,
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.4,
                                      child: PlayerCircle(
                                        color: player.color,
                                        number: player.number,
                                      ),
                                    ),
                                    child: PlayerCircle(
                                      color: player.color,
                                      number: player.number,
                                    ),
                                  ),
                          );
                        }),
                      );
                    },
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
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: _clearPlayers,
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
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
                    // Mouse listener for tracking position
                    MouseRegion(
                      onHover: (event) {
                        final localOffset = event.localPosition;
                        final dx = (localOffset.dx / fieldSize.width).clamp(0.0, 1.0);
                        final dy = (localOffset.dy / fieldSize.height).clamp(0.0, 1.0);
                        
                        // Update without forcing a full rebuild
                        if (mounted) {
                          setState(() {
                            _mousePosition = localOffset;
                            _transformedPosition = [
                              60 - (dy * 60),  // y-coordinate (0-60)
                              dx * 90,         // x-coordinate (0-90)
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
                                    MediaQuery.of(context).padding.top,
                              );
                          final dx =
                              (localOffset.dx / fieldSize.width).clamp(0.0, 1.0);
                          final dy =
                              (localOffset.dy / fieldSize.height).clamp(0.0, 1.0);

                          final positionTransformed = [
                            60 - (dy * 60),
                            dx * 90
                          ];
                          setState(() {
                            // print(fieldPlayers);
                            if (details.data.number == 3 &&
                                !goalkeeper_selected) {
                              goalkeeper_selected = true;
                            }
                            fieldPlayers.add(
                              details.data.copyWith(
                                position: Offset(dx, dy),
                              ),
                            );
                          });
                          print('Player added: ${details.data.number} at position: $positionTransformed');
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
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (player.ballpossession) {
                                // Remove possession if player already has it
                                has_Ball = false;
                                fieldPlayers[index] =
                                    player.copyWith(ballpossession: false);
                              } else {
                                // Remove from all players
                                if (player.number == 1) {
                                  for (int i = 0;
                                      i < fieldPlayers.length;
                                      i++) {
                                    fieldPlayers[i] = fieldPlayers[i]
                                        .copyWith(ballpossession: false);
                                  }
                                }
                                // Give possession to this player
                                if (player.number == 1) {
                                  has_Ball = true;

                                  fieldPlayers[index] =
                                      player.copyWith(ballpossession: true);
                                }
                              }
                            });
                          },
                          child: PlayerCircle(
                            color: player.color,
                            number: player.number,
                            highlight: player.ballpossession,
                          ),
                        ),
                      );
                    }),
                    
                    // Display position coordinates tooltip
                    if (_mousePosition != null && _transformedPosition != null)
                      Positioned(
                        left: _mousePosition!.dx + 10,
                        top: _mousePosition!.dy - 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Bottom Bar
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: 60,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6C41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (!has_Ball) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.sports_soccer, color: Colors.green),
                            SizedBox(width: 8),
                            Text('No Player Selected'),
                          ],
                        ),
                        content: const Text(
                          'Please select a player who currently has the ball '
                          'before proceeding.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => PrecacheScreen(
                            scene: fieldPlayers), // Replace with your widget
                      ),
                    );
                  }
                },
                child: const Text(
                  'Generate Tactics',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ...existing code...

// Player Model
class PlayerFormation {
  final Color color;
  final int number;
  final Offset position;
  final bool ballpossession;

  PlayerFormation({
    required this.color,
    required this.number,
    this.position = Offset.zero,
    this.ballpossession = false,
  });

  PlayerFormation copyWith({
    Color? color,
    int? number,
    Offset? position,
    bool? ballpossession,
  }) {
    return PlayerFormation(
      color: color ?? this.color,
      number: number ?? this.number,
      position: position ?? this.position,
      ballpossession: ballpossession ?? this.ballpossession,
    );
  }
}

// Player Dot Widget
class PlayerCircle extends StatelessWidget {
  final Color color;
  final int number;
  final bool highlight;
  final bool inside;

  const PlayerCircle({
    required this.color,
    required this.number,
    this.highlight = false,
    this.inside = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.03,
      height: MediaQuery.sizeOf(context).height * 0.03,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (number == 1)
            ? const Color.fromARGB(255, 255, 255, 0)
            : (number == 2)
                ? const Color.fromARGB(255, 255, 55, 0)
                : const Color.fromARGB(255, 27, 3, 249),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? Colors.red : Colors.white,
          width: 3,
        ),
      ),
    );
  }
}

// Field Painter
