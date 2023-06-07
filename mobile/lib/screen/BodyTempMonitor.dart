import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BodyTempMonitorPage extends StatefulWidget {
  @override
  _BodyTempMonitorPageState createState() => _BodyTempMonitorPageState();
}

class _BodyTempMonitorPageState extends State<BodyTempMonitorPage> {
  late DatabaseReference _databaseReference;
  List<Record> _heartRateRecords = [];
  int _currentHeartRate = 0;

  @override
  void initState() {
    super.initState();
    _databaseReference =
        FirebaseDatabase.instance.reference().child('heart_rate');
    _startHeartRateListener();
  }

  void _startHeartRateListener() {
    _databaseReference.onChildAdded.listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate Monitor'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Current Heart Rate: $_currentHeartRate bpm',
              style: TextStyle(fontSize: 20.0),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _buildHeartRateGraph(),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Daily Summary',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildHeartRateGraph() {
    // Implement your heart rate graph here using a charting library like 'charts_flutter'
    return Placeholder();
  }

  Widget _buildSummaryCard() {
    // Implement your summary card here with average, max, and min heart rates
    return Card(
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
