import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    sendFlexMessage();
  }
}

void sendFlexMessage() async {
  final url = Uri.parse('https://api.line.me/v2/bot/message/push');
  String channelAccessToken =
      "8g2rzsNHv1jnflo7TtXlLFMQ3f0a5+apgLyjZcwnFaxw8Pb0qhrWA8l6UoKE+Rh7/nQoGG24ps0/EqQfaN0lajNtlgC337+qKvfKyNqh2M6qckhqdVIw0UwSO2J4a/ZIf3VB5C8wL4CrSpRJNyuzrQdB04t89/1O/w1cDnyilFU=";

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $channelAccessToken',
  };

  final requestBody = {
    'to': userID, // Add the user ID of the recipient here
    'messages': [
      {
        "type": "flex",
        "altText": "แจ้งเตือนค่าเกินที่กำหนด",
        "contents": {
          "type": "bubble",
          "body": {
            "type": "box",
            "layout": "vertical",
            "contents": [
              {
                "type": "image",
                "url": "https://cdn-icons-png.flaticon.com/512/559/559343.png",
                "size": "full",
                "aspectRatio": "20:13",
                "aspectMode": "cover"
              },
              {
                "type": "text",
                "text": "แจ้งเตือนค่าเกินที่กำหนด",
                "weight": "bold",
                "size": "md",
                "margin": "lg"
              },
              {
                "type": "box",
                "layout": "baseline",
                "margin": "md",
                "contents": [
                  {
                    "type": "icon",
                    "url":
                        "https://cdn-icons-png.flaticon.com/512/214/214309.png",
                    "size": "xxl"
                  },
                  {
                    "type": "text",
                    "text": "$heartrateBPM bpm",
                    "size": "xl",
                    "align": "start",
                    "gravity": "center"
                  }
                ]
              },
              {
                "type": "text",
                "text": "อัตราการเต้นหัวใจ",
                "size": "sm",
                "color": "#aaaaaa",
                "margin": "md"
              },
              {
                "type": "text",
                "text": "$minHeartRateLimit bpm/$maxHeartRateLimit bpm",
                "size": "sm",
                "color": "#aaaaaa",
                "margin": "md"
              },
              {
                "type": "box",
                "layout": "baseline",
                "margin": "md",
                "contents": [
                  {
                    "type": "icon",
                    "url":
                        "https://upload.wikimedia.org/wikipedia/en/d/d5/Thermometer_icon.png",
                    "size": "xxl"
                  },
                  {
                    "type": "text",
                    "text": "$bodyTemp °C",
                    "size": "xl",
                    "align": "start",
                    "gravity": "center"
                  }
                ]
              },
              {
                "type": "text",
                "text": "อุณหภูมิร่างกาย",
                "size": "sm",
                "color": "#aaaaaa",
                "margin": "md"
              },
              {
                "type": "text",
                "text": "$minBodyTempLimit °C/$maxBodyTempLimit °C",
                "size": "sm",
                "color": "#aaaaaa",
                "margin": "md"
              },
              {"type": "separator", "margin": "lg"},
              {
                "type": "box",
                "layout": "horizontal",
                "margin": "md",
                "contents": [
                  {
                    "type": "button",
                    "action": {
                      "type": "uri",
                      "label": "โทรหาหน่วยแพทย์ฉุกเฉิน",
                      "uri": "tel://1669"
                    },
                    "height": "sm",
                    "style": "primary"
                  }
                ]
              }
            ]
          }
        }
      }
    ]
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
