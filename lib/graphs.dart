import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sense_stm/widget.dart';
import 'http_conn.dart';
import 'thingsboard.dart';


class GraphPage extends StatefulWidget {
  final MqttService mqttService;
  final HttpService httpService;


  GraphPage({required this.httpService, required this.mqttService});
 // GraphPage({required this.mqttService});

  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  Map<String, dynamic> sensorData = {};
  Map<String, dynamic> sensorData2 = {};


  @override
  void initState() {
    super.initState();
    widget.httpService.onMessageReceived = (data) {
      setState(() {
        sensorData = data;
      });
    };

    widget.mqttService.onMessageReceived = (data2) {
      setState(() {
        sensorData2 = data2;
      });
    };

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graphs'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Perform custom actions before navigating back
            HttpService.discon();
            widget.mqttService.disconn();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: LineChartSample(sensorData: sensorData, sensorData2: sensorData2,),
      ),
    );
  }
}
