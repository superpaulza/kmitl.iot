import 'package:bee_project/firebase_options.dart';
import 'package:bee_project/screen/body_temp_monitor.dart';
import 'package:bee_project/screen/heart_rate_monitor.dart';
import 'package:bee_project/screen/register_band.dart';
import 'package:bee_project/screen/set_alert_notification.dart';
import 'package:bee_project/screen/settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Screen/main_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
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
