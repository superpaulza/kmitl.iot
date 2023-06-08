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
  List<BodyTempData> bodyTempDataList = [];
  List<BodyTempData> filteredBodyTempDataList = [];
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

    _dataSubscription = databaseReference
        .child('/$macAddress/records')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          // Clear previous data
          bodyTempDataList.clear();
          filteredBodyTempDataList.clear();

          // Extract heart rate data from the snapshot
          data.forEach((key, value) {
            final heartRate = value['body_temp']['C'];
            final timestamp = value['timestamp'];

            bodyTempDataList
                .add(BodyTempData(timestamp, heartRate.toDouble()));
          });
        });
      }
    });
    updateFilteredData();
  }

  void updateFilteredData() {
    DateTime currentDate = DateTime.now();
    filteredBodyTempDataList.clear();

    if (selectedRangeIndex == 0) {
      // 5 minutes
      const range = Duration(minutes: 5);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 1) {
      // 30 minutes
      const range = Duration(minutes: 30);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 2) {
      // 1 hour
      const range = Duration(hours: 1);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 3) {
      // 6 hours
      const range = Duration(hours: 6);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 4) {
      // 1 day
      const range = Duration(days: 1);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 5) {
      // 1 week
      const range = Duration(days: 7);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 6) {
      // 1 month
      const range = Duration(days: 30);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 7) {
      // 1 year
      const range = Duration(days: 365);
      filteredBodyTempDataList =
          filterDataByRange(currentDate.subtract(range), currentDate);
    } else if (selectedRangeIndex == 8) {
      // All
      filteredBodyTempDataList = List.from(bodyTempDataList);
    }
  }

  List<BodyTempData> filterDataByRange(DateTime startDate, DateTime endDate) {
    return bodyTempDataList.where((data) {
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000);
      return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Body Temp Monitor'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('Select Range: '),
                    SizedBox(width: 16.0),
                    DropdownButton<int>(
                      value: selectedRangeIndex,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedRangeIndex = newValue!;
                          updateFilteredData();
                        });
                      },
                      items: [
                        DropdownMenuItem<int>(
                          value: 0,
                          child: Text('5 min'),
                        ),
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('30 min'),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('1 hour'),
                        ),
                        DropdownMenuItem<int>(
                          value: 3,
                          child: Text('6 hours'),
                        ),
                        DropdownMenuItem<int>(
                          value: 4,
                          child: Text('1 day'),
                        ),
                        DropdownMenuItem<int>(
                          value: 5,
                          child: Text('1 week'),
                        ),
                        DropdownMenuItem<int>(
                          value: 6,
                          child: Text('1 month'),
                        ),
                        DropdownMenuItem<int>(
                          value: 7,
                          child: Text('1 year'),
                        ),
                        DropdownMenuItem<int>(
                          value: 8,
                          child: Text('All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _buildHeartRateGraph(),
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
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              _buildSummaryCard(),
            ],
          ),
        ));
  }

  Widget _buildHeartRateGraph() {
    // Implement your heart rate graph here using a charting library like 'charts_flutter'
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(),
      series: <ChartSeries>[
        LineSeries<BodyTempData, DateTime>(
          dataSource: filteredBodyTempDataList,
          xValueMapper: (BodyTempData data, _) =>
              DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000),
          yValueMapper: (BodyTempData data, _) => data.tempC,
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    // Implement your summary card here with average, max, and min heart rates
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Average: 75 bpm',
              style: TextStyle(fontSize: 16.0),
            ),
            Text(
              'Max: 100 bpm',
              style: TextStyle(fontSize: 16.0),
            ),
            Text(
              'Min: 60 bpm',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}

class BodyTempData {
  final int timestamp;
  final double tempC;

  BodyTempData(this.timestamp, this.tempC);
}
