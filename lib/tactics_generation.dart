import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tactinho/football_field.dart';
import 'package:tactinho/loading.dart';
import 'package:tactinho/report.dart';
import 'package:tactinho/tactics_board.dart';
import 'package:tactinho/backend.dart';
import 'package:flutter/rendering.dart';
import 'package:tactinho/goal.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:tactinho/models/tactic_item.dart';

class PrecacheScreen extends StatefulWidget {
  final List<PlayerFormation> scene;
  const PrecacheScreen({Key? key, required this.scene}) : super(key: key);
  @override
  State<PrecacheScreen> createState() => _PrecacheScreenState();
}

class _PrecacheScreenState extends State<PrecacheScreen> {
  List<Image> pepFrames = [];
  bool _done = false;
  List<Player> currentPlayers = [];
  List<PlayerFormation> scene = [];
  String jsonString = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_done) {
      _precacheImages();
    }
  }

  Map<String, Map<dynamic, dynamic>> sceneToJson() {
    scene = widget.scene;
    final toSend = {
      "players": {},
      "referees": {},
      "ball": {},
      "goalkeeper": {},
      "goalpost": {}
    };
    var count = 0;
    bool has_Ball = false;
    for (var player in scene) {
      if (player.ballpossession) {
        
        has_Ball = true;
        toSend["ball"]?['1'] = {
          "conf": 0.11,
          "position_transformed": [
            60 - (player.position.dy * 60),
            player.position.dx * 90
          ]
        };
      }
      if (player.number == 3) {
        toSend["goalkeeper"]?['1'] = {
          "team": 0,
          "position_transformed": [
            60 - (player.position.dy * 60),
            player.position.dx * 90
          ]
        };
      } else {
        toSend["players"]?[count.toString()] = {
          "team": (player.number == 1) ? 1 : 0,
          "position_transformed": [
            60 - (player.position.dy * 60),
            player.position.dx * 90
          ],
          if (has_Ball) "has_ball": true,
        };
        has_Ball = false;
      }
      count++;
    }

    return toSend;
  }

  Future<void> _precacheImages() async {
    var jsonToSend = sceneToJson();
    // final jsonString = jsonEncode(jsonToSend);
    final response = await sendPlayerData(jsonToSend);
    if (response.length > 0) {
      jsonString = jsonEncode(response);

      setState(() {
        _done = true;
      });
    } else {
      // i want pop up here and navigate back to tactics board
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("No similar tactics found"),
            content: Text(
                "No similar tactics found. Please try again with different formations."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Navigate back to tactics board
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return TacticsRun(pepFrames: pepFrames, jsonString: jsonString);
    }
    return const LoadingScreen();
  }
}

class TacticsRun extends StatefulWidget {
  final List<Image> pepFrames;
  final String jsonString;
  TacticsRun({required this.pepFrames, required this.jsonString});

  @override
  _TacticsRunState createState() => _TacticsRunState();
}

class _TacticsRunState extends State<TacticsRun> {
  List<List<Player>> formations = [];
  // action values
  List<int> actions = [];
  List<Player> currentPlayers = [];
  int currentFormationIndex = 0;
  String _currentDescription = "";
  double _descriptionOpacity = 0.0;
  int _talkingFrameIndex = 0;
  Timer? _talkingAnimationTimer;
  late List<Image> _pepFrames;
  int counter = 0;
  Offset? ballPosition;
  List<TacticItem> tactics = [];

  final GlobalKey _fieldKey = GlobalKey();

  final List<String> _descriptions = [
    "Player 1 starts with the ball.",
    "Player 1 moves forward.",
    "Player 1 passes the ball to Player 2.",
    "Player 1 starts with the ball.",
    "Player 1 moves forward.",
    "Player 1 passes the ball to Player 2.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    "Player 2 moves forward through on goal.",
    // "Player 2 shoots -> Goal!"
  ];

  final Map<int, String> actionList = {
    0: "Pass Left", // Was Forward, now Left
    1: "Pass Forward-Left", // Was Forward-Right, now Forward-Left
    2: "Pass Forward", // Was Right, now Forward
    3: "Pass Forward-Right", // Was Backward-Right, now Forward-Right
    4: "Pass Right", // Was Backward, now Right
    5: "Pass Backward-Right", // Was Backward-Left, now Backward-Right
    6: "Pass Backward", // Was Left, now Backward
    7: "Pass Backward-Left", // Was Forward-Left, now Backward-Left
    8: "Dribble Left", // Was Dribble Forward, now Dribble Left
    9: "Dribble Forward-Left", // Was Dribble Forward-Right, now Dribble Forward-Left
    10: "Dribble Forward", // Was Dribble Right, now Dribble Forward
    11: "Dribble Forward-Right", // Was Dribble Backward-Right, now Dribble Forward-Right
    12: "Dribble Right", // Was Dribble Backward, now Dribble Right
    13: "Dribble Backward-Right", // Was Dribble Backward-Left, now Dribble Backward-Right
    14: "Dribble Backward", // Was Dribble Left, now Dribble Backward
    15: "Dribble Backward-Left", // Was Dribble Forward-Left, now Dribble Backward-Left
    16: "Shoot", // Shoot remains the same
  };

  Future<void> _captureFieldImage() async {
    try {
      RenderRepaintBoundary boundary =
          _fieldKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory =
          await getApplicationDocumentsDirectory(); // Internal app storage
      final filePath =
          '${directory.path}/tactic_${currentFormationIndex++}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      print('Saved screenshot to: $filePath');

      // add to tactics list
      tactics.add(TacticItem(
        title: "Tactic ${counter++}",
        imagePath: filePath,
        description: _currentDescription,
      ));
    } catch (e) {
      print('Error saving screenshot: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pepFrames = widget.pepFrames;
    _loadFormationsFromJson();
    Future.delayed(const Duration(milliseconds: 500), _startAnimationLoop);
  }

  @override
  void dispose() {
    _talkingAnimationTimer?.cancel();
    super.dispose();
  }

  void _startAnimationLoop() async {
    for (int i = 0; i < formations.length && mounted; i++) {
      setState(() {
        // currentFormationIndex = (currentFormationIndex + i) % formations.length;
        // draw actions[i];
        if (actions.isNotEmpty) {
          // i want the _currentDescription to be the action description + scene id
          _currentDescription =
              "Scene ${i}: " + (actionList[actions[i]] ?? "Unknown Action");
          // _currentDescription = actionList[actions[i]] ?? "Unknown Action";
        } else {
          _currentDescription = _descriptions[i];
        }
        currentPlayers = formations[i];
        // _currentDescription = _descriptions[i];
        _descriptionOpacity = 1.0;
        final ballPlayer = currentPlayers.firstWhere((p) => p.ballpossession,
            orElse: () => currentPlayers[0]);
        ballPosition = Offset(
          ballPlayer.position.dx * MediaQuery.of(context).size.width,
          ballPlayer.position.dy *
              (((MediaQuery.of(context).size.height) -MediaQuery.of(context).padding.top
                     ) *
                  6 /
                  7),
        );
        _startTalkingAnimation();
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _captureFieldImage();

      setState(() {
        _descriptionOpacity = 0.0;
        _stopTalkingAnimation();
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    setState(() {
      _currentDescription = "finish";
      _descriptionOpacity = 0.0;
      _stopTalkingAnimation();
    });
  }

  void _startTalkingAnimation() {
    _talkingAnimationTimer?.cancel();
    _talkingAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      // setState(() {
      //   // _talkingFrameIndex = (_talkingFrameIndex + 1) % _pepFrames.length;
      // });
    });
  }

  void _stopTalkingAnimation() {
    _talkingAnimationTimer?.cancel();
    _talkingFrameIndex = 0;
  }

  void _loadFormationsFromJson() {
    final List<dynamic> jsonData = jsonDecode(widget.jsonString);
    // print("JSON Data: $jsonData");

    formations = jsonData.map<List<Player>>((formation) {
      // Extract action value if present
      int? actionValue;
      final List<Player> players = [];

      for (var p in formation) {
        if (p is Map && p.containsKey('action')) {
          actionValue = p['action'];
        } else {
          players.add(Player.fromJson(p));
          // print("Player: ${p['number']} at position: ${p['position']}");
        }
      }

      // Store action somewhere if needed
      if (actionValue != null) {
        // print("Action for this formation: $actionValue");
        actions.add(actionValue);
        // You could store this in a separate list or map if needed
      }

      return players;
    }).toList();
 
    currentPlayers = formations.first;
    // print("Actions: $actions");
  }

  @override
  Widget build(BuildContext context) {
    return 
       SafeArea( 
         child: Scaffold(
          body: Container(
            color: const Color(0xFF1E6C41),
            child: Column(
              children: [
                Expanded(
                    flex: 1,
                    child: Container(child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldSize = constraints.biggest;
                        return Stack(
                          children: [
                            // Draw Goal
                            CustomPaint(
                              size: fieldSize,
                              painter: Goal(),
                            ),
                          ],
                        );
                      },
                    ))),
                Expanded(
                  flex: 6,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fieldSize = constraints.biggest;
                      return RepaintBoundary(
                        key: _fieldKey,
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: fieldSize,
                              painter: HalfFootballFieldPainter(),
                            ),
                            if (_currentDescription != "")
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: LoadingAnimation(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    height:
                                        MediaQuery.of(context).size.height * 0.3,
                                    imagePrefix: 'assets/pep/pep_',
                                    frameCount: 29,
                                    imageExtension: '.png',
                                    frameDuration:
                                        const Duration(milliseconds: 100),
                                    loop: true,
                                    in_tactics: false,
                                    // currentFrameIndex: _talkingFrameIndex,
                                  ),
                                ),
                              ),
                            ...currentPlayers.map((player) {
                              final pos = Offset(
                                player.position.dx * fieldSize.width,
                                player.position.dy * fieldSize.height,
                              );
                              return AnimatedPositioned(
                                key: ValueKey(player.number),
                                duration: Duration(seconds: 1),
                                left: pos.dx,
                                top: pos.dy ,
                                child: PlayerDot(
                                  team: player.team,
                                  color: player.color,
                                  number: player.number,
                                  highlight: player.ballpossession,
                                ),
                              );
                            }),
                            if (ballPosition != null)
                              AnimatedPositioned(
                                duration: Duration(seconds: 1),
                                left: ballPosition!.dx +
                                    (MediaQuery.of(context).size.width * 0.01),
                                top: ballPosition!.dy -
                                    (MediaQuery.of(context).size.height * 0.03)+15,
                                child: BallWidget(),
                              ),
                            // Add description text here - before the finish buttons
                            if (_currentDescription != "" &&
                                _currentDescription != "finish")
                              Positioned(
                                bottom: 70,
                                left: 20,
                                right: 20,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _currentDescription,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            (_currentDescription == "finish")
                                ? Positioned(
                                    bottom: 20,
                                    right: 10,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              currentFormationIndex = 0;
                                              _currentDescription = "";
                                              _descriptionOpacity = 0.0;
                                              counter = 0;
                                              tactics.clear();
                                            });
                                            Future.delayed(
                                                const Duration(milliseconds: 100),
                                                _startAnimationLoop);
                                          },
                                          child: Row(children: [
                                            Text(
                                              "Reset Tactics",
                                              style: TextStyle(fontSize: 15),
                                            )
                                          ]),
                                        ),
                                        SizedBox(height: 3),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TacticsReportPage(
                                                  tactics: tactics,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "View Report",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
               
             ),
       );
  }
}

class Player {
  final Color color;
  final int number;
  final Offset position;
  final bool ballpossession;
  final int team;

  Player(
      {required this.color,
      required this.number,
      required this.position,
      required this.ballpossession,
      required this.team});

  factory Player.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('action') && !json.containsKey('number')) {
      // Return a default player with action data
      return Player(
        color: Colors.transparent, // Make it invisible
        number: -1, // Special number to indicate action
        position: Offset(0, 0), // Off-screen position
        ballpossession: false,
        team: -1, // Special team for action
      );
    }
    return Player(
      position:  Offset(
        json['position']['dx'] ?? 0.0,
        json['position']['dy'] ?? 0.0,

),

      color: Color(json['color']),
      number: json['number'],
      ballpossession: json['ballpossession'],
      team: json['team'],
    );
  }
}

class PlayerDot extends StatelessWidget {
  final Color color;
  final int team;
  final bool highlight;
  final int number;

  const PlayerDot(
      {required this.color,
      required this.team,
      this.highlight = false,
      required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.03,
      height: MediaQuery.of(context).size.height * 0.03,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (team == 1)
            ? Colors.yellow
            : (team == 3)
                ? Color.fromARGB(255, 0, 64, 255)
                : Color.fromARGB(255, 255, 64, 0),
        shape: BoxShape.circle,
        border:
            Border.all(color: highlight ? Colors.red : Colors.white, width: 3),
      ),
    );
  }
}

class BallWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.015,
      height: MediaQuery.of(context).size.height * 0.015,
      decoration: BoxDecoration(
        color: Colors.deepOrangeAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
    );
  }
}