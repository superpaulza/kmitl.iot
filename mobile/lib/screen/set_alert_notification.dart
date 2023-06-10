import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:http/http.dart' as http;

class SetAlertNotificationPage extends StatefulWidget {
  @override
  _SetAlertNotificationPageState createState() =>
      _SetAlertNotificationPageState();
}

class _SetAlertNotificationPageState extends State<SetAlertNotificationPage> {
  Timer? _timer;
  double bodyTemp = 0.0;
  double heartrateBPM = 0.0;
  String macAddress = "";
  String channelAccessToken =
      "8g2rzsNHv1jnflo7TtXlLFMQ3f0a5+apgLyjZcwnFaxw8Pb0qhrWA8l6UoKE+Rh7/nQoGG24ps0/EqQfaN0lajNtlgC337+qKvfKyNqh2M6qckhqdVIw0UwSO2J4a/ZIf3VB5C8wL4CrSpRJNyuzrQdB04t89/1O/w1cDnyilFU=";
  String userID = "";

  final TextEditingController _minHeartRateController = TextEditingController();
  final TextEditingController _maxHeartRateController = TextEditingController();
  final TextEditingController _minBodyTempController = TextEditingController();
  final TextEditingController _maxBodyTempController = TextEditingController();

  double minBodyTempLimit = 0.0;
  double maxBodyTempLimit = 0.0;
  double minHeartRateLimit = 0.0;
  double maxHeartRateLimit = 0.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _minHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _minBodyTempController.dispose();
    _maxBodyTempController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  loadData() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (savedPref.getString('macAddress') ?? "");
      minBodyTempLimit = savedPref.getDouble('minBodyTempLimit') ?? 0.0;
      maxBodyTempLimit = savedPref.getDouble('maxBodyTempLimit') ?? 0.0;
      minHeartRateLimit = savedPref.getDouble('minHeartRateLimit') ?? 0.0;
      maxHeartRateLimit = savedPref.getDouble('maxHeartRateLimit') ?? 0.0;
      userID = savedPref.getString('userID') ?? "";
      _minHeartRateController.text = minHeartRateLimit.toString();
      _maxHeartRateController.text = maxHeartRateLimit.toString();
      _minBodyTempController.text = minBodyTempLimit.toString();
      _maxBodyTempController.text = maxBodyTempLimit.toString();
    });
  }

  void saveData(double minBodyTempLimit, double maxBodyTempLimit,
      double minHeartRateLimit, double maxHeartRateLimit) async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    savedPref.setDouble('minBodyTempLimit', minBodyTempLimit);
    savedPref.setDouble('maxBodyTempLimit', maxBodyTempLimit);
    savedPref.setDouble('minHeartRateLimit', minHeartRateLimit);
    savedPref.setDouble('maxHeartRateLimit', maxHeartRateLimit);
  }

  void showAlertBodyTemp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ตั้งค่าแจ้งเตือนอุณหภูมิร่างกาย"),
          content: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _minBodyTempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ค่าต่ำกว่า (ค่าสูงสุด: 100 °C)',
                ),
              ),
              TextFormField(
                controller: _maxBodyTempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ค่าสูงกว่า (ค่าสูงสุด: 100 °C)',
                ),
              ),
            ],
          )),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('ตั้งค่า'),
              onPressed: () {
                setState(() {
                  double minLimit = double.parse(_minBodyTempController.text);
                  double maxLimit = double.parse(_maxBodyTempController.text);
                  if (minLimit > maxLimit) {
                    double temp = minLimit;
                    minLimit = maxLimit;
                    maxLimit = temp;
                    _minBodyTempController.text = minLimit.toString();
                    _maxBodyTempController.text = maxLimit.toString();
                  }
                  if (maxLimit > 100) {
                    maxLimit = 100;
                    _maxBodyTempController.text = "100";
                  }
                  minBodyTempLimit = minLimit;
                  maxBodyTempLimit = maxLimit;
                  saveData(minBodyTempLimit, maxBodyTempLimit,
                      minHeartRateLimit, maxHeartRateLimit);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showAlertHeartRate() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ตั้งค่าแจ้งเตือนอัตราการเต้นหัวใจ"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _minHeartRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ค่าต่ำกว่า (ค่าสูงสุด: 200 bpm)',
                  ),
                ),
                TextFormField(
                  controller: _maxHeartRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ค่าสูงกว่า (ค่าสูงสุด: 200 bpm)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('ตั้งค่า'),
              onPressed: () {
                setState(() {
                  double minLimit = double.parse(_minHeartRateController.text);
                  double maxLimit = double.parse(_maxHeartRateController.text);
                  if (minLimit > maxLimit) {
                    double temp = minLimit;
                    minLimit = maxLimit;
                    maxLimit = temp;
                    _minHeartRateController.text = minLimit.toString();
                    _maxHeartRateController.text = maxLimit.toString();
                  }
                  if (maxLimit > 200) {
                    maxLimit = 200;
                    _maxHeartRateController.text = "200";
                  }
                  minHeartRateLimit = minLimit;
                  maxHeartRateLimit = maxLimit;
                  saveData(minBodyTempLimit, maxBodyTempLimit,
                      minHeartRateLimit, maxHeartRateLimit);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าการแจ้งเตือน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => showAlertHeartRate(),
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'อัตราการเต้นหัวใจ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ต่ำสุด: ${minHeartRateLimit.toStringAsFixed(1)} bpm\n'
                        'สูงสุด: ${maxHeartRateLimit.toStringAsFixed(1)} bpm',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => showAlertBodyTemp(),
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.thermostat_outlined,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'อุณหภูมิร่างกาย',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ต่ำสุด: ${minBodyTempLimit.toStringAsFixed(1)} °C\n'
                        'สูงสุด: ${maxBodyTempLimit.toStringAsFixed(1)} °C',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
