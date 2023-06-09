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
  final databaseReference = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _dataSubscription;
  Timer? _timer;

  double bodyTemp = 0.0;
  double heartrateBPM = 0.0;
  String macAddress = "";
  String channelAccessToken =
      "8g2rzsNHv1jnflo7TtXlLFMQ3f0a5+apgLyjZcwnFaxw8Pb0qhrWA8l6UoKE+Rh7/nQoGG24ps0/EqQfaN0lajNtlgC337+qKvfKyNqh2M6qckhqdVIw0UwSO2J4a/ZIf3VB5C8wL4CrSpRJNyuzrQdB04t89/1O/w1cDnyilFU=";
  String userID = "";

  final TextEditingController _limitHeartRateController =
      TextEditingController();
  final TextEditingController _limitBodyTempController =
      TextEditingController();
  double bodyTempLimit = 0.0;
  double heartRateLimit = 0.0;

  @override
  void initState() {
    super.initState();
    loadData().then((_) {
      startDataSubscription();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        checkThresholds();
      });
    });
  }

  @override
  void dispose() {
    stopDataSubscription();
    _limitHeartRateController.dispose();
    _limitBodyTempController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  loadData() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (savedPref.getString('macAddress') ?? "");
      bodyTempLimit = savedPref.getDouble('bodyTempLimit') ?? 0.0;
      heartRateLimit = savedPref.getDouble('heartRateLimit') ?? 0.0;
      userID = savedPref.getString('userID') ?? "";
      _limitHeartRateController.text = heartRateLimit.toString();
      _limitBodyTempController.text = bodyTempLimit.toString();
    });
  }

  void saveData(double bodyTempLimit, double heartRateLimit) async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    savedPref.setDouble('bodyTempLimit', bodyTempLimit);
    savedPref.setDouble('heartRateLimit', heartRateLimit);
  }

  void showAlertBodyTemp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bodytemp Limit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _limitBodyTempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit (Max: 100 °C)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Set'),
              onPressed: () {
                setState(() {
                  if (double.parse(_limitBodyTempController.text) > 100) {
                    bodyTempLimit = 100;
                    _limitBodyTempController.text = "100";
                  } else {
                    bodyTempLimit = double.parse(_limitBodyTempController.text);
                  }
                  saveData(bodyTempLimit, heartRateLimit);
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
          title: const Text("Heartrate Limit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _limitHeartRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit (Max: 200 bpm)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Set'),
              onPressed: () {
                setState(() {
                  if (double.parse(_limitHeartRateController.text) > 200) {
                    heartRateLimit = 200;
                    _limitHeartRateController.text = "200";
                  } else {
                    heartRateLimit =
                        double.parse(_limitHeartRateController.text);
                  }
                  saveData(bodyTempLimit, heartRateLimit);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void checkThresholds() {
    if (bodyTemp >= bodyTempLimit) {
      sendLineMessage(
          "[แจ้งเตือน] นาฬิกา $macAddress มีอุณหภูมิ $bodyTemp °C, เกินกว่า $bodyTempLimit °C ที่กำหนด");
    }
    if (heartrateBPM >= heartRateLimit) {
      sendLineMessage(
          "[แจ้งเตือน] นาฬิกา $macAddress มีอัตราการเต้นหัวใจ $heartrateBPM bpm, เกินกว่า $heartRateLimit bpm ที่กำหนด");
    }
  }

  void sendLineMessage(String str) async {
    final url = Uri.parse('https://api.line.me/v2/bot/message/multicast');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $channelAccessToken',
    };

    final requestBody = {
      'to': [userID], // Add the user ID of the recipient here
      'messages': [
        {
          'type': 'text',
          'text': str,
          // Modify the notification message as desired
        }
      ],
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      // Notify sent successfully
      if (kDebugMode) {
        print(response.body);
      }
    } else {
      // Handle notify failure
      if (kDebugMode) {
        print(response.body);
      }
    }
  }

  void startDataSubscription() {
    _dataSubscription = databaseReference
        .child('/$macAddress/body_temp/C')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          bodyTemp = double.parse(event.snapshot.value.toString());
          checkThresholds();
        });
      }
    });
    _dataSubscription = databaseReference
        .child('/$macAddress/heart_rate/Avg BPM')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          heartrateBPM = double.parse(event.snapshot.value.toString());
          checkThresholds();
        });
      }
    });
  }

  void stopDataSubscription() {
    _dataSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.count(
          crossAxisCount: 2,
          children: [
            GestureDetector(
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
                      "Heartrate",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        Text(
                          'Limit: $heartRateLimit',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
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
                      "Body Temp",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        Text(
                          'Limit: $bodyTempLimit',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
