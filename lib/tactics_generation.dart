import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tactinho/football_field.dart';
import 'package:tactinho/loading.dart';
import 'package:tactinho/tactics_board.dart';
import 'package:tactinho/backend.dart';

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
          "team": 1,
          "position_transformed": [
            60 - (player.position.dy * 60),
            player.position.dx * 90
          ]
        };
      } else {
        toSend["players"]?[count.toString()] = {
          "team": player.number - 1,
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
  TacticsRun({required this.pepFrames, required this.jsonString });

  @override
  _TacticsRunState createState() => _TacticsRunState();
}

class _TacticsRunState extends State<TacticsRun> {
  List<List<Player>> formations = [];
  List<Player> currentPlayers = [];
  int currentFormationIndex = 0;
  String _currentDescription = "";
  double _descriptionOpacity = 0.0;
  int _talkingFrameIndex = 0;
  Timer? _talkingAnimationTimer;
  late List<Image> _pepFrames;
  Offset? ballPosition;

  final List<String> _descriptions = [
    "Player 1 starts with the ball.",
    "Player 1 moves forward.",
    "Player 1 passes the ball to Player 2.",
    // "Player 2 moves forward through on goal.",
    // "Player 2 shoots -> Goal!"
  ];

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
        currentPlayers = formations[i];
        _currentDescription = _descriptions[i];
        _descriptionOpacity = 1.0;
        final ballPlayer = currentPlayers.firstWhere((p) => p.ballpossession,
            orElse: () => currentPlayers[0]);
        ballPosition = Offset(
          ballPlayer.position.dx * MediaQuery.of(context).size.width,
          ballPlayer.position.dy * MediaQuery.of(context).size.height * 6 / 7,
        );
        _startTalkingAnimation();
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _descriptionOpacity = 0.0;
        _stopTalkingAnimation();
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    setState(() {
      _currentDescription = "GOOAAAALLLLL!!";
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
    formations = jsonData
        .map<List<Player>>((formation) =>
            formation.map<Player>((p) => Player.fromJson(p)).toList())
        .toList();
    currentPlayers = formations.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fieldSize = constraints.biggest;
                  return Stack(
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
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: LoadingAnimation(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: MediaQuery.of(context).size.height * 0.3,
                              imagePrefix: 'assets/pep/pep_',
                              frameCount: 29,
                              imageExtension: '.png',
                              frameDuration: const Duration(milliseconds: 100),
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
                          top: pos.dy - 15,
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
                          left: ballPosition!.dx + 9,
                          top: ballPosition!.dy - 15,
                          child: BallWidget(),
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: (_currentDescription != "")
                  ? Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentDescription,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SizedBox(),
            )
          ],
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
    return Player(
      color: Color(json['color']),
      number: json['number'],
      position: Offset(
          json['position']['dx'].toDouble(), json['position']['dy'].toDouble()),
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
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (team == 1) ? Colors.yellow :(team==2)? Color.fromARGB(255, 255, 64, 0):Color.fromARGB(255, 0, 64, 255),
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
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: Colors.deepOrangeAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
    );
  }
}
