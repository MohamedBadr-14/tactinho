import 'package:flutter/material.dart';
import 'package:tactinho/football_field.dart';
import 'package:tactinho/tactics_generation.dart';





class TacticsBoard extends StatefulWidget {
  const TacticsBoard({super.key});

  @override
  _TacticsBoardState createState() => _TacticsBoardState();
}

class _TacticsBoardState extends State<TacticsBoard> {
  List<Player> fieldPlayers = [];

  void _undoLastPlayer() {
    if (fieldPlayers.isNotEmpty) {
      setState(() {
        fieldPlayers.removeLast();
      });
    }
  }

  void _clearPlayers() {
    setState(() {
      fieldPlayers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
        color: Colors.green,
        child: Column(
          children: [
            // Top Controls
            Container(
              color: const Color.fromARGB(255, 216, 206, 206),
              padding: EdgeInsets.symmetric(vertical: 8),
              height: 60,
              child: Row(
                children: [
                  // Undo Button
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child:  ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:Color(0xFF1E6C41),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: 
       _undoLastPlayer,
      
      child: Text(
        'Undo',
        style: TextStyle(color: Colors.white),
      ),
    ),
                    ),
                  ),
                  // Bench Players
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        final player = Player(
                          color: Colors.primaries[index],
                          number: index + 1,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Draggable<Player>(
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
                    ),
                  ),
                  // Clear Button
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child:  ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:Color(0xFF1E6C41),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: 
       _clearPlayers,
      
      child: Text(
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
                      // Drag Target
                      DragTarget<Player>(
                        onAcceptWithDetails: (details) {
                          final localOffset = details.offset -
                              Offset(
                                0,
                                AppBar().preferredSize.height +
                                    MediaQuery.of(context).padding.top 
                                  ,
                              );
                          final dx = (localOffset.dx / fieldSize.width)
                              .clamp(0.0, 1.0);
                          final dy = (localOffset.dy / fieldSize.height)
                              .clamp(0.0, 1.0);

                          setState(() {
                            print(fieldPlayers);
                            fieldPlayers.add(
                              details.data.copyWith(
                                position: Offset(dx, dy),
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
                                    }}
                                  // Give possession to this player
                          if (player.number == 1) {
  fieldPlayers[index] = player.copyWith(ballpossession: true);
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
                    ],
                  );
                },
              ),
            ),

            // Bottom Bar
            Container(
  color: const Color.fromARGB(255, 255, 255, 255),
  padding: EdgeInsets.symmetric(vertical: 8),
  height: 60,
  child: Center(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:Color(0xFF1E6C41),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PrecacheScreen(), // Replace with your widget
          ),
        );
      },
      child: Text(
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

// Player Model
class Player {
  final Color color;
  final int number;
  final Offset position;
  final bool ballpossession;

  Player({
    required this.color,
    required this.number,
    this.position = Offset.zero,
    this.ballpossession = false,
  });

  Player copyWith({
    Color? color,
    int? number,
    Offset? position,
    bool? ballpossession,
  }) {
    return Player(
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
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (number == 1)
            ? const Color.fromARGB(255, 255, 255, 0)
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
