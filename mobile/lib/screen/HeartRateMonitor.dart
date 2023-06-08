import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HeartRateMonitorPage extends StatefulWidget {
  @override
  _HeartRateMonitorPageState createState() => _HeartRateMonitorPageState();
}

class _HeartRateMonitorPageState extends State<HeartRateMonitorPage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  double heartrateBPM = 0.0;
  List<_ChartData> heartRateDataList = [];
  List<_ChartData> filteredHeartRateDataList = [];
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
        .child('/$macAddress/heart_rate/Avg BPM')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          heartrateBPM = double.parse(event.snapshot.value.toString());
          // Update your dataText variables with the fetched data
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
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
    double averageHeartRate = 0;
    double maxHeartRate = double.negativeInfinity;
    double minHeartRate = double.infinity;

    for (_ChartData data in heartRateDataList) {
      averageHeartRate += data.y1;

      if (data.y1 > maxHeartRate) {
        maxHeartRate = data.y1;
      }

      if (data.y1 < minHeartRate) {
        minHeartRate = data.y1;
      }
    }

    if (heartRateDataList.isNotEmpty) {
      averageHeartRate /= heartRateDataList.length;
    }

    // Build the summary card widget
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Average: ${averageHeartRate.toStringAsFixed(2)} bpm',
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              'Max: ${maxHeartRate.toStringAsFixed(2)} bpm',
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              'Min: ${minHeartRate.toStringAsFixed(2)} bpm',
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
          heartRateDataList.clear();
          filteredHeartRateDataList.clear();

          // Extract heart rate data from the snapshot
          data.forEach((key, value) {
            final heartRate = value['heart_rate']['Avg BPM'];
            final timestamp =
                DateTime.fromMillisecondsSinceEpoch(value['timestamp'] * 1000).add(const Duration(hours: 7));

            heartRateDataList.add(_ChartData(timestamp, heartRate.toDouble()));
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
                        dataSource: heartRateDataList,
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
                    '$heartrateBPM bpm',
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
