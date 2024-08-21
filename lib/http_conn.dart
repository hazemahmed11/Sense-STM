import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

//This method connects to thingsboard using http

typedef OnMessageReceived = void Function(Map<String, dynamic> message);

class HttpService {
  final String baseUrl = 'https://demo.thingsboard.io/api/v1';
  String accessToken;
  OnMessageReceived? onMessageReceived;
 static Timer? _fetchTimer;

  HttpService({
    required this.accessToken,
    this.onMessageReceived,
  });

  Future<void> fetchAttributes() async {
    final url = Uri.parse('$baseUrl/$accessToken/attributes');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (onMessageReceived != null) {
          onMessageReceived!(data);
          print('Got the data');
        }
        print('Received data: $data');
      } else {
        print('Failed to fetch attributes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  void startFetchingData() {
    _fetchTimer= Timer.periodic(Duration(seconds: 20), (Timer timer) {
      fetchAttributes();
    });
  }

  void updateAccessToken(String newAccessToken) {
    accessToken = newAccessToken;
    _fetchTimer?.cancel();
    _fetchTimer=null;
  }
  static void discon(){
    _fetchTimer?.cancel();
    _fetchTimer=null;

  }
}
