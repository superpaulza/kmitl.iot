import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadData().then((_) {
      fetchData();
    });
  }

  @override
  void dispose() {
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
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filterChartData();
      });
    }
  }

  void filterChartData() {
    filteredBodyTempDataList.clear();
    for (_ChartData data in bodyTempDataList) {
      if (data.x.year == selectedDate.year &&
          data.x.month == selectedDate.month &&
          data.x.day == selectedDate.day) {
        filteredBodyTempDataList.add(data);
      }
    }
  }

  void unpairDevice() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    savedPref.remove('macAddress');
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('อุณหภูมิร่างกาย'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: _showChart(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double averageHeartRate = 0;
    double maxHeartRate = double.negativeInfinity;
    double minHeartRate = double.infinity;

    for (_ChartData data in filteredBodyTempDataList) {
      averageHeartRate += data.y1;

      if (data.y1 > maxHeartRate) {
        maxHeartRate = data.y1;
      }

      if (data.y1 < minHeartRate) {
        minHeartRate = data.y1;
      }
    }

    if (filteredBodyTempDataList.isNotEmpty) {
      averageHeartRate /= filteredBodyTempDataList.length;
    }

    if (minHeartRate == double.infinity ||
        maxHeartRate == double.negativeInfinity) {
      return Text("ไม่พบข้อมูล");
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'ค่าเฉลี่ย: ${averageHeartRate.toStringAsFixed(2)} bpm',
                style: const TextStyle(fontSize: 16.0),
              ),
              Text(
                'สูงสุด: ${maxHeartRate.toStringAsFixed(2)} bpm',
                style: const TextStyle(fontSize: 16.0),
              ),
              Text(
                'ต่ำสุด: ${minHeartRate.toStringAsFixed(2)} bpm',
                style: const TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }
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

          bodyTempDataList.clear();

          data.forEach((key, value) {
            final heartRate = value['body_temp']['C'];
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    value['timestamp'] * 1000,
                    isUtc: true)
                .toLocal();

            bodyTempDataList.add(_ChartData(timestamp, heartRate.toDouble()));
          });

          filterChartData();
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
                        dataSource: filteredBodyTempDataList,
                        trendlines: <Trendline>[
                          Trendline(
                              type: TrendlineType.linear, color: Colors.blue)
                        ],
                        xAxisName: "เวลา",
                        yAxisName: "°C",
                        name: "อุณหภูมิร่างกาย",
                        color: Colors.redAccent,
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
                    style: const TextStyle(fontSize: 40.0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'รายงานประจำวัน \n ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSummaryCard(),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          widget = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ไม่พบอุปกรณ์',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: unpairDevice,
                  child: Text('ยกเลิกการเชื่อมต่ออุปกรณ์'),
                ),
              ],
            ),
          );
        } else {
          widget = Center(child: CircularProgressIndicator());
        }

        return SizedBox(
          width: double.infinity,
          height: 300,
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
