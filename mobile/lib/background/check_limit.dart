import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final databaseReference = FirebaseDatabase.instance.ref();
StreamSubscription<DatabaseEvent>? _dataSubscription;
String macAddress = "";
double minBodyTempLimit = 0.0;
double maxBodyTempLimit = 0.0;
double minHeartRateLimit = 0.0;
double maxHeartRateLimit = 0.0;
String userID = "";
double heartrateBPM = 0.0;
double bodyTemp = 0.0;

Future<void> checkSensorLimit() async {
  await getPreference();
  startDataSubscription();
  // Return `Future.value(true)` if the task is successful
  return Future.value(true);
}

Future<void> getPreference() async {
  // Retrieve the necessary data from the shared preferences
  SharedPreferences savedPref = await SharedPreferences.getInstance();
  macAddress = (savedPref.getString('macAddress') ?? "");
  minBodyTempLimit = savedPref.getDouble('minBodyTempLimit') ?? 0.0;
  maxBodyTempLimit = savedPref.getDouble('maxBodyTempLimit') ?? 0.0;
  minHeartRateLimit = savedPref.getDouble('minHeartRateLimit') ?? 0.0;
  maxHeartRateLimit = savedPref.getDouble('maxHeartRateLimit') ?? 0.0;
  userID = savedPref.getString('userID') ?? "";
}

void checkThresholds() {
  if ((bodyTemp < minBodyTempLimit || bodyTemp > maxBodyTempLimit) ||
      (heartrateBPM < minHeartRateLimit || heartrateBPM > maxHeartRateLimit)) {
    sendLineMessage(
        "[แจ้งเตือน] อุปกรณ์ $macAddress มีอุณหภูมิ $bodyTemp °C และมีอัตราการเต้นหัวใจ $heartrateBPM bpm, ซึ่งถึงค่าที่กำหนดไว้");
  }
}

void sendLineMessage(String str) async {
  final url = Uri.parse('https://api.line.me/v2/bot/message/multicast');
  String channelAccessToken =
      "8g2rzsNHv1jnflo7TtXlLFMQ3f0a5+apgLyjZcwnFaxw8Pb0qhrWA8l6UoKE+Rh7/nQoGG24ps0/EqQfaN0lajNtlgC337+qKvfKyNqh2M6qckhqdVIw0UwSO2J4a/ZIf3VB5C8wL4CrSpRJNyuzrQdB04t89/1O/w1cDnyilFU=";

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
      bodyTemp = double.parse(event.snapshot.value.toString());
      checkThresholds();
    }
  });
  _dataSubscription = databaseReference
      .child('/$macAddress/heart_rate/Avg BPM')
      .onValue
      .listen((DatabaseEvent event) {
    if (event.snapshot.value != null) {
      heartrateBPM = double.parse(event.snapshot.value.toString());
      checkThresholds();
    }
  });
}

void stopDataSubscription() {
  _dataSubscription?.cancel();
}
