import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BodyTempMonitorPage extends StatefulWidget {
  @override
  _BodyTempMonitorPageState createState() => _BodyTempMonitorPageState();
}

class _BodyTempMonitorPageState extends State<BodyTempMonitorPage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  double bodyTemp = 0.0;
  List<_ChartData> bodyTempDataList = [];
  List<_ChartData> filteredBodyTempDataList = [];
  int selectedRangeIndex = 0;
  String macAddress = "";

  @override
  void initState() {
    super.initState();
    loadData().then((_) {
      fetchData();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _dataSubscription?.cancel();
    // timer.cancel();
  }

  loadData() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (savedPref.getString('macAddress') ?? "");
    });
  }

  void fetchData() {
    _dataSubscription = databaseReference
        .child('/$macAddress/body_temp/C')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          bodyTemp = double.parse(event.snapshot.value.toString());
          // Update your dataText variables with the fetched data
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Temp Monitor'),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: _showChart(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate average, max, and min heart rates
    double averageTemp = 0;
    double maxTemp = double.negativeInfinity;
    double minTemp = double.infinity;

    for (_ChartData data in bodyTempDataList) {
      averageTemp += data.y1;

      if (data.y1 > maxTemp) {
        maxTemp = data.y1;
      }

      if (data.y1 < minTemp) {
        minTemp = data.y1;
      }
    }

    if (bodyTempDataList.isNotEmpty) {
      averageTemp /= bodyTempDataList.length;
    }

    // Build the summary card widget
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Average: ${averageTemp.toStringAsFixed(2)} °C',
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              'Max: ${maxTemp.toStringAsFixed(2)} °C',
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              'Min: ${minTemp.toStringAsFixed(2)} °C',
              style: const TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showChart() {
    return StreamBuilder(
      stream: databaseReference.child('/$macAddress/records').onValue,
      builder: (context, snapshot) {
        Widget widget;
        if (snapshot.hasData &&
            !snapshot.hasError &&
            snapshot.data?.snapshot.value != null) {
          final data =
          Map<String, dynamic>.from(snapshot.data?.snapshot.value as Map);

          // Clear previous data
          bodyTempDataList.clear();
          filteredBodyTempDataList.clear();

          // Extract heart rate data from the snapshot
          data.forEach((key, value) {
            final heartRate = value['body_temp']['C'];
            final timestamp =
            DateTime.fromMillisecondsSinceEpoch(value['timestamp'] * 1000).add(const Duration(hours: 7));

            bodyTempDataList.add(_ChartData(timestamp, heartRate.toDouble()));
          });

          widget = SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SfCartesianChart(
                    tooltipBehavior: TooltipBehavior(enable: true),
                    primaryXAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.auto,
                    ),
                    primaryYAxis: NumericAxis(),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePanning: true,
                      enablePinching: true,
                    ),
                    series: <ScatterSeries<_ChartData, DateTime>>[
                      ScatterSeries<_ChartData, DateTime>(
                        dataSource: bodyTempDataList,
                        trendlines: <Trendline>[
                          Trendline(
                              type: TrendlineType.linear, color: Colors.blue)
                        ],
                        sortFieldValueMapper: (_ChartData data, _) => data.x,
                        markerSettings: const MarkerSettings(isVisible: true),
                        xValueMapper: (_ChartData data, _) => data.x,
                        yValueMapper: (_ChartData data, _) => data.y1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '$bodyTemp °C',
                    style: const TextStyle(fontSize: 20.0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Daily Summary',
                    style:
                    TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSummaryCard(),
              ],
            ),
          );
        } else {
          widget = const Center(child: CircularProgressIndicator());
        }

        return SizedBox(
          // Wrap the chart in a fixed-sized container to prevent flickering
          width: double.infinity,
          height: 300, // Adjust the height as needed
          child: widget,
        );
      },
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y1);

  final DateTime x;
  final double y1;
}
