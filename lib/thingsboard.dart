import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' as typed;



//This method is fully functional in connecting to thingsboard or any other broker using MQTT.
// The application has successfully connected using mqtt and http, and both are implemented to be used as necessary.




typedef OnMessageReceived = void Function(Map<String, dynamic> message);
class MqttService {
  final MqttServerClient client;
  String accessToken;
  OnMessageReceived? onMessageReceived;

  MqttService({
    required this.accessToken,
    this.onMessageReceived,
  }) : client = MqttServerClient('demo.thingsboard.io','client');


  Future<void> connect() async {
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 40;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    final connMess = MqttConnectMessage()
        .withClientIdentifier('client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect(accessToken);
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      client.subscribe('v1/devices/me/attributes/response/+', MqttQos.atLeastOnce);
      requestAttributes();
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received message: $pt from topic: ${c[0].topic}>');
        try {
          final data2 = jsonDecode(pt) as Map<String, dynamic>;
          if (onMessageReceived != null) {
            onMessageReceived!(data2);
            print('data is done');
          }
        } catch (e) {
          print('Error decoding JSON: $e');
        }
      });
    } else {
      print('ERROR: MQTT client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void requestAttributes() {
    final payload = jsonEncode({
      "clientKeys": "temperature,humidity"
    });
    final buffer = typed.Uint8Buffer()..addAll(payload.codeUnits);
    client.publishMessage('v1/devices/me/attributes/request/1', MqttQos.atLeastOnce, buffer);
    print("Published attributes request");
  }

  void onConnected() {
    print('Connected');
    _getdata();
  }


   void disconn(){
    client.disconnect();
  }

  void updateAccessToken(String newAccessToken) {
    accessToken = newAccessToken;
    client.disconnect(); // Disconnect current client

  }

  void onDisconnected() {
    print('Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  void _getdata() {
     Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        requestAttributes();
      } else {

        timer.cancel();
      }
    });
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates => client.updates;
}
