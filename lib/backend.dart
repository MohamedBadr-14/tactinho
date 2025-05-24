import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendPlayerData(var jsonSend) async {
  // On Android emulator, use 10.0.2.2 to reach your host machine’s localhost.
  // On iOS simulator or a real device, replace with your machine’s LAN IP or use ngrok.
  final uri = Uri.parse('http://127.0.0.1:5000/api/predict_sequence');
  



  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'scene' : jsonSend
        }),
    );
    // print(jsonSend);

    if (response.statusCode == 200 || response.statusCode == 201) {

      final responseData = jsonDecode(response.body);
      




      // Success!
      print('Server responded: ${responseData}');
    } else {
      // Something went wrong
      print('Error ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('Request failed: $e');
  }
}
