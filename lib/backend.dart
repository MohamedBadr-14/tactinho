import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

Future<List<List<Map<String, dynamic>>>> sendPlayerData(var jsonSend) async {
  // On Android emulator, use 10.0.2.2 to reach your host machine’s localhost.
  // On iOS simulator or a real device, replace with your machine’s LAN IP or use ngrok.
  final uri = Uri.parse('http://127.0.0.1:5000/api/predict_sequence');

  List<List<Map<String, dynamic>>> allScenes = [];
  // print('Sending data to server: ${jsonEncode(jsonSend)}');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'scene': jsonSend}),
    );
    // print(jsonSend);
    Map<String, dynamic> Shoot_object_2 = {
      "color": 4278190080,
      "number": 99,
      "position": {"dx": 0.53, "dy": -0.04},
      "ballpossession": false,
      "team": 3
    };

    Map<String, dynamic> Shoot_object_1 = {
      "color": 4278190080,
      "number": 500,
      "position": {"dx": 0.44, "dy": -0.04},
      "ballpossession": false,
      "team": 3
    };

    List<Map<String, dynamic>> lastscene = [];
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      if (responseData.containsKey('sequence')) {
        final List<dynamic> sequence = responseData['sequence'];

        // Process each scene in the sequence

        // print('Received sequence: $sequence');

        for (int i = 0; i < sequence.length; i++) {
          List<Map<String, dynamic>> scenePlayersList = [];
          Map<String, dynamic> scene = sequence[i];

          // Process players in the scene
          if (scene.containsKey('players')) {
            Map<String, dynamic> players = scene['players'];

            // Loop through all players
            players.forEach((playerId, playerData) {
              // Extract position from position_transformed
              List<dynamic> positionTransformed =
                  playerData['position_transformed'];
              double dy =
                  (60 - positionTransformed[0]) / 60; // Normalize to 0-1 range
              double dx = positionTransformed[1] / 90; // Normalize to 0-1 range

              // Convert team to color (example mapping)
              int color = playerData['team'] == 0
                  ? 4294901760
                  : 4294901760; // Green for team 0, Red for team 1

              // Create player object in desired format
              Map<String, dynamic> playerObject = {
                "color": color,
                "number": int.parse(playerId) +
                    1, // Use playerId as number or adjust as needed
                "position": {"dx": dx, "dy": dy},
                "ballpossession": playerData['has_ball'] ?? false,
                "team": playerData['team']
              };

              scenePlayersList.add(playerObject);
            });
          }

          // Add goalkeeper if exists

          Map<String, dynamic> keeperObject = {
            "color": 4278190080,
            "number": 97,
            "position": {"dx": 0.485, "dy": 0.02},
            "ballpossession": false,
            "team": 3
          };

          scenePlayersList.add(keeperObject);

// Create a copy of scenePlayersList instead of just a reference
          lastscene = List<Map<String, dynamic>>.from(scenePlayersList);
          scenePlayersList.add(Shoot_object_1);

          scenePlayersList.add(Shoot_object_2);

          // action: 2 example of action
          if (scene.containsKey('action')) {
            scenePlayersList.add({"action": scene['action']});
          }
          // Add scene to all scenes
          allScenes.add(scenePlayersList);
        }
      }

      List<Map<String, dynamic>> Shootsceen = [];
      print("daksdkas $lastscene");
      for (var player in lastscene) {
        Map<String, dynamic> playerCopy = Map<String, dynamic>.from(player);
        playerCopy['ballpossession'] = false;

        Shootsceen.add(playerCopy);
      }
      print("Shootsceen: $Shootsceen");

      // Generate random number (1 or 2)
      final random = Random();
      final randomNumber =
          random.nextInt(2) + 1; // Random number between 1 and 2

      print('Random number generated: $randomNumber');

      if (randomNumber == 1) {
        // Add Shoot_object_1 to Shootsceen
        Shoot_object_1['ballpossession'] = true;
      } else {
        // Add Shoot_object_2 to Shootsceen
        Shoot_object_2['ballpossession'] = true;
      }
      Shootsceen.add(Shoot_object_1);
      Shootsceen.add(Shoot_object_2);
      Shootsceen.add({"action": 16});

      allScenes.add(Shootsceen);

      print(allScenes);

      return allScenes;

      // Success!
    } else {
      // Something went wrong
      print('Error ${response.statusCode}: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Request failed: $e');
    return [];
  }
}
