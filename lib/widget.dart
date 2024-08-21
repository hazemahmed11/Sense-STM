import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartSample extends StatefulWidget {
  final Map<String, dynamic> sensorData;
  final Map<String, dynamic> sensorData2;

  LineChartSample({required this.sensorData, required this.sensorData2});

  @override
  _LineChartSampleState createState() => _LineChartSampleState();
}

class _LineChartSampleState extends State<LineChartSample> {
  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  double timecounter = 0;

  @override
  void initState() {
    super.initState();
    _updateChartData(widget.sensorData);
    _updateChartData(widget.sensorData2);

  }

  @override
  void didUpdateWidget(LineChartSample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensorData != widget.sensorData) {
      _updateChartData(widget.sensorData);
    }

    if (oldWidget.sensorData2 != widget.sensorData2) {
      _updateChartData(widget.sensorData2);
    }
  }

  void _updateChartData(Map<String, dynamic> data) {
    setState(() {
      temperatureData.addAll(_generateChartData('temperature', data));
      humidityData.addAll(_generateChartData('humidity', data));
      temperatureData.addAll(_generChartData('temperature', data));
      humidityData.addAll(_generChartData('humidity', data));


    });
  }

  List<FlSpot> _generateChartData(String key, Map<String, dynamic> data) {
    List<FlSpot> chartData = [];
    if (data.containsKey('client')) {
      var clientData = data['client'];
      if (clientData.containsKey(key)) {
        var value = clientData[key];
        double time = timecounter;
        if (value is num) {
          chartData.add(FlSpot(time, value.toDouble()));
          timecounter += 5;
        } else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            double yValue = value[i].toDouble();
            if (yValue.isFinite) {
              chartData.add(FlSpot(time + i * 5, yValue));
            } else {
              print('Invalid data point: $yValue for key $key');
            }
          }
          timecounter += value.length * 5;
        }
      }
    }
    return chartData;
  }

   List<FlSpot> _generChartData(String key, Map<String, dynamic> data) {  //USED FOR MQTT DATA
    List<FlSpot> chartData = [];
    if (widget.sensorData.containsKey('client')) {
      var clientData = widget.sensorData['client'];
      if (clientData.containsKey(key)) {
        var value = clientData[key];
        double time = timecounter;
        if (value is num) {
          chartData.add(FlSpot(time, value.toDouble()));
          timecounter += 5;
        } else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            double yValue = value[i].toDouble();
            if (yValue.isFinite) {
              chartData.add(FlSpot(
                  time + i * 5, yValue));
            } else {
              print('Invalid data point: $yValue for key $key');
            }
          }
          timecounter += value.length *
              5;
        }
      }
    }
    return chartData;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      minY: -20,
                      minX: 0,
                      maxY: 50,
                      maxX: timecounter + 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: temperatureData,
                          isCurved: true,
                          colors: [Colors.red],
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: false,
                            colors: [Colors.red.withOpacity(0.3)],
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(showTitles: true),
                        bottomTitles: SideTitles(showTitles: true),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 60,
                    child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                      'Temperature',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                  ),
                  )],
              ),
            ),
            SizedBox(height: 16), // Space between the two charts
            Expanded(
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      minY: 0,
                      minX: 0,
                      maxY: 50,
                      maxX: timecounter + 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: humidityData,
                          isCurved: true,
                          colors: [Colors.blue],
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: false,
                            colors: [Colors.blue.withOpacity(0.3)],
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(showTitles: true),
                        bottomTitles: SideTitles(showTitles: true),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 60,
                    child: Container(
                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                       color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.blue),
                         ),
                    child: Text(
                      'Humidity',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  )],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
