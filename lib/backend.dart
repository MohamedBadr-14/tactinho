import 'dart:convert';

import 'package:http/http.dart' as http;

Future<List<List<Map<String, dynamic>>>> sendPlayerData(var jsonSend) async {
  // On Android emulator, use 10.0.2.2 to reach your host machine’s localhost.
  // On iOS simulator or a real device, replace with your machine’s LAN IP or use ngrok.
  final uri = Uri.parse('http://192.168.100.150:5000/api/predict_sequence');

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      if (responseData.containsKey('sequence')) {
        final List<dynamic> sequence = responseData['sequence'];

        // Process each scene in the sequence

        // print('Received sequence: $sequence');

        for (int i = 0; i < sequence.length; i++) {
          Map<String, dynamic> scene = sequence[i];
          List<Map<String, dynamic>> scenePlayersList = [];

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
                  ? 4278255360
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
          if (scene.containsKey('goalkeeper')) {
            scene['goalkeeper'].forEach((keeperId, keeperData) {
              List<dynamic> positionTransformed =
                  keeperData['position_transformed'];
              double dy =
                  (60 - positionTransformed[0]) / 60; // Normalize to 0-1 range
              double dx = positionTransformed[1] / 90;
              Map<String, dynamic> keeperObject = {
                "color": 4278190080, // Black color for goalkeeper
                "number": int.parse(keeperId) +
                    1, // Using 3 for goalkeeper as in your example
                "position": {"dx": dx, "dy": dy},
                "ballpossession": false,
                "team": 3
              };

              scenePlayersList.add(keeperObject);
            });
          }
          // action: 2 example of action
          if (scene.containsKey('action')){
            scenePlayersList.add({
              "action": scene['action']});
          } 
          // Add scene to all scenes
          allScenes.add(scenePlayersList);
        }
        // print('Processed ${allScenes.length} scenes.');
        // print('First scene players: ${allScenes[0]}');
        // print('Last scene players: ${allScenes.last}');
      }

      // Print the result for debugging
      // print('Transformed data: ${jsonEncode(allScenes)}');
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
