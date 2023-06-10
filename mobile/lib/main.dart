import 'dart:async';

import 'package:bee_project/firebase_options.dart';
import 'package:bee_project/screen/body_temp_monitor.dart';
import 'package:bee_project/screen/heart_rate_monitor.dart';
import 'package:bee_project/screen/register_band.dart';
import 'package:bee_project/screen/set_alert_notification.dart';
import 'package:bee_project/screen/settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'Screen/main_menu.dart';
import 'background/check_limit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => {
            Workmanager().initialize(callbackDispatcher, isInDebugMode: true),
            Workmanager()
                .registerPeriodicTask("check_sensor_limit", "dataCheckTask",
                    frequency: const Duration(minutes: 15),
                    constraints: Constraints(
                      networkType: NetworkType.connected,
                      // requiresBatteryNotLow: true,
                      // requiresCharging: true,
                      // requiresDeviceIdle: true,
                      // requiresStorageNotLow: true
                    ))
          });
  runApp(const MyApp());
  checkSensorLimit();
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Perform your data checking and sending messages logic here
    await checkSensorLimit();
    // Retrieve the necessary data from the shared preferences or any other source
    // Check the data against the user limits
    // Send LINE messages if necessary
    int? totalExecutions;
    final sharedPreference =
        await SharedPreferences.getInstance(); //Initialize dependency

    try {
      //add code execution
      totalExecutions = sharedPreference.getInt("totalExecutions");
      sharedPreference.setInt(
          "totalExecutions", totalExecutions == null ? 1 : totalExecutions + 1);
    } catch (err) {
      if (kDebugMode) {
        print(err.toString());
      } // Logger flutter package, prints error on the debug console
      throw Exception(err);
    }
    // Return `Future.value(true)` if the task is successful
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'อบอุ่นหัวใจ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const RegisterSmartBandPage(),
      routes: <String, WidgetBuilder>{
        '/setalert': (BuildContext context) => SetAlertNotificationPage(),
        '/heartrate': (BuildContext context) => HeartRateMonitorPage(),
        '/bodytemp': (BuildContext context) => BodyTempMonitorPage(),
        '/settings': (BuildContext context) => SettingsPage(),
        '/register': (BuildContext context) => const RegisterSmartBandPage()
      },
    );
  }
}
