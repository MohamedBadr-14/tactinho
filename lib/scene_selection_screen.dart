import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tactinho/tactics_board.dart';
import 'package:tactinho/tactics_generation.dart';
import 'dart:math' as math;

class SceneSelectionScreen extends StatefulWidget {
const SceneSelectionScreen({Key? key}) : super(key: key);

@override
_SceneSelectionScreenState createState() => _SceneSelectionScreenState();
}

class _SceneSelectionScreenState extends State<SceneSelectionScreen> {
bool isLoading = true;
List<dynamic> firstScenes = [];
String errorMessage = '';

@override
void initState() {
    super.initState();
    _fetchFirstScenes();
}

Future<void> _fetchFirstScenes() async {
    setState(() {
    isLoading = true;
    errorMessage = '';
    });

    try {
    final uri = Uri.parse('http://127.0.0.1:5000/api/get_all_first_scenes');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
        firstScenes = data['first_scenes'];
        isLoading = false;
        });
    } else {
        setState(() {
        errorMessage = 'Failed to load scenes: ${response.statusCode}';
        isLoading = false;
        });
    }
    } catch (e) {
    setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
    });
    }
}

List<PlayerFormation> _convertToPlayerFormations(Map<String, dynamic> scene) {
    List<PlayerFormation> players = [];
    
    // Get the original scene data
    final originalScene = scene['original_scene'];
    
    if (originalScene['players'] != null) {
    originalScene['players'].forEach((playerId, playerData) {
        List<dynamic> posTransformed = playerData['position_transformed'];
        double dy = (60 - posTransformed[0]) / 60;
        double dx = posTransformed[1] / 90;
        
        players.add(PlayerFormation(
        color: playerData['team'] == 1 
            ? Colors.yellow 
            : Colors.red,
        number: playerData['team'] == 1 ? 1 : 2,
        position: Offset(dx, dy),
        ballpossession: playerData['has_ball'] ?? false,
        ));
    });
    }
    
    if (originalScene['goalkeeper'] != null) {
    originalScene['goalkeeper'].forEach((id, data) {
        List<dynamic> posTransformed = data['position_transformed'];
        double dy = (60 - posTransformed[0]) / 60;
        double dx = posTransformed[1] / 90;
        
        players.add(PlayerFormation(
        color: Colors.blue,
        number: 3,
        position: Offset(dx, dy),
        ballpossession: false,
        ));
    });
    }
    
    return players;
}

@override
Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
    appBar: AppBar(
        title: Text(
        'Select Scene',
        style: TextStyle(color: colorScheme.onPrimary),
        ),
        backgroundColor: colorScheme.primary,
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Text(errorMessage),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _fetchFirstScenes,
                        child: Text('Retry'),
                    ),
                    ],
                ),
                )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Card(
                        elevation: 4,
                        child: InkWell(
                        onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TacticsBoard(),
                            ),
                            );
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                            children: [
                                Icon(
                                Icons.create,
                                size: 48,
                                color: colorScheme.primary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                'Create Your Own Scene',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                'Set up your own player positions and generate tactics',
                                textAlign: TextAlign.center,
                                ),
                            ],
                            ),
                        ),
                        ),
                    ),
                    SizedBox(height: 24),
                    Text(
                        'Or choose from existing scenes:',
                        style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                        child: firstScenes.isEmpty
                            ? Center(
                                child: Text('No existing scenes available'),
                            )
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                ),
                                itemCount: firstScenes.length,
                                itemBuilder: (context, index) {
                                return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                    onTap: () {
                                        final scene = firstScenes[index];
                                        final playerFormations = _convertToPlayerFormations(scene);
                                        
                                        Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => PrecacheScreen(
                                            scene: playerFormations,
                                            ),
                                        ),
                                        );
                                    },
                                    child: Column(
                                        children: [
                                        Expanded(
                                        child: Container(
                                            color: Colors.green.shade800,
                                            child: Center(
                                            child: SizedBox(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: CustomPaint(
                                                painter: MiniFieldPainter(
                                                    players: _convertToPlayerFormations(firstScenes[index]),
                                                ),
                                                ),
                                            ),
                                            ),
                                        ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                            'Scene ${index + 1}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
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
                ),
    );
}
}
class MiniFieldPainter extends CustomPainter {
final List<PlayerFormation> players;

MiniFieldPainter({required this.players});

@override
void paint(Canvas canvas, Size size) {
    // Base colors
    final grassColor = Color(0xFF4CAF50);
    final lineColor = Colors.white;

    // Define paints
    final grassPaint = Paint()
    ..color = grassColor
    ..style = PaintingStyle.fill;
    
    final alternateGrassPaint = Paint()
    ..color = grassColor.withOpacity(0.9)
    ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
    ..color = lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.005;

    // Draw base grass
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
    
    // Draw alternating grass pattern
    final stripWidth = size.width / 6;
    for (int i = 0; i < 6; i += 2) {
    canvas.drawRect(
        Rect.fromLTWH(i * stripWidth, 0, stripWidth, size.height),
        alternateGrassPaint,
    );
    }
    
    // Field dimensions calculation (keep same proportions as half field)
    final fieldWidth = size.width * 0.95;
    final fieldHeight = size.height * 0.95;
    final borderOffset = size.width * 0.025;
    
    // Outer border
    canvas.drawRect(
    Rect.fromLTWH(
        borderOffset,
        borderOffset,
        fieldWidth,
        fieldHeight,
    ),
    linePaint,
    );
    
    // Calculate goal positions (at the top of the field)
    final goalLineY = borderOffset;
    final goalWidth = fieldWidth * 0.3;
    final goalX = borderOffset + (fieldWidth - goalWidth) / 2;
    
    // Goal line
    canvas.drawLine(
    Offset(goalX, goalLineY),
    Offset(goalX + goalWidth, goalLineY),
    linePaint,
    );
    
    // Penalty area 
    final penaltyAreaWidth = fieldWidth * 0.8;
    final penaltyAreaHeight = fieldHeight * 0.25;
    final penaltyAreaX = borderOffset + (fieldWidth - penaltyAreaWidth) / 2;
    
    canvas.drawRect(
    Rect.fromLTWH(
        penaltyAreaX,
        borderOffset,
        penaltyAreaWidth,
        penaltyAreaHeight,
    ),
    linePaint,
    );
    
    // Goal area
    final goalAreaWidth = penaltyAreaWidth * 0.6;
    final goalAreaHeight = penaltyAreaHeight * 0.6;
    final goalAreaX = borderOffset + (fieldWidth - goalAreaWidth) / 2;
    
    canvas.drawRect(
    Rect.fromLTWH(
        goalAreaX,
        borderOffset,
        goalAreaWidth,
        goalAreaHeight,
    ),
    linePaint,
    );
    
    // Penalty spot
    final penaltySpotY = borderOffset + penaltyAreaHeight * 1.2;
    final penaltySpotX = borderOffset + fieldWidth / 2;
    canvas.drawCircle(
    Offset(penaltySpotX, penaltySpotY),
    size.width * 0.01,
    Paint()..color = lineColor,
    );
    
    // Center line
    final centerY = borderOffset + fieldHeight;
    canvas.drawLine(
    Offset(borderOffset, centerY),
    Offset(borderOffset + fieldWidth, centerY),
    linePaint,
    );
    
    // Center circle (half)
    final centerX = borderOffset + fieldWidth / 2;
    final centerCircleRadius = fieldWidth * 0.15;
    final centerCircleRect = Rect.fromCenter(
    center: Offset(centerX, centerY),
    width: centerCircleRadius * 2,
    height: centerCircleRadius * 2,
    );
    canvas.drawArc(
    centerCircleRect,
    -math.pi, 
    math.pi,
    false,
    linePaint,
    );
    
    // Center spot
    canvas.drawCircle(
    Offset(centerX, centerY),
    size.width * 0.01,
    Paint()..color = lineColor,
    );
    
    // Corner arcs
    final cornerArcRadius = size.width * 0.02;
    
    // Top-left corner
    canvas.drawArc(
    Rect.fromLTWH(
        borderOffset - cornerArcRadius,
        borderOffset - cornerArcRadius,
        cornerArcRadius * 2,
        cornerArcRadius * 2,
    ),
    0,
    math.pi / 2,
    false,
    linePaint,
    );
    
    // Top-right corner
    canvas.drawArc(
    Rect.fromLTWH(
        borderOffset + fieldWidth - cornerArcRadius,
        borderOffset - cornerArcRadius,
        cornerArcRadius * 2,
        cornerArcRadius * 2,
    ),
    math.pi / 2,
    math.pi / 2,
    false,
    linePaint,
    );
    
    // Draw players
    for (var player in players) {
    final playerPaint = Paint()
        ..color = player.color
        ..style = PaintingStyle.fill;
        
    // Flip the y-coordinate to match vertical orientation with goal at top
    final playerPosition = Offset(
        player.position.dx * size.width,
        player.position.dy * size.height, // Use dy for y-coordinate
    );
    
    // Draw player dot
    final playerRadius = size.width * 0.03;
    canvas.drawCircle(playerPosition, playerRadius, playerPaint);
    
    // Add white border to player dot
    final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.005;
    canvas.drawCircle(playerPosition, playerRadius, borderPaint);
    
    // If player has ball possession, draw a small white circle inside
    if (player.ballpossession) {
        final ballPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        canvas.drawCircle(playerPosition, playerRadius * 0.33, ballPaint);
    }
    }
}

@override
bool shouldRepaint(covariant MiniFieldPainter oldDelegate) {
    return true;
}
}
